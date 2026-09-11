import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../domain/credit_scoring_engine.dart';
import '../domain/credit_signals.dart';

/// IbuDaya's own score, computed from what the user recorded.
///
/// Two rules hold this screen together: the four categories shown *are* the
/// entire calculation, and when there is not enough history the screen says so
/// instead of inventing a number.
class CreditScoreScreen extends ConsumerWidget {
  const CreditScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(creditScoreOrNullProvider);
    final readiness = ref.watch(creditReadinessProvider);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Skor Energi Saya',
      onBack: () => context.pop(),
      bottomBar: score == null
          ? PrimaryButton(
              icon: Icons.add_rounded,
              label: 'Catat Tagihan',
              onPressed: () => context.push(AppRoute.billAddPath),
            )
          : PrimaryButton(
              icon: Icons.calculate_outlined,
              label: 'Hitung Rencana Pembiayaan',
              onPressed: () => context.push(AppRoute.financingPath),
            ),
      body: score == null
          ? _NotReady(readiness: readiness)
          : _Ready(score: score, text: text),
    );
  }
}

class _NotReady extends StatelessWidget {
  const _NotReady({required this.readiness});
  final CreditReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = (readiness.billsRecorded / kMinBillsForScore).clamp(
      0.0,
      1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: AppGradients.mint,
            borderRadius: AppRadius.lgBr,
            border: Border.all(color: AppColors.primaryContainerDim),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 44,
                color: AppColors.primaryDark,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Belum cukup data',
                style: text.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Skor baru bisa dihitung setelah ada minimal '
                '$kMinBillsForScore tagihan. Ini agar angkanya benar-benar '
                'mencerminkan kebiasaan Anda.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${readiness.billsRecorded} dari $kMinBillsForScore tagihan',
                style: text.labelMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        Text('Yang perlu Anda lengkapi', style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in readiness.missing) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(item, style: text.bodyMedium)),
                    ],
                  ),
                ),
              ],
              if (readiness.missing.isEmpty)
                Text('Semua sudah lengkap.', style: text.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const InfoBanner(
          tone: InfoTone.info,
          title: 'Kenapa tidak langsung ada angkanya?',
          message:
              'Skor dari satu bulan data tidak berarti apa-apa. IbuDaya lebih '
              'memilih mengatakan "belum tahu" daripada memberi angka yang '
              'menyesatkan.',
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.score, required this.text});
  final CreditScore score;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: AppGradients.mint,
            borderRadius: AppRadius.lgBr,
            border: Border.all(color: AppColors.primaryContainerDim),
          ),
          child: Column(
            children: [
              ScoreRing(
                score: score.score,
                size: 168,
                stroke: 16,
                caption: 'dari 100',
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                score.band.label,
                style: text.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        Text('Faktor Penentu Skor Anda', style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (final f in score.factors) ...[
          _FactorRow(factor: f),
          const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.md),
        _ImproveCard(factors: score.factors),
        const SizedBox(height: AppSpacing.md),

        const InfoBanner(
          tone: InfoTone.info,
          title: 'Ini skor internal IbuDaya',
          message:
              'Dihitung dari catatan Anda sendiri dengan aturan tetap yang '
              'ditampilkan di atas — keempat nilai itu dijumlahkan, tidak ada '
              'perhitungan tersembunyi. Ini bukan skor BI Checking/SLIK dan '
              'bukan penilaian dari bank mana pun.',
        ),
      ],
    );
  }
}

/// Static, actionable guidance keyed to the user's two weakest factors.
class _ImproveCard extends StatelessWidget {
  const _ImproveCard({required this.factors});
  final List<CreditFactor> factors;

  static String _tip(CreditCategory c) => switch (c) {
    CreditCategory.energyUsage =>
      'Catat tagihan tiap bulan dan jaga pemakaian tetap stabil — lonjakan '
          'besar menurunkan nilai ini.',
    CreditCategory.paymentHistory =>
      'Catat setoran iuran arisan Anda setiap bulan tepat waktu.',
    CreditCategory.businessActivity =>
      'Daftarkan alat usaha Anda dan catat setiap pemakaian di Solar Hub.',
    CreditCategory.communityParticipation =>
      'Aktif di grup arisan dan tawarkan sisa kuota energi Anda ke anggota '
          'lain.',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ranked = [...factors]
      ..sort((a, b) {
        final ra = a.maxPoints == 0 ? 0.0 : a.points / a.maxPoints;
        final rb = b.maxPoints == 0 ? 0.0 : b.points / b.maxPoints;
        return ra.compareTo(rb);
      });

    return SectionCard(
      tone: CardTone.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                size: 20,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Cara meningkatkan skor',
                style: text.titleSmall?.copyWith(
                  color: AppColors.primaryDarker,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final f in ranked.take(2))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _tip(f.category),
                      style: text.bodySmall?.copyWith(
                        color: AppColors.primaryDarker,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    final double ratio = factor.maxPoints == 0
        ? 0
        : factor.points / factor.maxPoints;

    final ({Color color, IconData icon}) dir = switch (factor.direction) {
      FactorDirection.positive => (
        color: AppColors.success,
        icon: Icons.trending_up_rounded,
      ),
      FactorDirection.negative => (
        color: AppColors.danger,
        icon: Icons.trending_down_rounded,
      ),
      FactorDirection.neutral => (
        color: AppColors.warning,
        icon: Icons.trending_flat_rounded,
      ),
    };

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(dir.icon, size: 18, color: dir.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(factor.label, style: text.titleSmall, maxLines: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${factor.points}/${factor.maxPoints}',
                style: text.labelMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(dir.color),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(factor.reason, style: text.bodySmall),
        ],
      ),
    );
  }
}
