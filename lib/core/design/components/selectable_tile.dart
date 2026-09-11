import 'package:flutter/material.dart';

import '../tokens.dart';

/// A single-select option card (appliance, slot, purpose). Animates between
/// resting and selected: a mint fill, a primary ring and a check.
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

    final Color bg = disabled
        ? AppColors.surfaceAlt
        : (selected ? AppColors.primaryContainer : AppColors.surface);
    final Color border = disabled
        ? AppColors.outline
        : (selected ? AppColors.primary : AppColors.outline);

    return Semantics(
      selected: selected,
      button: true,
      enabled: !disabled,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: kAppCurve,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.smBr,
          border: Border.all(color: border, width: selected ? 2 : 1.2),
          boxShadow: selected && !disabled ? AppShadows.sm : AppShadows.none,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: AppRadius.smBr,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.surface
                            : AppColors.primaryContainer,
                        borderRadius: AppRadius.xsBr,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: disabled
                            ? AppColors.textTertiary
                            : AppColors.primaryDark,
                      ),
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
                          style: text.titleSmall?.copyWith(
                            color: disabled
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sublabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            sublabel!,
                            style: text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: disabled
                            ? AppColors.outline
                            : badgeColor.withValues(alpha: 0.14),
                        borderRadius: AppRadius.pillBr,
                      ),
                      child: Text(
                        badge!,
                        style: text.labelSmall?.copyWith(
                          color: disabled
                              ? AppColors.textSecondary
                              : badgeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    AnimatedScale(
                      duration: AppDurations.fast,
                      scale: selected ? 1 : 0,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
