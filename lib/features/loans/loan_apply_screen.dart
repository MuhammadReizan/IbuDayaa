import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/loan_math.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/repositories/local/local_loan_repository.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';

/// Ajukan Pembiayaan: the member picks amount, tenor and purpose within the
/// cooperative's policy; an admin decides.
class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  static const _min = LocalLoanRepository.minimumAmountIdr;

  int? _amount;
  int? _tenor;
  LoanPurpose _purpose = LoanPurpose.rawMaterial;
  final _note = TextEditingController();
  bool _agree = false;
  bool _busy = false;
  LoanApplication? _done;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final coop = data.cooperative;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final done = _done;
    if (done != null) {
      return SuccessPanel(
        title: l10n.loanApplySuccess,
        message: l10n.loanApplySuccess,
        primaryLabel: l10n.scaffoldLoanDetail,
        onPrimary: () => context.pushReplacement(Paths.loan(done.id)),
        secondaryLabel: l10n.navHome,
        onSecondary: () => context.go(Paths.memberHome),
        child: SectionCard(
          child: Column(
            children: [
              KeyValueRow(
                label: l10n.loanAmount,
                value: formatRupiah(done.amountIdr),
                emphasize: true,
              ),
              KeyValueRow(
                label: l10n.loanApplyTenor,
                value: '${done.tenorMonths} bulan',
              ),
              KeyValueRow(
                label: l10n.loanInstallments,
                value: formatRupiah(done.monthlyInstallmentIdr),
              ),
              const Divider(height: AppSpacing.xl),
              TimelineItem(title: l10n.loanStatusSubmitted, done: true),
              TimelineItem(
                title: l10n.loanStatusInReview,
                done: false,
                tone: PillTone.warning,
              ),
              TimelineItem(
                title: l10n.loanStatusDisbursed,
                done: false,
                isLast: true,
              ),
            ],
          ),
        ),
      );
    }

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

    if (coop == null ||
        eligibility == null ||
        !eligibility.canApply ||
        eligibility.ceilingIdr < _min) {
      return AppScaffold(
        title: l10n.scaffoldLoanApply,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.finance,
          title: l10n.loanCannotApply,
          message: eligibility == null
              ? l10n.labelError
              : eligibility.canApply
              ? '${l10n.loanCannotApply} ${formatRupiah(_min)}.'
              : eligibility.localizedMessage(l10n),
          action: SecondaryButton(
            label: l10n.homeSkorKredit,
            expand: false,
            onPressed: () => context.pushReplacement(Paths.score),
          ),
        ),
      );
    }

    final ceiling = eligibility.ceilingIdr;
    final amount = (_amount ?? (ceiling / 2 / 100000).round() * 100000).clamp(
      _min,
      ceiling,
    );
    final tenor = _tenor ?? coop.loanTenors.first;
    final quote = quoteLoan(
      principalIdr: amount,
      tenorMonths: tenor,
      flatMonthlyRatePct: coop.loanFlatMonthlyRatePct,
    );
    final steps = ((ceiling - _min) / 100000).round();

    return AppScaffold(
      title: l10n.scaffoldLoanApply,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.actionSubmit,
        loading: _busy,
        onPressed: _agree ? () => _submit(amount, tenor, quote, l10n) : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(
            tone: InfoTone.success,
            title: l10n.loanApplyConfirm,
            message:
                'Skor ${score!.score} (${score.band.localizedLabel(l10n)}) · ${l10n.loanCeilingTitle(formatRupiah(ceiling))} ${coop.name}.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.loanApplyAmount, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(formatRupiah(amount), style: AppTypography.numeric(32)),
          ),
          if (steps > 0)
            Slider(
              value: amount.toDouble(),
              min: _min.toDouble(),
              max: ceiling.toDouble(),
              divisions: steps,
              label: formatRupiah(amount),
              onChanged: (v) =>
                  setState(() => _amount = (v / 100000).round() * 100000),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatRupiah(_min), style: text.labelSmall),
              Text(formatRupiah(ceiling), style: text.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.loanApplyTenor, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in coop.loanTenors)
                ChoiceChip(
                  label: Text(l10n.unitMonths(t)),
                  selected: tenor == t,
                  onSelected: (_) => setState(() => _tenor = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.loanApplyPurpose, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final p in LoanPurpose.values) ...[
            SelectableTile(
              label: p.localizedLabel(l10n),
              icon: switch (p) {
                LoanPurpose.rawMaterial => Icons.inventory_2_rounded,
                LoanPurpose.equipment => Icons.precision_manufacturing_rounded,
                LoanPurpose.renovation => Icons.storefront_rounded,
                LoanPurpose.other => Icons.more_horiz_rounded,
              },
              selected: _purpose == p,
              onTap: () => setState(() => _purpose = p),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: '${l10n.labelNote} (${l10n.labelOptional})',
            controller: _note,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            tone: CardTone.mint,
            title: l10n.loanAmount,
            child: Column(
              children: [
                KeyValueRow(
                  label: l10n.loanAmount,
                  value: formatRupiah(quote.principalIdr),
                ),
                KeyValueRow(
                  label:
                      'Jasa ${formatPercent(coop.loanFlatMonthlyRatePct, decimals: 1)}/bulan × $tenor bulan',
                  value: formatRupiah(quote.totalInterestIdr),
                ),
                KeyValueRow(
                  label: l10n.labelTotal,
                  value: formatRupiah(quote.totalRepaymentIdr),
                ),
                const Divider(height: AppSpacing.lg),
                KeyValueRow(
                  label: l10n.loanInstallments,
                  value: formatRupiah(quote.monthlyInstallmentIdr),
                  emphasize: true,
                  valueColor: AppColors.primaryDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.loanCoopPolicy(
              coop.name,
              formatRupiah(coop.loanMaxAmountIdr),
              formatPercent(coop.loanFlatMonthlyRatePct, decimals: 1),
              coop.loanTenors.join('/'),
              coop.loanMinScore,
            ),
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LoanDecisionNotice(),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            value: _agree,
            onChanged: (v) => setState(() => _agree = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              '${l10n.actionConfirm}: ${formatRupiah(quote.monthlyInstallmentIdr)} / ${l10n.loanApplyTenor}',
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    int amount,
    int tenor,
    LoanQuote quote,
    AppLocalizations l10n,
  ) async {
    final ok = await confirmDialog(
      context,
      title: l10n.loanApplyConfirm,
      message:
          '${formatRupiah(amount)} ($tenor bulan, ${formatRupiah(quote.monthlyInstallmentIdr)}/bulan)',
      confirmLabel: l10n.actionSubmit,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    LoanApplication? result;
    await runAction(
      context,
      () async => result = await ref
          .read(actionsProvider)
          .submitLoan(
            amountIdr: amount,
            purpose: _purpose,
            tenorMonths: tenor,
            note: _note.text,
          ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = result;
    });
  }
}
