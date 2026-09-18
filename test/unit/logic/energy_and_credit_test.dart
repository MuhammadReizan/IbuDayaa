import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/logic/credit_signals.dart';
import 'package:ibudaya/core/logic/energy_insights.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';

final _now = DateTime(2026, 9, 15);

EnergyRecord _rec({
  required String id,
  required DateTime month,
  required double kwh,
  EnergyKind kind = EnergyKind.postpaid,
  int? total,
}) => EnergyRecord(
  id: id,
  userId: 'u1',
  kind: kind,
  periodMonth: month,
  kwh: kwh,
  totalIdr: total ?? (kwh * 1500).round(),
  source: RecordSource.manual,
  createdAt: month,
);

CreditContext _ctx({
  List<EnergyRecord> records = const [],
  List<ArisanMember> memberships = const [],
  List<ArisanGroup> groups = const [],
  List<ArisanPayment> payments = const [],
  List<LoanInstallment> installments = const [],
}) => CreditContext(
  userId: 'u1',
  now: _now,
  records: records,
  appliances: const [],
  bookings: const [],
  memberships: memberships,
  groups: groups,
  payments: payments,
  installments: installments,
  offers: const [],
);

void main() {
  group('monthlyUsage', () {
    test('a bill wins over tokens in the same month', () {
      final m = monthlyUsage([
        _rec(
          id: 't1',
          month: DateTime(2026, 9),
          kwh: 40,
          kind: EnergyKind.token,
        ),
        _rec(id: 'b1', month: DateTime(2026, 9), kwh: 120),
      ]);
      expect(m.single.kwh, 120);
      expect(m.single.fromTokens, isFalse);
    });

    test('tokens in a month without a bill are summed', () {
      final m = monthlyUsage([
        _rec(
          id: 't1',
          month: DateTime(2026, 9),
          kwh: 40,
          kind: EnergyKind.token,
        ),
        _rec(
          id: 't2',
          month: DateTime(2026, 9),
          kwh: 55.5,
          kind: EnergyKind.token,
        ),
      ]);
      expect(m.single.kwh, closeTo(95.5, 1e-9));
      expect(m.single.fromTokens, isTrue);
      expect(m.single.recordCount, 2);
    });
  });

  test('a spike is measured against the earlier average', () {
    final insight = buildEnergyInsight(
      records: [
        _rec(id: 'a', month: DateTime(2026, 9), kwh: 150),
        _rec(id: 'b', month: DateTime(2026, 8), kwh: 100),
        _rec(id: 'c', month: DateTime(2026, 7), kwh: 100),
      ],
      appliances: const [],
      completedBookings: const [],
      tariff: 1000,
    )!;
    expect(insight.spikeDetected, isTrue);
    expect(insight.changePct, closeTo(50, 1e-9));
    expect(insight.extraCostIdr(1000), 50000);
  });

  group('credit signals', () {
    test('no score before three recorded months', () {
      final c = _ctx(
        records: [
          _rec(id: 'a', month: DateTime(2026, 9), kwh: 100),
          _rec(id: 'b', month: DateTime(2026, 8), kwh: 100),
        ],
      );
      expect(creditReadiness(c).isReady, isFalse);
      expect(creditReadiness(c).monthsStillNeeded, 1);
      expect(
        computeCreditScore(c, const RuleBasedCreditScoringEngine()),
        isNull,
      );
    });

    test('three steady months produce a score', () {
      final c = _ctx(
        records: [
          _rec(id: 'a', month: DateTime(2026, 9), kwh: 100),
          _rec(id: 'b', month: DateTime(2026, 8), kwh: 102),
          _rec(id: 'c', month: DateTime(2026, 7), kwh: 98),
        ],
      );
      final score = computeCreditScore(c, const RuleBasedCreditScoringEngine());
      expect(score, isNotNull);
      expect(creditSignals(c).energyUsageConsistency, greaterThan(0.9));
    });

    test('payment history counts confirmed dues and on-time installments', () {
      final group = ArisanGroup(
        id: 'g',
        cooperativeId: 'c',
        name: 'Melati',
        contributionIdr: 100000,
        // July, August, September → 3 months owed.
        startMonth: DateTime(2026, 7),
        createdBy: 'admin',
        createdAt: DateTime(2026, 7),
      );
      ArisanPayment pay(int month, PaymentStatus status) => ArisanPayment(
        id: 'p$month$status',
        groupId: 'g',
        userId: 'u1',
        type: PaymentType.contribution,
        amountIdr: 100000,
        periodMonth: DateTime(2026, month),
        status: status,
        createdAt: DateTime(2026, month),
      );

      final c = _ctx(
        memberships: [
          ArisanMember(
            id: 'm',
            groupId: 'g',
            userId: 'u1',
            turnOrder: 1,
            joinedAt: DateTime(2026, 7),
          ),
        ],
        groups: [group],
        payments: [
          pay(7, PaymentStatus.confirmed),
          pay(8, PaymentStatus.confirmed),
          // Pending is not yet proof of payment.
          pay(9, PaymentStatus.pending),
        ],
        installments: [
          LoanInstallment(
            id: 'i1',
            loanId: 'l',
            seq: 1,
            dueDate: DateTime(2026, 8, 10),
            amountIdr: 1,
            paidAt: DateTime(2026, 8, 9),
          ),
          LoanInstallment(
            id: 'i2',
            loanId: 'l',
            seq: 2,
            dueDate: DateTime(2026, 9, 10),
            amountIdr: 1,
            paidAt: DateTime(2026, 9, 12),
          ),
          // Not due yet — does not count either way.
          LoanInstallment(
            id: 'i3',
            loanId: 'l',
            seq: 3,
            dueDate: DateTime(2026, 10, 10),
            amountIdr: 1,
          ),
        ],
      );

      // (2 confirmed dues + 1 on-time installment) / (3 owed + 2 due).
      expect(creditSignals(c).paymentHistory, closeTo(3 / 5, 1e-9));
    });

    test(
      'no dues owed yet scores payment history as neutral, not a default',
      () {
        // Not in any arisan group and no loan installments due — there is
        // nothing to have paid late, so this must not read as a negative
        // signal (see rule_based_credit_scoring_engine's reason strings).
        final c = _ctx();
        expect(creditSignals(c).paymentHistory, 0.5);
      },
    );
  });
}
