import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/logic/loan_math.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../../core/state/snapshot.dart';
import '../credit_score/application/credit_score_provider.dart';
import '../shared/labels.dart';

class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;

    final l10n = AppLocalizations.of(context);
    final insight = data.insightOf(me.id);
    final observations = data.observationsOf(me.id, now, l10n);
    final impact = data.impactOf(me.id, now);
    final unread = data.unreadNotificationsOf(me.id);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(appStateProvider.notifier).refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            children: [
              Row(
                children: [
                  MemberAvatar(name: me.fullName, size: 46),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.homeHelloPrefix}, ${me.greetingName}',
                          style: text.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          data.cooperative?.name ?? me.businessName,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.scaffoldNotifications,
                    onPressed: () => context.push(Paths.notifications),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _BillHero(insight: insight, tariff: me.tariffIdrPerKwh),
              const SizedBox(height: AppSpacing.xl),
              _QuickActions(pendingQuota: _pendingQuotaFor(data, me.id)),
              const SizedBox(height: AppSpacing.xl),
              if (observations.isNotEmpty) ...[
                SectionHeader(title: l10n.homeStatusHeader),
                for (final o in observations.take(4)) ...[
                  TintedRow(
                    filled: true,
                    icon: switch (o.tone) {
                      ObservationTone.danger => Icons.trending_up_rounded,
                      ObservationTone.warning => Icons.bolt_rounded,
                      ObservationTone.success => Icons.eco_rounded,
                      ObservationTone.info => Icons.info_outline_rounded,
                    },
                    tone: switch (o.tone) {
                      ObservationTone.danger => PillTone.danger,
                      ObservationTone.warning => PillTone.warning,
                      ObservationTone.success => PillTone.success,
                      ObservationTone.info => PillTone.info,
                    },
                    title: o.title,
                    subtitle: o.body,
                    onTap: () => context.push(_routeFor(o, insight)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              _ScoreTeaser(me: me),
              const SizedBox(height: AppSpacing.lg),
              _LoanTeaser(me: me),
              if (impact.hasData) ...[
                const SizedBox(height: AppSpacing.lg),
                _ImpactCard(impact: impact),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static int _pendingQuotaFor(CoopSnapshot data, String userId) => data.offers
      .where((o) => o.ownerId == userId && o.status == QuotaStatus.pending)
      .length;

  static String _routeFor(PowerObservation o, EnergyInsight? insight) =>
      switch (o.action) {
        ObservationAction.scanBill => Paths.scan,
        ObservationAction.appliances => Paths.appliances,
        ObservationAction.analysis => Paths.energyAnalysis,
        ObservationAction.booking => Uri(
          path: Paths.booking,
          queryParameters: {
            if (insight != null && insight.contributors.isNotEmpty)
              'alat': insight.contributors.first.appliance.name,
          },
        ).toString(),
        ObservationAction.confirmBooking => Paths.bookings,
      };
}

class _BillHero extends StatelessWidget {
  const _BillHero({required this.insight, required this.tariff});

  final EnergyInsight? insight;
  final double tariff;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final i = insight;
    final change = i?.changePct;

    return HeroCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      i == null
                          ? l10n.homeBillLabel
                          : l10n.billMonthLabel(
                              monthYearLabel(i.latest.month, l10n: l10n),
                            ),
                      style: text.labelLarge?.copyWith(
                        color: AppColors.textOnDarkDim,
                      ),
                    ),
                  ),
                  if (change != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs + 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: AppRadius.pillBr,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            change > 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${change.abs().round()}% ${l10n.homeChangePctSuffix}',
                            style: text.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(right: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i == null) ...[
                      Text(
                        l10n.homeBillNoData,
                        style: text.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.homeBillNoDataHint,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.textOnDarkDim,
                        ),
                      ),
                    ] else ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(i.latest.totalIdr),
                          style: AppTypography.numeric(34, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${formatKwh(i.latest.kwh)}'
                        '${i.latest.fromTokens ? ' · ${l10n.homeFromTokens(i.latest.recordCount)}' : ''}',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textOnDarkDim,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _HeroButton(
                      icon: Icons.insights_rounded,
                      label: l10n.homeAnalysis,
                      onTap: () => context.push(
                        i == null ? Paths.energy : Paths.energyAnalysis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 8,
            bottom: -AppSpacing.hero.bottom,
            child: IgnorePointer(
              child: SizedBox(
                width: 145,
                height: 135,
                child: Image.asset(
                  'assets/images/house.webp',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: AppRadius.buttonBr,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonBr,
        child: Container(
          height: kMinTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: fg),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.pendingQuota});

  final int pendingQuota;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final l10n = AppLocalizations.of(context);
        final items = [
          (
            Icons.solar_power_rounded,
            l10n.homeBookingHub,
            Paths.booking,
            AppColors.secondaryDark,
            AppColors.secondaryContainer,
            0,
          ),
          (
            Icons.groups_rounded,
            l10n.homeArisanEnergi,
            Paths.arisan,
            AppColors.primary,
            AppColors.primaryContainer,
            0,
          ),
          (
            Icons.swap_horiz_rounded,
            l10n.homeTukarKuota,
            Paths.quota,
            AppColors.primary,
            AppColors.primaryContainer,
            pendingQuota,
          ),
          (
            Icons.speed_rounded,
            l10n.homeSkorKredit,
            Paths.score,
            AppColors.info,
            AppColors.infoContainer,
            0,
          ),
          (
            Icons.account_balance_wallet_rounded,
            l10n.homePembiayaan,
            Paths.loans,
            AppColors.secondaryDark,
            AppColors.secondaryContainer,
            0,
          ),
          (
            Icons.receipt_long_rounded,
            l10n.homeCatatanListrik,
            Paths.energy,
            AppColors.primary,
            AppColors.primaryContainer,
            0,
          ),
          (
            Icons.kitchen_rounded,
            l10n.homeAlatUsaha,
            Paths.appliances,
            AppColors.info,
            AppColors.infoContainer,
            0,
          ),
        ];
        final cols = c.maxWidth < 340 ? 3 : 4;
        final w = c.maxWidth / cols;
        return Wrap(
          runSpacing: AppSpacing.md,
          children: [
            for (final (icon, label, path, color, bg, badge) in items)
              SizedBox(
                width: w,
                child: QuickAction(
                  icon: icon,
                  label: label,
                  color: color,
                  background: bg,
                  badge: badge,
                  onTap: () => context.push(path),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScoreTeaser extends ConsumerWidget {
  const _ScoreTeaser({required this.me});

  final Profile me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final readiness = data.readinessOf(me.id, now);
    final score = data.scoreOf(
      me.id,
      now,
      ref.read(creditScoringEngineProvider),
    );
    final coop = data.cooperative;

    if (score == null) {
      return SectionCard(
        onTap: () => context.push(Paths.score),
        child: Row(
          children: [
            const FeatureBadge(icon: Icons.speed_rounded, tone: BadgeTone.sky),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeScoreTitle, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeScoreMonthsNeeded(readiness.monthsStillNeeded),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppProgressBar(
                    value: readiness.monthsRecorded / 3,
                    color: AppColors.info,
                    track: AppColors.infoContainer,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final eligibility = coop == null
        ? null
        : loanEligibility(
            coop: coop,
            score: score,
            hasActiveLoan: data.activeLoanOf(me.id) != null,
          );
    return SectionCard(
      onTap: () => context.push(Paths.score),
      child: Row(
        children: [
          ScoreRing(score: score.score, size: 72, stroke: 8),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeScoreTitle, style: text.bodySmall),
                Text(score.band.localizedLabel(l10n), style: text.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  eligibility == null
                      ? ''
                      : eligibility.canApply
                      ? l10n.homeLoanCanApply(
                          formatRupiah(eligibility.ceilingIdr),
                        )
                      : eligibility.localizedMessage(l10n),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _LoanTeaser extends ConsumerWidget {
  const _LoanTeaser({required this.me});

  final Profile me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final now = ref.read(clockProvider)();
    final loan = data.activeLoanOf(me.id);
    if (loan == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final next = data
        .installmentsOf(loan.id)
        .where((i) => !i.isPaid)
        .firstOrNull;

    return SectionCard(
      onTap: () => context.push(Paths.loan(loan.id)),
      child: Row(
        children: [
          const FeatureBadge(
            icon: Icons.account_balance_wallet_rounded,
            tone: BadgeTone.solar,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.homePembiayaan} ${formatRupiah(loan.amountIdr)}',
                  style: text.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (next != null)
                  Text(
                    l10n.homeLoanInstallment(
                          next.seq,
                          formatRupiah(next.amountIdr),
                          formatShortDate(next.dueDate, l10n: l10n),
                        ) +
                        (next.isOverdue(now)
                            ? ' · ${l10n.homeLoanOverdue}'
                            : ' · ${l10n.homeLoanDue}'),
                    style: text.bodySmall?.copyWith(
                      color: next.isOverdue(now) ? AppColors.dangerText : null,
                    ),
                  )
                else
                  StatusPill(
                    label: loan.status.localizedLabel(l10n),
                    tone: loanTone(loan.status),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.impact});

  final ImpactMetrics impact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      tone: CardTone.mint,
      title: AppLocalizations.of(context).homeImpactTitle,
      leadingIcon: Icons.eco_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: AppLocalizations.of(context).homeImpactThisMonth,
                  value: formatRupiah(impact.thisMonthSavingIdr),
                  valueSize: 18,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: AppLocalizations.of(context).homeImpactSolarEnergy,
                  value: formatKwh(impact.solarKwh),
                  valueSize: 18,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: AppLocalizations.of(context).homeImpactCo2,
                  value: '${impact.co2AvoidedKg.round()} kg',
                  valueSize: 18,
                  qualifier: QualifierKind.estimasi,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context).homeImpactCo2Note,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
