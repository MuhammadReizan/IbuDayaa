import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/logic/loan_math.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/repositories/local/local_loan_repository.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';
import '../shared/labels.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final coop = data.cooperative;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final loans = data.loansOf(me.id);
    final score = data.scoreOf(
      me.id,
      now,
      ref.read(creditScoringEngineProvider),
    );
    final eligibility = coop == null
        ? null
        : loanEligibility(
            coop: coop,
            score: score,
            hasActiveLoan: data.activeLoanOf(me.id) != null,
          );
    final canApply =
        eligibility != null &&
        eligibility.canApply &&
        eligibility.ceilingIdr >= LocalLoanRepository.minimumAmountIdr;

    return AppScaffold(
      title: 'Pembiayaan',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Ajukan Pembiayaan',
        icon: Icons.add_rounded,
        onPressed: canApply ? () => context.push(Paths.loanApply) : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            tone: canApply ? CardTone.mint : CardTone.plain,
            onTap: () => context.push(Paths.score),
            child: Row(
              children: [
                if (score != null)
                  ScoreRing(score: score.score, size: 64, stroke: 7)
                else
                  const FeatureBadge(
                    icon: Icons.speed_rounded,
                    tone: BadgeTone.sky,
                    size: 56,
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canApply
                            ? 'Plafon Anda ${formatRupiah(eligibility.ceilingIdr)}'
                            : 'Belum bisa mengajukan',
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        canApply
                            ? 'Dari skor ${score!.score} (${score.band.label}).'
                            : eligibility?.message ?? '',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          if (coop != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Kebijakan ${coop.name}: maksimal ${formatRupiah(coop.loanMaxAmountIdr)}, '
              'jasa ${formatPercent(coop.loanFlatMonthlyRatePct, decimals: 1)} per bulan (flat), '
              'tenor ${coop.loanTenors.join('/')} bulan, skor minimum ${coop.loanMinScore}.',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Pengajuan saya'),
          if (loans.isEmpty)
            Text('Belum ada pengajuan.', style: text.bodyMedium)
          else
            for (final l in loans) ...[
              _LoanCard(loan: l),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.lg),
          const LoanDecisionNotice(),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});

  final LoanApplication loan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                Text(formatRupiah(loan.amountIdr), style: text.titleMedium),
                Text(
                  '${loan.purpose.label} · ${loan.tenorMonths} bulan · ${formatShortDate(loan.createdAt)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          StatusPill(label: loan.status.label, tone: loanTone(loan.status)),
        ],
      ),
    );
  }
}
