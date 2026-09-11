import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/labels.dart';
import 'usage_bars.dart';

class EnergyAnalysisScreen extends ConsumerWidget {
  const EnergyAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final text = Theme.of(context).textTheme;
    final insight = s.data.insightOf(me.id);
    final tariff = me.tariffIdrPerKwh;

    if (insight == null) {
      return AppScaffold(
        title: 'Analisis Energi',
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.scan,
          title: 'Belum ada yang dianalisis',
          message:
              'Scan tagihan listrik pertama Anda untuk melihat analisisnya.',
          action: PrimaryButton(
            label: 'Scan Tagihan',
            expand: false,
            onPressed: () => context.pushReplacement(Paths.scan),
          ),
        ),
      );
    }

    final months = monthlyUsage(s.data.recordsOf(me.id));
    final change = insight.changePct;
    final extra = insight.extraCostIdr(tariff);
    final top = insight.contributors.firstOrNull;

    return AppScaffold(
      title: 'Analisis Energi',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemakaian ${monthYearLabel(insight.latest.month)}',
                  style: text.labelLarge?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatKwhValue(insight.latest.kwh),
                      style: AppTypography.numeric(40, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'kWh',
                        style: text.titleMedium?.copyWith(
                          color: AppColors.textOnDarkDim,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatRupiah(insight.latest.totalIdr),
                            style: AppTypography.numeric(
                              20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  change == null
                      ? 'Catat bulan berikutnya untuk melihat perubahan.'
                      : change >= 0
                      ? 'Naik ${change.round()}% dari ${monthYearLabel(insight.previous!.month)}'
                            '${extra > 0 ? ' · lebih mahal ± ${formatRupiah(extra)}' : ''}'
                      : 'Turun ${change.abs().round()}% dari '
                            '${monthYearLabel(insight.previous!.month)}',
                  style: text.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          if (insight.spikeDetected) ...[
            const SizedBox(height: AppSpacing.md),
            const InfoBanner(
              tone: InfoTone.danger,
              title: 'Lonjakan terdeteksi',
              message:
                  'Bulan ini lebih dari 15% di atas rata-rata 3 bulan '
                  'sebelumnya. Cek alat yang jam pakainya bertambah.',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Tren 6 bulan',
            child: UsageBars(months: months),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Rincian per alat',
            trailing: TextButton(
              onPressed: () => context.push(Paths.appliances),
              child: Text(insight.contributors.isEmpty ? 'Tambah' : 'Ubah'),
            ),
            child: insight.contributors.isEmpty
                ? Text(
                    'Daftarkan alat usaha (oven, kulkas, mesin jahit…) untuk '
                    'melihat alat mana yang paling banyak memakan listrik.',
                    style: text.bodyMedium,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (insight.declaredExceedsUsage) ...[
                        InfoBanner(
                          tone: InfoTone.warning,
                          title: 'Data alat perlu dicek',
                          message:
                              'Total alat (${formatKwh(insight.declaredKwh)}) '
                              'melebihi pemakaian tercatat '
                              '(${formatKwh(insight.latest.kwh)}). Periksa watt '
                              'atau jam pakainya.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      for (final c in insight.contributors) ...[
                        _ContributorRow(cost: c),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (!insight.declaredExceedsUsage &&
                          insight.unaccountedKwh > 0)
                        KeyValueRow(
                          label: 'Belum terdaftar (lampu, dll.)',
                          value: formatKwh(insight.unaccountedKwh),
                        ),
                    ],
                  ),
          ),
          if (top != null && !insight.declaredExceedsUsage) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              tone: CardTone.solar,
              leadingIcon: Icons.lightbulb_rounded,
              title: 'Saran penghematan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${top.appliance.name} memakai sekitar '
                    '${formatKwh(top.monthlyKwh)} per bulan '
                    '(± ${formatRupiah(top.monthlyCostIdr)}). Pakai di jam Solar '
                    'Hub koperasi untuk mengurangi tagihan PLN.',
                    style: text.bodyMedium?.copyWith(color: AppColors.onSolar),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Booking Solar Hub',
                    icon: Icons.solar_power_rounded,
                    onPressed: () => context.push(
                      Uri(
                        path: Paths.booking,
                        queryParameters: {'alat': top.appliance.name},
                      ).toString(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Cara menghitung: watt × jam per hari × hari per minggu × 30/7 ÷ '
            '1000 = kWh per bulan, dikali tarif Anda ${formatRupiah(tariff)}/kWh. '
            'Angkanya perkiraan dari data alat yang Anda isi.',
            style: text.bodySmall,
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
            Icon(
              applianceIcon(cost.appliance.kind),
              size: 20,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(cost.appliance.name, style: text.titleSmall)),
            Text(
              '${(cost.share * 100).round()}% · ${formatRupiah(cost.monthlyCostIdr)}',
              style: text.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        AppProgressBar(
          value: cost.share,
          color: cost.share >= 0.35
              ? AppColors.secondaryDark
              : AppColors.primary,
        ),
      ],
    );
  }
}
