import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
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
import '../credit_score/application/credit_score_provider.dart';
import '../shared/labels.dart';

/// One application, for the member who made it or an admin reviewing it.
class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({
    super.key,
    required this.loanId,
    this.adminView = false,
  });

  final String loanId;
  final bool adminView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final loan = data.loan(loanId);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final now = ref.read(clockProvider)();

    if (loan == null) {
      return AppScaffold(
        title: l10n.scaffoldLoanDetail,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(title: l10n.loansEmpty),
      );
    }

    final isAdmin = adminView && me.isAdmin;
    final member = data.profile(loan.userId);
    final events = data.eventsOf(loan.id);
    final installments = data.installmentsOf(loan.id);
    final paid = installments
        .where((i) => i.isPaid)
        .fold<int>(0, (a, i) => a + i.amountIdr);
    final actions = ref.read(actionsProvider);

    final upcoming = switch (loan.status) {
      LoanStatus.submitted => [
        l10n.loanStatusInReview,
        l10n.loanStatusApproved,
        l10n.loanStatusDisbursed,
      ],
      LoanStatus.inReview => [
        l10n.loanStatusApproved,
        l10n.loanStatusDisbursed,
      ],
      LoanStatus.approved => [l10n.loanStatusDisbursed],
      LoanStatus.disbursed => [l10n.loanStatusRepaid],
      _ => const <String>[],
    };

    Future<void> act(Future<void> Function() run, String success) =>
        runAction(context, run, success: success);

    final bottom = <Widget>[
      if (isAdmin && loan.status == LoanStatus.submitted) ...[
        _reject(context, actions, loan, l10n),
        PrimaryButton(
          label: l10n.isEn ? 'Start review' : 'Mulai review',
          onPressed: () =>
              act(() => actions.startLoanReview(loan.id), 'Status: in review.'),
        ),
      ],
      if (isAdmin && loan.status == LoanStatus.inReview) ...[
        _reject(context, actions, loan, l10n),
        PrimaryButton(
          label: l10n.isEn ? 'Approve' : 'Setujui',
          onPressed: () async {
            final note = await promptText(
              context,
              title: l10n.isEn ? 'Approve application?' : 'Setujui pengajuan?',
              label: l10n.labelNote,
              confirmLabel: l10n.isEn ? 'Approve' : 'Setujui',
              required: false,
            );
            if (note == null || !context.mounted) return;
            await act(
              () => actions.approveLoan(loan.id, note: note),
              'Loan approved.',
            );
          },
        ),
      ],
      if (isAdmin && loan.status == LoanStatus.approved)
        PrimaryButton(
          label: l10n.isEn ? 'Record disbursement' : 'Catat dana dicairkan',
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: l10n.isEn ? 'Record disbursement' : 'Catat dana dicairkan',
              message: formatRupiah(loan.amountIdr),
              confirmLabel: l10n.isEn
                  ? 'Yes, disbursed'
                  : 'Ya, sudah dicairkan',
            );
            if (!ok || !context.mounted) return;
            await act(
              () => actions.disburseLoan(loan.id),
              'Disbursement recorded.',
            );
          },
        ),
      if (!isAdmin &&
          loan.userId == me.id &&
          loan.status == LoanStatus.submitted)
        SecondaryButton(
          label: l10n.loanStatusCancelled,
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: l10n.loanStatusCancelled,
              message: l10n.loanStatusCancelled,
              confirmLabel: l10n.actionConfirm,
              destructive: true,
            );
            if (!ok || !context.mounted) return;
            await act(() => actions.cancelLoan(loan.id), 'Loan cancelled.');
          },
        ),
    ];

    final currentScore = isAdmin
        ? data.scoreOf(loan.userId, now, ref.read(creditScoringEngineProvider))
        : null;
    final support = data.supportThreadOf(loan.userId);

    return AppScaffold(
      title: isAdmin
          ? (l10n.isEn ? 'Review Application' : 'Review Pengajuan')
          : l10n.scaffoldLoanDetail,
      onBack: () => context.pop(),
      bottomBar: bottom.isEmpty
          ? null
          : Row(
              children: [
                for (int i = 0; i < bottom.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: bottom[i]),
                ],
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatRupiah(loan.amountIdr),
                        style: AppTypography.numeric(28),
                      ),
                    ),
                    StatusPill(
                      label: loan.status.localizedLabel(l10n),
                      tone: loanTone(loan.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${loan.purpose.localizedLabel(l10n)} · ${formatLongDate(loan.createdAt, l10n: l10n)}',
                  style: text.bodySmall,
                ),
                const Divider(height: AppSpacing.xl),
                KeyValueRow(
                  label: l10n.loanApplyTenor,
                  value: '${loan.tenorMonths} bulan',
                ),
                KeyValueRow(
                  label: l10n.loanApplyTitle,
                  value: formatPercent(loan.flatMonthlyRatePct, decimals: 1),
                ),
                KeyValueRow(
                  label: l10n.loanInstallments,
                  value: formatRupiah(loan.monthlyInstallmentIdr),
                  emphasize: true,
                ),
                KeyValueRow(
                  label: l10n.labelTotal,
                  value: formatRupiah(loan.totalRepaymentIdr),
                ),
                if (loan.note != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${l10n.labelNote}: "${loan.note}"',
                    style: text.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          if (loan.decisionNote != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              tone: loan.status == LoanStatus.rejected
                  ? InfoTone.danger
                  : InfoTone.success,
              title: loan.status == LoanStatus.rejected
                  ? l10n.labelRejected
                  : l10n.labelApproved,
              message: loan.decisionNote!,
            ),
          ],
          if (isAdmin && member != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              child: Row(
                children: [
                  MemberAvatar(name: member.fullName, size: 44),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.fullName, style: text.titleSmall),
                        Text(
                          '${member.businessName} · ${member.displayPhone}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.navMessages,
                    onPressed: support == null
                        ? null
                        : () => context.push(Paths.thread(support.id)),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.navProfile,
                    onPressed: () => context.push(Paths.adminMember(member.id)),
                    icon: const Icon(Icons.person_search_outlined),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title:
                '${l10n.homeSkorKredit}: ${loan.scoreSnapshot} (${loan.scoreBand})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in loan.scoreFactors) ...[
                  Row(
                    children: [
                      Expanded(child: Text(f.label, style: text.bodyMedium)),
                      Text(
                        '${f.points}/${f.maxPoints}',
                        style: text.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppProgressBar(
                    value: f.maxPoints == 0 ? 0 : f.points / f.maxPoints,
                    height: 6,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (currentScore != null &&
                    currentScore.score != loan.scoreSnapshot)
                  Text(
                    '${l10n.homeSkorKredit}: ${currentScore.score} (${currentScore.band.localizedLabel(l10n)}).',
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
          if (installments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: l10n.isEn ? 'Installments' : 'Cicilan',
              trailing: Text(
                '${formatRupiah(paid)} / ${formatRupiah(loan.totalRepaymentIdr)}',
                style: text.labelMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppProgressBar(
                    value: loan.totalRepaymentIdr == 0
                        ? 0
                        : paid / loan.totalRepaymentIdr,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final i in installments)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text('${i.seq}', style: text.titleSmall),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatRupiah(i.amountIdr),
                                  style: text.titleSmall,
                                ),
                                Text(
                                  i.isPaid
                                      ? '${l10n.labelCompleted} ${formatShortDate(i.paidAt!, l10n: l10n)}'
                                      : '${l10n.labelDate} ${formatShortDate(i.dueDate, l10n: l10n)} ${i.dueDate.year}',
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (i.isPaid)
                            StatusPill(
                              label: i.paidOnTime
                                  ? l10n.labelCompleted
                                  : l10n.labelPending,
                              tone: i.paidOnTime
                                  ? PillTone.success
                                  : PillTone.warning,
                            )
                          else if (isAdmin &&
                              loan.status == LoanStatus.disbursed)
                            TextButton(
                              onPressed: () async {
                                final ok = await confirmDialog(
                                  context,
                                  title: '${l10n.loanInstallments} #${i.seq}',
                                  message: formatRupiah(i.amountIdr),
                                  confirmLabel: l10n.actionConfirm,
                                );
                                if (!ok || !context.mounted) return;
                                await act(
                                  () => actions.markInstallmentPaid(i.id),
                                  'Installment recorded.',
                                );
                              },
                              child: Text(l10n.actionConfirm),
                            )
                          else
                            StatusPill(
                              label: i.isOverdue(now)
                                  ? l10n.homeLoanOverdue
                                  : l10n.labelPending,
                              tone: i.isOverdue(now)
                                  ? PillTone.danger
                                  : PillTone.neutral,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.arisanHistory,
            child: Column(
              children: [
                for (int i = 0; i < events.length; i++)
                  TimelineItem(
                    title: localizedLoanEventLabel(events[i].type, l10n),
                    subtitle: [
                      if (events[i].actorId != null)
                        data.nameOf(events[i].actorId),
                      if (events[i].note != null) events[i].note!,
                    ].join(' · '),
                    time: formatDateTime(events[i].createdAt, l10n: l10n),
                    tone:
                        events[i].type == 'rejected' ||
                            events[i].type == 'cancelled'
                        ? PillTone.danger
                        : PillTone.success,
                    isLast: i == events.length - 1 && upcoming.isEmpty,
                  ),
                for (int i = 0; i < upcoming.length; i++)
                  TimelineItem(
                    title: upcoming[i],
                    done: false,
                    isLast: i == upcoming.length - 1,
                  ),
              ],
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            const LoanDecisionNotice(),
          ],
        ],
      ),
    );
  }

  Widget _reject(
    BuildContext context,
    AppActions actions,
    LoanApplication loan,
    AppLocalizations l10n,
  ) => SecondaryButton(
    label: l10n.labelRejected,
    onPressed: () async {
      final reason = await promptText(
        context,
        title: l10n.labelRejected,
        label: l10n.labelNote,
        confirmLabel: l10n.labelRejected,
        destructive: true,
      );
      if (reason == null || !context.mounted) return;
      await runAction(
        context,
        () => actions.rejectLoan(loan.id, reason),
        success: 'Loan rejected.',
      );
    },
  );
}
