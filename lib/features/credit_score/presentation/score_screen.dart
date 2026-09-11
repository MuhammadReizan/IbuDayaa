import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/brand.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/format.dart';
import '../../../core/logic/credit_signals.dart';
import '../../../core/logic/loan_math.dart';
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
    final engine = ref.read(creditScoringEngineProvider);
    final score = data.scoreOf(me.id, now, engine);
    final readiness = data.readinessOf(me.id, now);
    final coop = data.cooperative;

    if (score == null) {
      return AppScaffold(
        title: 'Skor Kredit Energi',
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
              'Skor belum bisa dihitung',
              style: text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Skor dihitung dari catatan Anda sendiri. Dengan data kurang dari '
              '$kMinMonthsForScore bulan, angkanya belum bisa dipercaya.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionCard(
              title:
                  'Catatan listrik ${readiness.monthsRecorded}/$kMinMonthsForScore bulan',
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
                  ? 'Catatan listrik cukup'
                  : 'Scan tagihan ${readiness.monthsStillNeeded} bulan lagi',
              subtitle: 'Bisa juga dari tagihan bulan-bulan sebelumnya.',
              onTap: () => context.push(Paths.scan),
            ),
            const SizedBox(height: AppSpacing.sm),
            TintedRow(
              icon: Icons.groups_rounded,
              tone: readiness.inArisan ? PillTone.success : PillTone.warning,
              title: readiness.inArisan
                  ? 'Sudah ikut arisan'
                  : 'Ikut grup arisan koperasi',
              onTap: () => context.push(Paths.arisan),
            ),
            const SizedBox(height: AppSpacing.sm),
            TintedRow(
              icon: Icons.kitchen_rounded,
              tone: readiness.appliancesDeclared > 0
                  ? PillTone.success
                  : PillTone.warning,
              title: readiness.appliancesDeclared > 0
                  ? '${readiness.appliancesDeclared} alat terdaftar'
                  : 'Daftarkan alat usaha',
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
      title: 'Skor Kredit Energi',
      onBack: () => context.pop(),
      bottomBar: eligibility == null
          ? null
          : PrimaryButton(
              label: eligibility.canApply
                  ? 'Ajukan Pembiayaan'
                  : 'Lihat Pembiayaan',
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
                SemiGauge(value: score.score, caption: 'dari 100'),
                const SizedBox(height: AppSpacing.sm),
                StatusPill(
                  label: score.band.label,
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
                      ? 'Skor pertama Anda bulan ini.'
                      : delta == 0
                      ? 'Sama dengan ${monthYearLabel(previous!.month)}.'
                      : '${delta > 0 ? 'Naik' : 'Turun'} ${delta.abs()} poin dari '
                            '${monthYearLabel(previous!.month)}.',
                  style: text.bodyMedium?.copyWith(
                    color: delta == null || delta == 0
                        ? null
                        : delta > 0
                        ? AppColors.primaryDark
                        : AppColors.dangerText,
                  ),
                ),
              ],
            ),
          ),
          if (eligibility != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              tone: eligibility.canApply ? InfoTone.success : InfoTone.warning,
              title: eligibility.canApply
                  ? 'Skor Anda mendukung pengajuan hingga ${formatRupiah(eligibility.ceilingIdr)}'
                  : null,
              message: eligibility.canApply
                  ? 'Keputusan tetap di tangan admin koperasi.'
                  : eligibility.message,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Yang membentuk skor Anda'),
          for (final f in score.factors) ...[
            _FactorCard(
              factor: f,
              previousPoints: previous?.factorPoints[f.category.name],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Tentang skor ini',
            leadingIcon: Icons.info_outline_rounded,
            child: Text(
              'Skor Kredit Energi adalah hitungan aturan tetap dari catatan Anda '
              'di IbuDaya: kestabilan pemakaian listrik (35 poin), ketepatan bayar '
              'iuran dan cicilan (30), aktivitas usaha (20), dan keaktifan di '
              'komunitas (15). Ini bukan skor bank atau BI Checking. Koperasi '
              'memakainya sebagai bahan pertimbangan'
              '${coop == null ? '' : ', dengan skor minimum ${coop.loanMinScore} untuk mengajukan'}.',
              style: text.bodySmall,
            ),
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
