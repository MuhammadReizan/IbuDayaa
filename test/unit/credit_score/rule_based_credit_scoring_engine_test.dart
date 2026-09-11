import 'package:flutter_test/flutter_test.dart';

import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';
import 'package:ibudaya/features/credit_score/domain/credit_scoring_engine.dart';

void main() {
  const engine = RuleBasedCreditScoringEngine();

  // Canonical Ibu Clara inputs (docs/DATA_MODEL.md §4.1).
  const claraInputs = CreditScoreInputs(
    energyUsageConsistency: 0.857,
    paymentHistory: 0.80,
    businessActivity: 0.90,
    communityParticipation: 0.667,
  );

  group('RuleBasedCreditScoringEngine — Ibu Clara canonical output', () {
    late CreditScore result;

    setUpAll(() {
      result = engine.compute(claraInputs);
    });

    test('total score equals 82', () {
      expect(result.score, equals(82));
    });

    test('band is baikSekali', () {
      expect(result.band, equals(CreditBand.baikSekali));
    });

    test('band label is "Baik Sekali"', () {
      expect(result.band.label, equals('Baik Sekali'));
    });

    test('has exactly 4 factors (one per category)', () {
      expect(result.factors.length, equals(4));
    });

    test('factors sum equals total score', () {
      final sum = result.factors.fold(0, (s, f) => s + f.points);
      expect(sum, equals(result.score));
    });

    test('energyUsage factor: 30 / 35', () {
      final f = result.factors.firstWhere(
        (f) => f.category == CreditCategory.energyUsage,
      );
      expect(f.points, equals(30));
      expect(f.maxPoints, equals(35));
    });

    test('paymentHistory factor: 24 / 30', () {
      final f = result.factors.firstWhere(
        (f) => f.category == CreditCategory.paymentHistory,
      );
      expect(f.points, equals(24));
      expect(f.maxPoints, equals(30));
    });

    test('businessActivity factor: 18 / 20', () {
      final f = result.factors.firstWhere(
        (f) => f.category == CreditCategory.businessActivity,
      );
      expect(f.points, equals(18));
      expect(f.maxPoints, equals(20));
    });

    test('communityParticipation factor: 10 / 15', () {
      final f = result.factors.firstWhere(
        (f) => f.category == CreditCategory.communityParticipation,
      );
      expect(f.points, equals(10));
      expect(f.maxPoints, equals(15));
    });

    test('all factors have non-empty labels', () {
      for (final f in result.factors) {
        expect(f.label, isNotEmpty);
      }
    });

    test('all factors have non-empty reasons', () {
      for (final f in result.factors) {
        expect(f.reason, isNotEmpty);
      }
    });

    test('eligibilityLabel is non-empty', () {
      expect(result.eligibilityLabel, isNotEmpty);
    });

    test('eligible score produces a positive eligibility message', () {
      // score = 82 >= threshold (65) → eligible path.
      expect(result.eligibilityLabel.toLowerCase(), contains('layak'));
    });

    test('eligibilityLabel does NOT mention rupiah or loan amounts', () {
      // Correction #4: Rp / amounts belong to the financing domain.
      expect(result.eligibilityLabel, isNot(contains('Rp')));
      expect(result.eligibilityLabel, isNot(contains('2.000.000')));
    });

    test('engine description does NOT mention AI or machine learning', () {
      // Product-honesty: the engine is rule-based, not AI/ML.
      // We verify the band label and eligibility message are free of
      // AI/ML claims (the engine class itself has no such strings).
      final text = [
        result.band.label,
        result.eligibilityLabel,
        ...result.factors.map((f) => f.reason),
        ...result.factors.map((f) => f.label),
      ].join(' ').toLowerCase();
      expect(text, isNot(contains('machine learning')));
      expect(text, isNot(contains('ai model')));
      expect(text, isNot(contains('artificial intelligence')));
    });
  });

  group('RuleBasedCreditScoringEngine — band thresholds', () {
    CreditScore scoreFor(double signal) => engine.compute(
      CreditScoreInputs(
        energyUsageConsistency: signal,
        paymentHistory: signal,
        businessActivity: signal,
        communityParticipation: signal,
      ),
    );

    test('score 0 → perluPeningkatan', () {
      expect(scoreFor(0).band, equals(CreditBand.perluPeningkatan));
    });

    test('score ≥ 80 → baikSekali (all max)', () {
      expect(scoreFor(1.0).band, equals(CreditBand.baikSekali));
    });

    test('score in 65–79 → baik', () {
      // Tune: 0.65 * 35=22.75→23, 0.65*30=19.5→20, 0.65*20=13, 0.65*15=9.75→10
      // sum = 23+20+13+10 = 66 → baik
      final s = engine.compute(
        const CreditScoreInputs(
          energyUsageConsistency: 0.65,
          paymentHistory: 0.65,
          businessActivity: 0.65,
          communityParticipation: 0.65,
        ),
      );
      expect(s.band, equals(CreditBand.baik));
    });

    test('score in 50–64 → cukup', () {
      // 0.50 * 35=17.5→18, *30=15, *20=10, *15=7.5→8  sum=51 → cukup
      final s = engine.compute(
        const CreditScoreInputs(
          energyUsageConsistency: 0.50,
          paymentHistory: 0.50,
          businessActivity: 0.50,
          communityParticipation: 0.50,
        ),
      );
      expect(s.band, equals(CreditBand.cukup));
    });
  });

  group('RuleBasedCreditScoringEngine — factor direction', () {
    test('ratio >= 0.6 → positive direction', () {
      final result = engine.compute(
        const CreditScoreInputs(
          energyUsageConsistency: 0.857, // 30/35 = 0.857 >= 0.6
          paymentHistory: 0.80,
          businessActivity: 0.90,
          communityParticipation: 0.667,
        ),
      );
      for (final f in result.factors) {
        expect(f.direction, equals(FactorDirection.positive));
      }
    });

    test('ratio < 0.4 → negative direction', () {
      final result = engine.compute(
        const CreditScoreInputs(
          energyUsageConsistency: 0.1, // 0.1 * 35 = 3.5 → 4; 4/35 ≈ 0.11 < 0.4
          paymentHistory: 0.1,
          businessActivity: 0.1,
          communityParticipation: 0.1,
        ),
      );
      for (final f in result.factors) {
        expect(f.direction, equals(FactorDirection.negative));
      }
    });
  });

  group('RuleBasedCreditScoringEngine — edge cases', () {
    test('signals clamped to 0–1 range', () {
      final overMax = engine.compute(
        const CreditScoreInputs(
          energyUsageConsistency: 2.0, // clamped to 1.0
          paymentHistory: 1.5,
          businessActivity: -0.5, // clamped to 0.0
          communityParticipation: 1.0,
        ),
      );
      // energyUsage: round(1.0*35)=35, paymentHistory: round(1.0*30)=30,
      // businessActivity: round(0.0*20)=0, communityParticipation: round(1.0*15)=15
      expect(
        overMax.factors
            .firstWhere((f) => f.category == CreditCategory.energyUsage)
            .points,
        equals(35),
      );
      expect(
        overMax.factors
            .firstWhere((f) => f.category == CreditCategory.businessActivity)
            .points,
        equals(0),
      );
    });

    test('compute is a pure function — same input same output', () {
      final r1 = engine.compute(claraInputs);
      final r2 = engine.compute(claraInputs);
      expect(r1.score, equals(r2.score));
      expect(r1.band, equals(r2.band));
    });

    test('implements CreditScoringEngine interface', () {
      expect(engine, isA<CreditScoringEngine>());
    });
  });
}
