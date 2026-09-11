import 'package:flutter/material.dart';

import 'tokens.dart';

/// Typography system (docs/DESIGN_SYSTEM.md §3).
///
/// Target face: **Plus Jakarta Sans** — a warm humanist sans that fits the
/// IbuDaya brand. The `.ttf` files are not bundled in this environment; drop
/// them into `assets/fonts/` and enable the `fonts:` block in `pubspec.yaml`
/// (see `assets/fonts/README.md`), then set [fontFamily] to `'PlusJakartaSans'`.
/// Until then the platform humanist sans is used and only the scale is fixed.
abstract final class AppTypography {
  static const String? fontFamily = null;

  /// Numbers (Rp 245.000 · 82 · 45% · 12 kWh) are primary information, not
  /// body text: heavy weight, tabular figures, tight tracking.
  static TextStyle numeric(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.textPrimary,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height ?? 1.0,
      letterSpacing: size >= 28 ? -1.0 : -0.4,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextTheme textTheme(ColorScheme scheme) {
    const Color primary = AppColors.textPrimary;
    const Color secondary = AppColors.textSecondary;

    TextStyle t(
      double size,
      FontWeight weight, {
      Color color = primary,
      double height = 1.4,
      double spacing = 0,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: color,
      );
    }

    return TextTheme(
      // Hero numbers / marketing headlines.
      displayLarge: t(44, FontWeight.w800, height: 1.02, spacing: -1.2),
      displayMedium: t(34, FontWeight.w800, height: 1.05, spacing: -0.8),
      displaySmall: t(26, FontWeight.w700, height: 1.1, spacing: -0.4),
      // Big amounts inside screens.
      headlineMedium: t(24, FontWeight.w700, height: 1.15, spacing: -0.4),
      // Screen titles.
      headlineSmall: t(21, FontWeight.w700, height: 1.2, spacing: -0.2),
      titleLarge: t(18, FontWeight.w700, height: 1.25),
      // Card titles / section headers.
      titleMedium: t(16, FontWeight.w600, height: 1.3),
      titleSmall: t(14, FontWeight.w600, height: 1.3),
      // Body.
      bodyLarge: t(15, FontWeight.w400, height: 1.5),
      bodyMedium: t(14, FontWeight.w400, color: secondary, height: 1.5),
      bodySmall: t(12.5, FontWeight.w400, color: secondary, height: 1.45),
      // Buttons / chips / captions.
      labelLarge: t(15, FontWeight.w600, height: 1.1, spacing: 0.1),
      labelMedium: t(12.5, FontWeight.w600, height: 1.15, spacing: 0.1),
      labelSmall: t(11, FontWeight.w600, color: secondary, spacing: 0.3),
    );
  }

  /// Legacy alias kept for existing call sites — the big credit-score / rupiah
  /// figure. Prefer [numeric] for new code.
  static TextStyle get displayScore => numeric(44, weight: FontWeight.w800);
}
