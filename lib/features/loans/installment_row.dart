import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';

/// Where one installment stands. The same states in the member's schedule, the
/// admin's schedule and the loan detail, so they always read alike.
enum InstallmentState {
  paid,
  paidLate,
  awaiting,
  rejected,
  overdue,
  upcoming;

  static InstallmentState of(LoanInstallment i, DateTime now) {
    if (i.isPaid) return i.paidOnTime ? paid : paidLate;
    if (i.isAwaitingConfirmation) return awaiting;
    if (i.isOverdue(now)) return overdue;
    if (i.wasRejected) return rejected;
    return upcoming;
  }

  String label(AppLocalizations l10n) => switch (this) {
    paid => l10n.instStatusPaid,
    paidLate => l10n.instStatusPaidLate,
    awaiting => l10n.instStatusAwaiting,
    rejected => l10n.instStatusRejected,
    overdue => l10n.instStatusOverdue,
    upcoming => l10n.instStatusUpcoming,
  };

  /// A short form for list rows, where the pill shares the line with an
  /// amount and a date. Upcoming installments need no pill at all.
  String? shortLabel(AppLocalizations l10n) => switch (this) {
    paid => l10n.instStatusPaid,
    paidLate => l10n.instStatusLate,
    awaiting => l10n.labelPending,
    rejected => l10n.instStatusRejected,
    overdue => l10n.adminInstOverdueLabel,
    upcoming => null,
  };

  PillTone get tone => switch (this) {
    paid => PillTone.success,
    paidLate => PillTone.warning,
    awaiting => PillTone.warning,
    rejected => PillTone.danger,
    overdue => PillTone.danger,
    upcoming => PillTone.neutral,
  };
}

/// One line of an installment schedule: its number, amount, the date that
/// matters for its state, and a status pill. [action] sits under the pill for
/// whoever can act on it.
class InstallmentRow extends StatelessWidget {
  const InstallmentRow({
    super.key,
    required this.installment,
    required this.now,
    this.action,
  });

  final LoanInstallment installment;
  final DateTime now;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final i = installment;
    final state = InstallmentState.of(i, now);
    final date = switch (state) {
      InstallmentState.paid || InstallmentState.paidLate => l10n.instPaidOn(
        formatShortDate(i.submittedAt ?? i.paidAt!, l10n: l10n),
      ),
      InstallmentState.awaiting => l10n.instSentOn(
        formatShortDate(i.submittedAt!, l10n: l10n),
      ),
      _ => l10n.instDueOn(
        '${formatShortDate(i.dueDate, l10n: l10n)} ${i.dueDate.year}',
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 32, child: Text('${i.seq}', style: text.titleSmall)),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatRupiah(i.amountIdr), style: text.titleSmall),
                Text(date, style: text.bodySmall),
                if (state == InstallmentState.rejected ||
                    (state == InstallmentState.overdue && i.wasRejected))
                  Text(
                    l10n.instRejectedReason(i.reviewNote ?? ''),
                    style: text.bodySmall?.copyWith(
                      color: AppColors.dangerText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (state.shortLabel(l10n) case final short?)
                  StatusPill(label: short, tone: state.tone),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
