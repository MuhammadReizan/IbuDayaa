/// Model untuk data panel surya yang dibaca dari QR code demo.
library;

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

  /// Akurasi analisis AI dalam persen (0–100).
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

  /// Label paparan matahari dalam Bahasa Indonesia.
  String get sunExposureLabel => switch (sunExposure) {
    'excellent' => 'Sangat Baik',
    'good' => 'Baik',
    _ => 'Rendah',
  };

  /// Tip AI berdasarkan status panel.
  String get aiTip => switch (status) {
    SolarPanelStatus.healthy =>
      'Lokasi sangat cocok untuk Solar Hub.\nPotensi penghematan tinggi.',
    SolarPanelStatus.warning =>
      'Masih layak digunakan,\nnamun efisiensi belum optimal.',
    SolarPanelStatus.poor =>
      'Paparan matahari rendah.\nDisarankan evaluasi lokasi pemasangan.',
  };

  /// Label status dalam Bahasa Indonesia.
  String get statusLabel => switch (status) {
    SolarPanelStatus.healthy => 'Cocok untuk Solar Hub',
    SolarPanelStatus.warning => 'Perlu Optimasi',
    SolarPanelStatus.poor => 'Belum Direkomendasikan',
  };

  /// Label akurasi AI — diikuti label kualitas singkat.
  String get accuracyLabel => switch (accuracy) {
    >= 90 => 'Optimal',
    >= 85 => 'Sangat Baik',
    _ => 'Baik',
  };
}
