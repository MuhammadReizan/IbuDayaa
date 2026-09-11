import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// An animated circular score gauge (0–[max]). Sweeps in on first build and
/// shows the value in the tabular numeric style at its centre.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.max = 100,
    this.size = 128,
    this.stroke = 12,
    this.caption,
    this.centerLabel,
    this.trackColor = AppColors.primaryContainerDim,
    this.progressColors = const [AppColors.secondary, AppColors.primary],
  });

  final int score;
  final int max;
  final double size;
  final double stroke;

  /// Small text under the number (e.g. "dari 100").
  final String? caption;

  /// Text above the number (e.g. band name). Rarely used.
  final String? centerLabel;
  final Color trackColor;
  final List<Color> progressColors;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double target = (score / max).clamp(0.0, 1.0);

    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              value: value,
              stroke: stroke,
              track: trackColor,
              colors: progressColors,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (centerLabel != null)
                    Text(centerLabel!, style: text.labelSmall),
                  Text(
                    '${(value * max).round()}',
                    style: AppTypography.numeric(size * 0.30),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: text.labelSmall?.copyWith(
                        fontSize: (size * 0.10).clamp(9.0, 12.0),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.track,
    required this.colors,
  });

  final double value;
  final double stroke;
  final Color track;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final double radius = (size.shortestSide - stroke) / 2;
    const double start = -math.pi / 2;

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      2 * math.pi,
      false,
      trackPaint,
    );

    if (value <= 0) return;
    final Paint progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: colors.length == 1 ? [colors.first, colors.first] : colors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      2 * math.pi * value,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.stroke != stroke;
}
