import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
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
    final l10n = AppLocalizations.of(context);
    final insight = s.data.insightOf(me.id);
    final tariff = me.tariffIdrPerKwh;

    if (insight == null) {
      return AppScaffold(
        title: l10n.energyAnalysisTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.scan,
          title: l10n.energyAnalysisEmpty,
          message:
              'Scan tagihan listrik pertama Anda untuk melihat analisisnya.',
          action: PrimaryButton(
            label: l10n.scanConfirm,
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
      title: l10n.energyAnalysisTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.energyAnalysisUsage(
                    monthYearLabel(insight.latest.month, l10n: l10n),
                  ),
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
                      ? l10n.energyAnalysisNoPrev
                      : change >= 0
                      ? l10n.energyAnalysisUp(
                          change.round(),
                          monthYearLabel(insight.previous!.month, l10n: l10n),
                          extra > 0
                              ? l10n.energyAnalysisMoreExpensive(
                                  formatRupiah(extra),
                                )
                              : '',
                        )
                      : l10n.energyAnalysisDown(
                          change.abs().round(),
                          monthYearLabel(insight.previous!.month, l10n: l10n),
                        ),
                  style: text.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          if (insight.spikeDetected) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              tone: InfoTone.danger,
              title: l10n.energyAnalysisSpikeTitle,
              message: l10n.energyAnalysisSpikeBody,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.energyAnalysisTrend6Months,
            child: UsageBars(months: months),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.energyAnalysisBreakdownTitle,
            trailing: TextButton(
              onPressed: () => context.push(Paths.appliances),
              child: Text(
                insight.contributors.isEmpty ? l10n.actionAdd : l10n.actionEdit,
              ),
            ),
            child: insight.contributors.isEmpty
                ? Text(l10n.energyAnalysisNoAppliances, style: text.bodyMedium)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (insight.declaredExceedsUsage) ...[
                        InfoBanner(
                          tone: InfoTone.warning,
                          title: l10n.obsMismatchTitle,
                          message: l10n.energyAnalysisMismatchBody(
                            formatKwh(insight.declaredKwh),
                            formatKwh(insight.latest.kwh),
                          ),
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
                          label: l10n.energyAnalysisUnregistered,
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
              title: l10n.energyAnalysisSavingTipTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.energyAnalysisSavingTipBody(
                      applianceKindLabel(top.appliance.kind, l10n),
                      formatKwh(top.monthlyKwh),
                      formatRupiah(top.monthlyCostIdr),
                    ),
                    style: text.bodyMedium?.copyWith(color: AppColors.onSolar),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: l10n.scaffoldBooking,
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
            l10n.energyAnalysisFormula(formatRupiah(tariff)),
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
    final l10n = AppLocalizations.of(context);
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
            Expanded(
              child: Text(
                cost.appliance.name.isNotEmpty
                    ? cost.appliance.name
                    : applianceKindLabel(cost.appliance.kind, l10n),
                style: text.titleSmall,
              ),
            ),
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
