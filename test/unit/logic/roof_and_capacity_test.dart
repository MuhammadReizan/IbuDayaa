import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/logic/hub_capacity.dart';
import 'package:ibudaya/core/logic/quota_ledger.dart';
import 'package:ibudaya/core/logic/roof_estimator.dart';
import 'package:ibudaya/core/models/models.dart';

HubSlot _slot(String id, int start, int end, int sort) =>
    HubSlot(id: id, hubId: 'h', startHour: start, endHour: end, sort: sort);

HubBooking _booking({
  String slotId = 's2',
  String userId = 'u1',
  required DateTime date,
  double kwh = 3,
  BookingStatus status = BookingStatus.booked,
}) => HubBooking(
  id: 'b${date.day}$slotId$kwh$status',
  hubId: 'h',
  slotId: slotId,
  userId: userId,
  applianceName: 'Oven',
  bookingDate: date,
  estKwh: kwh,
  status: status,
  createdAt: date,
);

void main() {
  group('estimateRoof', () {
    test('north-facing, unshaded 10×6 m roof', () {
      final e = estimateRoof(
        lengthM: 10,
        widthM: 6,
        orientation: RoofOrientation.north,
        shading: RoofShading.none,
        tariffIdrPerKwh: 1500,
        costPerKwpIdr: 15000000,
      );
      expect(e.usableAreaM2, closeTo(42, 1e-9));
      expect(e.kwp, closeTo(7, 1e-9));
      // 7 kWp × 4 h × 0,8 × 30 days.
      expect(e.monthlyKwh, closeTo(672, 1e-9));
      expect(e.monthlySavingIdr, 1008000);
      expect(e.systemCostIdr, 105000000);
      expect(e.paybackYears, closeTo(8.68, 0.01));
      expect(e.band, 'Sangat Layak');
    });

    test('savings are capped at what the business actually uses', () {
      final e = estimateRoof(
        lengthM: 10,
        widthM: 6,
        orientation: RoofOrientation.north,
        shading: RoofShading.none,
        tariffIdrPerKwh: 1500,
        costPerKwpIdr: 15000000,
        monthlyUsageKwh: 200,
      );
      expect(e.monthlySavingIdr, 300000);
    });

    test('heavy shade drags a large roof down', () {
      final e = estimateRoof(
        lengthM: 10,
        widthM: 6,
        orientation: RoofOrientation.south,
        shading: RoofShading.heavy,
        tariffIdrPerKwh: 1500,
        costPerKwpIdr: 15000000,
      );
      expect(e.band, isNot('Sangat Layak'));
      expect(e.siteFactor, lessThan(0.5));
    });
  });

  group('hub capacity', () {
    final hub = SolarHub(
      id: 'h',
      cooperativeId: 'c',
      name: 'Hub',
      location: 'Balai',
      dailyCapacityKwh: 17.5,
      createdAt: DateTime(2026),
      maxMembersPerSlot: 5,
    );
    final slots = [
      _slot('s1', 8, 10, 1),
      _slot('s2', 10, 12, 2),
      _slot('s3', 13, 15, 3),
      _slot('s4', 15, 17, 4),
    ];
    final day = DateTime(2026, 9, 12);

    test('the hub plans for members × quota ÷ 30 days', () {
      expect(
        dailyCapacityForQuota(members: 15, monthlyQuotaKwh: 35),
        closeTo(17.5, 1e-9),
      );
      expect(
        dailyCapacityForQuota(members: 5, monthlyQuotaKwh: 35),
        closeTo(5.83, 0.01),
      );
    });

    test('one booking, however big, does not fill a slot', () {
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: [_booking(slotId: 's2', date: day, kwh: 4.5)],
        date: day,
      );
      final s2 = a.firstWhere((x) => x.slot.id == 's2');
      expect(s2.bookedMembers, 1);
      expect(s2.isFull, isFalse);
      expect(s2.remainingSeats, 4);
      // Energy is the day's, shared by every slot.
      expect(s2.dayRemainingKwh, closeTo(13, 1e-9));
      expect(a.every((x) => x.dayRemainingKwh == s2.dayRemainingKwh), isTrue);
    });

    test('a slot is full when its seats are taken, by different members', () {
      final bookings = [
        for (int i = 0; i < 5; i++)
          _booking(slotId: 's2', userId: 'u$i', date: day, kwh: 0.5),
      ];
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: bookings,
        date: day,
      );
      final s2 = a.firstWhere((x) => x.slot.id == 's2');
      expect(s2.bookedMembers, 5);
      expect(s2.isFull, isTrue);
      expect(s2.hasSeat, isFalse);
      expect(a.firstWhere((x) => x.slot.id == 's1').isFull, isFalse);
    });

    test('seats count members, not bookings, and not cancelled ones', () {
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: [
          _booking(slotId: 's2', userId: 'u1', date: day),
          _booking(slotId: 's2', userId: 'u1', date: day, kwh: 1),
          _booking(
            slotId: 's2',
            userId: 'u2',
            date: day,
            status: BookingStatus.cancelled,
          ),
        ],
        date: day,
      ).firstWhere((x) => x.slot.id == 's2');
      expect(a.bookedMembers, 1);
    });

    test('three seats per slot work the same way', () {
      final three = hub.copyWith(maxMembersPerSlot: 3);
      final a = slotAvailability(
        hub: three,
        slots: slots,
        bookings: [
          for (int i = 0; i < 3; i++)
            _booking(slotId: 's1', userId: 'u$i', date: day, kwh: 0.5),
        ],
        date: day,
      ).firstWhere((x) => x.slot.id == 's1');
      expect(a.isFull, isTrue);
    });

    test('no seat limit set means seats are not checked', () {
      final open = hub.copyWith(maxMembersPerSlot: 0);
      final a = slotAvailability(
        hub: open,
        slots: slots,
        bookings: [
          for (int i = 0; i < 12; i++)
            _booking(slotId: 's1', userId: 'u$i', date: day, kwh: 0.5),
        ],
        date: day,
      ).firstWhere((x) => x.slot.id == 's1');
      expect(a.hasSeatLimit, isFalse);
      expect(a.isFull, isFalse);
    });

    test('only live bookings on that day consume the day', () {
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: [
          _booking(date: day, kwh: 5),
          _booking(
            userId: 'u2',
            date: day,
            kwh: 7,
            status: BookingStatus.cancelled,
          ),
          _booking(
            userId: 'u3',
            date: day.add(const Duration(days: 1)),
            kwh: 9,
          ),
        ],
        date: day,
      );
      final s2 = a.firstWhere((x) => x.slot.id == 's2');
      expect(s2.bookedKwh, 5);
      expect(dayCapacity(a).bookedKwh, 5);
      expect(dayCapacity(a).capacityKwh, 17.5);
      expect(a.first.fitsKwh(12.5), isTrue);
      expect(a.first.fitsKwh(12.6), isFalse);
    });

    test('recommends the least crowded slot that still fits', () {
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: [
          _booking(slotId: 's1', userId: 'u1', date: day, kwh: 1),
          _booking(slotId: 's1', userId: 'u2', date: day, kwh: 1),
          _booking(slotId: 's2', userId: 'u3', date: day, kwh: 1),
        ],
        date: day,
      );
      final pick = recommendSlot(a, 3);
      expect(pick, isNotNull);
      expect(pick!.slot.id, 's3');
      expect(recommendSlot(a, 1000), isNull);
    });
  });

  test('quota balance: allocation − booked − given + received', () {
    final month = DateTime(2026, 9);
    final balance = quotaBalance(
      userId: 'u1',
      month: month,
      allocationKwh: 30,
      bookings: [
        _booking(date: DateTime(2026, 9, 3), kwh: 5),
        _booking(date: DateTime(2026, 8, 3), kwh: 3),
        _booking(
          date: DateTime(2026, 9, 4),
          kwh: 6,
          status: BookingStatus.cancelled,
        ),
      ],
      offers: [
        QuotaOffer(
          id: 'o1',
          cooperativeId: 'c',
          ownerId: 'u1',
          kind: QuotaKind.share,
          kwh: 2,
          slotNote: 'Sabtu',
          status: QuotaStatus.completed,
          counterpartyId: 'u2',
          createdAt: month,
          updatedAt: DateTime(2026, 9, 5),
        ),
        QuotaOffer(
          id: 'o2',
          cooperativeId: 'c',
          ownerId: 'u1',
          kind: QuotaKind.need,
          kwh: 4,
          slotNote: 'Minggu',
          status: QuotaStatus.completed,
          counterpartyId: 'u3',
          createdAt: month,
          updatedAt: DateTime(2026, 9, 6),
        ),
      ],
    );
    expect(balance.bookedKwh, 5);
    expect(balance.givenKwh, 2);
    expect(balance.receivedKwh, 4);
    expect(balance.availableKwh, 27);
  });

  group('monthly quota: used, booked and what is left', () {
    final month = DateTime(2026, 10);
    QuotaBalance balance(List<HubBooking> bookings) => quotaBalance(
      userId: 'u1',
      month: month,
      allocationKwh: 35,
      bookings: bookings,
      offers: const [],
    );

    test('a recorded session comes off the 35 kWh as used', () {
      final b = balance([
        _booking(
          date: DateTime(2026, 10, 1),
          kwh: 3,
          status: BookingStatus.completed,
        ),
      ]);
      expect(b.usedKwh, 3);
      expect(b.reservedKwh, 0);
      expect(b.availableKwh, 32);
    });

    test('a booking not used yet is reserved, and counted once', () {
      final b = balance([
        _booking(
          slotId: 's1',
          date: DateTime(2026, 10, 1),
          kwh: 3,
          status: BookingStatus.completed,
        ),
        _booking(slotId: 's2', date: DateTime(2026, 10, 5), kwh: 2),
        _booking(
          slotId: 's3',
          date: DateTime(2026, 10, 6),
          kwh: 4,
          status: BookingStatus.cancelled,
        ),
        _booking(slotId: 's4', date: DateTime(2026, 9, 28), kwh: 9),
      ]);
      expect(b.usedKwh, 3);
      expect(b.reservedKwh, 2);
      expect(b.bookedKwh, 5);
      expect(b.availableKwh, 30);
      expect(b.usedFraction, closeTo(5 / 35, 1e-9));
    });

    test('quota received and given change the month\'s total', () {
      final b = QuotaBalance(
        allocationKwh: 35,
        bookedKwh: 10,
        usedKwh: 10,
        givenKwh: 2,
        receivedKwh: 5,
      );
      expect(b.totalKwh, 38);
      expect(b.availableKwh, 28);
    });

    test('energy used today counts only what the hub recorded today', () {
      final today = DateTime(2026, 10, 7);
      final used = usedOnDay(
        userId: 'u1',
        day: today,
        bookings: [
          _booking(
            slotId: 's1',
            date: today,
            kwh: 3,
            status: BookingStatus.completed,
          ),
          _booking(slotId: 's2', date: today, kwh: 2),
          _booking(
            slotId: 's3',
            date: today.subtract(const Duration(days: 1)),
            kwh: 4,
            status: BookingStatus.completed,
          ),
        ],
      );
      expect(used, 3);
    });

    test(
      'days left count today, and the pace spreads what is left over them',
      () {
        final first = quotaPace(
          now: DateTime(2026, 10, 1, 9),
          availableKwh: 31,
        );
        expect(first.daysLeft, 31);
        expect(first.lastDay, DateTime(2026, 10, 31));
        expect(first.perDayKwh, closeTo(1, 1e-9));

        final last = quotaPace(now: DateTime(2026, 10, 31), availableKwh: 4);
        expect(last.daysLeft, 1);
        expect(last.perDayKwh, 4);

        expect(
          quotaPace(now: DateTime(2026, 2, 10), availableKwh: 0).perDayKwh,
          0,
        );
        expect(
          quotaPace(now: DateTime(2026, 2, 10), availableKwh: 5).daysLeft,
          19,
        );
        expect(
          quotaPace(now: DateTime(2026, 2, 10), availableKwh: -3).perDayKwh,
          0,
        );
      },
    );
  });

  group('simultaneous load', () {
    SolarHub hub({double maxLoadKw = 5}) => SolarHub(
      id: 'h',
      cooperativeId: 'c',
      name: 'Hub',
      location: '',
      dailyCapacityKwh: 16,
      createdAt: DateTime(2026, 9, 1),
      maxLoadKw: maxLoadKw,
    );

    HubBooking load(String slotId, double kw, {String id = 'x'}) => HubBooking(
      id: id,
      hubId: 'h',
      slotId: slotId,
      userId: 'u',
      applianceName: 'A',
      bookingDate: DateTime(2026, 9, 12),
      estKwh: 1,
      loadKw: kw,
      status: BookingStatus.booked,
      createdAt: DateTime(2026, 9, 1),
    );

    test(
      'sums the load booked into a slot and checks it against the limit',
      () {
        final slots = [_slot('s1', 8, 10, 1), _slot('s2', 10, 12, 2)];
        final a = slotAvailability(
          hub: hub(),
          slots: slots,
          bookings: [
            load('s2', 3, id: 'a'),
            load('s2', 1, id: 'b'),
          ],
          date: DateTime(2026, 9, 12),
        ).firstWhere((x) => x.slot.id == 's2');
        expect(a.loadKw, 4);
        expect(a.remainingKw, 1);
        expect(a.fitsLoad(1), isTrue);
        expect(a.fitsLoad(1.5), isFalse);
      },
    );

    test('no limit set means load is not checked', () {
      final a = slotAvailability(
        hub: hub(maxLoadKw: 0),
        slots: [_slot('s1', 8, 10, 1)],
        bookings: [load('s1', 50)],
        date: DateTime(2026, 9, 12),
      ).single;
      expect(a.hasLoadLimit, isFalse);
      expect(a.fitsLoad(100), isTrue);
    });

    test('recommendSlot skips closed, full and overloaded slots', () {
      final slots = [
        SlotAvailability(
          slot: HubSlot(
            id: 'closed',
            hubId: 'h',
            startHour: 10,
            endHour: 12,
            sort: 1,
            isOpen: false,
          ),
          dayCapacityKwh: 10,
          maxLoadKw: 5,
        ),
        SlotAvailability(
          slot: _slot('busy', 12, 14, 2),
          dayCapacityKwh: 10,
          loadKw: 4.5,
          maxLoadKw: 5,
        ),
        SlotAvailability(
          slot: _slot('full', 14, 16, 3),
          dayCapacityKwh: 10,
          seatLimit: 2,
          bookedMembers: 2,
          maxLoadKw: 5,
        ),
        SlotAvailability(
          slot: _slot('ok', 16, 18, 4),
          dayCapacityKwh: 10,
          seatLimit: 2,
          bookedMembers: 1,
          maxLoadKw: 5,
        ),
      ];
      expect(recommendSlot(slots, 2, neededKw: 2)?.slot.id, 'ok');
    });
  });
}
