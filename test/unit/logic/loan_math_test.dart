import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/logic/loan_math.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/features/credit_score/domain/credit_scoring_engine.dart';

CreditScore _score(int value, CreditBand band) => CreditScore(
  score: value,
  band: band,
  factors: const [],
  eligibilityLabel: '',
  computedAt: DateTime(2026),
);

Cooperative _coop({int max = 5000000, int minScore = 60}) => Cooperative(
  id: 'c',
  name: 'Koperasi',
  city: 'Palembang',
  inviteCode: 'ABC234',
  createdBy: 'a',
  loanMaxAmountIdr: max,
  loanMinScore: minScore,
  createdAt: DateTime(2026),
);

void main() {
  group('quoteLoan', () {
    test('flat rate over the whole tenor', () {
      final q = quoteLoan(
        principalIdr: 2000000,
        tenorMonths: 6,
        flatMonthlyRatePct: 2,
      );
      expect(q.totalInterestIdr, 240000);
      expect(q.totalRepaymentIdr, 2240000);
      expect(q.monthlyInstallmentIdr, 373333);
    });

    test('rejects nonsense terms', () {
      expect(
        () => quoteLoan(principalIdr: 0, tenorMonths: 6, flatMonthlyRatePct: 2),
        throwsArgumentError,
      );
    });
  });

  group('installmentSchedule', () {
    test('sums to exactly the total; the last one absorbs rounding', () {
      final s = installmentSchedule(
        totalIdr: 2240000,
        tenorMonths: 6,
        disbursedAt: DateTime(2026, 3, 10),
      );
      expect(s, hasLength(6));
      expect(s.fold<int>(0, (a, i) => a + i.amountIdr), 2240000);
      expect(s.first.amountIdr, 373333);
      expect(s.last.amountIdr, 373335);
      expect(s.first.due, DateTime(2026, 4, 10));
    });

    test('a 31st disbursement falls due on the last day of short months', () {
      final s = installmentSchedule(
        totalIdr: 300000,
        tenorMonths: 3,
        disbursedAt: DateTime(2027, 1, 31),
      );
      expect(s[0].due, DateTime(2027, 2, 28));
      expect(s[1].due, DateTime(2027, 3, 31));
    });
  });

  group('loanEligibility', () {
    test('no score yet means not enough history', () {
      final e = loanEligibility(
        coop: _coop(),
        score: null,
        hasActiveLoan: false,
      );
      expect(e.blocker, LoanBlocker.notEnoughHistory);
      expect(e.canApply, isFalse);
    });

    test('below the cooperative minimum is blocked', () {
      final e = loanEligibility(
        coop: _coop(minScore: 60),
        score: _score(55, CreditBand.cukup),
        hasActiveLoan: false,
      );
      expect(e.blocker, LoanBlocker.scoreTooLow);
    });

    test('ceiling is the band share of the maximum, rounded down to 100k', () {
      final e = loanEligibility(
        coop: _coop(max: 5000000),
        score: _score(70, CreditBand.baik),
        hasActiveLoan: false,
      );
      expect(e.canApply, isTrue);
      // 5.000.000 × 0,75 = 3.750.000 → 3.700.000.
      expect(e.ceilingIdr, 3700000);
    });

    test('an open loan blocks a second application', () {
      final e = loanEligibility(
        coop: _coop(),
        score: _score(90, CreditBand.baikSekali),
        hasActiveLoan: true,
      );
      expect(e.blocker, LoanBlocker.activeLoan);
    });
  });

  group('status machine', () {
    test('valid path from submission to repayment', () {
      expect(canTransition(LoanStatus.submitted, LoanStatus.inReview), isTrue);
      expect(canTransition(LoanStatus.inReview, LoanStatus.approved), isTrue);
      expect(canTransition(LoanStatus.approved, LoanStatus.disbursed), isTrue);
      expect(canTransition(LoanStatus.disbursed, LoanStatus.repaid), isTrue);
    });

    test('final states cannot be reopened', () {
      expect(canTransition(LoanStatus.rejected, LoanStatus.approved), isFalse);
      expect(canTransition(LoanStatus.repaid, LoanStatus.disbursed), isFalse);
      expect(
        canTransition(LoanStatus.cancelled, LoanStatus.submitted),
        isFalse,
      );
    });

    test('money cannot be disbursed before approval', () {
      expect(
        canTransition(LoanStatus.submitted, LoanStatus.disbursed),
        isFalse,
      );
      expect(canTransition(LoanStatus.inReview, LoanStatus.disbursed), isFalse);
    });
  });
}
