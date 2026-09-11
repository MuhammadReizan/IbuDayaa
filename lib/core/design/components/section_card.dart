import 'package:flutter/material.dart';

import '../tokens.dart';

/// Surface tone for a [SectionCard].
enum CardTone { plain, mint, solar, forest }

/// The IbuDaya card: a soft, shadowed rounded surface with an optional header
/// (leading icon + title + trailing action). Depth comes from a green-tinted
/// shadow, not a hard border.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    this.leadingIcon,
    this.tone = CardTone.plain,
    this.padding = AppSpacing.card,
    this.onTap,
    required this.child,
  });

  final String? title;
  final Widget? trailing;
  final IconData? leadingIcon;
  final CardTone tone;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    final ({Color bg, Color fg, Color border, List<BoxShadow> shadow}) t =
        switch (tone) {
          CardTone.plain => (
            bg: AppColors.surface,
            fg: AppColors.textPrimary,
            border: AppColors.outlineSubtle,
            shadow: AppShadows.sm,
          ),
          CardTone.mint => (
            bg: AppColors.primaryContainer,
            fg: AppColors.primaryDarker,
            border: Colors.transparent,
            shadow: AppShadows.none,
          ),
          CardTone.solar => (
            bg: AppColors.secondaryContainer,
            fg: AppColors.warningText,
            border: Colors.transparent,
            shadow: AppShadows.none,
          ),
          CardTone.forest => (
            bg: AppColors.primaryDark,
            fg: AppColors.textOnDark,
            border: Colors.transparent,
            shadow: AppShadows.md,
          ),
        };

    final bool hasHeader =
        title != null || trailing != null || leadingIcon != null;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: AppIconSize.md, color: t.fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title ?? '',
                  style: text.titleMedium?.copyWith(color: t.fg),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        child,
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: t.border),
        boxShadow: t.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBr,
          child: Padding(padding: padding, child: content),
        ),
      ),
    );
  }
}
