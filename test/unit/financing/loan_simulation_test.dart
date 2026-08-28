import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';
import 'package:ibudaya/features/financing/domain/financing_simulation.dart';

void main() {
  const params = DemoLoanParams(
    minIdr: 500000,
    maxDemoFinancingIdr: 2000000,
    flatMonthlyRatePct: 2.0,
    eligibleScoreThreshold: 65,
  );

  LoanSimulation run({int principal = 1000000, int tenor = 3}) =>
      LoanSimulation.compute(
        principalIdr: principal,
        purpose: 'Bahan Produksi',
        tenorMonths: tenor,
        params: params,
      );

  group('LoanSimulation.compute — approved flat formula', () {
    test('3 months: cost = principal * rate * tenor', () {
      final s = run(principal: 1000000, tenor: 3);
      // 1_000_000 * 0.02 * 3 = 60_000
      expect(s.totalCostIdr, 60000);
      expect(s.totalRepaymentIdr, 1060000);
      expect(s.monthlyInstallmentIdr, 353333);
    });

    test('6 months', () {
      final s = run(principal: 1000000, tenor: 6);
      // 1_000_000 * 0.02 * 6 = 120_000
      expect(s.totalCostIdr, 120000);
      expect(s.totalRepaymentIdr, 1120000);
      expect(s.monthlyInstallmentIdr, (1120000 / 6).round());
    });

    test('12 months', () {
      final s = run(principal: 2000000, tenor: 12);
      // 2_000_000 * 0.02 * 12 = 480_000
      expect(s.totalCostIdr, 480000);
      expect(s.totalRepaymentIdr, 2480000);
      expect(s.monthlyInstallmentIdr, (2480000 / 12).round());
    });
  });

  group('LoanSimulation.compute — validation', () {
    test('accepts the demo minimum and maximum', () {
      expect(run(principal: 500000).principalIdr, 500000);
      expect(run(principal: 2000000).principalIdr, 2000000);
    });

    test('rejects a principal below the minimum', () {
      expect(
        () => run(principal: 499999),
        throwsA(
          isA<LoanSimulationException>().having(
            (e) => e.error,
            'error',
            LoanSimulationError.belowMinimum,
          ),
        ),
      );
    });

    test('enforces the Rp 2.000.000 demo maximum', () {
      expect(
        () => run(principal: 2000001),
        throwsA(
          isA<LoanSimulationException>().having(
            (e) => e.error,
            'error',
            LoanSimulationError.aboveMaximum,
          ),
        ),
      );
    });

    test('rejects a tenor that is not 3, 6 or 12 months', () {
      for (final t in [1, 4, 9, 24]) {
        expect(
          () => run(tenor: t),
          throwsA(
            isA<LoanSimulationException>().having(
              (e) => e.error,
              'error',
              LoanSimulationError.invalidTenor,
            ),
          ),
          reason: 'tenor $t must be rejected',
        );
      }
    });

    test('rejects invalid rate parameters', () {
      expect(
        () => LoanSimulation.compute(
          principalIdr: 1000000,
          purpose: 'x',
          tenorMonths: 3,
          params: const DemoLoanParams(
            minIdr: 500000,
            maxDemoFinancingIdr: 2000000,
            flatMonthlyRatePct: 0,
            eligibleScoreThreshold: 65,
          ),
        ),
        throwsA(isA<LoanSimulationException>()),
      );
    });
  });
}
