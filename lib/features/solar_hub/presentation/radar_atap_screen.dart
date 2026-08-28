import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../application/solar_hub_providers.dart';

/// SC-05: Radar Atap — Kelayakan Awal (docs/SCREEN_INVENTORY.md §SC-05)
class RadarAtapScreen extends ConsumerWidget {
  const RadarAtapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DemoRoofScan scan = ref.watch(roofScanProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Radar Atap',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Lanjut ke Rekomendasi Solar Hub',
        onPressed: () => context.pushReplacement(AppRoute.solarBookingPath),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(
            tone: InfoTone.warning,
            icon: Icons.info_outline,
            message: scan.verificationNotice,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            child: Column(
              children: [
                Icon(
                  _getSuitabilityIcon(scan.suitability),
                  color: _getSuitabilityColor(scan.suitability),
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Kelayakan Awal: ${_formatSuitability(scan.suitability)}',
                  style: text.titleMedium?.copyWith(
                    color: _getSuitabilityColor(scan.suitability),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const QualifierLabel(QualifierKind.estimasiAwal),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Perkiraan Hasil Pemindaian', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _MetricRow(
            icon: Icons.straighten,
            label: 'Perkiraan area potensial',
            value: '${scan.estimatedPotentialAreaM2.toStringAsFixed(0)} m²',
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricRow(
            icon: Icons.explore_outlined,
            label: 'Orientasi atap',
            value: scan.roofOrientationLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Potensi paparan matahari',
            value: scan.sunExposurePotentialLabel,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Tips IbuDaya', style: text.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(scan.tip, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSuitabilityIcon(String suitability) {
    if (suitability == 'sangatBaik') return Icons.verified;
    if (suitability == 'baik') return Icons.check_circle_outline;
    if (suitability == 'cukup') return Icons.info_outline;
    return Icons.warning_amber_rounded;
  }

  Color _getSuitabilityColor(String suitability) {
    if (suitability == 'sangatBaik' || suitability == 'baik') {
      return AppColors.success;
    }
    if (suitability == 'cukup') return AppColors.info;
    return AppColors.warning;
  }

  String _formatSuitability(String suitability) {
    if (suitability == 'sangatBaik') return 'Sangat Baik';
    if (suitability == 'baik') return 'Baik';
    if (suitability == 'cukup') return 'Cukup';
    if (suitability == 'kurang') return 'Kurang';
    return suitability;
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
