import '../../../features/credit_score/domain/credit_scoring_engine.dart';
import '../../db/row.dart';
import '../../errors.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'supabase_base.dart';

/// Energy records, appliances and roof assessments are plain
/// `user_id = auth.uid()` writes under RLS — no RPC needed, the same trust
/// boundary as [LocalEnergyRepository].
class SupabaseEnergyRepository extends SupabaseRepo
    implements EnergyRepository, ScoreRepository {
  SupabaseEnergyRepository(super.client);

  @override
  Future<EnergyRecord> saveRecord({
    required Profile me,
    required EnergyKind kind,
    required DateTime periodMonth,
    required double kwh,
    required int totalIdr,
    String? customerId,
    String? photoPath,
    required RecordSource source,
    String? replaceId,
    String? bookingId,
  }) => guard(() async {
    if (kwh <= 0) throw const AppException('Jumlah kWh harus lebih dari 0.');
    if (totalIdr <= 0) {
      throw const AppException('Total pembayaran harus lebih dari 0.');
    }
    final month = monthOf(periodMonth);
    if (month.isAfter(monthOf(DateTime.now()))) {
      throw const AppException('Bulan tagihan tidak boleh di masa depan.');
    }

    String? targetId = replaceId;
    if (targetId == null && kind == EnergyKind.postpaid) {
      // One bill per month: re-scanning a month corrects it instead of
      // doubling the usage (same as the local repository; the unique index
      // energy_one_bill_per_month is the server-side backstop).
      final existing = await table('energy_records')
          .select('id')
          .eq('user_id', me.id)
          .eq('kind', 'postpaid')
          .eq('period_month', dateOnly(month))
          .maybeSingle();
      targetId = existing?['id'] as String?;
    }

    final payload = {
      'user_id': me.id,
      'kind': kind.db,
      'period_month': dateOnly(month),
      'kwh': kwh,
      'total_idr': totalIdr,
      'customer_id': customerId,
      'photo_path': photoPath,
      'source': source.db,
      'booking_id': bookingId,
    };

    final row = targetId == null
        ? await table('energy_records').insert(payload).select().single()
        : await table(
            'energy_records',
          ).update(payload).eq('id', targetId).select().single();
    return EnergyRecord.fromRow(row);
  });

  @override
  Future<void> deleteRecord(Profile me, String recordId) => guard(
    () => table(
      'energy_records',
    ).delete().eq('id', recordId).eq('user_id', me.id),
  );

  @override
  Future<Appliance> saveAppliance({
    required Profile me,
    String? id,
    required String name,
    required String kind,
    required double watts,
    required double hoursPerDay,
    required int daysPerWeek,
  }) => guard(() async {
    if (name.trim().isEmpty) throw const AppException('Nama alat wajib diisi.');
    if (watts <= 0 || watts > 20000) {
      throw const AppException('Daya alat harus antara 1 dan 20.000 watt.');
    }
    if (hoursPerDay <= 0 || hoursPerDay > 24) {
      throw const AppException('Jam pemakaian harus antara 0 dan 24.');
    }
    if (daysPerWeek < 1 || daysPerWeek > 7) {
      throw const AppException('Hari pemakaian harus 1 sampai 7.');
    }
    final payload = {
      'user_id': me.id,
      'name': name.trim(),
      'kind': kind,
      'watts': watts,
      'hours_per_day': hoursPerDay,
      'days_per_week': daysPerWeek,
    };
    final row = id == null
        ? await table('appliances').insert(payload).select().single()
        : await table(
            'appliances',
          ).update(payload).eq('id', id).eq('user_id', me.id).select().single();
    return Appliance.fromRow(row);
  });

  @override
  Future<void> deleteAppliance(Profile me, String applianceId) => guard(
    () =>
        table('appliances').delete().eq('id', applianceId).eq('user_id', me.id),
  );

  @override
  Future<RoofAssessment> saveRoofAssessment(Profile me, RoofAssessment draft) =>
      guard(() async {
        if (draft.lengthM <= 0 || draft.widthM <= 0) {
          throw const AppException(
            'Panjang dan lebar atap harus lebih dari 0.',
          );
        }
        final row = await table('roof_assessments')
            .insert({
              'user_id': me.id,
              'photo_path': draft.photoPath,
              'length_m': draft.lengthM,
              'width_m': draft.widthM,
              'orientation': draft.orientation,
              'shading': draft.shading,
              'usable_area_m2': draft.usableAreaM2,
              'est_kwp': draft.estKwp,
              'est_monthly_kwh': draft.estMonthlyKwh,
              'est_monthly_saving_idr': draft.estMonthlySavingIdr,
              'est_payback_years': draft.estPaybackYears,
              'band': draft.band,
            })
            .select()
            .single();
        return RoofAssessment.fromRow(row);
      });

  @override
  Future<void> recordMonthlySnapshot(Profile me, CreditScore score) => guard(
    () async {
      final month = dateOnly(monthOf(DateTime.now()));
      final points = {for (final f in score.factors) f.category.name: f.points};
      final existing = await table('score_snapshots')
          .select('id, score')
          .eq('user_id', me.id)
          .eq('month', month)
          .maybeSingle();
      if (existing == null) {
        await table('score_snapshots').insert({
          'user_id': me.id,
          'month': month,
          'score': score.score,
          'factor_points': points,
        });
      } else if (rInt(existing, 'score') != score.score) {
        await table('score_snapshots')
            .update({'score': score.score, 'factor_points': points})
            .eq('id', existing['id'] as String);
      }
    },
  );
}
