import '../../db/row.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'supabase_base.dart';

/// Every write here goes through a `security definer` RPC in
/// `supabase/migrations` — group creation, contribution/payout bookkeeping
/// and quota trading all have rules (membership, one-per-month, available
/// balance) that must hold no matter what the client sends, the same
/// guarantee [LocalArisanRepository] gives by running the checks itself.
class SupabaseArisanRepository extends SupabaseRepo
    implements ArisanRepository {
  SupabaseArisanRepository(super.client);

  @override
  Future<ArisanGroup> createGroup({
    required Profile admin,
    required String name,
    required int contributionIdr,
    required DateTime startMonth,
    required List<String> memberIdsInTurnOrder,
  }) => guard(() async {
    final row = await client.rpc(
      'create_arisan_group',
      params: {
        'p_name': name.trim(),
        'p_contribution': contributionIdr,
        'p_start': dateOnly(startMonth),
        'p_members': memberIdsInTurnOrder,
      },
    );
    return ArisanGroup.fromRow(row as Map<String, dynamic>);
  });

  @override
  Future<ArisanPayment> submitContribution({
    required Profile me,
    required String groupId,
    required DateTime periodMonth,
    String? note,
  }) => guard(() async {
    final row = await client.rpc(
      'submit_contribution',
      params: {'p_group': groupId, 'p_note': note},
    );
    return ArisanPayment.fromRow(row as Map<String, dynamic>);
  });

  @override
  Future<void> reviewPayment({
    required Profile admin,
    required String paymentId,
    required bool approve,
    String? note,
  }) => guard(
    () => client.rpc(
      'review_payment',
      params: {'p_payment': paymentId, 'p_approve': approve, 'p_note': note},
    ),
  );

  @override
  Future<ArisanPayment> recordPayout({
    required Profile admin,
    required String groupId,
    required String userId,
    required DateTime periodMonth,
  }) => guard(() async {
    final row = await client.rpc(
      'record_payout',
      params: {'p_group': groupId, 'p_user': userId},
    );
    return ArisanPayment.fromRow(row as Map<String, dynamic>);
  });

  @override
  Future<QuotaOffer> postQuota({
    required Profile me,
    required QuotaKind kind,
    required double kwh,
    required String slotNote,
    String? note,
  }) => guard(() async {
    final row = await client.rpc(
      'post_quota',
      params: {
        'p_kind': kind.db,
        'p_kwh': kwh,
        'p_slot_note': slotNote.trim(),
        'p_note': note,
      },
    );
    return QuotaOffer.fromRow(row as Map<String, dynamic>);
  });

  @override
  Future<void> respondToQuota({required Profile me, required String offerId}) =>
      guard(() => client.rpc('respond_quota', params: {'p_offer': offerId}));

  @override
  Future<void> settleQuota({
    required Profile me,
    required String offerId,
    required bool accept,
  }) => guard(
    () => client.rpc(
      'settle_quota',
      params: {'p_offer': offerId, 'p_accept': accept},
    ),
  );

  @override
  Future<void> cancelQuota({required Profile me, required String offerId}) =>
      guard(() => client.rpc('cancel_quota', params: {'p_offer': offerId}));
}
