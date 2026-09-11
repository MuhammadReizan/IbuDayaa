import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'qualifier_label.dart';

/// Label + hero number + optional delta / qualifier. The number is rendered in
/// the tabular numeric style so figures line up and read as primary info.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.qualifier,
    this.valueColor,
    this.delta,
    this.deltaPositive = true,
    this.onDark = false,
    this.valueSize = 22,
  });

  final String label;
  final String value;
  final QualifierKind? qualifier;
  final Color? valueColor;
  final String? delta;
  final bool deltaPositive;
  final bool onDark;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color labelColor = onDark
        ? AppColors.textOnDarkDim
        : AppColors.textSecondary;
    final Color numberColor =
        valueColor ?? (onDark ? Colors.white : AppColors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: labelColor,
            letterSpacing: 0.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.numeric(valueSize, color: numberColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (delta != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                deltaPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: onDark
                    ? Colors.white
                    : (deltaPositive ? AppColors.success : AppColors.danger),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  delta!,
                  style: text.labelSmall?.copyWith(
                    color: onDark ? AppColors.textOnDarkDim : labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (qualifier != null) ...[
          const SizedBox(height: AppSpacing.xs),
          QualifierLabel(qualifier!, onDark: onDark),
        ],
      ],
    );
  }
}
