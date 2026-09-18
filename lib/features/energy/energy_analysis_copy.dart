import '../../core/l10n/l10n.dart';

/// Localised display copy for the live spike/savings heuristic computed from
/// a member's own record history, shown on the Analisis Energi screen.
///
/// Centralised here (instead of inline in the screen) so its wording never
/// leaks a hardcoded-language string past a locale switch.

/// Heuristic computed from the member's own record history.
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
            ? 'Usage is above your earlier months'
            : 'Pemakaian di atas bulan-bulan sebelumnya',
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
  UsageHeuristic.spike =>
    l10n.isEn ? 'Extra energy value' : 'Tambahan nilai energi',
  UsageHeuristic.savings => l10n.isEn ? 'Estimated savings' : 'Estimasi hemat',
  UsageHeuristic.normal =>
    l10n.isEn ? 'Energy value this month' : 'Nilai energi bulan ini',
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
    applianceNames.isEmpty
        ? (l10n.isEn
              ? 'Hub usage recorded this month is higher than before.'
              : 'Pemakaian Solar Hub yang tercatat bulan ini lebih tinggi dari sebelumnya.')
        : (l10n.isEn
              ? '$applianceNames draw the most energy from the hub.'
              : '$applianceNames paling banyak menyerap energi hub.'),
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
