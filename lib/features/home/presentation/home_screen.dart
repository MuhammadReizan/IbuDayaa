import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';
import '../../credit_score/application/credit_score_provider.dart';
import '../../credit_score/domain/credit_scoring_engine.dart';

/// SC-01 — Home (Beranda)
///
/// IMPLEMENTATION STATUS: IMPLEMENTED.
///
/// Sections (top → bottom, SingleChildScrollView):
///   1. Header: greeting + notification bell
///   2. Savings & Solar Share card  (DEMO_SIMULATION — docs/DATA_MODEL.md §3.3)
///   3. Quick-action grid  (2 × 2 Wrap, no nested scroll — correction #6)
///   4. Skor Kredit Energi tile  (live from DemoCreditScoringEngine)
///   5. Arisan Energi status card
///   6. Solar Hub status card  (DEMO_SIMULATION — docs/DATA_MODEL.md §3.7)
///
/// docs/SCREEN_INVENTORY.md SC-01.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final scenario = ref.watch(demoRepositoryProvider).current;
    final impact = scenario.impact;
    final arisan = scenario.arisanSummary;
    final solar = scenario.solarDaySummary;
    final creditScore = ref.watch(creditScoreProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Header ─────────────────────────────────────────────────
              _HomeHeader(greetingName: user.greetingName),
              const SizedBox(height: AppSpacing.lg),

              // ── 2. Savings + Impact card ──────────────────────────────────
              Padding(
                padding: AppSpacing.screenH,
                child: _SavingsCard(impact: impact),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 3. Quick-action grid ──────────────────────────────────────
              Padding(
                padding: AppSpacing.screenH,
                child: const _QuickActionGrid(),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 4. Skor Kredit Energi tile ────────────────────────────────
              Padding(
                padding: AppSpacing.screenH,
                child: _CreditScoreTile(score: creditScore),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 5. Arisan Energi status card ──────────────────────────────
              Padding(
                padding: AppSpacing.screenH,
                child: _ArisanCard(arisan: arisan),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 6. Solar Hub status card ──────────────────────────────────
              Padding(
                padding: AppSpacing.screenH,
                child: _SolarHubCard(solar: solar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Header
// ---------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.greetingName});

  final String greetingName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat datang,', style: text.bodyMedium),
                Text(
                  'Hi, $greetingName 👋',
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification bell — SC-20 (P1 — FUTURE_IMPLEMENTATION).
          Semantics(
            label: 'Notifikasi',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              iconSize: 24,
              tooltip: 'Notifikasi',
              onPressed: () {
                // FUTURE_IMPLEMENTATION: navigate to SC-20 when implemented.
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Savings + Solar Share card
// ---------------------------------------------------------------------------

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.impact});

  final DemoImpactMetrics impact;

  @override
  Widget build(BuildContext context) {
    // DEMO_SIMULATION — values from docs/DATA_MODEL.md §3.3.
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardBr,
      ),
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: AppRadius.pillBr,
            ),
            child: Text(
              'bulan ini • estimasi',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _GreenStat(
                  label: 'Tabungan Energi',
                  value: formatRupiah(impact.monthlySavingIdr),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _GreenStat(
                  label: 'Dari Solar Hub',
                  value: formatPercent(impact.solarSharePct),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreenStat extends StatelessWidget {
  const _GreenStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodySmall?.copyWith(color: Colors.white70)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.displayScore.copyWith(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Quick-action grid
// ---------------------------------------------------------------------------

/// 2 × 2 Wrap-based grid — avoids nested scrolling (correction #6).
class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        const actions = [
          _QuickActionDef(
            icon: Icons.receipt_long_outlined,
            label: 'Scan\nTagihan',
            route: AppRoute.scanTagihanPath,
          ),
          _QuickActionDef(
            icon: Icons.solar_power_outlined,
            label: 'Solar\nHub',
            route: AppRoute.solarPath,
          ),
          _QuickActionDef(
            icon: Icons.groups_outlined,
            label: 'Arisan\nEnergi',
            route: AppRoute.arisanPath,
          ),
          _QuickActionDef(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Simulasi\nPembiayaan',
            route: AppRoute.pembiayaanPath,
          ),
        ];

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: actions
              .map((a) {
                return SizedBox(
                  width: tileWidth,
                  child: _QuickActionTile(def: a),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

@immutable
class _QuickActionDef {
  const _QuickActionDef({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.def});

  final _QuickActionDef def;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: () => context.push(def.route),
        borderRadius: AppRadius.cardBr,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(def.icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(def.label, style: text.titleSmall, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Skor Kredit Energi tile
// ---------------------------------------------------------------------------

class _CreditScoreTile extends StatelessWidget {
  const _CreditScoreTile({required this.score});

  final CreditScore score;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Skor Kredit Energi',
      trailing: TextButton(
        onPressed: () => context.push(AppRoute.creditScorePath),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        ),
        child: const Text('Lihat Detail'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score badge + band + eligibility
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${score.score}',
                    style: AppTypography.displayScore.copyWith(
                      fontSize: 22,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(score.band.label, style: text.titleMedium),
                    Text('dari 100 poin', style: text.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      score.eligibilityLabel,
                      style: text.bodySmall?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          // Factor summary rows
          ...score.factors.map((f) => _FactorRow(factor: f)),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});

  final CreditFactor factor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final Color dirColor = switch (factor.direction) {
      FactorDirection.positive => AppColors.success,
      FactorDirection.negative => AppColors.danger,
      FactorDirection.neutral => AppColors.warning,
    };
    final IconData dirIcon = switch (factor.direction) {
      FactorDirection.positive => Icons.arrow_upward_rounded,
      FactorDirection.negative => Icons.arrow_downward_rounded,
      FactorDirection.neutral => Icons.remove_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(dirIcon, size: 14, color: dirColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              factor.label,
              style: text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${factor.points}/${factor.maxPoints}',
            style: text.labelMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Arisan Energi status card
// ---------------------------------------------------------------------------

class _ArisanCard extends StatelessWidget {
  const _ArisanCard({required this.arisan});

  final DemoArisanSummary arisan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bool isLunas = arisan.myContributionStatus.toLowerCase() == 'lunas';

    return SectionCard(
      title: 'Arisan Energi',
      trailing: TextButton(
        onPressed: () => context.push(AppRoute.arisanPath),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        ),
        child: const Text('Lihat'),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(arisan.groupName, style: text.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${arisan.memberCount} anggota • Giliran ke-${arisan.myTurnPosition}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isLunas
                  ? AppColors.successContainer
                  : AppColors.warningContainer,
              borderRadius: AppRadius.pillBr,
            ),
            child: Text(
              isLunas ? 'Lunas ✓' : arisan.myContributionStatus,
              style: text.labelMedium?.copyWith(
                color: isLunas
                    ? AppColors.primaryDark
                    : const Color(0xFF8A5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Solar Hub status card
// ---------------------------------------------------------------------------

class _SolarHubCard extends StatelessWidget {
  const _SolarHubCard({required this.solar});

  final DemoSolarDaySummary solar;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // DEMO_SIMULATION — capacityPct from solarDay (86), docs/DATA_MODEL.md §3.7.
    return SectionCard(
      title: 'Solar Hub',
      trailing: TextButton(
        onPressed: () => context.go(AppRoute.solarPath),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        ),
        child: const Text('Buka'),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 10,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(solar.statusLabel, style: text.bodyLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Kapasitas hari ini', style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            formatPercent(solar.capacityPct),
            style: AppTypography.displayScore.copyWith(
              fontSize: 28,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
