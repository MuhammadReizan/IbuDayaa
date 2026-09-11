/// Centralised design tokens — the single source of truth for the IbuDaya
/// visual language (see docs/DESIGN_SYSTEM.md).
///
/// Screens and components read from these tokens only; never inline a hex,
/// radius, spacing or duration in feature code.
library;

import 'package:flutter/material.dart';

/// Colour tokens. Warm, community-first green identity:
/// growth green + soft mint + warm cream + solar accent.
abstract final class AppColors {
  // ── Brand greens ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF18864B); // growth green
  static const Color primaryDark = Color(0xFF0E5D35); // deep forest
  static const Color primaryDarker = Color(0xFF0A4527);
  static const Color primaryContainer = Color(0xFFEAF6EF); // soft mint
  static const Color primaryContainerDim = Color(0xFFDCEEE3);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Solar accent ──────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFF4B63E); // solar yellow
  static const Color secondaryDark = Color(0xFFD9931B);
  static const Color secondaryContainer = Color(0xFFFDF3DE);
  static const Color onSecondary = Color(0xFF3D2E05);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surfaceAlt = Color(
    0xFFF4F1E9,
  ); // input fill, subtle panels
  static const Color background = Color(0xFFFAF9F5); // warm cream screen bg
  static const Color backgroundDeep = Color(0xFFF1EEE4);
  static const Color outline = Color(0xFFE7E3D6); // hairline borders / dividers
  static const Color outlineSubtle = Color(0xFFF0ECE0);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF17211B);
  static const Color textSecondary = Color(0xFF5B655F);
  static const Color textTertiary = Color(0xFF8B948D);
  static const Color textOnDark = Color(0xFFF3F7F3);
  static const Color textOnDarkDim = Color(0xFFB9D4C4);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF18864B);
  static const Color successContainer = Color(0xFFEAF6EF);
  static const Color warning = Color(0xFFE39A1F);
  static const Color warningText = Color(0xFF8A5A00);
  static const Color warningContainer = Color(0xFFFCF1DC);
  static const Color danger = Color(0xFFD8412F);
  static const Color dangerText = Color(0xFFA5291B);
  static const Color dangerContainer = Color(0xFFFBEBE8);
  static const Color info = Color(0xFF2F6FE0);
  static const Color infoText = Color(0xFF1B4DA6);
  static const Color infoContainer = Color(0xFFEAF1FC);

  // ── Fixed accents ────────────────────────────────────────────────────────
  /// Warm ink used on the solar-yellow surfaces.
  static const Color onSolar = Color(0xFF3D2E05);

  /// Near-black used for the bill-scanner viewfinder.
  static const Color scannerDark = Color(0xFF12211A);

  /// Bright leaf-green used only for success-screen confetti.
  static const Color accentLeaf = Color(0xFF5FD08D);
}

/// Reusable brand gradients as ready-to-use [LinearGradient]s.
abstract final class AppGradients {
  static const LinearGradient brand = LinearGradient(
    colors: [Color(0xFF1FA25A), Color(0xFF0E5D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandSoft = LinearGradient(
    colors: [Color(0xFF23A661), Color(0xFF127A44)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient solar = LinearGradient(
    colors: [Color(0xFFF9CB63), Color(0xFFEBA21F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mint = LinearGradient(
    colors: [Color(0xFFF4FBF6), Color(0xFFE3F1E9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark forest wash used on the splash and success screens.
  static const LinearGradient forest = LinearGradient(
    colors: [Color(0xFF0E5D35), Color(0xFF0A4527)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Spacing scale (4 dp base grid).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 44;

  static const double lgPlus = 18;
  static const double gutter = 20;

  /// Standard screen horizontal padding.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: 20);

  /// Standard card padding.
  static const EdgeInsets card = EdgeInsets.all(18);

  /// Padding for the larger gradient "hero" surfaces.
  static const EdgeInsets hero = EdgeInsets.all(20);
}

/// Corner radii.
abstract final class AppRadius {
  static const double xs = 10;
  static const double sm = 14;
  static const double card = 20;
  static const double lg = 26;
  static const double xl = 32;
  static const double button = 16;
  static const double pill = 999;

  static const BorderRadius xsBr = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBr = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius cardBr = BorderRadius.all(Radius.circular(card));
  static const BorderRadius lgBr = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBr = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius buttonBr = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius pillBr = BorderRadius.all(Radius.circular(pill));
}

/// Soft, green-tinted elevation. Cards use shadow (not a hard border) for depth.
abstract final class AppShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Resting card.
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D14331F), blurRadius: 10, offset: Offset(0, 3)),
  ];

  /// Raised card / hero surface.
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x14153A24), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Floating element (sheets, pinned CTA bar, FAB).
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F0E5D35), blurRadius: 36, offset: Offset(0, 18)),
  ];

  /// Coloured glow under primary buttons.
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x33127A44), blurRadius: 18, offset: Offset(0, 8)),
  ];
}

/// Legacy elevation aliases (kept for any Material widgets that take a double).
abstract final class AppElevation {
  static const double card = 0;
  static const double sheet = 3;
}

/// Motion tokens. Includes the deliberate simulated latency used on
/// scan/analyse screens — kept here so it is tunable in one place.
abstract final class AppDurations {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration splashMin = Duration(milliseconds: 550);
  static const Duration simulatedScan = Duration(milliseconds: 1400);
}

/// Standard easing curve for entrance / selection transitions.
const Curve kAppCurve = Curves.easeOutCubic;

/// Icon size scale: inline / default / tile / hero.
abstract final class AppIconSize {
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;
  static const double xl = 40;
}

/// Minimum interactive target (accessibility).
const double kMinTapTarget = 48;
