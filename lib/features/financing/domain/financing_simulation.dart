import 'package:flutter/foundation.dart';

import '../../../core/demo/demo_scenario.dart';

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

  /// Pure computation for the simulation.
  /// docs/DATA_MODEL.md §4.3
  static LoanSimulation compute({
    required int principalIdr,
    required String purpose,
    required int tenorMonths,
    required DemoLoanParams params,
  }) {
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
