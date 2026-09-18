import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';

/// The cooperative's month at a glance: the same indicators the YESIST12
/// proposal says it will track, limited to what the app can really measure.
class CoopSummaryScreen extends ConsumerWidget {
  const CoopSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final data = s.data;
    final now = ref.read(clockProvider)();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final kpis = data.coopKpisOf(now, ref.read(creditScoringEngineProvider));
    final impact = data.quotaImpactOf(now);

    final tiles = [
      (
        Icons.groups_rounded,
        '${kpis.activeMembers}/${kpis.members}',
        l10n.adminSummaryActive,
      ),
      (Icons.verified_rounded, '${kpis.loanReady}', l10n.adminSummaryLoanReady),
      (
        Icons.swap_horiz_rounded,
        '${kpis.quotaTrades}',
        l10n.adminSummaryTrades,
      ),
      (
        Icons.bolt_rounded,
        formatKwh(impact.tradedKwh),
        l10n.adminSummaryTradedKwh,
      ),
    ];

    return AppScaffold(
      title: l10n.adminKpiTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: monthYearLabel(now, l10n: l10n)),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final (icon, value, label) in tiles)
                    SizedBox(
                      width: w,
                      child: SectionCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: AppColors.primary),
                            const SizedBox(height: AppSpacing.sm),
                            Text(value, style: AppTypography.numeric(24)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(label, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.adminSummaryUtilization,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${impact.utilizationPct}%',
                  style: AppTypography.numeric(24),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(value: impact.utilizationPct / 100),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.adminSummaryUtilizationHint, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: l10n.adminSummaryRepayment,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpis.onTimePct == null
                      ? l10n.adminSummaryRepaymentNone
                      : '${kpis.onTimePct}%',
                  style: kpis.onTimePct == null
                      ? text.bodyMedium
                      : AppTypography.numeric(24),
                ),
                if (kpis.onTimePct != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.adminSummaryRepaymentDetail(
                      kpis.installmentsOnTime,
                      kpis.installmentsDue,
                    ),
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoBanner(tone: InfoTone.info, message: l10n.adminKpiNote),
        ],
      ),
    );
  }
}
