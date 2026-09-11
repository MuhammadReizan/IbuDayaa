import '../../../features/credit_score/domain/credit_scoring_engine.dart';
import '../../db/ids.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'local_base.dart';

class LocalEnergyRepository extends LocalRepo
    implements EnergyRepository, ScoreRepository {
  LocalEnergyRepository(super.db, super.now);

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
  }) async {
    if (kwh <= 0) throw const AppException('Jumlah kWh harus lebih dari 0.');
    if (totalIdr <= 0) {
      throw const AppException('Total pembayaran harus lebih dari 0.');
    }
    final month = monthOf(periodMonth);
    if (month.isAfter(monthOf(now()))) {
      throw const AppException('Bulan tagihan tidak boleh di masa depan.');
    }

    String? targetId = replaceId;
    if (targetId != null) {
      final existing = db.find(Tbl.energyRecords, targetId);
      if (existing == null || existing['user_id'] != me.id) {
        throw const AppException('Catatan tidak ditemukan.');
      }
    } else if (kind == EnergyKind.postpaid) {
      // One bill per month: re-scanning a month corrects it instead of
      // doubling the usage.
      targetId =
          db.first(
                Tbl.energyRecords,
                (r) =>
                    r['user_id'] == me.id &&
                    r['kind'] == 'postpaid' &&
                    r['period_month'] == dateOnly(month),
              )?['id']
              as String?;
    }

    final record = EnergyRecord(
      id: targetId ?? newId(),
      userId: me.id,
      kind: kind,
      periodMonth: month,
      kwh: kwh,
      totalIdr: totalIdr,
      customerId: customerId,
      photoPath: photoPath,
      source: source,
      createdAt: now(),
    );

    if (targetId == null) {
      await db.insert(Tbl.energyRecords, record.toRow());
    } else {
      await db.update(Tbl.energyRecords, targetId, record.toRow());
    }
    return record;
  }

  @override
  Future<void> deleteRecord(Profile me, String recordId) async {
    final row = db.find(Tbl.energyRecords, recordId);
    if (row == null || row['user_id'] != me.id) {
      throw const AppException('Catatan tidak ditemukan.');
    }
    await db.delete(Tbl.energyRecords, recordId);
  }

  @override
  Future<Appliance> saveAppliance({
    required Profile me,
    String? id,
    required String name,
    required String kind,
    required double watts,
    required double hoursPerDay,
    required int daysPerWeek,
  }) async {
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

    if (id != null) {
      final row = db.find(Tbl.appliances, id);
      if (row == null || row['user_id'] != me.id) {
        throw const AppException('Alat tidak ditemukan.');
      }
    }

    final appliance = Appliance(
      id: id ?? newId(),
      userId: me.id,
      name: name.trim(),
      kind: kind,
      watts: watts,
      hoursPerDay: hoursPerDay,
      daysPerWeek: daysPerWeek,
      createdAt: now(),
    );
    if (id == null) {
      await db.insert(Tbl.appliances, appliance.toRow());
    } else {
      await db.update(Tbl.appliances, id, appliance.toRow());
    }
    return appliance;
  }

  @override
  Future<void> deleteAppliance(Profile me, String applianceId) async {
    final row = db.find(Tbl.appliances, applianceId);
    if (row == null || row['user_id'] != me.id) {
      throw const AppException('Alat tidak ditemukan.');
    }
    await db.delete(Tbl.appliances, applianceId);
  }

  @override
  Future<RoofAssessment> saveRoofAssessment(
    Profile me,
    RoofAssessment draft,
  ) async {
    if (draft.lengthM <= 0 || draft.widthM <= 0) {
      throw const AppException('Panjang dan lebar atap harus lebih dari 0.');
    }
    final saved = RoofAssessment(
      id: newId(),
      userId: me.id,
      photoPath: draft.photoPath,
      lengthM: draft.lengthM,
      widthM: draft.widthM,
      orientation: draft.orientation,
      shading: draft.shading,
      usableAreaM2: draft.usableAreaM2,
      estKwp: draft.estKwp,
      estMonthlyKwh: draft.estMonthlyKwh,
      estMonthlySavingIdr: draft.estMonthlySavingIdr,
      estPaybackYears: draft.estPaybackYears,
      band: draft.band,
      createdAt: now(),
    );
    await db.insert(Tbl.roofAssessments, saved.toRow());
    return saved;
  }

  @override
  Future<void> recordMonthlySnapshot(Profile me, CreditScore score) async {
    final month = dateOnly(monthOf(now()));
    final points = {for (final f in score.factors) f.category.name: f.points};
    final existing = db.first(
      Tbl.scoreSnapshots,
      (r) => r['user_id'] == me.id && r['month'] == month,
    );
    if (existing == null) {
      await db.insert(
        Tbl.scoreSnapshots,
        ScoreSnapshot(
          id: newId(),
          userId: me.id,
          month: monthOf(now()),
          score: score.score,
          factorPoints: points,
          createdAt: now(),
        ).toRow(),
      );
    } else if (existing['score'] != score.score) {
      await db.update(Tbl.scoreSnapshots, existing['id'] as String, {
        'score': score.score,
        'factor_points': points,
      });
    }
  }
}
