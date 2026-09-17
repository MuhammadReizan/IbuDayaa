import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/brand.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/paths.dart';
import '../../../core/solar_demo/solar_panel_model.dart';

/// Layar hasil scan QR solar panel — menampilkan data panel, estimasi
/// penghematan, akurasi sensor, ROI, tip, dan CTA booking. Ini adalah
/// perhitungan berbasis aturan, bukan model terlatih — teks di layar ini
/// tidak boleh mengklaim "AI" (lihat aturan kejujuran di CLAUDE.md).
///
/// Mengikuti gaya visual Radar Atap yang bersih dan konsisten dengan sistem
/// desain IbuDaya (HeroCard bergradien + BrandArt, NumberedSection,
/// SectionCard, KeyValueRow, dan PrimaryButton).
class SolarPanelResultScreen extends StatelessWidget {
  const SolarPanelResultScreen({super.key, required this.data});

  final SolarPanelData data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.solarScanResultTitle,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: data.recommendation
            ? l10n.solarScanContinueToBooking
            : l10n.solarScanNotRecommended,
        icon: data.recommendation
            ? Icons.arrow_forward_rounded
            : Icons.block_rounded,
        onPressed: data.recommendation
            ? () => context.push(Paths.booking)
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section 1: Hero Card Status ────────────────────────────────────
          _StatusHeroCard(data: data),
          const SizedBox(height: AppSpacing.xl),

          // ── Section 2: Paparan Matahari ───────────────────────────────────
          NumberedSection(
            number: 1,
            title: l10n.solarScanSunSection,
            child: SectionCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: l10n.solarScanExposureQuality,
                    value: data.sunExposureLabel(l10n),
                    emphasize: true,
                  ),
                  KeyValueRow(
                    label: l10n.solarScanSensorAccuracy,
                    value: '${data.accuracy}% (${data.accuracyLabel(l10n)})',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Section 3: Data Atap ───────────────────────────────────────────
          NumberedSection(
            number: 2,
            title: l10n.solarScanRoofSection,
            child: SectionCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: l10n.solarScanRoofArea,
                    value: '${data.roofArea} m²',
                    emphasize: true,
                  ),
                  KeyValueRow(
                    label: l10n.solarScanRoofSlope,
                    value: '${data.roofSlope}°',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Section 4: Estimasi Penghematan ───────────────────────────────
          NumberedSection(
            number: 3,
            title: l10n.solarScanSavingsSection,
            child: SectionCard(
              tone: CardTone.mint,
              child: Column(
                children: [
                  KeyValueRow(
                    label: l10n.solarScanSavingsPerMonth,
                    value: l10n.solarScanPerMonth(
                      formatRupiah(data.monthlySaving),
                    ),
                    emphasize: true,
                    valueColor: AppColors.primaryDark,
                  ),
                  KeyValueRow(
                    label: l10n.solarScanSavingsPerYear,
                    value: formatRupiah(data.monthlySaving * 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Section 5: Tips IbuDaya ───────────────────────────────────────
          SectionCard(
            tone: CardTone.solar,
            leadingIcon: Icons.lightbulb_rounded,
            title: l10n.solarScanTipsTitle,
            child: Text(
              data.tip(l10n),
              style: text.bodySmall?.copyWith(
                color: AppColors.onSolar,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Hero Card
// ---------------------------------------------------------------------------

/// HeroCard bergradien dengan ilustrasi BrandArt — bersih, elegan, dan tanpa
/// duplikasi label text.
class _StatusHeroCard extends StatelessWidget {
  const _StatusHeroCard({required this.data});
  final SolarPanelData data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final gradient = switch (data.status) {
      SolarPanelStatus.healthy => AppGradients.brand,
      SolarPanelStatus.warning => const LinearGradient(
        colors: [Color(0xFFD9931B), Color(0xFFB07310)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      SolarPanelStatus.poor => const LinearGradient(
        colors: [Color(0xFFD8412F), Color(0xFFA5291B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    };

    final (pillTone, pillLabel) = switch (data.status) {
      SolarPanelStatus.healthy => (
        PillTone.success,
        l10n.solarScanPillVeryFeasible,
      ),
      SolarPanelStatus.warning => (
        PillTone.warning,
        l10n.solarScanPillNeedsOptimization,
      ),
      SolarPanelStatus.poor => (
        PillTone.danger,
        l10n.solarScanPillLessFeasible,
      ),
    };

    return HeroCard(
      gradient: gradient,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.panelId} · ${data.location}',
                  style: text.labelLarge?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.statusLabel(l10n),
                  style: text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusPill(label: pillLabel, tone: pillTone),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const BrandArt(motif: BrandArtMotif.solar, size: 80, onDark: true),
        ],
      ),
    );
  }
}
