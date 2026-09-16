import '../../errors.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'supabase_base.dart';

/// Messaging + cooperative settings. Combined in one class the way
/// [LocalMessageRepository] combines the two interfaces — both are thin
/// wrappers over a handful of tables/RPCs with no logic worth splitting out.
class SupabaseMessageRepository extends SupabaseRepo
    implements MessageRepository, CooperativeRepository {
  SupabaseMessageRepository(super.client);

  @override
  Future<MessageThread> directThread({
    required Profile me,
    required String otherUserId,
  }) => guard(() async {
    final threadId = await client.rpc(
      'direct_thread',
      params: {'p_other': otherUserId},
    );
    final row = await table(
      'message_threads',
    ).select().eq('id', threadId as String).single();
    return MessageThread.fromRow(row);
  });

  @override
  Future<Message> send({
    required Profile me,
    required String threadId,
    required String body,
  }) => guard(() async {
    final text = body.trim();
    if (text.isEmpty) throw const AppException('Pesan masih kosong.');
    if (text.length > 2000) {
      throw const AppException('Pesan terlalu panjang (maks. 2.000 huruf).');
    }
    final row = await table('messages')
        .insert({'thread_id': threadId, 'sender_id': me.id, 'body': text})
        .select()
        .single();
    await table('thread_participants')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('thread_id', threadId)
        .eq('user_id', me.id);
    return Message.fromRow(row);
  });

  @override
  Future<void> markThreadRead({
    required Profile me,
    required String threadId,
  }) => guard(
    () => table('thread_participants')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('thread_id', threadId)
        .eq('user_id', me.id),
  );

  @override
  Future<void> markNotificationRead(Profile me, String notificationId) => guard(
    () => table('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .eq('user_id', me.id)
        .isFilter('read_at', null),
  );

  @override
  Future<void> markAllNotificationsRead(Profile me) => guard(
    () => table('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', me.id)
        .isFilter('read_at', null),
  );

  // -- Cooperative settings -------------------------------------------------

  @override
  Future<Cooperative> updateSettings(Profile admin, Cooperative updated) =>
      guard(() async {
        if (updated.name.trim().isEmpty) {
          throw const AppException('Nama koperasi wajib diisi.');
        }
        if (updated.loanFlatMonthlyRatePct < 0 ||
            updated.loanFlatMonthlyRatePct > 10) {
          throw const AppException('Bunga per bulan harus antara 0% dan 10%.');
        }
        if (updated.loanMaxAmountIdr < 500000) {
          throw const AppException('Plafon maksimum minimal Rp 500.000.');
        }
        if (updated.loanMinScore < 0 || updated.loanMinScore > 100) {
          throw const AppException('Skor minimum harus 0 sampai 100.');
        }
        if (updated.loanTenors.isEmpty ||
            updated.loanTenors.any((t) => t < 1 || t > 36)) {
          throw const AppException(
            'Pilih minimal satu tenor antara 1–36 bulan.',
          );
        }
        if (updated.memberMonthlyQuotaKwh < 0) {
          throw const AppException('Kuota anggota tidak boleh negatif.');
        }
        final row = await table('cooperatives')
            .update({
              'name': updated.name.trim(),
              'city': updated.city.trim(),
              'loan_flat_monthly_rate_pct': updated.loanFlatMonthlyRatePct,
              'loan_max_amount_idr': updated.loanMaxAmountIdr,
              'loan_min_score': updated.loanMinScore,
              'loan_tenors': ([...updated.loanTenors]..sort()),
              'member_monthly_quota_kwh': updated.memberMonthlyQuotaKwh,
              'solar_cost_per_kwp_idr': updated.solarCostPerKwpIdr,
            })
            .eq('id', updated.id)
            .select()
            .single();
        return Cooperative.fromRow(row);
      });

  @override
  Future<Cooperative> regenerateInviteCode(Profile admin) => guard(() async {
    await client.rpc('regenerate_invite_code');
    final row = await table(
      'cooperatives',
    ).select().eq('id', admin.cooperativeId).single();
    return Cooperative.fromRow(row);
  });
}
