import 'package:flutter/foundation.dart';

import '../../../core/demo/demo_scenario.dart';

/// Why a [LoanSimulation.compute] call was rejected.
enum LoanSimulationError {
  belowMinimum,
  aboveMaximum,
  invalidTenor,
  invalidRate,
  invalidParams,
}

extension LoanSimulationErrorMessage on LoanSimulationError {
  String get message => switch (this) {
    LoanSimulationError.belowMinimum =>
      'Nominal di bawah batas minimum simulasi.',
    LoanSimulationError.aboveMaximum =>
      'Nominal melebihi batas maksimum simulasi.',
    LoanSimulationError.invalidTenor => 'Tenor harus 3, 6, atau 12 bulan.',
    LoanSimulationError.invalidRate => 'Parameter biaya simulasi tidak valid.',
    LoanSimulationError.invalidParams => 'Parameter simulasi tidak valid.',
  };
}

class LoanSimulationException implements Exception {
  LoanSimulationException(this.error);
  final LoanSimulationError error;
  @override
  String toString() => 'LoanSimulationException: ${error.message}';
}

/// Tenors offered by the demo (docs/DATA_MODEL.md §3.12).
const List<int> kAllowedTenorMonths = [3, 6, 12];

/// The transient result of a financing simulation.
/// docs/DATA_MODEL.md §3.12
@immutable
class LoanSimulation {
  const LoanSimulation({
    required this.principalIdr,
    required this.purpose,
    required this.tenorMonths,
    required this.flatMonthlyRatePct,
    required this.totalCostIdr,
    required this.totalRepaymentIdr,
    required this.monthlyInstallmentIdr,
  });

  final int principalIdr;
  final String purpose;
  final int tenorMonths;
  final double flatMonthlyRatePct;
  final int totalCostIdr;
  final int totalRepaymentIdr;
  final int monthlyInstallmentIdr;

  /// Pure computation for the simulation. Validates its inputs and throws a
  /// [LoanSimulationException] on anything out of range — the approved formula
  /// itself is unchanged (docs/DATA_MODEL.md §4.3).
  static LoanSimulation compute({
    required int principalIdr,
    required String purpose,
    required int tenorMonths,
    required DemoLoanParams params,
  }) {
    if (params.minIdr <= 0 || params.maxDemoFinancingIdr < params.minIdr) {
      throw LoanSimulationException(LoanSimulationError.invalidParams);
    }
    if (params.flatMonthlyRatePct <= 0 || params.flatMonthlyRatePct > 100) {
      throw LoanSimulationException(LoanSimulationError.invalidRate);
    }
    if (!kAllowedTenorMonths.contains(tenorMonths)) {
      throw LoanSimulationException(LoanSimulationError.invalidTenor);
    }
    if (principalIdr < params.minIdr) {
      throw LoanSimulationException(LoanSimulationError.belowMinimum);
    }
    if (principalIdr > params.maxDemoFinancingIdr) {
      throw LoanSimulationException(LoanSimulationError.aboveMaximum);
    }

    final double rate = params.flatMonthlyRatePct / 100.0;

    final int totalCostIdr = (principalIdr * rate * tenorMonths).round();
    final int totalRepaymentIdr = principalIdr + totalCostIdr;
    final int monthlyInstallmentIdr = (totalRepaymentIdr / tenorMonths).round();

    return LoanSimulation(
      principalIdr: principalIdr,
      purpose: purpose,
      tenorMonths: tenorMonths,
      flatMonthlyRatePct: params.flatMonthlyRatePct,
      totalCostIdr: totalCostIdr,
      totalRepaymentIdr: totalRepaymentIdr,
      monthlyInstallmentIdr: monthlyInstallmentIdr,
    );
  }
}
