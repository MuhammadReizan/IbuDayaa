import 'package:flutter/material.dart';

import '../tokens.dart';

/// Colour treatment for a [FeatureBadge].
enum BadgeTone { mint, solar, sky, forest, alert }

/// A rounded-square icon container — the consistent way IbuDaya presents a
/// feature or category icon (quick actions, list rows, section headers).
class FeatureBadge extends StatelessWidget {
  const FeatureBadge({
    super.key,
    required this.icon,
    this.tone = BadgeTone.mint,
    this.size = 44,
  });

  final IconData icon;
  final BadgeTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg}) c = switch (tone) {
      BadgeTone.mint => (
        bg: AppColors.primaryContainer,
        fg: AppColors.primaryDark,
      ),
      BadgeTone.solar => (
        bg: AppColors.secondaryContainer,
        fg: AppColors.secondaryDark,
      ),
      BadgeTone.sky => (bg: AppColors.infoContainer, fg: AppColors.info),
      BadgeTone.forest => (bg: AppColors.primaryDark, fg: Colors.white),
      BadgeTone.alert => (bg: AppColors.dangerContainer, fg: AppColors.danger),
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(icon, size: size * 0.5, color: c.fg),
    );
  }
}
