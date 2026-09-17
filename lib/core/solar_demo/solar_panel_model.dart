/// Model untuk data panel surya yang dibaca dari QR code demo.
library;

import '../l10n/l10n.dart';

/// Status kondisi solar panel.
enum SolarPanelStatus {
  /// Panel dalam kondisi prima, sangat direkomendasikan.
  healthy,

  /// Panel masih layak namun perlu optimasi.
  warning,

  /// Panel belum direkomendasikan untuk Solar Hub.
  poor,
}

/// Representasi data hasil scan QR solar panel demo.
class SolarPanelData {
  const SolarPanelData({
    required this.panelId,
    required this.location,
    required this.status,
    required this.sunExposure,
    required this.roofArea,
    required this.roofSlope,
    required this.roiYears,
    required this.accuracy,
    required this.monthlySaving,
    required this.recommendation,
  });

  /// ID unik panel, misalnya "IBUDAYA-SOLAR-001".
  final String panelId;

  /// Nama lokasi Solar Hub.
  final String location;

  /// Status kondisi panel.
  final SolarPanelStatus status;

  /// Paparan matahari: "excellent", "good", atau "low".
  final String sunExposure;

  /// Luas atap dalam meter persegi.
  final int roofArea;

  /// Kemiringan atap dalam derajat.
  final int roofSlope;

  /// Estimasi return on investment dalam tahun.
  final double roiYears;

  /// Akurasi estimasi sensor dalam persen (0–100). Ini bukan skor
  /// kepercayaan model AI — jangan tampilkan sebagai "akurasi AI".
  final int accuracy;

  /// Estimasi penghematan per bulan dalam rupiah.
  final int monthlySaving;

  /// Apakah lokasi ini direkomendasikan untuk Solar Hub.
  final bool recommendation;

  /// Buat instance dari map JSON (payload lokal).
  factory SolarPanelData.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status'] as String? ?? 'poor';
    final status = switch (rawStatus) {
      'healthy' => SolarPanelStatus.healthy,
      'warning' => SolarPanelStatus.warning,
      _ => SolarPanelStatus.poor,
    };

    return SolarPanelData(
      panelId: map['panel_id'] as String? ?? '',
      location: map['location'] as String? ?? '',
      status: status,
      sunExposure: map['sun_exposure'] as String? ?? 'low',
      roofArea: (map['roof_area'] as num?)?.toInt() ?? 0,
      roofSlope: (map['roof_slope'] as num?)?.toInt() ?? 0,
      roiYears: (map['roi_years'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      monthlySaving: (map['monthly_saving'] as num?)?.toInt() ?? 0,
      recommendation: map['recommendation'] as bool? ?? false,
    );
  }

  /// Label paparan matahari.
  String sunExposureLabel(AppLocalizations l10n) => switch (sunExposure) {
    'excellent' => l10n.solarScanSunExcellent,
    'good' => l10n.solarScanSunGood,
    _ => l10n.solarScanSunLow,
  };

  /// Tip berdasarkan status panel.
  String tip(AppLocalizations l10n) => switch (status) {
    SolarPanelStatus.healthy => l10n.solarScanTipHealthy,
    SolarPanelStatus.warning => l10n.solarScanTipWarning,
    SolarPanelStatus.poor => l10n.solarScanTipPoor,
  };

  /// Label status.
  String statusLabel(AppLocalizations l10n) => switch (status) {
    SolarPanelStatus.healthy => l10n.solarScanStatusHealthy,
    SolarPanelStatus.warning => l10n.solarScanStatusWarning,
    SolarPanelStatus.poor => l10n.solarScanStatusPoor,
  };

  /// Label akurasi — diikuti label kualitas singkat.
  String accuracyLabel(AppLocalizations l10n) => switch (accuracy) {
    >= 90 => l10n.solarScanAccuracyOptimal,
    >= 85 => l10n.solarScanAccuracyVeryGood,
    _ => l10n.solarScanAccuracyGood,
  };
}
