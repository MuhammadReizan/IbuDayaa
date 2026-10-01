import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/quota_ledger.dart';
import '../../core/paths.dart';

/// The month's 35 kWh at a glance: what is left, what was used and booked, what
/// she used today, and how many days of the month remain. A session comes off
/// the moment it is booked (and is "used" once the admin approves the scan).
class QuotaCard extends StatelessWidget {
  const QuotaCard({
    super.key,
    required this.quota,
    required this.usedToday,
    required this.now,
  });

  final QuotaBalance quota;
  final double usedToday;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final left = quota.availableKwh;
    final pace = quotaPace(now: now, availableKwh: left);
    final low = quota.totalKwh > 0 && left / quota.totalKwh < 0.15;

    Widget stat(String label, double kwh) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          Text(formatKwh(kwh), style: text.titleSmall),
        ],
      ),
    );

    return SectionCard(
      onTap: () => context.go(Paths.memberSolar),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.quotaCardTitle(monthYearLabel(now, l10n: l10n)),
                  style: text.bodySmall,
                ),
              ),
              StatusPill(
                label: l10n.quotaDaysLeft(pace.daysLeft),
                tone: PillTone.info,
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.quotaCardRemaining(
                formatKwh(left < 0 ? 0 : left),
                formatKwh(quota.allocationKwh),
              ),
              style: AppTypography.numeric(24),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: quota.usedFraction,
            color: low ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              stat(l10n.quotaCardUsed, quota.usedKwh),
              stat(l10n.quotaCardReserved, quota.reservedKwh),
              stat(l10n.quotaCardToday, usedToday),
            ],
          ),
          if (quota.givenKwh > 0 || quota.receivedKwh > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.quotaCardTrades(
                formatKwh(quota.givenKwh),
                formatKwh(quota.receivedKwh),
              ),
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            left > 0
                ? l10n.quotaPaceLine(
                    formatKwh(pace.perDayKwh),
                    formatShortDate(pace.lastDay, l10n: l10n),
                  )
                : l10n.quotaEmptyLine,
            style: text.bodySmall?.copyWith(
              color: left > 0 ? null : AppColors.dangerText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.quotaCardNote, style: text.labelSmall),
        ],
      ),
    );
  }
}
