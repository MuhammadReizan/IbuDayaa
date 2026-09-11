import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/brand/brand.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/insights.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';
import '../../credit_score/domain/credit_scoring_engine.dart';
import '../../credit_score/domain/credit_signals.dart';

/// The dashboard. Every figure here traces back to something the user entered;
/// when nothing has been entered yet, the screen asks for it rather than
/// showing zeros dressed up as insight.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final profile = ref.watch(profileProvider);
    final impact = ref.watch(impactProvider);
    final insight = ref.watch(energyInsightProvider);
    final score = ref.watch(creditScoreOrNullProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HomeHeader(),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Hi, ${profile?.greetingName ?? 'Ibu'} 👋',
                style: text.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                profile?.businessName.isNotEmpty == true
                    ? profile!.businessName
                    : 'Selamat datang kembali.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!data.hasAnyRecords)
                const _GetStartedCard()
              else ...[
                _BillHero(insight: insight),
                const SizedBox(height: AppSpacing.md),
                if (impact.solarKwh > 0) ...[
                  _SolarShareCard(impact: impact),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),

              Text('Akses Cepat', style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              const _QuickActionGrid(),
              const SizedBox(height: AppSpacing.xl),

              const _ObservationsSection(),

              if (score != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _ScoreCard(score: score),
              ] else if (data.bills.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                const _ScoreProgressCard(),
              ],

              const SizedBox(height: AppSpacing.md),
              const _ArisanCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final name = ref.watch(profileProvider)?.name ?? '';

    return Row(
      children: [
        const IbuDayaLogo(height: 26),
        const Spacer(),
        Semantics(
          button: true,
          label: unread > 0 ? 'Pemberitahuan, $unread baru' : 'Pemberitahuan',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.sm,
            ),
            child: Stack(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: 'Pemberitahuan',
                  onPressed: () => context.push(AppRoute.notificationsPath),
                ),
                if (unread > 0)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Profil',
          child: GestureDetector(
            onTap: () => context.go(AppRoute.profilePath),
            child: MemberAvatar(name: name.isEmpty ? 'Ibu' : name, size: 40),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _GetStartedCard extends StatelessWidget {
  const _GetStartedCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: AppRadius.lgBr,
        boxShadow: AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgBr,
        child: Padding(
          padding: AppSpacing.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mulai dari tagihan pertama',
                style: text.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Catat tagihan listrik bulan ini. Dari situ IbuDaya bisa '
                'memecah biaya per alat, menghitung penghematan, dan menyusun '
                'skor energi Anda.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textOnDarkDim,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Catat Tagihan Pertama'),
                  onPressed: () => context.push(AppRoute.billAddPath),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillHero extends StatelessWidget {
  const _BillHero({required this.insight});
  final EnergyInsight? insight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final i = insight;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: AppRadius.lgBr,
        boxShadow: AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgBr,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => context.push(
              i == null ? AppRoute.billAddPath : AppRoute.energyAnalysisPath,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: Opacity(
                    opacity: 0.9,
                    child: BrandArt(
                      motif: BrandArtMotif.finance,
                      size: 116,
                      onDark: true,
                    ),
                  ),
                ),
                Padding(
                  padding: AppSpacing.hero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: AppRadius.pillBr,
                        ),
                        child: Text(
                          i == null
                              ? 'BELUM ADA TAGIHAN'
                              : formatMonthYear(
                                  i.latest.periodMonth,
                                ).toUpperCase(),
                          style: text.labelSmall?.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        i == null ? '—' : formatRupiah(i.latest.totalIdr),
                        style: AppTypography.numeric(32, color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text(
                            i == null
                                ? 'Catat tagihan Anda'
                                : formatKwh(i.latest.kwh),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.textOnDarkDim,
                            ),
                          ),
                          if (i?.changePct != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              i!.changePct! >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 16,
                              color: i.changePct! >= 0
                                  ? AppColors.secondary
                                  : AppColors.accentLeaf,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${i.changePct!.abs().round()}%',
                              style: text.bodySmall?.copyWith(
                                color: AppColors.textOnDarkDim,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SolarShareCard extends StatelessWidget {
  const _SolarShareCard({required this.impact});
  final ImpactMetrics impact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      onTap: () => context.go(AppRoute.solarPath),
      child: Row(
        children: [
          ScoreRing(
            score: impact.solarSharePct,
            size: 68,
            stroke: 8,
            caption: '%',
            progressColors: const [AppColors.secondary, AppColors.primary],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Energi dari Solar Hub', style: text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${formatKwh(impact.solarKwh)} tercatat · senilai '
                  '${formatRupiah(impact.monthlySavingIdr)} bulan ini',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  static const _actions = [
    (
      icon: Icons.receipt_long_outlined,
      label: 'Catat\nTagihan',
      route: AppRoute.billsPath,
      tone: BadgeTone.mint,
    ),
    (
      icon: Icons.electrical_services_outlined,
      label: 'Alat\nUsaha',
      route: AppRoute.appliancesPath,
      tone: BadgeTone.solar,
    ),
    (
      icon: Icons.solar_power_outlined,
      label: 'Solar\nHub',
      route: AppRoute.solarPath,
      tone: BadgeTone.sky,
    ),
    (
      icon: Icons.calculate_outlined,
      label: 'Hitung\nCicilan',
      route: AppRoute.financingPath,
      tone: BadgeTone.mint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final double w = (c.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final a in _actions)
              SizedBox(
                width: w,
                child: _QuickActionTile(
                  icon: a.icon,
                  label: a.label,
                  tone: a.tone,
                  onTap: () => a.route == AppRoute.solarPath
                      ? context.go(a.route)
                      : context.push(a.route),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final BadgeTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBr,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeatureBadge(icon: icon, tone: tone),
                const SizedBox(height: AppSpacing.sm),
                Text(label, style: text.titleSmall, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ObservationsSection extends ConsumerWidget {
  const _ObservationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observations = ref.watch(observationsProvider);
    final text = Theme.of(context).textTheme;
    if (observations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Yang Perlu Diperhatikan', style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < observations.take(3).length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _ObservationRow(observation: observations[i]),
        ],
      ],
    );
  }
}

class _ObservationRow extends StatelessWidget {
  const _ObservationRow({required this.observation});
  final PowerObservation observation;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final ({IconData icon, BadgeTone tone}) s = switch (observation.severity) {
      'danger' => (icon: Icons.trending_up_rounded, tone: BadgeTone.alert),
      'warning' => (icon: Icons.bolt_rounded, tone: BadgeTone.solar),
      'schedule' => (icon: Icons.schedule_rounded, tone: BadgeTone.mint),
      _ => (icon: Icons.info_outline_rounded, tone: BadgeTone.sky),
    };

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: observation.route == null
          ? null
          : () => context.push(observation.route!),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeatureBadge(icon: s.icon, tone: s.tone, size: 38),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  observation.title,
                  style: text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(observation.body, style: text.bodySmall),
              ],
            ),
          ),
          if (observation.route != null) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final CreditScore score;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Skor Energi Saya',
      trailing: TextButton(
        onPressed: () => context.push(AppRoute.creditScorePath),
        child: const Text('Lihat Detail'),
      ),
      child: Row(
        children: [
          ScoreRing(
            score: score.score,
            size: 92,
            stroke: 10,
            caption: 'dari 100',
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.band.label, style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Dihitung dari catatan Anda sendiri.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreProgressCard extends ConsumerWidget {
  const _ScoreProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(creditReadinessProvider);
    final text = Theme.of(context).textTheme;
    final progress = (readiness.billsRecorded / kMinBillsForScore).clamp(
      0.0,
      1.0,
    );

    return SectionCard(
      leadingIcon: Icons.hourglass_top_rounded,
      title: 'Skor Energi Saya',
      trailing: TextButton(
        onPressed: () => context.push(AppRoute.creditScorePath),
        child: const Text('Lihat'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Butuh ${readiness.billsStillNeeded} tagihan lagi sebelum skor '
            'bisa dihitung.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArisanCard extends ConsumerWidget {
  const _ArisanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(arisanProvider);
    final text = Theme.of(context).textTheme;

    if (group == null) {
      return SectionCard(
        leadingIcon: Icons.groups_2_outlined,
        title: 'Arisan Energi',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Belum ada grup. Buat arisan untuk mencatat iuran dan giliran '
              'bersama anggota lain.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Buat Grup Arisan',
              onPressed: () => context.push(AppRoute.arisanCreatePath),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      leadingIcon: Icons.groups_2_outlined,
      title: 'Arisan Energi',
      trailing: TextButton(
        onPressed: () => context.go(AppRoute.arisanPath),
        child: const Text('Buka'),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${group.members.length} anggota · '
                  '${formatRupiah(group.contributionIdr)}/bulan',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
