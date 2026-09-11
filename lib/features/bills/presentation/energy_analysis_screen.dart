import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/insights.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';

/// Where the user's electricity money went last month — computed from the bill
/// they recorded and the appliances they declared. Nothing here is estimated
/// by a model; it is arithmetic they can check by hand.
class EnergyAnalysisScreen extends ConsumerWidget {
  const EnergyAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(energyInsightProvider);
    final profile = ref.watch(profileProvider);
    final text = Theme.of(context).textTheme;

    if (insight == null) {
      return AppScaffold(
        title: 'Analisis Energi',
        onBack: () => context.pop(),
        body: EmptyState(
          motif: BrandArtMotif.scan,
          title: 'Belum ada tagihan',
          message:
              'Catat tagihan listrik Anda dulu. Analisis ini dihitung dari '
              'angka pada struk PLN Anda sendiri.',
          action: PrimaryButton(
            label: 'Catat Tagihan',
            expand: false,
            onPressed: () => context.push(AppRoute.billAddPath),
          ),
        ),
      );
    }

    final tariff = profile?.tariffIdrPerKwh ?? insight.latest.idrPerKwh;
    final change = insight.changePct;

    return AppScaffold(
      title: 'Analisis Energi',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        icon: Icons.solar_power_rounded,
        label: 'Catat Pemakaian Solar Hub',
        onPressed: () => context.push(AppRoute.sessionAddPath),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BillHero(insight: insight, changePct: change),
          const SizedBox(height: AppSpacing.lg),

          if (insight.spikeDetected && change != null && change > 0)
            InfoBanner(
              tone: InfoTone.warning,
              title: 'Pemakaian naik ${change.round()}%',
              message:
                  'Dibanding rata-rata bulan sebelumnya, tagihan ini lebih '
                  'tinggi sekitar '
                  '${formatRupiah(insight.extraCostIdr(tariff))}.',
            )
          else if (change != null && change < -5)
            InfoBanner(
              tone: InfoTone.success,
              title: 'Lebih hemat ${change.abs().round()}%',
              message:
                  'Pemakaian turun dibanding bulan sebelumnya. Pertahankan!',
            )
          else if (insight.previous == null)
            const InfoBanner(
              tone: InfoTone.info,
              message:
                  'Catat satu bulan lagi untuk melihat naik-turun pemakaian '
                  'Anda.',
            ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              Expanded(
                child: Text('Pemakaian per Alat', style: text.titleMedium),
              ),
              TextButton(
                onPressed: () => context.push(AppRoute.appliancesPath),
                child: const Text('Atur'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (insight.contributors.isEmpty)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Anda belum mendaftarkan alat usaha, jadi tagihan ini '
                    'belum bisa dipecah per alat.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    icon: Icons.add_rounded,
                    label: 'Daftarkan Alat',
                    onPressed: () => context.push(AppRoute.applianceEditPath),
                  ),
                ],
              ),
            )
          else ...[
            if (insight.declaredExceedsBill) ...[
              const InfoBanner(
                tone: InfoTone.warning,
                title: 'Angka alat perlu dikoreksi',
                message:
                    'Total pemakaian alat yang Anda catat melebihi tagihan '
                    'bulan ini. Periksa lagi daya (watt) atau jam pemakaian.',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            SectionCard(
              child: Column(
                children: [
                  for (int i = 0; i < insight.contributors.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    _ContributorRow(cost: insight.contributors[i]),
                  ],
                  if (insight.unaccountedKwh > 0.5) ...[
                    const Divider(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Belum tercatat',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          formatKwh(insight.unaccountedKwh),
                          style: text.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lampu, kipas, dan alat rumah tangga lain yang belum '
                      'Anda daftarkan.',
                      style: text.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          SectionCard(
            tone: CardTone.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Saran IbuDaya',
                      style: text.titleSmall?.copyWith(
                        color: AppColors.primaryDarker,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _advice(insight),
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.primaryDarker,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _advice(EnergyInsight insight) {
    if (insight.contributors.isEmpty) {
      return 'Daftarkan alat usaha Anda agar IbuDaya bisa menunjukkan alat '
          'mana yang paling menyedot biaya.';
    }
    final top = insight.contributors.first;
    if (top.share >= 0.3) {
      return '${top.appliance.name} menyumbang sekitar '
          '${(top.share * 100).round()}% dari pemakaian alat Anda. Menjalankan '
          'alat ini di Solar Hub saat siang bisa memangkas biayanya.';
    }
    return 'Pemakaian Anda cukup merata antar alat. Memindahkan alat berdaya '
        'besar ke jam Solar Hub tetap bisa menurunkan tagihan.';
  }
}

class _BillHero extends StatelessWidget {
  const _BillHero({required this.insight, required this.changePct});

  final EnergyInsight insight;
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bill = insight.latest;

    return Container(
      padding: AppSpacing.hero,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: AppRadius.lgBr,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatMonthYear(bill.periodMonth).toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: AppColors.textOnDarkDim,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatRupiah(bill.totalIdr),
            style: AppTypography.numeric(30, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                formatKwh(bill.kwh),
                style: text.bodyMedium?.copyWith(color: Colors.white),
              ),
              if (changePct != null) ...[
                const SizedBox(width: AppSpacing.md),
                Icon(
                  changePct! >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: changePct! >= 0
                      ? AppColors.secondary
                      : AppColors.accentLeaf,
                ),
                const SizedBox(width: 4),
                Text(
                  '${changePct!.abs().round()}% vs bulan lalu',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ContributorRow extends StatelessWidget {
  const _ContributorRow({required this.cost});
  final ApplianceCost cost;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cost.appliance.name,
                style: text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${(cost.share * 100).round()}%', style: text.labelSmall),
            const SizedBox(width: AppSpacing.md),
            Text(
              formatRupiah(cost.monthlyCostIdr),
              style: text.labelMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: cost.share.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatKwh(cost.monthlyKwh)} · ${cost.appliance.watts.round()} W '
          '· ${cost.appliance.hoursPerDay} jam/hari',
          style: text.labelSmall,
        ),
      ],
    );
  }
}
