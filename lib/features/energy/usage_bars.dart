import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/energy_insights.dart';

/// Monthly kWh bars, oldest on the left, newest highlighted.
class UsageBars extends StatelessWidget {
  const UsageBars({super.key, required this.months, this.height = 150});

  /// Newest first, as [monthlyUsage] returns.
  final List<MonthlyUsage> months;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = months.take(6).toList().reversed.toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final peak = shown.map((m) => m.kwh).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < shown.length; i++)
            Expanded(
              child: Semantics(
                label:
                    '${monthYearLabel(shown[i].month, l10n: AppLocalizations.of(context))}: ${formatKwh(shown[i].kwh)}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatKwhValue(shown[i].kwh),
                      style: text.labelSmall?.copyWith(
                        color: i == shown.length - 1
                            ? AppColors.primaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: peak <= 0 ? 0 : shown[i].kwh / peak,
                        ),
                        duration: AppDurations.slow,
                        curve: kAppCurve,
                        builder: (_, v, _) => FractionallySizedBox(
                          heightFactor: v.clamp(0.04, 1.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              gradient: i == shown.length - 1
                                  ? AppGradients.brand
                                  : null,
                              color: i == shown.length - 1
                                  ? null
                                  : AppColors.primaryContainerDim,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.xs),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      monthAbbr(
                        shown[i].month,
                        l10n: AppLocalizations.of(context),
                      ),
                      style: text.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
