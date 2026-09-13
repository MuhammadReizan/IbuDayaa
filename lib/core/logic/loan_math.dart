/// Installment arithmetic, eligibility and the status machine for member loans.
///
/// The cooperative's admins decide every application. Nothing here approves
/// anything — it only computes the numbers both sides look at and refuses
/// status changes that make no sense.
library;

import 'package:flutter/foundation.dart';

import '../../features/credit_score/domain/credit_scoring_engine.dart';
import '../l10n/l10n.dart';
import '../models/account.dart';
import '../models/loan.dart';

@immutable
class LoanQuote {
  const LoanQuote({
    required this.principalIdr,
    required this.tenorMonths,
    required this.flatMonthlyRatePct,
    required this.totalInterestIdr,
    required this.totalRepaymentIdr,
    required this.monthlyInstallmentIdr,
  });

  final int principalIdr;
  final int tenorMonths;
  final double flatMonthlyRatePct;
  final int totalInterestIdr;
  final int totalRepaymentIdr;
  final int monthlyInstallmentIdr;
}

/// Flat rate: interest = principal × rate × months, spread evenly.
LoanQuote quoteLoan({
  required int principalIdr,
  required int tenorMonths,
  required double flatMonthlyRatePct,
}) {
  if (principalIdr <= 0 || tenorMonths <= 0 || flatMonthlyRatePct < 0) {
    throw ArgumentError('Invalid loan terms');
  }
  final interest = (principalIdr * flatMonthlyRatePct / 100 * tenorMonths)
      .round();
  final total = principalIdr + interest;
  return LoanQuote(
    principalIdr: principalIdr,
    tenorMonths: tenorMonths,
    flatMonthlyRatePct: flatMonthlyRatePct,
    totalInterestIdr: interest,
    totalRepaymentIdr: total,
    monthlyInstallmentIdr: (total / tenorMonths).round(),
  );
}

/// Same day-of-month [months] later, clamped to the month's last day
/// (31 Jan + 1 month → 28/29 Feb).
DateTime addMonthsClamped(DateTime d, int months) {
  final target = DateTime(d.year, d.month + months);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  return DateTime(target.year, target.month, d.day.clamp(1, lastDay));
}

/// Monthly schedule from the disbursement date. The last installment absorbs
/// rounding so the schedule sums to exactly [totalIdr].
List<({int seq, DateTime due, int amountIdr})> installmentSchedule({
  required int totalIdr,
  required int tenorMonths,
  required DateTime disbursedAt,
}) {
  final base = totalIdr ~/ tenorMonths;
  final remainder = totalIdr - base * tenorMonths;
  final start = DateTime(disbursedAt.year, disbursedAt.month, disbursedAt.day);
  return [
    for (int i = 1; i <= tenorMonths; i++)
      (
        seq: i,
        due: addMonthsClamped(start, i),
        amountIdr: i == tenorMonths ? base + remainder : base,
      ),
  ];
}

// ---------------------------------------------------------------------------
// Eligibility
// ---------------------------------------------------------------------------

enum LoanBlocker { none, notEnoughHistory, scoreTooLow, activeLoan }

@immutable
class LoanEligibility {
  const LoanEligibility({required this.blocker, required this.ceilingIdr});

  final LoanBlocker blocker;

  /// Largest amount this member may request under the cooperative's policy.
  final int ceilingIdr;

  bool get canApply => blocker == LoanBlocker.none && ceilingIdr > 0;

  String get message => switch (blocker) {
    LoanBlocker.none => 'Anda bisa mengajukan hingga plafon ini.',
    LoanBlocker.notEnoughHistory =>
      'Catat tagihan atau token minimal 3 bulan agar skor bisa dihitung.',
    LoanBlocker.scoreTooLow =>
      'Skor Anda belum mencapai batas minimum yang ditetapkan koperasi.',
    LoanBlocker.activeLoan =>
      'Selesaikan pinjaman yang masih berjalan sebelum mengajukan lagi.',
  };

  String localizedMessage(AppLocalizations l10n) => switch (blocker) {
    LoanBlocker.none => l10n.eligibilityNone,
    LoanBlocker.notEnoughHistory => l10n.eligibilityNotEnoughHistory,
    LoanBlocker.scoreTooLow => l10n.eligibilityScoreTooLow,
    LoanBlocker.activeLoan => l10n.eligibilityActiveLoan,
  };
}

/// Share of the cooperative's maximum each band may request. Published on the
/// application screen so members see why their ceiling is what it is.
const Map<CreditBand, double> kCeilingShareByBand = {
  CreditBand.baikSekali: 1.0,
  CreditBand.baik: 0.75,
  CreditBand.cukup: 0.5,
  CreditBand.perluPeningkatan: 0.25,
};

LoanEligibility loanEligibility({
  required Cooperative coop,
  required CreditScore? score,
  required bool hasActiveLoan,
}) {
  if (hasActiveLoan) {
    return const LoanEligibility(
      blocker: LoanBlocker.activeLoan,
      ceilingIdr: 0,
    );
  }
  if (score == null) {
    return const LoanEligibility(
      blocker: LoanBlocker.notEnoughHistory,
      ceilingIdr: 0,
    );
  }
  if (score.score < coop.loanMinScore) {
    return const LoanEligibility(
      blocker: LoanBlocker.scoreTooLow,
      ceilingIdr: 0,
    );
  }
  final share = kCeilingShareByBand[score.band] ?? 0;
  final raw = coop.loanMaxAmountIdr * share;
  final ceiling = (raw / 100000).floor() * 100000;
  return LoanEligibility(blocker: LoanBlocker.none, ceilingIdr: ceiling);
}

// ---------------------------------------------------------------------------
// Status machine
// ---------------------------------------------------------------------------

const Map<LoanStatus, Set<LoanStatus>> kLoanTransitions = {
  LoanStatus.submitted: {
    LoanStatus.inReview,
    LoanStatus.approved,
    LoanStatus.rejected,
    LoanStatus.cancelled,
  },
  LoanStatus.inReview: {LoanStatus.approved, LoanStatus.rejected},
  LoanStatus.approved: {LoanStatus.disbursed, LoanStatus.cancelled},
  LoanStatus.disbursed: {LoanStatus.repaid},
  LoanStatus.rejected: {},
  LoanStatus.repaid: {},
  LoanStatus.cancelled: {},
};

bool canTransition(LoanStatus from, LoanStatus to) =>
    kLoanTransitions[from]?.contains(to) ?? false;

class LoanRuleException implements Exception {
  const LoanRuleException(this.message);
  final String message;

  @override
  String toString() => message;
}
