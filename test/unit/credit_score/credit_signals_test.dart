import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/data/app_data.dart';
import 'package:ibudaya/core/data/models.dart';
import 'package:ibudaya/features/credit_score/domain/credit_signals.dart';

import '../../support/fixtures.dart';

void main() {
  group('CreditReadiness', () {
    test('a new user is not ready and is told what is missing', () {
      final r = buildReadiness(AppData(profile: testProfile()));

      expect(r.isReady, isFalse);
      expect(r.billsStillNeeded, kMinBillsForScore);
      expect(r.missing, isNotEmpty);
      expect(r.missing.first, contains('$kMinBillsForScore'));
    });

    test('becomes ready at the minimum number of bills', () {
      final data = AppData(
        profile: testProfile(),
        bills: [
          for (int i = 0; i < kMinBillsForScore; i++)
            testBill(id: 'b$i', monthsAgo: i, kwh: 100),
        ],
      );
      expect(buildReadiness(data).isReady, isTrue);
    });

    test('one bill short is still not ready', () {
      final data = AppData(
        profile: testProfile(),
        bills: [
          for (int i = 0; i < kMinBillsForScore - 1; i++)
            testBill(id: 'b$i', monthsAgo: i, kwh: 100),
        ],
      );
      expect(buildReadiness(data).isReady, isFalse);
    });
  });

  group('buildCreditSignals', () {
    test('steady usage scores higher than erratic usage', () {
      AppData withKwh(List<double> kwh) => AppData(
        profile: testProfile(),
        bills: [
          for (int i = 0; i < kwh.length; i++)
            testBill(id: 'b$i', monthsAgo: i, kwh: kwh[i]),
        ],
      );

      final steady = buildCreditSignals(
        withKwh([100, 102, 98, 101]),
      ).energyUsageConsistency;
      final erratic = buildCreditSignals(
        withKwh([40, 160, 55, 180]),
      ).energyUsageConsistency;

      expect(steady, greaterThan(erratic));
      expect(steady, greaterThan(0.8));
    });

    test('every signal is zero with no records at all', () {
      final s = buildCreditSignals(AppData(profile: testProfile()));
      expect(s.energyUsageConsistency, 0);
      expect(s.paymentHistory, 0);
      expect(s.businessActivity, 0);
      expect(s.communityParticipation, 0);
    });

    test('payment history reflects dues actually logged', () {
      final now = DateTime.now();
      const me = ArisanMember(id: 'm1', name: 'Ibu Sari', isMe: true);

      AppData withPayments(int count) => AppData(
        profile: testProfile(),
        arisan: ArisanGroup(
          name: 'Melati',
          contributionIdr: 150000,
          members: const [me],
          // Started three months ago → four expected payments including now.
          startedAt: DateTime(now.year, now.month - 3),
        ),
        ledger: [
          for (int i = 0; i < count; i++)
            LedgerEntry(
              id: 'l$i',
              type: 'contribution',
              memberId: me.id,
              memberName: me.name,
              amountIdr: 150000,
              at: DateTime(now.year, now.month - i),
            ),
        ],
      );

      expect(buildCreditSignals(withPayments(0)).paymentHistory, 0);
      expect(
        buildCreditSignals(withPayments(4)).paymentHistory,
        closeTo(1.0, 0.001),
      );
      expect(
        buildCreditSignals(withPayments(2)).paymentHistory,
        closeTo(0.5, 0.001),
      );
    });

    test('business activity rewards recent hub use over equipment alone', () {
      final now = DateTime.now();
      final equipmentOnly = AppData(
        profile: testProfile(),
        appliances: [
          for (int i = 0; i < 4; i++)
            testAppliance(id: 'a$i', name: 'Alat $i', watts: 500),
        ],
      );
      final alsoUsed = equipmentOnly.copyWith(
        sessions: [
          for (int i = 0; i < 8; i++)
            SolarSession(
              id: 's$i',
              applianceName: 'Alat',
              date: now.subtract(Duration(days: i * 3)),
              slotLabel: '10.00–12.00',
              kwh: 2,
              recordedAt: now,
            ),
        ],
      );

      expect(
        buildCreditSignals(alsoUsed).businessActivity,
        greaterThan(buildCreditSignals(equipmentOnly).businessActivity),
      );
    });

    test('signals stay within 0..1 even with extreme data', () {
      final now = DateTime.now();
      final data = AppData(
        profile: testProfile(),
        bills: [
          for (int i = 0; i < 24; i++)
            testBill(id: 'b$i', monthsAgo: i, kwh: 100),
        ],
        appliances: [
          for (int i = 0; i < 40; i++)
            testAppliance(id: 'a$i', name: 'Alat $i', watts: 500),
        ],
        sessions: [
          for (int i = 0; i < 80; i++)
            SolarSession(
              id: 's$i',
              applianceName: 'Alat',
              date: now,
              slotLabel: '10.00–12.00',
              kwh: 2,
              recordedAt: now,
            ),
        ],
        arisan: ArisanGroup(
          name: 'Melati',
          contributionIdr: 1000,
          members: const [ArisanMember(id: 'm1', name: 'Ibu', isMe: true)],
          startedAt: now,
        ),
        offers: [
          for (int i = 0; i < 20; i++)
            QuotaOffer(
              id: 'o$i',
              ownerId: 'm1',
              ownerName: 'Ibu',
              amountKwh: 1,
              slotLabel: 'Sabtu',
              status: 'open',
              createdAt: now,
            ),
        ],
      );

      final s = buildCreditSignals(data);
      for (final v in [
        s.energyUsageConsistency,
        s.paymentHistory,
        s.businessActivity,
        s.communityParticipation,
      ]) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
