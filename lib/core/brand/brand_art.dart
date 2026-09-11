import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Editorial spot-illustration motifs, painted with simple geometry so they
/// stay crisp at any size and ship with zero image assets.
enum BrandArtMotif {
  community,
  solar,
  scan,
  inbox,
  success,
  arisan,
  finance,
  roof,
}

/// A branded spot illustration: a soft rounded backdrop with a bold, friendly
/// motif. Used on empty / success states and feature intros.
class BrandArt extends StatelessWidget {
  const BrandArt({
    super.key,
    required this.motif,
    this.size = 140,
    this.onDark = false,
  });

  final BrandArtMotif motif;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BrandArtPainter(motif, onDark)),
    );
  }
}

class _BrandArtPainter extends CustomPainter {
  _BrandArtPainter(this.motif, this.onDark);

  final BrandArtMotif motif;
  final bool onDark;

  Paint _fill(Color c) => Paint()
    ..isAntiAlias = true
    ..color = c;

  Paint _stroke(Color c, double w) => Paint()
    ..isAntiAlias = true
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Rect box = Offset.zero & size;
    final RRect backdrop = RRect.fromRectAndRadius(
      box.deflate(s * 0.02),
      Radius.circular(s * 0.34),
    );

    canvas.drawRRect(
      backdrop,
      Paint()
        ..shader = LinearGradient(
          colors: onDark
              ? const [Color(0xFF15794A), Color(0xFF0C4E2E)]
              : const [Color(0xFFF1FAF4), Color(0xFFE1F0E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(box),
    );

    final Paint dot = _fill(
      (onDark ? Colors.white : AppColors.primary).withValues(
        alpha: onDark ? 0.16 : 0.10,
      ),
    );
    canvas.drawCircle(Offset(s * 0.16, s * 0.20), s * 0.030, dot);
    canvas.drawCircle(Offset(s * 0.85, s * 0.30), s * 0.022, dot);
    canvas.drawCircle(Offset(s * 0.80, s * 0.82), s * 0.034, dot);

    canvas.save();
    canvas.clipRRect(backdrop);
    switch (motif) {
      case BrandArtMotif.community:
      case BrandArtMotif.arisan:
        _community(canvas, s);
      case BrandArtMotif.solar:
      case BrandArtMotif.roof:
        _solar(canvas, s);
      case BrandArtMotif.scan:
        _scan(canvas, s);
      case BrandArtMotif.inbox:
        _inbox(canvas, s);
      case BrandArtMotif.success:
        _success(canvas, s);
      case BrandArtMotif.finance:
        _finance(canvas, s);
    }
    canvas.restore();
  }

  void _sun(Canvas c, double s, Offset center, double r) {
    c.drawCircle(center, r, _fill(AppColors.secondary));
    final Paint ray = _stroke(AppColors.secondary, s * 0.028);
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4;
      c.drawLine(
        center + Offset.fromDirection(a, r * 1.4),
        center + Offset.fromDirection(a, r * 1.85),
        ray,
      );
    }
  }

  void _house(Canvas c, double s) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.30, s * 0.52, s * 0.40, s * 0.30),
        Radius.circular(s * 0.04),
      ),
      _fill(Colors.white),
    );
    final Path roof = Path()
      ..moveTo(s * 0.24, s * 0.54)
      ..lineTo(s * 0.50, s * 0.34)
      ..lineTo(s * 0.76, s * 0.54)
      ..close();
    c.drawPath(roof, _fill(AppColors.primary));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.45, s * 0.64, s * 0.10, s * 0.18),
        Radius.circular(s * 0.02),
      ),
      _fill(AppColors.primary),
    );
  }

  void _solar(Canvas c, double s) {
    _sun(c, s, Offset(s * 0.74, s * 0.24), s * 0.10);
    _house(c, s);
    final Paint panel = _fill(AppColors.primaryDark);
    final Path p = Path()
      ..moveTo(s * 0.40, s * 0.46)
      ..lineTo(s * 0.60, s * 0.46)
      ..lineTo(s * 0.56, s * 0.40)
      ..lineTo(s * 0.44, s * 0.40)
      ..close();
    c.drawPath(p, panel);
    c.drawLine(
      Offset(s * 0.50, s * 0.40),
      Offset(s * 0.50, s * 0.46),
      _stroke(AppColors.primaryContainer, s * 0.012),
    );
  }

  void _community(Canvas c, double s) {
    _sun(c, s, Offset(s * 0.5, s * 0.22), s * 0.09);
    const List<double> xs = [0.30, 0.5, 0.70];
    const List<Color> cols = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.primaryDark,
    ];
    for (int i = 0; i < 3; i++) {
      final double x = s * xs[i];
      final double y = s * (i == 1 ? 0.50 : 0.56);
      c.drawCircle(Offset(x, y), s * 0.075, _fill(Colors.white));
      c.drawCircle(Offset(x, y), s * 0.050, _fill(cols[i]));
      final Path shoulders = Path()
        ..moveTo(x - s * 0.11, s * 0.90)
        ..quadraticBezierTo(x, y + s * 0.10, x + s * 0.11, s * 0.90)
        ..close();
      c.drawPath(shoulders, _fill(Colors.white));
      c.drawPath(shoulders, _stroke(cols[i], s * 0.02));
    }
  }

  void _scan(Canvas c, double s) {
    final RRect receipt = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.26, s * 0.22, s * 0.34, s * 0.52),
      Radius.circular(s * 0.03),
    );
    c.drawRRect(receipt, _fill(Colors.white));
    final Paint line = _stroke(AppColors.primaryContainerDim, s * 0.022);
    for (int i = 0; i < 4; i++) {
      final double y = s * (0.32 + i * 0.09);
      c.drawLine(
        Offset(s * 0.31, y),
        Offset(s * (i.isEven ? 0.55 : 0.48), y),
        line,
      );
    }
    c.drawLine(
      Offset(s * 0.28, s * 0.48),
      Offset(s * 0.58, s * 0.48),
      _stroke(AppColors.secondary, s * 0.03),
    );
    c.drawCircle(Offset(s * 0.62, s * 0.62), s * 0.15, _fill(Colors.white));
    c.drawCircle(
      Offset(s * 0.62, s * 0.62),
      s * 0.15,
      _stroke(AppColors.primary, s * 0.04),
    );
    c.drawLine(
      Offset(s * 0.73, s * 0.73),
      Offset(s * 0.82, s * 0.82),
      _stroke(AppColors.primaryDark, s * 0.05),
    );
  }

  void _inbox(Canvas c, double s) {
    for (int i = 2; i >= 1; i--) {
      final double off = i * s * 0.045;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            s * 0.24 + off,
            s * 0.30 + off,
            s * 0.52 - off * 2,
            s * 0.34,
          ),
          Radius.circular(s * 0.04),
        ),
        _fill(Colors.white.withValues(alpha: 0.55)),
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.24, s * 0.30, s * 0.52, s * 0.34),
        Radius.circular(s * 0.04),
      ),
      _fill(Colors.white),
    );
    final Path flap = Path()
      ..moveTo(s * 0.24, s * 0.32)
      ..lineTo(s * 0.50, s * 0.50)
      ..lineTo(s * 0.76, s * 0.32);
    c.drawPath(flap, _stroke(AppColors.primary, s * 0.03));
    _sun(c, s, Offset(s * 0.80, s * 0.20), s * 0.06);
  }

  void _success(Canvas c, double s) {
    c.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.24, _fill(AppColors.primary));
    c.drawCircle(
      Offset(s * 0.5, s * 0.5),
      s * 0.24,
      _stroke(AppColors.primaryContainer, s * 0.03),
    );
    final Path check = Path()
      ..moveTo(s * 0.40, s * 0.51)
      ..lineTo(s * 0.47, s * 0.58)
      ..lineTo(s * 0.61, s * 0.42);
    c.drawPath(check, _stroke(Colors.white, s * 0.05));
    for (final Offset o in const [
      Offset(0.24, 0.30),
      Offset(0.78, 0.66),
      Offset(0.74, 0.28),
    ]) {
      c.drawCircle(
        Offset(s * o.dx, s * o.dy),
        s * 0.02,
        _fill(AppColors.secondary),
      );
    }
  }

  void _finance(Canvas c, double s) {
    _sun(c, s, Offset(s * 0.76, s * 0.22), s * 0.08);
    for (int i = 0; i < 3; i++) {
      final double y = s * (0.70 - i * 0.09);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.24, y, s * 0.24, s * 0.08),
          Radius.circular(s * 0.04),
        ),
        _fill(i.isEven ? AppColors.secondary : AppColors.secondaryDark),
      );
    }
    final Path arrow = Path()
      ..moveTo(s * 0.54, s * 0.64)
      ..lineTo(s * 0.66, s * 0.48)
      ..lineTo(s * 0.78, s * 0.58);
    c.drawPath(arrow, _stroke(AppColors.primary, s * 0.045));
  }

  @override
  bool shouldRepaint(covariant _BrandArtPainter old) =>
      old.motif != motif || old.onDark != onDark;
}
