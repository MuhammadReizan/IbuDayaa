import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// How the IbuDaya mark/logo is coloured for its background.
enum BrandVariant {
  /// Full colour (green leaf + solar sun) — for light surfaces.
  color,

  /// Solid white — for photos / green / forest surfaces.
  onDark,

  /// Single-colour green — for dense or monochrome contexts.
  mono,
}

/// The IbuDaya symbol: a rising sun cradled by a growing leaf — energy,
/// community and growth. Recognisable down to ~18 px.
class IbuDayaMark extends StatelessWidget {
  const IbuDayaMark({
    super.key,
    this.size = 32,
    this.variant = BrandVariant.color,
  });

  final double size;
  final BrandVariant variant;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(variant)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.variant);

  final BrandVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Paint p = Paint()..isAntiAlias = true;

    final Color leafColor = switch (variant) {
      BrandVariant.color => AppColors.primary,
      BrandVariant.onDark => Colors.white,
      BrandVariant.mono => AppColors.primaryDark,
    };
    final Color sunColor = switch (variant) {
      BrandVariant.color => AppColors.secondary,
      BrandVariant.onDark => Colors.white,
      BrandVariant.mono => AppColors.primaryDark,
    };

    // ── Leaf: two mirrored arcs meeting at top and bottom ──────────────────
    final Path leaf = Path()
      ..moveTo(s * 0.5, s * 0.06)
      ..cubicTo(s * 0.98, s * 0.30, s * 0.92, s * 0.86, s * 0.5, s * 0.98)
      ..cubicTo(s * 0.08, s * 0.86, s * 0.02, s * 0.30, s * 0.5, s * 0.06)
      ..close();
    p.color = leafColor;
    canvas.drawPath(leaf, p);

    // Central vein, drawn as a soft stroke in the mint tint.
    final Path vein = Path()
      ..moveTo(s * 0.5, s * 0.20)
      ..quadraticBezierTo(s * 0.52, s * 0.55, s * 0.5, s * 0.88)
      ..quadraticBezierTo(s * 0.48, s * 0.55, s * 0.5, s * 0.20)
      ..close();
    canvas.drawPath(
      vein,
      Paint()
        ..isAntiAlias = true
        ..strokeWidth = s * 0.05
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = variant == BrandVariant.color
            ? AppColors.primaryContainer
            : (variant == BrandVariant.onDark
                  ? AppColors.primary
                  : AppColors.primaryContainer),
    );

    // ── Sun: a disc sitting in the leaf's upper bowl + short rays ──────────
    final Offset sunC = Offset(s * 0.5, s * 0.42);
    final double sunR = s * 0.17;
    p.color = sunColor;
    canvas.drawCircle(sunC, sunR, p);

    final Paint ray = Paint()
      ..isAntiAlias = true
      ..color = sunColor
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;
    const int rays = 5;
    for (int i = 0; i < rays; i++) {
      final double a = (-3.14159 / 2) + (i - (rays - 1) / 2) * 0.62;
      final Offset from = sunC + Offset.fromDirection(a, sunR * 1.45);
      final Offset to = sunC + Offset.fromDirection(a, sunR * 1.95);
      canvas.drawLine(from, to, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.variant != variant;
}

/// The IbuDaya wordmark: [IbuDayaMark] + "IbuDaya", with an optional tagline.
class IbuDayaLogo extends StatelessWidget {
  const IbuDayaLogo({
    super.key,
    this.height = 30,
    this.variant = BrandVariant.color,
    this.tagline,
  });

  final double height;
  final BrandVariant variant;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final Color wordColor = variant == BrandVariant.onDark
        ? Colors.white
        : AppColors.textPrimary;
    final Color accent = variant == BrandVariant.onDark
        ? Colors.white
        : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IbuDayaMark(size: height, variant: variant),
        const SizedBox(width: AppSpacing.sm),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: null,
                  fontSize: height * 0.62,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.0,
                  color: wordColor,
                ),
                children: [
                  const TextSpan(text: 'Ibu'),
                  TextSpan(
                    text: 'Daya',
                    style: TextStyle(color: accent),
                  ),
                ],
              ),
            ),
            if (tagline != null) ...[
              const SizedBox(height: 2),
              Text(
                tagline!,
                style: TextStyle(
                  fontSize: height * 0.30,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  color: variant == BrandVariant.onDark
                      ? AppColors.textOnDarkDim
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
