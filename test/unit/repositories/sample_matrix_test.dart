import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/db/local_database.dart';
import 'package:ibudaya/core/db/row.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/core/repositories/local/local_auth_repository.dart';
import 'package:ibudaya/core/repositories/local/local_snapshot_repository.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/selectors.dart';
import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';

/// The sample cooperative is seeded on whatever day and hour someone taps
/// "Coba dengan data contoh", so every promise it makes has to hold at month
/// ends, leap days, midnight and after the last slot — not only on the day the
/// tests were written.
void main() {
  const engine = RuleBasedCreditScoringEngine();

  final clocks = <DateTime>[
    DateTime(2026, 9, 11, 10),
    DateTime(2026, 9, 11, 6, 30),
    DateTime(2026, 9, 11, 17),
    DateTime(2026, 9, 11, 23, 59),
    DateTime(2026, 10, 1, 0, 5),
    DateTime(2026, 10, 31, 23),
    DateTime(2026, 1, 31, 9),
    DateTime(2026, 3, 1, 12),
    DateTime(2026, 12, 31, 14),
    DateTime(2028, 2, 29, 11),
  ];

  for (final at in clocks) {
    test('the sample holds together when seeded at $at', () async {
      final db = await LocalDatabase.open(MemoryDbStorage());
      await SampleSeeder(db, () => at, engine).seed();
      final auth = LocalAuthRepository(db, () => at);
      final admin = await auth.login(
        phone: SampleSeeder.adminPhone,
        pin: SampleSeeder.pin,
      );
      final data = await LocalSnapshotRepository(db, () => at).load(admin);
      final hub = data.hub!;

      // Who is there.
      expect(data.memberProfiles, hasLength(5));
      expect(hub.dailyCapacityKwh, closeTo(17.5, 1e-9));
      expect(hub.maxMembersPerSlot, 5);

      // Nothing the hub or a member's quota forbids.
      final counted = data.bookings.where((b) => b.countsAgainstCapacity);
      final perMonth = <String, double>{};
      for (final b in counted) {
        final k = '${b.userId}|${monthOf(b.bookingDate)}';
        perMonth[k] = (perMonth[k] ?? 0) + b.estKwh;
      }
      for (final e in perMonth.entries) {
        expect(e.value, lessThanOrEqualTo(35 + 1e-9), reason: e.key);
      }
      for (final d in counted.map((b) => dayOf(b.bookingDate)).toSet()) {
        for (final a in data.availabilityOn(d)) {
          expect(a.bookedMembers, lessThanOrEqualTo(5), reason: '$d');
          expect(a.dayBookedKwh, lessThanOrEqualTo(17.5 + 1e-9), reason: '$d');
          expect(a.loadKw, lessThanOrEqualTo(hub.maxLoadKw + 1e-9));
        }
      }
      // One seat per member per slot per day.
      final seats = <String>{};
      for (final b in counted) {
        expect(
          seats.add('${b.userId}|${b.slotId}|${dayOf(b.bookingDate)}'),
          isTrue,
          reason: 'two bookings for one seat',
        );
      }

      // Every scenario the sample promises.
      final byName = {for (final m in data.memberProfiles) m.fullName: m};
      final loansOf = {
        for (final m in data.memberProfiles)
          m.fullName: data.loansOf(m.id).map((l) => l.status).toList(),
      };
      expect(loansOf['Siti Rahma'], [LoanStatus.submitted]);
      expect(loansOf['Ibu Lina'], [LoanStatus.disbursed]);
      expect(loansOf['Ibu Putri'], [LoanStatus.disbursed]);
      expect(loansOf['Ibu Clara'], isEmpty);
      expect(loansOf['Ibu Dewi'], isEmpty);
      expect(data.installmentsAwaiting, hasLength(1));
      expect(
        data.openInstallments.where((i) => i.isOverdue(at)),
        isNotEmpty,
        reason: 'Lina has an overdue installment',
      );

      final withheld = [
        for (final m in data.memberProfiles)
          if (data.scoreOf(m.id, at, engine) == null) m.fullName,
      ];
      expect(withheld, ['Ibu Dewi']);
      for (final m in data.memberProfiles) {
        final score = data.scoreOf(m.id, at, engine);
        if (score != null) {
          expect(score.score, greaterThanOrEqualTo(60), reason: m.fullName);
        }
        expect(
          data.quotaOf(m.id, at).availableKwh,
          greaterThanOrEqualTo(-1e-9),
          reason: '${m.fullName} must not be over her quota',
        );
      }

      // Arisan: Lina has not paid this month, Siti's is waiting.
      final group = data.groups.single;
      expect(
        data.contributionFor(group.id, byName['Ibu Lina']!.id, at),
        isNull,
      );
      expect(
        data.contributionFor(group.id, byName['Siti Rahma']!.id, at)?.status,
        PaymentStatus.pending,
      );
      expect(data.groupMembers, hasLength(4));

      // Dewi's scan waits for the admin while her slot has not ended.
      expect(data.hubRequests.length, lessThanOrEqualTo(1));
      if (at.hour < 17) {
        expect(data.hubRequests, hasLength(1), reason: 'the demo scan');
        expect(data.hubRequests.single.userId, byName['Ibu Dewi']!.id);
      }
      // The four demo logins start with nothing booked today or tomorrow.
      final demo = ['Ibu Clara', 'Siti Rahma', 'Ibu Lina', 'Ibu Putri'];
      final today = dayOf(at);
      for (final n in demo) {
        expect(
          data
              .bookingsOf(byName[n]!.id)
              .where((b) => !b.bookingDate.isBefore(today)),
          isEmpty,
          reason: '$n books for herself',
        );
      }
    });
  }
}
