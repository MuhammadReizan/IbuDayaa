import 'package:flutter/material.dart';

import '../tokens.dart';

/// An option card used in single-select flows (e.g. appliances, slots).
/// See docs/DESIGN_SYSTEM.md §6.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.label,
    this.sublabel,
    this.icon,
    this.selected = false,
    this.disabled = false,
    this.badge,
    this.badgeColor = AppColors.warning,
    required this.onTap,
  });

  final String label;
  final String? sublabel;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      button: true,
      enabled: !disabled,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryContainer
                : (disabled
                      ? AppColors.outline.withValues(alpha: 0.3)
                      : AppColors.surface),
            borderRadius: AppRadius.cardBr,
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (disabled
                        ? AppColors.outline.withValues(alpha: 0.5)
                        : AppColors.outline),
              width: selected ? 2 : 1,
            ),
          ),
          padding: AppSpacing.card,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: disabled
                      ? AppColors.textSecondary
                      : AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: disabled
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sublabel!,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: disabled
                        ? AppColors.outline
                        : badgeColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.pillBr,
                    border: Border.all(
                      color: disabled
                          ? AppColors.outline
                          : badgeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: text.labelSmall?.copyWith(
                      color: disabled ? AppColors.textSecondary : badgeColor,
                    ),
                  ),
                ),
              ],
              if (selected && badge == null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
