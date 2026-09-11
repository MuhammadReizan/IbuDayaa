import 'package:flutter/material.dart';

import '../tokens.dart';

/// Inline callout in four semantic tones. See docs/DESIGN_SYSTEM.md §6.
enum InfoTone { success, warning, danger, info }

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.tone,
    required this.message,
    this.title,
    this.icon,
  });

  final InfoTone tone;
  final String message;
  final String? title;
  final IconData? icon;

  ({Color bg, Color fg, Color accent, IconData icon}) get _style =>
      switch (tone) {
        InfoTone.success => (
          bg: AppColors.successContainer,
          fg: AppColors.primaryDarker,
          accent: AppColors.primary,
          icon: Icons.verified_rounded,
        ),
        InfoTone.warning => (
          bg: AppColors.warningContainer,
          fg: AppColors.warningText,
          accent: AppColors.secondaryDark,
          icon: Icons.info_rounded,
        ),
        InfoTone.danger => (
          bg: AppColors.dangerContainer,
          fg: AppColors.dangerText,
          accent: AppColors.danger,
          icon: Icons.error_rounded,
        ),
        InfoTone.info => (
          bg: AppColors.infoContainer,
          fg: AppColors.infoText,
          accent: AppColors.info,
          icon: Icons.info_rounded,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: s.bg, borderRadius: AppRadius.smBr),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? s.icon, color: s.accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: text.titleSmall?.copyWith(color: s.fg)),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: text.bodySmall?.copyWith(color: s.fg, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
