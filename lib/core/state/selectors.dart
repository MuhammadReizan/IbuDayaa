/// Read-only questions screens ask of a [CoopSnapshot]. Pure functions over the
/// snapshot — no providers, no I/O — so they are cheap to call in `build` and
/// trivial to test.
library;

import 'package:flutter/foundation.dart';

import '../../features/credit_score/domain/credit_scoring_engine.dart';
import '../db/row.dart';
import '../format/money.dart';
import '../l10n/l10n.dart';
import '../logic/credit_signals.dart';
import '../logic/energy_insights.dart';
import '../logic/hub_capacity.dart';
import '../logic/quota_ledger.dart';
import '../models/models.dart';
import 'snapshot.dart';

@immutable
class ThreadSummary {
  const ThreadSummary({
    required this.thread,
    required this.title,
    required this.last,
    required this.unread,
    this.avatarName,
  });

  final MessageThread thread;
  final String title;
  final Message? last;
  final int unread;

  /// Name to draw initials from, for person-to-person threads.
  final String? avatarName;

  DateTime get activity => last?.createdAt ?? thread.createdAt;
}

extension SnapshotQueries on CoopSnapshot {
  // -- People ----------------------------------------------------------------

  List<Profile> get memberProfiles =>
      members.where((m) => !m.isAdmin).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

  // -- Energy ----------------------------------------------------------------

  List<EnergyRecord> recordsOf(String userId) =>
      energyRecords.where((r) => r.userId == userId).toList()..sort((a, b) {
        final c = b.periodMonth.compareTo(a.periodMonth);
        return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
      });

  List<Appliance> appliancesOf(String userId) =>
      appliances.where((a) => a.userId == userId).toList()
        ..sort((a, b) => b.monthlyKwh.compareTo(a.monthlyKwh));

  RoofAssessment? latestRoofOf(String userId) {
    final list = roofAssessments.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.firstOrNull;
  }

  EnergyInsight? insightOf(String userId) => buildEnergyInsight(
    records: recordsOf(userId),
    appliances: appliancesOf(userId),
    tariff: profile(userId)?.tariffIdrPerKwh ?? 1444.70,
  );

  ImpactMetrics impactOf(String userId, DateTime now) => buildImpact(
    records: recordsOf(userId),
    completedBookings: bookingsOf(userId),
    tariff: profile(userId)?.tariffIdrPerKwh ?? 1444.70,
    now: now,
  );

  List<PowerObservation> observationsOf(
    String userId,
    DateTime now, [
    AppLocalizations? l10n,
  ]) => buildObservations(
    insight: insightOf(userId),
    records: recordsOf(userId),
    appliances: appliancesOf(userId),
    myBookings: bookingsOf(userId),
    tariff: profile(userId)?.tariffIdrPerKwh ?? 1444.70,
    now: now,
    rupiah: formatRupiah,
    l10n: l10n,
  );

  // -- Solar hub -------------------------------------------------------------

  List<HubSlot> get orderedSlots =>
      [...slots]..sort((a, b) => a.sort.compareTo(b.sort));

  List<HubBooking> bookingsOf(String userId) =>
      bookings.where((b) => b.userId == userId).toList()
        ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

  List<SlotAvailability> availabilityOn(DateTime date) {
    final h = hub;
    if (h == null) return const [];
    return slotAvailability(
      hub: h,
      slots: orderedSlots,
      bookings: bookings,
      date: date,
    );
  }

  HubSlot? slot(String id) => slots.where((s) => s.id == id).firstOrNull;

  // -- Quota -----------------------------------------------------------------

  QuotaBalance quotaOf(String userId, DateTime now) => quotaBalance(
    userId: userId,
    month: now,
    allocationKwh: cooperative?.memberMonthlyQuotaKwh ?? 0,
    bookings: bookings,
    offers: offers,
  );

  List<QuotaOffer> get activeOffers =>
      offers
          .where(
            (o) =>
                o.status == QuotaStatus.open || o.status == QuotaStatus.pending,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // -- Arisan ----------------------------------------------------------------

  List<ArisanGroup> groupsOf(String userId) {
    final ids = groupMembers
        .where((m) => m.userId == userId)
        .map((m) => m.groupId)
        .toSet();
    return groups.where((g) => ids.contains(g.id)).toList();
  }

  ArisanGroup? group(String id) => groups.where((g) => g.id == id).firstOrNull;

  List<ArisanMember> membersOfGroup(String groupId) =>
      groupMembers.where((m) => m.groupId == groupId).toList()
        ..sort((a, b) => a.turnOrder.compareTo(b.turnOrder));

  List<ArisanPayment> paymentsOfGroup(String groupId) =>
      payments.where((p) => p.groupId == groupId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// The member's non-rejected dues for [month], if any.
  ArisanPayment? contributionFor(
    String groupId,
    String userId,
    DateTime month,
  ) => payments
      .where(
        (p) =>
            p.groupId == groupId &&
            p.userId == userId &&
            p.type == PaymentType.contribution &&
            p.status != PaymentStatus.rejected &&
            sameMonth(p.periodMonth, month),
      )
      .firstOrNull;

  /// Whose turn it is in [month]: turn N collects in start + (N − 1) months.
  ArisanMember? recipientFor(ArisanGroup g, DateTime month) {
    final list = membersOfGroup(g.id);
    if (list.isEmpty) return null;
    final offset = monthsBetween(g.startMonth, month);
    if (offset < 0) return null;
    return list[offset % list.length];
  }

  DateTime turnMonthOf(ArisanGroup g, String userId) {
    final m = membersOfGroup(g.id).where((x) => x.userId == userId).firstOrNull;
    return DateTime(
      g.startMonth.year,
      g.startMonth.month + (m?.turnOrder ?? 1) - 1,
    );
  }

  List<ArisanPayment> get pendingPayments =>
      payments.where((p) => p.status == PaymentStatus.pending).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  // -- Credit ----------------------------------------------------------------

  CreditContext creditContextOf(String userId, DateTime now) {
    final loanIds = loans
        .where((l) => l.userId == userId)
        .map((l) => l.id)
        .toSet();
    return CreditContext(
      userId: userId,
      now: now,
      records: recordsOf(userId),
      appliances: appliancesOf(userId),
      bookings: bookingsOf(userId),
      memberships: groupMembers.where((m) => m.userId == userId).toList(),
      groups: groups,
      payments: payments.where((p) => p.userId == userId).toList(),
      installments: installments
          .where((i) => loanIds.contains(i.loanId))
          .toList(),
      offers: offers,
    );
  }

  CreditReadiness readinessOf(String userId, DateTime now) =>
      creditReadiness(creditContextOf(userId, now));

  CreditScore? scoreOf(
    String userId,
    DateTime now,
    CreditScoringEngine engine,
  ) => computeCreditScore(creditContextOf(userId, now), engine);

  /// Last month's snapshot or older, to show how each factor moved.
  ScoreSnapshot? previousScoreOf(String userId, DateTime now) {
    final list =
        scoreSnapshots
            .where((s) => s.userId == userId && s.month.isBefore(monthOf(now)))
            .toList()
          ..sort((a, b) => b.month.compareTo(a.month));
    return list.firstOrNull;
  }

  // -- Loans -----------------------------------------------------------------

  List<LoanApplication> loansOf(String userId) =>
      loans.where((l) => l.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  LoanApplication? activeLoanOf(String userId) =>
      loansOf(userId).where((l) => l.status.isActive).firstOrNull;

  LoanApplication? loan(String id) =>
      loans.where((l) => l.id == id).firstOrNull;

  List<LoanInstallment> installmentsOf(String loanId) =>
      installments.where((i) => i.loanId == loanId).toList()
        ..sort((a, b) => a.seq.compareTo(b.seq));

  List<LoanEvent> eventsOf(String loanId) =>
      loanEvents.where((e) => e.loanId == loanId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Applications waiting on an admin, oldest first.
  List<LoanApplication> get loansAwaitingAdmin =>
      loans
          .where(
            (l) =>
                l.status == LoanStatus.submitted ||
                l.status == LoanStatus.inReview ||
                l.status == LoanStatus.approved,
          )
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  // -- Messages & notifications ---------------------------------------------

  List<AppNotification> notificationsOf(String userId) =>
      notifications.where((n) => n.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int unreadNotificationsOf(String userId) =>
      notifications.where((n) => n.userId == userId && !n.isRead).length;

  MessageThread? thread(String id) =>
      threads.where((t) => t.id == id).firstOrNull;

  MessageThread? supportThreadOf(String memberId) => threads
      .where((t) => t.kind == ThreadKind.support && t.refId == memberId)
      .firstOrNull;

  MessageThread? groupThreadOf(String groupId) => threads
      .where((t) => t.kind == ThreadKind.group && t.refId == groupId)
      .firstOrNull;

  List<Message> messagesOf(String threadId) =>
      messages.where((m) => m.threadId == threadId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  ThreadSummary summarize(MessageThread t, Profile me) {
    final msgs = messagesOf(t.id);
    final mine = participants
        .where((p) => p.threadId == t.id && p.userId == me.id)
        .firstOrNull;
    final readAt = mine?.lastReadAt;
    final unread = msgs
        .where(
          (m) =>
              m.senderId != me.id &&
              (readAt == null || m.createdAt.isAfter(readAt)),
        )
        .length;

    String title = t.title;
    String? avatarName;
    if (t.kind == ThreadKind.direct) {
      final otherId = participants
          .where((p) => p.threadId == t.id && p.userId != me.id)
          .firstOrNull
          ?.userId;
      title = nameOf(otherId);
      avatarName = title;
    } else if (t.kind == ThreadKind.support && me.isAdmin) {
      title = nameOf(t.refId);
      avatarName = title;
    }

    return ThreadSummary(
      thread: t,
      title: title,
      last: msgs.lastOrNull,
      unread: unread,
      avatarName: avatarName,
    );
  }

  List<ThreadSummary> threadsFor(Profile me) =>
      threads.map((t) => summarize(t, me)).toList()
        ..sort((a, b) => b.activity.compareTo(a.activity));

  int unreadMessagesOf(Profile me) =>
      threadsFor(me).fold(0, (s, t) => s + t.unread);
}
