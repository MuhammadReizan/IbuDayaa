import '../../core/l10n/l10n.dart';

/// Localised display copy for the scan-demo dummy analysis statuses and for
/// the live spike/savings heuristic computed from a member's own history.
///
/// Centralised here (instead of inline in each screen) so the scan result,
/// the confirm-form "result" view, and the Analisis Energi screen never
/// drift out of sync or leak a hardcoded-language string past a locale
/// switch. `demoPayloads` (lib/core/demo/demo_payloads.dart) only carries a
/// semantic `status` key plus numbers — every word shown to the member for
/// that status comes from here so it always matches the active locale.

String demoStatusTitle(String status, AppLocalizations l10n) =>
    switch (status) {
      'solar_recommendation' =>
        l10n.isEn
            ? 'Savings Opportunity Found'
            : 'Potensi Penghematan Ditemukan',
      'normal' => l10n.isEn ? 'Stable Usage' : 'Pemakaian Stabil',
      _ => l10n.isEn ? 'Energy Spike Detected' : 'Lonjakan Energi Terdeteksi',
    };

String demoStatusDescription(String status, AppLocalizations l10n) =>
    switch (status) {
      'solar_recommendation' =>
        l10n.isEn
            ? 'Solar Hub usage is recommended'
            : 'Disarankan menggunakan Solar Hub',
      'normal' =>
        l10n.isEn
            ? 'No usage spike detected'
            : 'Tidak ditemukan lonjakan pemakaian',
      _ =>
        l10n.isEn
            ? 'High usage between 6–9 PM'
            : 'Pemakaian tinggi jam 18.00–21.00',
    };

String demoStatusLabel(String status, AppLocalizations l10n) =>
    switch (status) {
      'solar_recommendation' =>
        l10n.isEn ? 'Estimated savings' : 'Estimasi penghematan',
      'normal' => l10n.isEn ? 'Estimated bill' : 'Estimasi tagihan',
      _ => l10n.isEn ? 'Extra cost' : 'Biaya tambahan',
    };

String demoCauseTitle(String status, AppLocalizations l10n) => switch (status) {
  'solar_recommendation' =>
    l10n.isEn ? 'Savings Opportunity' : 'Peluang Penghematan',
  'normal' => l10n.isEn ? 'Usage Pattern' : 'Pola Pemakaian',
  _ => l10n.isEn ? 'Cause of the Spike' : 'Penyebab Lonjakan',
};

String demoCauseText(String status, AppLocalizations l10n) => switch (status) {
  'solar_recommendation' =>
    l10n.isEn
        ? 'High oven and freezer use around midday.'
        : 'Pemakaian oven & freezer tinggi di siang hari.',
  'normal' =>
    l10n.isEn
        ? 'Business appliance use is stable and evenly scheduled.'
        : 'Penggunaan alat usaha stabil dan terjadwal secara merata.',
  _ =>
    l10n.isEn
        ? 'The fridge, oven, and blender are often used together in the evening.'
        : 'Kulkas, oven, dan blender sering dipakai bersamaan sore hari.',
};

String demoInsightText(
  String status,
  AppLocalizations l10n,
) => switch (status) {
  'solar_recommendation' =>
    l10n.isEn
        ? 'Shift appliance use to 10 AM–2 PM to save more.'
        : 'Pindahkan pemakaian alat ke jam 10.00–14.00 agar lebih hemat.',
  'normal' =>
    l10n.isEn
        ? 'Keep up this energy-saving pattern.'
        : 'Pertahankan pola pemakaian hemat energi ini.',
  _ =>
    l10n.isEn
        ? 'Shift heavy appliance use to 10 AM–2 PM to save more.'
        : 'Pindahkan pemakaian alat berat ke jam 10.00–14.00 agar lebih hemat.',
};

/// Live (non-demo) heuristic computed from the member's own record history.
enum UsageHeuristic { spike, savings, normal }

String heuristicTitle(UsageHeuristic h, AppLocalizations l10n) => switch (h) {
  UsageHeuristic.spike =>
    l10n.isEn ? 'Energy Spike Detected' : 'Lonjakan Energi Terdeteksi',
  UsageHeuristic.savings =>
    l10n.isEn ? 'Savings Potential' : 'Potensi Penghematan',
  UsageHeuristic.normal => l10n.isEn ? 'Normal Usage' : 'Pemakaian Normal',
};

String heuristicSubtitle(UsageHeuristic h, AppLocalizations l10n) =>
    switch (h) {
      UsageHeuristic.spike =>
        l10n.isEn
            ? 'High usage between 6–9 PM'
            : 'Pemakaian tinggi jam 18.00–21.00',
      UsageHeuristic.savings =>
        l10n.isEn
            ? 'More efficient usage than last month'
            : 'Pemakaian lebih hemat dibanding bulan lalu',
      UsageHeuristic.normal =>
        l10n.isEn
            ? 'Your electricity usage pattern is stable'
            : 'Pola pemakaian listrik Anda stabil',
    };

String heuristicLabel(UsageHeuristic h, AppLocalizations l10n) => switch (h) {
  UsageHeuristic.spike => l10n.isEn ? 'Extra cost' : 'Biaya tambahan',
  UsageHeuristic.savings => l10n.isEn ? 'Estimated savings' : 'Estimasi hemat',
  UsageHeuristic.normal => l10n.isEn ? 'Estimated bill' : 'Estimasi tagihan',
};

String heuristicCauseTitle(UsageHeuristic h, AppLocalizations l10n) =>
    switch (h) {
      UsageHeuristic.spike =>
        l10n.isEn ? 'Cause of the Spike' : 'Penyebab Lonjakan',
      UsageHeuristic.savings =>
        l10n.isEn ? 'Savings Opportunity' : 'Peluang Penghematan',
      UsageHeuristic.normal => l10n.isEn ? 'Usage Pattern' : 'Pola Pemakaian',
    };

/// [applianceNames] is only used for [UsageHeuristic.spike]; pass the
/// already-localised, comma-joined appliance name list.
String heuristicCauseText(
  UsageHeuristic h,
  AppLocalizations l10n, {
  String applianceNames = '',
}) => switch (h) {
  UsageHeuristic.spike =>
    l10n.isEn
        ? '$applianceNames are often used together in the evening.'
        : '$applianceNames sering dipakai bersamaan sore hari.',
  UsageHeuristic.savings =>
    l10n.isEn
        ? 'Energy use is better controlled than your 3-month average.'
        : 'Penggunaan energi lebih terkontrol dibanding rata-rata 3 bulan terakhir.',
  UsageHeuristic.normal =>
    l10n.isEn
        ? 'Electricity use is stable, matching your daily business activity.'
        : 'Konsumsi listrik stabil sesuai aktivitas harian usaha Anda.',
};

String heuristicInsightText(
  UsageHeuristic h,
  AppLocalizations l10n,
) => switch (h) {
  UsageHeuristic.spike =>
    l10n.isEn
        ? 'Shift heavy appliance use to 10 AM–2 PM to save more.'
        : 'Pindahkan pemakaian alat berat ke jam 10.00–14.00 agar lebih hemat.',
  UsageHeuristic.savings =>
    l10n.isEn
        ? 'Keep up this efficiency, or use Solar Hub to save even more.'
        : 'Pertahankan efisiensi ini atau gunakan Solar Hub untuk penghematan lebih tinggi.',
  UsageHeuristic.normal =>
    l10n.isEn
        ? 'Use Solar Hub during the day to cut costs further.'
        : 'Gunakan Solar Hub saat siang hari untuk menekan biaya lebih lanjut.',
};

/// Fallback appliance names shown only when the member has none recorded yet.
String defaultSpikeApplianceNames(AppLocalizations l10n) =>
    l10n.isEn ? 'oven, freezer, and blender' : 'oven, freezer, dan blender';
