import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../l10n/l10n.dart';

/// Pascabayar bill (monthly usage) or prabayar token purchase.
enum EnergyKind {
  postpaid,
  token;

  static EnergyKind fromDb(String? v) => v == 'token' ? token : postpaid;
  String get db => name;
  String localizedLabel(AppLocalizations l10n) =>
      this == token ? l10n.energyKindToken : l10n.energyKindBill;
}

enum RecordSource {
  scan,
  manual;

  static RecordSource fromDb(String? v) => v == 'scan' ? scan : manual;
  String get db => name;
}

/// Values to prefill the energy-entry form with — from OCR, a demo
/// QR/barcode, or nothing.
@immutable
class EnergyDraft {
  const EnergyDraft({
    this.kind = EnergyKind.postpaid,
    this.periodMonth,
    this.kwh,
    this.totalIdr,
    this.customerId,
    this.photoPath,
    this.source = RecordSource.manual,
    this.rawText,
    this.readFailed = false,
  });

  final EnergyKind kind;
  final DateTime? periodMonth;
  final double? kwh;
  final int? totalIdr;
  final String? customerId;
  final String? photoPath;
  final RecordSource source;
  final String? rawText;
  final bool readFailed;
}

@immutable
class EnergyRecord {
  const EnergyRecord({
    required this.id,
    required this.userId,
    required this.kind,
    required this.periodMonth,
    required this.kwh,
    required this.totalIdr,
    this.customerId,
    this.photoPath,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final EnergyKind kind;

  /// Billing month for a bill; purchase month for a token.
  final DateTime periodMonth;
  final double kwh;
  final int totalIdr;

  /// PLN ID pelanggan when the scan found one.
  final String? customerId;
  final String? photoPath;
  final RecordSource source;
  final DateTime createdAt;

  double get idrPerKwh => kwh <= 0 ? 0 : totalIdr / kwh;

  factory EnergyRecord.fromRow(Map<String, dynamic> r) => EnergyRecord(
    id: rStr(r, 'id'),
    userId: rStr(r, 'user_id'),
    kind: EnergyKind.fromDb(rStrN(r, 'kind')),
    periodMonth: monthOf(rDate(r, 'period_month')),
    kwh: rDbl(r, 'kwh'),
    totalIdr: rInt(r, 'total_idr'),
    customerId: rStrN(r, 'customer_id'),
    photoPath: rStrN(r, 'photo_path'),
    source: RecordSource.fromDb(rStrN(r, 'source')),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'user_id': userId,
    'kind': kind.db,
    'period_month': dateOnly(periodMonth),
    'kwh': kwh,
    'total_idr': totalIdr,
    'customer_id': customerId,
    'photo_path': photoPath,
    'source': source.db,
    'created_at': ts(createdAt),
  };
}

@immutable
class Appliance {
  const Appliance({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    required this.watts,
    required this.hoursPerDay,
    required this.daysPerWeek,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;

  /// 'oven' | 'sewingMachine' | 'refrigerator' | 'blender' | 'other'.
  final String kind;
  final double watts;
  final double hoursPerDay;
  final int daysPerWeek;
  final DateTime createdAt;

  /// Energy in a 30-day month from the declared usage.
  double get monthlyKwh => watts / 1000 * hoursPerDay * daysPerWeek * (30 / 7);

  int monthlyCostIdr(double tariff) => (monthlyKwh * tariff).round();

  Appliance copyWith({
    String? name,
    String? kind,
    double? watts,
    double? hoursPerDay,
    int? daysPerWeek,
  }) => Appliance(
    id: id,
    userId: userId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    watts: watts ?? this.watts,
    hoursPerDay: hoursPerDay ?? this.hoursPerDay,
    daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    createdAt: createdAt,
  );

  factory Appliance.fromRow(Map<String, dynamic> r) => Appliance(
    id: rStr(r, 'id'),
    userId: rStr(r, 'user_id'),
    name: rStr(r, 'name'),
    kind: rStrN(r, 'kind') ?? 'other',
    watts: rDbl(r, 'watts'),
    hoursPerDay: rDbl(r, 'hours_per_day'),
    daysPerWeek: rInt(r, 'days_per_week', 7),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'kind': kind,
    'watts': watts,
    'hours_per_day': hoursPerDay,
    'days_per_week': daysPerWeek,
    'created_at': ts(createdAt),
  };
}

enum RoofOrientation {
  north,
  eastWest,
  south,
  flat,
  unknown;

  static RoofOrientation fromDb(String? v) => switch (v) {
    'north' => north,
    'east_west' => eastWest,
    'south' => south,
    'flat' => flat,
    _ => unknown,
  };

  String get db => switch (this) {
    north => 'north',
    eastWest => 'east_west',
    south => 'south',
    flat => 'flat',
    unknown => 'unknown',
  };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    north => l10n.roofOrientationNorth,
    eastWest => l10n.roofOrientationEastWest,
    south => l10n.roofOrientationSouth,
    flat => l10n.roofOrientationFlat,
    unknown => l10n.roofOrientationUnknown,
  };
}

enum RoofShading {
  none,
  partial,
  heavy;

  static RoofShading fromDb(String? v) => switch (v) {
    'partial' => partial,
    'heavy' => heavy,
    _ => none,
  };

  String get db => name;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    none => l10n.roofShadingNone,
    partial => l10n.roofShadingPartial,
    heavy => l10n.roofShadingHeavy,
  };
}

@immutable
class RoofAssessment {
  const RoofAssessment({
    required this.id,
    required this.userId,
    this.photoPath,
    required this.lengthM,
    required this.widthM,
    required this.orientation,
    required this.shading,
    required this.usableAreaM2,
    required this.estKwp,
    required this.estMonthlyKwh,
    required this.estMonthlySavingIdr,
    this.estPaybackYears,
    required this.band,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? photoPath;
  final double lengthM;
  final double widthM;
  final RoofOrientation orientation;
  final RoofShading shading;
  final double usableAreaM2;
  final double estKwp;
  final double estMonthlyKwh;
  final int estMonthlySavingIdr;
  final double? estPaybackYears;
  final String band;
  final DateTime createdAt;

  factory RoofAssessment.fromRow(Map<String, dynamic> r) => RoofAssessment(
    id: rStr(r, 'id'),
    userId: rStr(r, 'user_id'),
    photoPath: rStrN(r, 'photo_path'),
    lengthM: rDbl(r, 'length_m'),
    widthM: rDbl(r, 'width_m'),
    orientation: RoofOrientation.fromDb(rStrN(r, 'orientation')),
    shading: RoofShading.fromDb(rStrN(r, 'shading')),
    usableAreaM2: rDbl(r, 'usable_area_m2'),
    estKwp: rDbl(r, 'est_kwp'),
    estMonthlyKwh: rDbl(r, 'est_monthly_kwh'),
    estMonthlySavingIdr: rInt(r, 'est_monthly_saving_idr'),
    estPaybackYears: rDblN(r, 'est_payback_years'),
    band: rStr(r, 'band'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'user_id': userId,
    'photo_path': photoPath,
    'length_m': lengthM,
    'width_m': widthM,
    'orientation': orientation.db,
    'shading': shading.db,
    'usable_area_m2': usableAreaM2,
    'est_kwp': estKwp,
    'est_monthly_kwh': estMonthlyKwh,
    'est_monthly_saving_idr': estMonthlySavingIdr,
    'est_payback_years': estPaybackYears,
    'band': band,
    'created_at': ts(createdAt),
  };
}
