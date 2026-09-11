import '../../db/tables.dart';
import '../../models/models.dart';
import '../../state/snapshot.dart';
import '../repositories.dart';
import 'local_base.dart';

/// Loads what [me] may see. Each filter here corresponds to one RLS policy in
/// `supabase/migrations`.
class LocalSnapshotRepository extends LocalRepo implements SnapshotRepository {
  LocalSnapshotRepository(super.db, super.now);

  @override
  Future<CoopSnapshot> load(Profile me) async {
    final coopId = me.cooperativeId;
    final coopRow = db.find(Tbl.cooperatives, coopId);

    final members = db
        .select(Tbl.profiles, (r) => r['cooperative_id'] == coopId)
        .map(Profile.fromRow)
        .toList();
    final memberIds = members.map((m) => m.id).toSet();

    // Personal data: own rows for a member, the whole cooperative for an admin.
    bool personal(Map<String, dynamic> r) =>
        me.isAdmin ? memberIds.contains(r['user_id']) : r['user_id'] == me.id;

    final hubs = db
        .select(Tbl.solarHubs, (r) => r['cooperative_id'] == coopId)
        .map(SolarHub.fromRow)
        .toList();
    final hubIds = hubs.map((h) => h.id).toSet();

    final groups = db
        .select(Tbl.arisanGroups, (r) => r['cooperative_id'] == coopId)
        .map(ArisanGroup.fromRow)
        .toList();
    final groupIds = groups.map((g) => g.id).toSet();
    final groupMembers = db
        .select(Tbl.arisanMembers, (r) => groupIds.contains(r['group_id']))
        .map(ArisanMember.fromRow)
        .toList();
    final myGroupIds = me.isAdmin
        ? groupIds
        : groupMembers
              .where((m) => m.userId == me.id)
              .map((m) => m.groupId)
              .toSet();

    final loans = db
        .select(
          Tbl.loanApplications,
          (r) =>
              r['cooperative_id'] == coopId &&
              (me.isAdmin || r['user_id'] == me.id),
        )
        .map(LoanApplication.fromRow)
        .toList();
    final loanIds = loans.map((l) => l.id).toSet();

    final myThreadIds = db
        .select(Tbl.threadParticipants, (r) => r['user_id'] == me.id)
        .map((r) => r['thread_id'])
        .toSet();

    return CoopSnapshot(
      cooperative: coopRow == null ? null : Cooperative.fromRow(coopRow),
      members: members,
      energyRecords: db
          .select(Tbl.energyRecords, personal)
          .map(EnergyRecord.fromRow)
          .toList(),
      appliances: db
          .select(Tbl.appliances, personal)
          .map(Appliance.fromRow)
          .toList(),
      roofAssessments: db
          .select(Tbl.roofAssessments, personal)
          .map(RoofAssessment.fromRow)
          .toList(),
      hubs: hubs,
      slots: db
          .select(Tbl.hubSlots, (r) => hubIds.contains(r['hub_id']))
          .map(HubSlot.fromRow)
          .toList(),
      // Every booking on the hub is needed to show remaining capacity; the UI
      // only shows details of the member's own.
      bookings: db
          .select(Tbl.hubBookings, (r) => hubIds.contains(r['hub_id']))
          .map(HubBooking.fromRow)
          .toList(),
      groups: groups,
      groupMembers: groupMembers,
      payments: db
          .select(Tbl.arisanPayments, (r) => myGroupIds.contains(r['group_id']))
          .map(ArisanPayment.fromRow)
          .toList(),
      offers: db
          .select(Tbl.quotaOffers, (r) => r['cooperative_id'] == coopId)
          .map(QuotaOffer.fromRow)
          .toList(),
      loans: loans,
      installments: db
          .select(Tbl.loanInstallments, (r) => loanIds.contains(r['loan_id']))
          .map(LoanInstallment.fromRow)
          .toList(),
      loanEvents: db
          .select(Tbl.loanEvents, (r) => loanIds.contains(r['loan_id']))
          .map(LoanEvent.fromRow)
          .toList(),
      threads: db
          .select(Tbl.messageThreads, (r) => myThreadIds.contains(r['id']))
          .map(MessageThread.fromRow)
          .toList(),
      participants: db
          .select(
            Tbl.threadParticipants,
            (r) => myThreadIds.contains(r['thread_id']),
          )
          .map(ThreadParticipant.fromRow)
          .toList(),
      messages: db
          .select(Tbl.messages, (r) => myThreadIds.contains(r['thread_id']))
          .map(Message.fromRow)
          .toList(),
      notifications: db
          .select(Tbl.notifications, (r) => r['user_id'] == me.id)
          .map(AppNotification.fromRow)
          .toList(),
      scoreSnapshots: db
          .select(Tbl.scoreSnapshots, personal)
          .map(ScoreSnapshot.fromRow)
          .toList(),
    );
  }
}
