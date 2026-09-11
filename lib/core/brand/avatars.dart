import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// The Ibu Clara persona avatar — a warm painted head-and-shoulders glyph on a
/// soft brand gradient. No image asset required.
class IbuClaraAvatar extends StatelessWidget {
  const IbuClaraAvatar({super.key, this.size = 44, this.ring = false});

  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring
            ? Border.all(color: Colors.white, width: size * 0.06)
            : null,
        boxShadow: ring ? AppShadows.sm : null,
      ),
      child: ClipOval(
        child: CustomPaint(size: Size.square(size), painter: _ClaraPainter()),
      ),
    );
  }
}

class _ClaraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Rect box = Offset.zero & size;

    canvas.drawRect(
      box,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFDEFD2), Color(0xFFEAF6EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(box),
    );

    // Headscarf (behind the face).
    final Paint scarf = Paint()..color = AppColors.primary;
    final Path scarfPath = Path()
      ..moveTo(s * 0.16, s * 0.98)
      ..lineTo(s * 0.16, s * 0.52)
      ..quadraticBezierTo(s * 0.16, s * 0.14, s * 0.5, s * 0.14)
      ..quadraticBezierTo(s * 0.84, s * 0.14, s * 0.84, s * 0.52)
      ..lineTo(s * 0.84, s * 0.98)
      ..close();
    canvas.drawPath(scarfPath, scarf);

    // Face.
    final Paint skin = Paint()..color = const Color(0xFFE7B58C);
    final Path face = Path()
      ..moveTo(s * 0.30, s * 0.40)
      ..quadraticBezierTo(s * 0.30, s * 0.66, s * 0.5, s * 0.72)
      ..quadraticBezierTo(s * 0.70, s * 0.66, s * 0.70, s * 0.40)
      ..quadraticBezierTo(s * 0.70, s * 0.24, s * 0.5, s * 0.24)
      ..quadraticBezierTo(s * 0.30, s * 0.24, s * 0.30, s * 0.40)
      ..close();
    canvas.drawPath(face, skin);

    // Shoulders / blouse.
    final Paint blouse = Paint()..color = AppColors.secondary;
    final Path shoulders = Path()
      ..moveTo(s * 0.06, s * 1.02)
      ..quadraticBezierTo(s * 0.14, s * 0.74, s * 0.5, s * 0.74)
      ..quadraticBezierTo(s * 0.86, s * 0.74, s * 0.94, s * 1.02)
      ..close();
    canvas.drawPath(shoulders, blouse);

    // Scarf front drape over one shoulder.
    final Path drape = Path()
      ..moveTo(s * 0.5, s * 0.70)
      ..lineTo(s * 0.66, s * 0.74)
      ..lineTo(s * 0.5, s * 0.86)
      ..close();
    canvas.drawPath(drape, Paint()..color = AppColors.primaryDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A generic member avatar: initials on a stable colour derived from the name.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  static const List<List<Color>> _palettes = [
    [Color(0xFF1FA25A), Color(0xFF0E5D35)],
    [Color(0xFFF4B63E), Color(0xFFD9931B)],
    [Color(0xFF2F6FE0), Color(0xFF1B4FA8)],
    [Color(0xFF17A398), Color(0xFF0C6F67)],
    [Color(0xFFB5651D), Color(0xFF8A4A12)],
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.elementAt(1).characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[name.hashCode.abs() % _palettes.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
