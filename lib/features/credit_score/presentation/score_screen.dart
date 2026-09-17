import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/brand.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logic/credit_signals.dart';
import '../../../core/logic/loan_math.dart';
import '../../../core/models/models.dart';
import '../../../core/paths.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/selectors.dart';
import '../application/credit_score_provider.dart';
import '../domain/credit_scoring_engine.dart';

/// Skor Kredit Energi — the cooperative's rule-based score, with every factor
/// and how it moved since last month.
class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final engine = ref.read(creditScoringEngineProvider);
    final score = data.scoreOf(me.id, now, engine);
    final readiness = data.readinessOf(me.id, now);
    final coop = data.cooperative;

    if (score == null) {
      return AppScaffold(
        title: l10n.scaffoldScore,
        onBack: () => context.pop(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: BrandArt(motif: BrandArtMotif.finance, size: 140),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.scoreNotCalculatedTitle,
              style: text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.scoreNotCalculatedMsg(kMinMonthsForScore),
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionCard(
              title: l10n.scoreRecordsCount(
                readiness.monthsRecorded,
                kMinMonthsForScore,
              ),
              child: AppProgressBar(
                value: readiness.monthsRecorded / kMinMonthsForScore,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TintedRow(
              icon: Icons.document_scanner_rounded,
              tone: readiness.monthsStillNeeded == 0
                  ? PillTone.success
                  : PillTone.warning,
              title: readiness.monthsStillNeeded == 0
                  ? l10n.scoreRecordsEnough
                  : l10n.scoreScanMoreMonths(readiness.monthsStillNeeded),
              subtitle: l10n.scoreScanMoreMonthsSubtitle,
              onTap: () => context.push(Paths.scan),
            ),
            const SizedBox(height: AppSpacing.sm),
            TintedRow(
              icon: Icons.groups_rounded,
              tone: readiness.inArisan ? PillTone.success : PillTone.warning,
              title: readiness.inArisan
                  ? l10n.scoreInArisan
                  : l10n.scoreJoinArisan,
              onTap: () => context.push(Paths.arisan),
            ),
            const SizedBox(height: AppSpacing.sm),
            TintedRow(
              icon: Icons.kitchen_rounded,
              tone: readiness.appliancesDeclared > 0
                  ? PillTone.success
                  : PillTone.warning,
              title: readiness.appliancesDeclared > 0
                  ? l10n.scoreAppliancesDeclaredCount(
                      readiness.appliancesDeclared,
                    )
                  : l10n.scoreRegisterAppliance,
              onTap: () => context.push(Paths.appliances),
            ),
          ],
        ),
      );
    }

    final previous = data.previousScoreOf(me.id, now);
    final delta = previous == null ? null : score.score - previous.score;
    final eligibility = coop == null
        ? null
        : loanEligibility(
            coop: coop,
            score: score,
            hasActiveLoan: data.activeLoanOf(me.id) != null,
          );

    return AppScaffold(
      title: l10n.scaffoldScore,
      onBack: () => context.pop(),
      bottomBar: eligibility == null
          ? null
          : PrimaryButton(
              label: eligibility.canApply
                  ? l10n.scoreApply
                  : l10n.scoreViewLoans,
              onPressed: () => context.push(
                eligibility.canApply ? Paths.loanApply : Paths.loans,
              ),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              children: [
                SemiGauge(value: score.score, caption: l10n.scoreFrom100),
                const SizedBox(height: AppSpacing.sm),
                StatusPill(
                  label: score.band.localizedLabel(l10n),
                  tone: switch (score.band) {
                    CreditBand.baikSekali ||
                    CreditBand.baik => PillTone.success,
                    CreditBand.cukup => PillTone.warning,
                    CreditBand.perluPeningkatan => PillTone.danger,
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  delta == null
                      ? l10n.scoreFirstThisMonth
                      : delta == 0
                      ? l10n.scoreSameAsMonth(
                          monthYearLabel(previous!.month, l10n: l10n),
                        )
                      : delta > 0
                      ? l10n.scoreDeltaUpFromMonth(
                          delta,
                          monthYearLabel(previous!.month, l10n: l10n),
                        )
                      : l10n.scoreDeltaDownFromMonth(
                          delta.abs(),
                          monthYearLabel(previous!.month, l10n: l10n),
                        ),
                  style: text.bodyMedium?.copyWith(
                    color: delta == null || delta == 0
                        ? null
                        : delta > 0
                        ? AppColors.primaryDark
                        : AppColors.dangerText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.scoreUpdatedAt(
                    formatDateTime(score.computedAt, l10n: l10n),
                  ),
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (data.scoreHistoryOf(me.id, now).length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: l10n.scoreHistoryTitle,
              child: _ScoreHistoryChart(
                history: data.scoreHistoryOf(me.id, now),
                l10n: l10n,
              ),
            ),
          ],
          if (eligibility != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              tone: eligibility.canApply ? InfoTone.success : InfoTone.warning,
              title: eligibility.canApply
                  ? l10n.scoreCanApplyAmount(
                      formatRupiah(eligibility.ceilingIdr),
                    )
                  : null,
              message: eligibility.canApply
                  ? l10n.scoreDecision
                  : eligibility.localizedMessage(l10n),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.scoreFactors),
          for (final f in score.factors) ...[
            _FactorCard(
              factor: f,
              previousPoints: previous?.factorPoints[f.category.name],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.scoreAbout,
            leadingIcon: Icons.info_outline_rounded,
            child: Text(l10n.scoreAboutBody, style: text.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _FactorCard extends StatelessWidget {
  const _FactorCard({required this.factor, this.previousPoints});

  final CreditFactor factor;
  final int? previousPoints;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final f = factor;
    final ratio = f.maxPoints == 0 ? 0.0 : f.points / f.maxPoints;
    final delta = previousPoints == null ? null : f.points - previousPoints!;
    final color = switch (f.direction) {
      FactorDirection.positive => AppColors.primary,
      FactorDirection.neutral => AppColors.secondaryDark,
      FactorDirection.negative => AppColors.danger,
    };

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(f.label, style: text.titleSmall)),
              if (delta != null && delta != 0) ...[
                StatusPill(
                  label: '${delta > 0 ? '+' : ''}$delta',
                  tone: delta > 0 ? PillTone.success : PillTone.danger,
                  icon: delta > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text('${f.points}/${f.maxPoints}', style: text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(value: ratio, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(f.reason, style: text.bodySmall),
        ],
      ),
    );
  }
}

/// A row of month bars scaled to the highest score in view, so a member can
/// see her trajectory rather than only last month's delta.
class _ScoreHistoryChart extends StatelessWidget {
  const _ScoreHistoryChart({required this.history, required this.l10n});

  final List<ScoreSnapshot> history;
  final AppLocalizations l10n;

  static const double _barAreaHeight = 96;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maxScore = history.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    final last = history.last;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final s in history) ...[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${s.score}', style: text.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: _barAreaHeight,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: maxScore == 0
                          ? 0
                          : (s.score / maxScore).clamp(0.05, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: s.month == last.month
                              ? AppColors.primary
                              : AppColors.primaryContainerDim,
                          borderRadius: AppRadius.xsBr,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  monthAbbr(s.month, l10n: l10n),
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (s != history.last) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}
