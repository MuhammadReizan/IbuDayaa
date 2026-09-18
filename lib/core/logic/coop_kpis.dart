/// The cooperative's numbers for the admin dashboard, mirroring the KPIs the
/// YESIST12 proposal promises to track. Only what the app can actually measure
/// is here: projections in the proposal (37.5% lower energy cost, a 95%
/// repayment target) are targets, not results, and are labelled that way.
library;

import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../models/account.dart';
import '../models/arisan.dart';
import '../models/loan.dart';
import '../models/solar.dart';

@immutable
class CoopKpis {
  const CoopKpis({
    required this.members,
    required this.activeMembers,
    required this.loanReady,
    required this.quotaTrades,
    required this.installmentsDue,
    required this.installmentsOnTime,
  });

  final int members;

  /// Members with at least one completed hub session this month.
  final int activeMembers;

  /// Members whose score meets the cooperative's loan minimum.
  final int loanReady;

  /// Quota trades completed this month.
  final int quotaTrades;

  /// Installments whose due date has arrived.
  final int installmentsDue;

  /// Of those, the ones paid on or before the due date.
  final int installmentsOnTime;

  /// Null until an installment has fallen due.
  int? get onTimePct => installmentsDue == 0
      ? null
      : (installmentsOnTime / installmentsDue * 100).round();
}

CoopKpis coopKpis({
  required Iterable<Profile> members,
  required Iterable<HubBooking> bookings,
  required Iterable<QuotaOffer> offers,
  required Iterable<LoanInstallment> installments,
  required int loanReady,
  required DateTime now,
}) {
  final memberIds = {for (final m in members) m.id};
  final active = <String>{
    for (final b in bookings)
      if (b.status == BookingStatus.completed &&
          memberIds.contains(b.userId) &&
          sameMonth(b.bookingDate, now))
        b.userId,
  };
  final today = dayOf(now);
  final due = installments.where((i) => !i.dueDate.isAfter(today)).toList();
  return CoopKpis(
    members: memberIds.length,
    activeMembers: active.length,
    loanReady: loanReady,
    quotaTrades: offers
        .where(
          (o) =>
              o.status == QuotaStatus.completed && sameMonth(o.updatedAt, now),
        )
        .length,
    installmentsDue: due.length,
    installmentsOnTime: due.where((i) => i.paidOnTime).length,
  );
}
