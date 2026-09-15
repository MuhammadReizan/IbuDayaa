import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/brand.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/format.dart';
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

    return AppScaffold(
      title: 'Hasil Scan Solar Panel',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: data.recommendation
            ? 'Lanjut ke Booking Solar Hub'
            : 'Solar Hub Belum Direkomendasikan',
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
            title: 'Paparan Matahari',
            child: SectionCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Kualitas paparan',
                    value: data.sunExposureLabel,
                    emphasize: true,
                  ),
                  KeyValueRow(
                    label: 'Akurasi sensor',
                    value: '${data.accuracy}% (${data.accuracyLabel})',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Section 3: Data Atap ───────────────────────────────────────────
          NumberedSection(
            number: 2,
            title: 'Data Atap',
            child: SectionCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Luas atap',
                    value: '${data.roofArea} m²',
                    emphasize: true,
                  ),
                  KeyValueRow(
                    label: 'Kemiringan atap',
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
            title: 'Estimasi Penghematan',
            child: SectionCard(
              tone: CardTone.mint,
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Hemat per bulan',
                    value: '${formatRupiah(data.monthlySaving)} / bulan',
                    emphasize: true,
                    valueColor: AppColors.primaryDark,
                  ),
                  KeyValueRow(
                    label: 'Hemat per tahun',
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
            title: 'Tips IbuDaya',
            child: Text(
              data.tip,
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
      SolarPanelStatus.healthy => (PillTone.success, 'Sangat Layak'),
      SolarPanelStatus.warning => (PillTone.warning, 'Perlu Optimasi'),
      SolarPanelStatus.poor => (PillTone.danger, 'Kurang Layak'),
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
                  data.statusLabel,
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
