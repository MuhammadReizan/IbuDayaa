import 'package:flutter/material.dart';

import '../tokens.dart';

/// Inline callout in four semantic tones. See docs/DESIGN_SYSTEM.md §6.
enum InfoTone { success, warning, danger, info }

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.tone,
    required this.message,
    this.icon,
  });

  final InfoTone tone;
  final String message;
  final IconData? icon;

  ({Color bg, Color fg, IconData icon}) get _style => switch (tone) {
    InfoTone.success => (
      bg: AppColors.successContainer,
      fg: AppColors.primaryDark,
      icon: Icons.check_circle_outline,
    ),
    InfoTone.warning => (
      bg: AppColors.warningContainer,
      fg: const Color(0xFF8A5A00),
      icon: Icons.warning_amber_rounded,
    ),
    InfoTone.danger => (
      bg: AppColors.dangerContainer,
      fg: const Color(0xFF9E2A1E),
      icon: Icons.error_outline,
    ),
    InfoTone.info => (
      bg: AppColors.infoContainer,
      fg: const Color(0xFF1B4DA6),
      icon: Icons.info_outline,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: s.bg, borderRadius: AppRadius.cardBr),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? s.icon, color: s.fg, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: s.fg),
            ),
          ),
        ],
      ),
    );
  }
}
