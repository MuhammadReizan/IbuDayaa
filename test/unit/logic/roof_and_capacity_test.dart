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
      dailyCapacityKwh: 100,
      createdAt: DateTime(2026),
    );
    final slots = [
      _slot('s1', 8, 10, 1),
      _slot('s2', 10, 12, 2),
      _slot('s3', 13, 15, 3),
      _slot('s4', 15, 17, 4),
    ];
    final day = DateTime(2026, 9, 12);

    test('midday slots get more of the day than morning or late slots', () {
      expect(solarWeight(10, 12), greaterThan(solarWeight(8, 10)));
      expect(solarWeight(10, 12), greaterThan(solarWeight(15, 17)));
    });

    test('slot capacities add up to the daily capacity', () {
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: const [],
        date: day,
      );
      expect(
        a.fold<double>(0, (s, x) => s + x.capacityKwh),
        closeTo(100, 1e-6),
      );
    });

    test('only live bookings on that day consume capacity', () {
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: [
          _booking(date: day, kwh: 5),
          _booking(date: day, kwh: 7, status: BookingStatus.cancelled),
          _booking(date: day.add(const Duration(days: 1)), kwh: 9),
        ],
        date: day,
      );
      final s2 = a.firstWhere((x) => x.slot.id == 's2');
      expect(s2.bookedKwh, 5);
      expect(dayCapacity(a).bookedKwh, 5);
    });

    test('recommends the roomiest slot that still fits', () {
      final a = slotAvailability(
        hub: hub,
        slots: slots,
        bookings: [_booking(slotId: 's2', date: day, kwh: 25)],
        date: day,
      );
      final pick = recommendSlot(a, 3);
      expect(pick, isNotNull);
      expect(pick!.slot.id, isNot('s2'));
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
}
