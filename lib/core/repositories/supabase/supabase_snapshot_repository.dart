import '../../models/models.dart';
import '../../state/snapshot.dart';
import '../repositories.dart';
import 'supabase_base.dart';

/// Loads what [me] may see. Unlike [LocalSnapshotRepository], there is no
/// manual filtering here — every `select` below relies on the RLS policies
/// in `supabase/migrations` to return exactly the rows [me] is allowed to
/// see (a member's own data, or the admin's whole cooperative). If a policy
/// is missing or wrong, this returns too little or too much, not a crash —
/// see docs/SUPABASE.md for the checks to run before real members use it.
class SupabaseSnapshotRepository extends SupabaseRepo
    implements SnapshotRepository {
  SupabaseSnapshotRepository(super.client);

  @override
  Future<CoopSnapshot> load(Profile me) => guard(() async {
    final results = await Future.wait<dynamic>([
      table('cooperatives').select().eq('id', me.cooperativeId).maybeSingle(),
      table('profiles').select(),
      table('energy_records').select(),
      table('appliances').select(),
      table('roof_assessments').select(),
      table('solar_hubs').select(),
      table('hub_slots').select(),
      table('hub_bookings').select(),
      table('arisan_groups').select(),
      table('arisan_members').select(),
      table('arisan_payments').select(),
      table('quota_offers').select(),
      table('loan_applications').select(),
      table('loan_installments').select(),
      table('loan_events').select(),
      table('message_threads').select(),
      table('thread_participants').select(),
      table('messages').select(),
      table('notifications').select(),
      table('score_snapshots').select(),
    ]);

    final coopRow = results[0] as Map<String, dynamic>?;
    List<Map<String, dynamic>> rows(int i) =>
        (results[i] as List).cast<Map<String, dynamic>>();

    return CoopSnapshot(
      cooperative: coopRow == null ? null : Cooperative.fromRow(coopRow),
      members: rows(1).map(Profile.fromRow).toList(),
      energyRecords: rows(2).map(EnergyRecord.fromRow).toList(),
      appliances: rows(3).map(Appliance.fromRow).toList(),
      roofAssessments: rows(4).map(RoofAssessment.fromRow).toList(),
      hubs: rows(5).map(SolarHub.fromRow).toList(),
      slots: rows(6).map(HubSlot.fromRow).toList(),
      bookings: rows(7).map(HubBooking.fromRow).toList(),
      groups: rows(8).map(ArisanGroup.fromRow).toList(),
      groupMembers: rows(9).map(ArisanMember.fromRow).toList(),
      payments: rows(10).map(ArisanPayment.fromRow).toList(),
      offers: rows(11).map(QuotaOffer.fromRow).toList(),
      loans: rows(12).map(LoanApplication.fromRow).toList(),
      installments: rows(13).map(LoanInstallment.fromRow).toList(),
      loanEvents: rows(14).map(LoanEvent.fromRow).toList(),
      threads: rows(15).map(MessageThread.fromRow).toList(),
      participants: rows(16).map(ThreadParticipant.fromRow).toList(),
      messages: rows(17).map(Message.fromRow).toList(),
      notifications: rows(18).map(AppNotification.fromRow).toList(),
      scoreSnapshots: rows(19).map(ScoreSnapshot.fromRow).toList(),
    );
  });
}
