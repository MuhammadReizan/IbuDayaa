/// Turns a member's recorded behaviour into the four signals the rule-based
/// scoring engine consumes, and says when there is not yet enough history for
/// a score to mean anything.
///
/// In the Supabase build this runs server-side (see `supabase/migrations`), so
/// a member cannot edit her own inputs to inflate the score.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../features/credit_score/domain/credit_scoring_engine.dart';
import '../db/row.dart';
import '../models/models.dart';
import 'energy_insights.dart';

const int kMinMonthsForScore = 3;

@immutable
class CreditContext {
  const CreditContext({
    required this.userId,
    required this.now,
    required this.records,
    required this.appliances,
    required this.bookings,
    required this.memberships,
    required this.groups,
    required this.payments,
    required this.installments,
    required this.offers,
  });

  final String userId;
  final DateTime now;
  final List<EnergyRecord> records;
  final List<Appliance> appliances;
  final List<HubBooking> bookings;
  final List<ArisanMember> memberships;
  final List<ArisanGroup> groups;
  final List<ArisanPayment> payments;
  final List<LoanInstallment> installments;
  final List<QuotaOffer> offers;
}

@immutable
class CreditReadiness {
  const CreditReadiness({
    required this.monthsRecorded,
    required this.inArisan,
    required this.appliancesDeclared,
  });

  final int monthsRecorded;
  final bool inArisan;
  final int appliancesDeclared;

  bool get isReady => monthsRecorded >= kMinMonthsForScore;
  int get monthsStillNeeded => math.max(0, kMinMonthsForScore - monthsRecorded);
}

CreditReadiness creditReadiness(CreditContext c) => CreditReadiness(
  monthsRecorded: monthlyUsage(c.records).length,
  inArisan: c.memberships.any((m) => m.userId == c.userId),
  appliancesDeclared: c.appliances.length,
);

CreditScoreInputs creditSignals(CreditContext c) => CreditScoreInputs(
  energyUsageConsistency: _consistency(c),
  paymentHistory: _payments(c),
  businessActivity: _business(c),
  communityParticipation: _community(c),
);

/// Null until [kMinMonthsForScore] months are recorded.
CreditScore? computeCreditScore(CreditContext c, CreditScoringEngine engine) =>
    creditReadiness(c).isReady ? engine.compute(creditSignals(c)) : null;

/// Steadier month-to-month usage scores higher, judged on spread relative to
/// the average so a small and a large business are compared fairly. The month
/// still in progress is left out while at least two complete months exist —
/// a half-finished month would otherwise look like a sudden drop.
double _consistency(CreditContext c) {
  final months = monthlyUsage(c.records);
  final complete = months.where((m) => !sameMonth(m.month, c.now)).toList();
  final kwh = (complete.length >= 2 ? complete : months)
      .map((m) => m.kwh)
      .where((k) => k > 0);
  if (kwh.length < 2) return 0;
  final mean = kwh.reduce((a, b) => a + b) / kwh.length;
  final variance =
      kwh.map((k) => math.pow(k - mean, 2)).reduce((a, b) => a + b) /
      kwh.length;
  final cv = math.sqrt(variance) / mean;
  return (1 - cv * 2).clamp(0.0, 1.0);
}

/// Confirmed arisan dues against months owed, plus loan installments paid on
/// time against installments already due.
double _payments(CreditContext c) {
  int owed = 0;
  int good = 0;

  for (final m in c.memberships.where((m) => m.userId == c.userId)) {
    final group = c.groups.where((g) => g.id == m.groupId).firstOrNull;
    if (group == null) continue;
    final months = math.max(0, monthsBetween(group.startMonth, c.now) + 1);
    owed += months;
    good += math.min(
      months,
      c.payments
          .where(
            (p) =>
                p.groupId == group.id &&
                p.userId == c.userId &&
                p.type == PaymentType.contribution &&
                p.status == PaymentStatus.confirmed,
          )
          .map((p) => monthOf(p.periodMonth))
          .toSet()
          .length,
    );
  }

  final due = c.installments.where((i) => !i.dueDate.isAfter(dayOf(c.now)));
  owed += due.length;
  good += due.where((i) => i.paidOnTime).length;

  // No dues have come due yet (e.g. she just joined an arisan group this
  // period) — neutral, not a default. `dir == negative` would otherwise
  // claim a late payment that never happened.
  if (owed == 0) return 0.5;
  return (good / owed).clamp(0.0, 1.0);
}

/// Productive use of the hub over the last 8 weeks (the "productivity
/// metrics" the credit identity is built on). Four fixed parts, each shown
/// on screen through the factor's reason text:
///  - equipment: registered business appliances (4 = full)          20 %
///  - frequency: completed hub sessions (8 = full)                   30 %
///  - volume: kWh actually used in those sessions (40 kWh = full)    20 %
///  - regularity: weeks out of 8 with at least one session           30 %
double _business(CreditContext c) {
  final cutoff = c.now.subtract(const Duration(days: 56));
  final sessions = c.bookings
      .where(
        (b) =>
            b.userId == c.userId &&
            b.status == BookingStatus.completed &&
            b.bookingDate.isAfter(cutoff),
      )
      .toList();
  final kwh = sessions.fold<double>(0, (s, b) => s + b.estKwh);
  final activeWeeks = sessions
      .map((b) => c.now.difference(b.bookingDate).inDays ~/ 7)
      .toSet()
      .length;
  return ((c.appliances.length / 4).clamp(0.0, 1.0) * 0.2 +
          (sessions.length / 8).clamp(0.0, 1.0) * 0.3 +
          (kwh / 40).clamp(0.0, 1.0) * 0.2 +
          (activeWeeks / 8).clamp(0.0, 1.0) * 0.3)
      .clamp(0.0, 1.0);
}

/// Belonging to a circle, and giving quota to it.
double _community(CreditContext c) {
  if (!c.memberships.any((m) => m.userId == c.userId)) return 0;
  final given = c.offers
      .where((o) => o.status == QuotaStatus.completed && o.giverId == c.userId)
      .length;
  return (0.4 + (given / 3).clamp(0.0, 1.0) * 0.6).clamp(0.0, 1.0);
}
