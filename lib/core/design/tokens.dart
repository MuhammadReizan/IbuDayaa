/// Centralised design tokens.
///
/// PROTOTYPE_DECISION: every value here is inferred from the prototype
/// screenshots (there is no authoritative Figma — see docs/DESIGN_SYSTEM.md).
/// Screens must read from these tokens only, never inline a hex / size, so the
/// real brand values can be dropped in later without touching screen code.
library;

import 'package:flutter/material.dart';

/// Colour tokens. See docs/DESIGN_SYSTEM.md §2.
abstract final class AppColors {
  // Brand greens.
  static const Color primary = Color(0xFF1E8E4E);
  static const Color primaryDark = Color(0xFF14663A);
  static const Color primaryContainer = Color(0xFFE7F4EC);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Accent.
  static const Color secondary = Color(0xFFF4A623);
  static const Color onSecondary = Color(0xFF1B1F1D);

  // Surfaces.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7F5);
  static const Color outline = Color(0xFFE2E6E2);

  // Text.
  static const Color textPrimary = Color(0xFF1B1F1D);
  static const Color textSecondary = Color(0xFF5E655F);

  // Semantic.
  static const Color success = Color(0xFF1E8E4E);
  static const Color successContainer = Color(0xFFE7F4EC);
  static const Color warning = Color(0xFFF4A623);
  static const Color warningContainer = Color(0xFFFDF1DD);
  static const Color danger = Color(0xFFD8412F);
  static const Color dangerContainer = Color(0xFFFBEBE9);
  static const Color info = Color(0xFF2F6FE0);
  static const Color infoContainer = Color(0xFFE9F0FC);
}

/// Spacing scale (4dp base grid). See docs/DESIGN_SYSTEM.md §4.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard screen horizontal padding.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);

  /// Standard card padding.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// Corner radii. See docs/DESIGN_SYSTEM.md §5.
abstract final class AppRadius {
  static const double card = 16;
  static const double button = 12;
  static const double pill = 999;

  static const BorderRadius cardBr = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonBr = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius pillBr = BorderRadius.all(Radius.circular(pill));
}

/// Elevation / shadow tokens. Cards are flat with a hairline border
/// (docs/DESIGN_SYSTEM.md §5); real shadows are reserved for sheets/dialogs.
abstract final class AppElevation {
  static const double card = 0;
  static const double sheet = 2;

  static const List<BoxShadow> none = <BoxShadow>[];
  static const List<BoxShadow> sheetShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

/// Motion tokens. Includes the deliberate simulated latency used on
/// scan/analyse screens (docs/ARCHITECTURE.md §6) — kept here so it is tunable
/// in one place.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration splashMin = Duration(milliseconds: 450);
  static const Duration simulatedScan = Duration(milliseconds: 1200);
}

/// Minimum interactive target (docs/DESIGN_SYSTEM.md §4 / accessibility).
const double kMinTapTarget = 48;
