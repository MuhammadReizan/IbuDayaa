import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import 'installment_row.dart';

/// A member's installment schedule. Paying works like an arisan payment: she
/// says she paid, an admin confirms it, and only then is it recorded as paid.
class InstallmentsScreen extends ConsumerStatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  ConsumerState<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends ConsumerState<InstallmentsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final loan = data.scheduleLoanOf(me.id);

    if (loan == null) {
      return AppScaffold(
        title: l10n.scaffoldInstallments,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.finance,
          title: l10n.instNoLoanTitle,
          message: l10n.instNoLoanMsg,
          action: SecondaryButton(
            label: l10n.scaffoldLoans,
            expand: false,
            onPressed: () => context.push(Paths.loans),
          ),
        ),
      );
    }

    final installments = data.installmentsOf(loan.id);
    final paid = installments
        .where((i) => i.isPaid)
        .fold<int>(0, (a, i) => a + i.amountIdr);
    final remaining = loan.totalRepaymentIdr - paid;
    final next = installments.where((i) => !i.isPaid).firstOrNull;
    final repaid = loan.status == LoanStatus.repaid;

    return AppScaffold(
      title: l10n.scaffoldInstallments,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.instRemaining,
                  style: text.labelMedium?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                Text(
                  formatRupiah(remaining),
                  style: AppTypography.numeric(30, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                AppProgressBar(
                  value: loan.totalRepaymentIdr == 0
                      ? 0
                      : paid / loan.totalRepaymentIdr,
                  color: Colors.white,
                  track: Colors.white24,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.instPaidOfTotal(
                    formatRupiah(paid),
                    formatRupiah(loan.totalRepaymentIdr),
                  ),
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: l10n.loanInstallments,
                        value: formatRupiah(loan.monthlyInstallmentIdr),
                        onDark: true,
                        valueSize: 16,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: l10n.loanApplyTenor,
                        value: l10n.monthsCount(loan.tenorMonths),
                        onDark: true,
                        valueSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (repaid)
            InfoBanner(
              tone: InfoTone.success,
              title: l10n.instRepaidTitle,
              message: l10n.instRepaidMsg,
            )
          else if (next != null)
            _NextPayment(
              installment: next,
              total: installments.length,
              now: now,
              busy: _busy,
              bankAccount: data.cooperative?.arisanBankAccount,
              onPay: () => _pay(next, l10n),
            ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.loanInstallments,
            child: Column(
              children: [
                for (int k = 0; k < installments.length; k++) ...[
                  if (k > 0) const Divider(height: 1),
                  InstallmentRow(installment: installments[k], now: now),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoBanner(tone: InfoTone.info, message: l10n.instNotice),
          const SizedBox(height: AppSpacing.md),
          TintedRow(
            icon: Icons.account_balance_wallet_rounded,
            tone: PillTone.solar,
            title: l10n.scaffoldLoanDetail,
            subtitle:
                '${formatRupiah(loan.amountIdr)} · ${loan.purpose.localizedLabel(l10n)}',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push(Paths.loan(loan.id)),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(LoanInstallment i, AppLocalizations l10n) async {
    final ok = await confirmDialog(
      context,
      title: l10n.instPayConfirmTitle,
      message: l10n.instPayConfirmMsg(i.seq, formatRupiah(i.amountIdr)),
      confirmLabel: l10n.actionSend,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await runAction(
      context,
      () => ref.read(actionsProvider).submitInstallmentPayment(i.id),
      success: l10n.instSentToast,
    );
    if (mounted) setState(() => _busy = false);
  }
}

/// The installment she pays next: what to do, then the state once she has.
class _NextPayment extends StatelessWidget {
  const _NextPayment({
    required this.installment,
    required this.total,
    required this.now,
    required this.busy,
    required this.bankAccount,
    required this.onPay,
  });

  final LoanInstallment installment;
  final int total;
  final DateTime now;
  final bool busy;
  final String? bankAccount;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final i = installment;
    final state = InstallmentState.of(i, now);
    final amount = formatRupiah(i.amountIdr);
    final bank = bankAccount?.trim() ?? '';

    return SectionCard(
      title: l10n.instNextTitle,
      trailing: StatusPill(label: state.label(l10n), tone: state.tone),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(amount, style: AppTypography.numeric(26)),
          Text(
            '${l10n.instNumber(i.seq, total)} · '
            '${l10n.instDueOn('${formatShortDate(i.dueDate, l10n: l10n)} ${i.dueDate.year}')}',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (i.isAwaitingConfirmation)
            Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l10n.instSentToast, style: text.bodyMedium),
                ),
              ],
            )
          else ...[
            if (i.wasRejected) ...[
              InfoBanner(
                tone: InfoTone.danger,
                message: l10n.instRejectedReason(i.reviewNote ?? ''),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              bank.isEmpty
                  ? l10n.instPayInstruction(amount)
                  : l10n.instPayInstructionWithBank(amount, bank),
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: l10n.instPayBtn,
              icon: Icons.payments_rounded,
              loading: busy,
              onPressed: onPay,
            ),
          ],
        ],
      ),
    );
  }
}
