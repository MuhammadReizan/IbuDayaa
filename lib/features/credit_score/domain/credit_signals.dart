/// Turns the user's own records into the four signals the scoring engine
/// consumes.
///
/// Every signal is arithmetic over things the person actually did — bills they
/// recorded, dues they logged, sessions they ran. Nothing is assumed. When
/// there is not enough history for a signal to mean anything, [CreditReadiness]
/// says so and the screen shows what is still missing instead of a number.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/data/app_data.dart';
import 'credit_scoring_engine.dart';

/// Minimum bills before usage consistency is meaningful.
const int kMinBillsForScore = 3;

@immutable
class CreditReadiness {
  const CreditReadiness({
    required this.billsRecorded,
    required this.hasArisan,
    required this.appliancesDeclared,
  });

  final int billsRecorded;
  final bool hasArisan;
  final int appliancesDeclared;

  /// A score is only shown once usage history can actually be measured.
  bool get isReady => billsRecorded >= kMinBillsForScore;

  int get billsStillNeeded => math.max(0, kMinBillsForScore - billsRecorded);

  /// Plain-language list of what would make the score stronger.
  List<String> get missing => [
    if (billsStillNeeded > 0)
      'Catat $billsStillNeeded tagihan lagi (minimal $kMinBillsForScore bulan).',
    if (!hasArisan) 'Buat atau catat grup arisan Anda.',
    if (appliancesDeclared == 0) 'Daftarkan alat usaha Anda.',
  ];
}

CreditReadiness buildReadiness(AppData data) => CreditReadiness(
  billsRecorded: data.bills.length,
  hasArisan: data.arisan != null,
  appliancesDeclared: data.appliances.length,
);

/// Derives the engine inputs from [data]. Only call when readiness allows.
CreditScoreInputs buildCreditSignals(AppData data) {
  return CreditScoreInputs(
    energyUsageConsistency: _usageConsistency(data),
    paymentHistory: _paymentHistory(data),
    businessActivity: _businessActivity(data),
    communityParticipation: _communityParticipation(data),
  );
}

/// Steadier month-to-month usage scores higher.
///
/// Uses the coefficient of variation (spread relative to the average) so a big
/// household and a small one are judged on steadiness, not on size.
double _usageConsistency(AppData data) {
  final kwh = data.bills.map((b) => b.kwh).where((k) => k > 0).toList();
  if (kwh.length < 2) return 0;
  final mean = kwh.reduce((a, b) => a + b) / kwh.length;
  if (mean <= 0) return 0;
  final variance =
      kwh.map((k) => math.pow(k - mean, 2).toDouble()).reduce((a, b) => a + b) /
      kwh.length;
  final cv = math.sqrt(variance) / mean;
  // cv 0 → 1.0; cv 0.5 or worse → 0.
  return (1 - cv * 2).clamp(0.0, 1.0);
}

/// Share of expected arisan dues the user has actually logged paying.
double _paymentHistory(AppData data) {
  final group = data.arisan;
  if (group == null) return 0;

  final me = group.members.where((m) => m.isMe).firstOrNull;
  if (me == null) return 0;

  final monthsElapsed = _monthsBetween(group.startedAt, DateTime.now()) + 1;
  if (monthsElapsed <= 0) return 0;

  final paid = data.ledger
      .where((e) => e.type == 'contribution' && e.memberId == me.id)
      .length;

  return (paid / monthsElapsed).clamp(0.0, 1.0);
}

/// Evidence the business is running: declared equipment and recent hub use.
double _businessActivity(AppData data) {
  final cutoff = DateTime.now().subtract(const Duration(days: 60));
  final recentSessions = data.sessions
      .where((s) => s.date.isAfter(cutoff))
      .length;

  final appliancePart = (data.appliances.length / 4).clamp(0.0, 1.0);
  final sessionPart = (recentSessions / 8).clamp(0.0, 1.0);

  // Equipment shows capacity; sessions show it is actually being used.
  return (appliancePart * 0.4 + sessionPart * 0.6).clamp(0.0, 1.0);
}

/// Being in a circle, and giving to it.
double _communityParticipation(AppData data) {
  final group = data.arisan;
  if (group == null) return 0;

  final membershipPart = 0.4;
  final shared = data.offers.where((o) => o.status != 'cancelled').length;
  final sharingPart = (shared / 3).clamp(0.0, 1.0) * 0.6;

  return (membershipPart + sharingPart).clamp(0.0, 1.0);
}

int _monthsBetween(DateTime a, DateTime b) =>
    (b.year - a.year) * 12 + (b.month - a.month);

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
