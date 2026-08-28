import 'package:flutter/material.dart';

import 'tokens.dart';

/// Typography system. See docs/DESIGN_SYSTEM.md §3.
///
/// PROTOTYPE_DECISION: the target face is a friendly humanist sans
/// (Poppins / Plus Jakarta Sans in the screenshots). No font file is bundled
/// yet and `google_fonts` is intentionally avoided (it fetches over the network
/// on first use, which would break offline Demo Mode). Until a `.ttf` is added,
/// `fontFamily` stays null (platform default) and only the scale is fixed here.
abstract final class AppTypography {
  static const String? fontFamily = null;

  static TextTheme textTheme(ColorScheme scheme) {
    final Color primary = scheme.onSurface;
    final Color secondary = AppColors.textSecondary;

    TextStyle base(
      double size,
      FontWeight weight, {
      Color? color,
      double height = 1.35,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? primary,
      );
    }

    return TextTheme(
      // Screen titles.
      headlineSmall: base(22, FontWeight.w700, height: 1.25),
      titleLarge: base(18, FontWeight.w700, height: 1.3),
      // Card titles / section headers.
      titleMedium: base(16, FontWeight.w600, height: 1.3),
      titleSmall: base(14, FontWeight.w600, height: 1.3),
      // Body.
      bodyLarge: base(15, FontWeight.w400),
      bodyMedium: base(14, FontWeight.w400, color: secondary),
      bodySmall: base(12, FontWeight.w400, color: secondary),
      // Chips / qualifiers / captions.
      labelLarge: base(15, FontWeight.w600, height: 1.2),
      labelMedium: base(12, FontWeight.w500, height: 1.2),
      labelSmall: base(11, FontWeight.w500, color: secondary, height: 1.2),
    );
  }

  /// One-off oversized style for hero numbers (credit score, headline rupiah).
  static const TextStyle displayScore = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.05,
    color: AppColors.textPrimary,
  );
}
