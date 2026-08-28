import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/money.dart';
import '../application/bill_scan_providers.dart';

/// SC-03: Analisis AI Energi (docs/SCREEN_INVENTORY.md §SC-03)
class EnergyAnalysisScreen extends ConsumerWidget {
  const EnergyAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DemoEnergyInsight? insight = ref.watch(energyInsightProvider);

    if (insight == null) {
      return AppScaffold(
        title: 'Analisis AI Energi',
        onBack: () => context.pop(),
        body: EmptyState(
          icon: Icons.analytics_outlined,
          title: 'Belum ada analisis',
          message: 'Scan tagihan listrik Anda untuk melihat analisis energi.',
          action: PrimaryButton(
            label: 'Scan Tagihan',
            onPressed: () => context.pushReplacement(AppRoute.scanTagihan),
            expand: false,
          ),
        ),
      );
    }

    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Analisis AI Energi',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Lihat Jadwal Solar Hub',
        onPressed: () => context.push(AppRoute.solarBooking),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (insight.spikeDetected) ...[
            SectionCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Lonjakan Energi Terdeteksi',
                    style: text.titleMedium?.copyWith(color: AppColors.danger),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    insight.spikeWindowLabel,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '+ ${formatRupiah(insight.addedMonthlyCostIdr)}',
                        style: text.headlineSmall?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const QualifierLabel(QualifierKind.estimasi),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SectionCard(
              child: InfoBanner(
                tone: InfoTone.success,
                message: 'Tidak ada lonjakan terdeteksi.',
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          Text('Insight Utama', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(insight.mainInsight, style: text.bodyLarge),

          if (insight.contributors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text('Alat Penyumbang Biaya', style: text.titleMedium),
                ),
                const QualifierLabel(QualifierKind.ilustrasi),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ..._sortContributors(
              insight.contributors,
            ).map((c) => _ContributorTile(contributor: c)),
          ],
        ],
      ),
    );
  }

  List<DemoApplianceCost> _sortContributors(List<DemoApplianceCost> list) {
    final sorted = List<DemoApplianceCost>.from(list);
    sorted.sort((a, b) => b.costIdr.compareTo(a.costIdr));
    return sorted;
  }
}

class _ContributorTile extends StatelessWidget {
  const _ContributorTile({required this.contributor});

  final DemoApplianceCost contributor;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SectionCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.electrical_services,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    contributor.name,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '+ ${formatRupiah(contributor.costIdr)}',
                  style: text.bodyMedium?.copyWith(color: AppColors.danger),
                ),
              ],
            ),
            if (contributor.tip != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                contributor.tip!,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
