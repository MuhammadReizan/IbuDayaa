import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../application/credit_score_provider.dart';
import '../domain/credit_scoring_engine.dart';

/// SC-09: Skor Kredit Energi (docs/SCREEN_INVENTORY.md §SC-09)
class CreditScoreScreen extends ConsumerWidget {
  const CreditScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CreditScore score = ref.watch(creditScoreProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Skor Kredit Energi',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Lihat Simulasi Pembiayaan',
        onPressed: () => context.push(AppRoute.financingPath), // to be created
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Large Gauge Section
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: score.score / 100.0,
                    strokeWidth: 16,
                    backgroundColor: AppColors.primaryContainer,
                    color: AppColors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.score}',
                      style: AppTypography.displayScore.copyWith(
                        fontSize: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'dari 100',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Text(
              score.band.label,
              style: text.headlineSmall?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              score.eligibilityLabel,
              style: text.bodyLarge?.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text('Faktor Penentu Skor Anda', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),

          // Factor list
          ...score.factors.map((f) => _FactorTile(factor: f)),

          const SizedBox(height: AppSpacing.xl),
          const InfoBanner(
            tone: InfoTone.info,
            icon: Icons.info_outline,
            message:
                'Skor kredit ini dikalkulasi berdasarkan aktivitas Anda di '
                'komunitas IbuDaya untuk menentukan kelayakan simulasi pembiayaan.',
          ),
        ],
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.factor});

  final CreditFactor factor;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    final Color dirColor = switch (factor.direction) {
      FactorDirection.positive => AppColors.success,
      FactorDirection.negative => AppColors.danger,
      FactorDirection.neutral => AppColors.warning,
    };
    final IconData dirIcon = switch (factor.direction) {
      FactorDirection.positive => Icons.trending_up,
      FactorDirection.negative => Icons.trending_down,
      FactorDirection.neutral => Icons.trending_flat,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(dirIcon, size: 24, color: dirColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(factor.label, style: text.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.pillBr,
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(
                    '${factor.points} / ${factor.maxPoints}',
                    style: text.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              factor.reason,
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
