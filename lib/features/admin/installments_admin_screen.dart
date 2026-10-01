import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../loans/installment_row.dart';

/// Every running loan's installments for the admin: payments members sent that
/// wait for confirmation (confirmed or rejected like arisan dues), what is
/// overdue, and each loan's progress.
class InstallmentsAdminScreen extends ConsumerWidget {
  const InstallmentsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(actionsProvider);

    final awaiting = data.installmentsAwaiting;
    final open = data.openInstallments;
    final overdue = open
        .where((i) => !i.isAwaitingConfirmation && i.isOverdue(now))
        .toList();
    final running = data.runningLoans;
    final outstanding = open.fold<int>(0, (a, i) => a + i.amountIdr);
    final received = data.installments
        .where((i) => i.isPaid)
        .fold<int>(0, (a, i) => a + i.amountIdr);

    return AppScaffold(
      title: l10n.scaffoldAdminInstallments,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatTile(
                  label: l10n.adminInstOutstanding,
                  value: formatRupiah(outstanding),
                  valueSize: 24,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: l10n.adminInstCollected,
                        value: formatRupiah(received),
                        valueSize: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatTile(
                        label: l10n.adminInstOverdueLabel,
                        value: '${overdue.length}',
                        valueSize: 16,
                        valueColor: overdue.isEmpty
                            ? null
                            : AppColors.dangerText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: '${l10n.labelPending} (${awaiting.length})'),
          if (awaiting.isEmpty)
            SectionCard(
              child: Row(
                children: [
                  const BrandArt(motif: BrandArtMotif.success, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.adminInstAwaitingEmpty,
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            InfoBanner(tone: InfoTone.info, message: l10n.adminInstNotice),
            const SizedBox(height: AppSpacing.md),
            for (final i in awaiting) ...[
              _AwaitingCard(
                installment: i,
                loan: data.loan(i.loanId)!,
                name: data.nameOf(data.loan(i.loanId)!.userId),
                total: data.installmentsOf(i.loanId).length,
                actions: actions,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.adminInstOverdueLabel),
            for (final i in overdue) ...[
              TintedRow(
                icon: Icons.warning_amber_rounded,
                tone: PillTone.danger,
                title:
                    '${data.nameOf(data.loan(i.loanId)?.userId)} · ${formatRupiah(i.amountIdr)}',
                subtitle:
                    '${l10n.instNumber(i.seq, data.installmentsOf(i.loanId).length)} · '
                    '${l10n.instDueOn('${formatShortDate(i.dueDate, l10n: l10n)} ${i.dueDate.year}')}',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: () => context.push(Paths.adminLoan(i.loanId)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.adminInstLoansTitle),
          if (running.isEmpty)
            Text(l10n.adminInstLoansEmpty, style: text.bodyMedium)
          else
            for (final l in running) ...[
              _LoanProgressRow(
                loan: l,
                name: data.nameOf(l.userId),
                installments: data.installmentsOf(l.id),
                now: now,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _AwaitingCard extends StatelessWidget {
  const _AwaitingCard({
    required this.installment,
    required this.loan,
    required this.name,
    required this.total,
    required this.actions,
  });

  final LoanInstallment installment;
  final LoanApplication loan;
  final String name;
  final int total;
  final AppActions actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final i = installment;
    final amount = formatRupiah(i.amountIdr);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MemberAvatar(name: name, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: text.titleSmall),
                    Text(l10n.instNumber(i.seq, total), style: text.bodySmall),
                  ],
                ),
              ),
              Text(amount, style: text.titleMedium),
            ],
          ),
          if (i.submitNote != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('"${i.submitNote}"', style: text.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatDateTime(i.submittedAt!, l10n: l10n),
            style: text.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.adminPaymentsReject,
                  onPressed: () async {
                    final reason = await promptText(
                      context,
                      title: l10n.adminInstRejectTitle,
                      label: l10n.labelNote,
                      confirmLabel: l10n.adminPaymentsReject,
                      destructive: true,
                    );
                    if (reason == null || !context.mounted) return;
                    await runAction(
                      context,
                      () => actions.rejectInstallmentPayment(i.id, reason),
                      success: l10n.instRejectedToast,
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: l10n.adminPaymentsApprove,
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: l10n.adminPaymentsApprove,
                      message: l10n.adminInstConfirmMsg(name, i.seq, amount),
                      confirmLabel: l10n.actionConfirm,
                    );
                    if (!ok || !context.mounted) return;
                    await runAction(
                      context,
                      () => actions.markInstallmentPaid(i.id),
                      success: l10n.loanToastInstallmentRecorded,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoanProgressRow extends StatelessWidget {
  const _LoanProgressRow({
    required this.loan,
    required this.name,
    required this.installments,
    required this.now,
  });

  final LoanApplication loan;
  final String name;
  final List<LoanInstallment> installments;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final paidCount = installments.where((i) => i.isPaid).length;
    final paid = installments
        .where((i) => i.isPaid)
        .fold<int>(0, (a, i) => a + i.amountIdr);
    final next = installments.where((i) => !i.isPaid).firstOrNull;
    final state = next == null ? null : InstallmentState.of(next, now);

    return SectionCard(
      onTap: () => context.push(Paths.adminLoan(loan.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MemberAvatar(name: name, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: text.titleSmall),
                    Text(
                      l10n.adminInstLoanRowSub(
                        paidCount,
                        installments.length,
                        formatRupiah(loan.totalRepaymentIdr - paid),
                      ),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (state != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  flex: 2,
                  child: StatusPill(
                    label: state.shortLabel(l10n) ?? state.label(l10n),
                    tone: state.tone,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: loan.totalRepaymentIdr == 0
                ? 0
                : paid / loan.totalRepaymentIdr,
            height: 6,
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.instNumber(next.seq, installments.length)} · '
              '${formatRupiah(next.amountIdr)} · '
              '${l10n.instDueOn('${formatShortDate(next.dueDate, l10n: l10n)} ${next.dueDate.year}')}',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
