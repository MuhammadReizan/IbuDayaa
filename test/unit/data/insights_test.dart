import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/data/app_data.dart';
import 'package:ibudaya/core/data/insights.dart';
import 'package:ibudaya/core/data/models.dart';

import '../../support/fixtures.dart';

void main() {
  group('buildEnergyInsight', () {
    test('returns null when no bill has been recorded', () {
      expect(buildEnergyInsight(AppData(profile: testProfile())), isNull);
    });

    test('attributes cost across declared appliances by share', () {
      final data = AppData(
        profile: testProfile(tariff: 1000),
        bills: [testBill(id: 'b0', monthsAgo: 0, kwh: 200)],
        appliances: [
          // 1000 W for 1 h/day, 7 days → 30 kWh/month.
          testAppliance(id: 'a1', name: 'Oven', watts: 1000, hoursPerDay: 1),
          // 500 W for 1 h/day, 7 days → 15 kWh/month.
          testAppliance(id: 'a2', name: 'Blender', watts: 500, hoursPerDay: 1),
        ],
      );

      final insight = buildEnergyInsight(data)!;

      expect(insight.contributors.first.appliance.name, 'Oven');
      expect(insight.declaredKwh, closeTo(45, 0.01));
      expect(insight.contributors.first.share, closeTo(30 / 45, 0.001));
      expect(insight.contributors.first.monthlyCostIdr, 30000);
      // The bill is bigger than what the appliances explain.
      expect(insight.unaccountedKwh, closeTo(155, 0.01));
      expect(insight.declaredExceedsBill, isFalse);
    });

    test('flags when declared usage exceeds the bill', () {
      final data = AppData(
        profile: testProfile(),
        bills: [testBill(id: 'b0', monthsAgo: 0, kwh: 10)],
        appliances: [
          testAppliance(id: 'a1', name: 'Oven', watts: 2000, hoursPerDay: 8),
        ],
      );

      final insight = buildEnergyInsight(data)!;
      expect(insight.declaredExceedsBill, isTrue);
      expect(insight.unaccountedKwh, 0);
    });

    test('detects a spike against the earlier average, not one month', () {
      final data = AppData(
        profile: testProfile(),
        bills: [
          testBill(id: 'b0', monthsAgo: 0, kwh: 150),
          testBill(id: 'b1', monthsAgo: 1, kwh: 100),
          testBill(id: 'b2', monthsAgo: 2, kwh: 100),
        ],
      );

      final insight = buildEnergyInsight(data)!;
      expect(insight.spikeDetected, isTrue);
      expect(insight.changePct, closeTo(50, 0.01));
    });

    test('a steady month is not a spike', () {
      final data = AppData(
        profile: testProfile(),
        bills: [
          testBill(id: 'b0', monthsAgo: 0, kwh: 102),
          testBill(id: 'b1', monthsAgo: 1, kwh: 100),
          testBill(id: 'b2', monthsAgo: 2, kwh: 101),
        ],
      );
      expect(buildEnergyInsight(data)!.spikeDetected, isFalse);
    });
  });

  group('buildImpact', () {
    test('reports no data rather than zeros on a fresh install', () {
      final impact = buildImpact(AppData(profile: testProfile()));
      expect(impact.hasData, isFalse);
    });

    test('derives solar share and CO2 from recorded sessions', () {
      final now = DateTime.now();
      final data = AppData(
        profile: testProfile(tariff: 1000),
        bills: [testBill(id: 'b0', monthsAgo: 0, kwh: 90)],
        sessions: [
          SolarSession(
            id: 's1',
            applianceName: 'Oven',
            date: now,
            slotLabel: '10.00–12.00',
            kwh: 10,
            recordedAt: now,
          ),
        ],
      );

      final impact = buildImpact(data);

      expect(impact.hasData, isTrue);
      expect(impact.solarKwh, 10);
      expect(impact.gridKwh, 90);
      expect(impact.solarSharePct, 10); // 10 of 100 total
      expect(
        impact.co2AvoidedKg,
        closeTo(10 * kGridEmissionFactorKgPerKwh, 0.001),
      );
      // This month's hub energy valued at the user's own tariff.
      expect(impact.monthlySavingIdr, 10000);
    });
  });

  group('buildObservations', () {
    test('nudges a brand-new user to record a bill and declare appliances', () {
      final observations = buildObservations(AppData(profile: testProfile()));
      final ids = observations.map((o) => o.id);
      expect(ids, contains('obs-nobill'));
      expect(ids, contains('obs-noappliance'));
    });

    test('raises a spike observation with a rupiah figure', () {
      final data = AppData(
        profile: testProfile(tariff: 1000),
        bills: [
          testBill(id: 'b0', monthsAgo: 0, kwh: 150),
          testBill(id: 'b1', monthsAgo: 1, kwh: 100),
          testBill(id: 'b2', monthsAgo: 2, kwh: 100),
        ],
      );

      final spike = buildObservations(
        data,
      ).where((o) => o.id == 'obs-spike').single;

      expect(spike.severity, 'danger');
      expect(spike.body, contains('50.000'));
    });

    test('never claims an AI produced any observation', () {
      final data = AppData(
        profile: testProfile(),
        bills: [
          testBill(id: 'b0', monthsAgo: 0, kwh: 150),
          testBill(id: 'b1', monthsAgo: 1, kwh: 100),
        ],
        appliances: [
          testAppliance(id: 'a1', name: 'Oven', watts: 1000, hoursPerDay: 3),
        ],
      );

      // "AI" as a standalone word — not the "ai" inside "naik"/"nilai".
      final aiWord = RegExp(r'\bAI\b', caseSensitive: false);
      for (final o in buildObservations(data)) {
        expect(aiWord.hasMatch(o.title), isFalse, reason: o.title);
        expect(aiWord.hasMatch(o.body), isFalse, reason: o.body);
        expect(o.body.toLowerCase(), isNot(contains('kecerdasan buatan')));
      }
    });
  });
}
