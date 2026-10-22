import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo app (bong bóng tin nhắn + mũi tên điều hướng), vẽ đúng hình của
/// launcher icon (`scripts/generate_app_icons.py`) để không cần asset ảnh.
/// Chỉ vẽ phần glyph — nền do widget cha lo.
class AppLogoGlyph extends StatelessWidget {
  const AppLogoGlyph({
    super.key,
    this.size = 52,
    this.bubbleColor = Colors.white,
    required this.arrowColor,
  });

  final double size;
  final Color bubbleColor;
  final Color arrowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AppLogoPainter(bubbleColor: bubbleColor, arrowColor: arrowColor),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  _AppLogoPainter({required this.bubbleColor, required this.arrowColor});

  final Color bubbleColor;
  final Color arrowColor;

  // Khung glyph trên lưới 108: x 28→80, y 32→81 → vẽ trong ô 24→84 (60 đơn vị)
  static const double _origin = 24;
  static const double _extent = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _extent;
    canvas
      ..save()
      ..scale(scale)
      ..translate(-_origin, -_origin);

    final bubble = Path()
      ..addRRect(RRect.fromLTRBR(28, 32, 80, 72, const Radius.circular(12)))
      ..moveTo(50, 71)
      ..lineTo(37, 81)
      ..lineTo(40, 70)
      ..close();
    canvas.drawPath(bubble, Paint()..color = bubbleColor);

    canvas
      ..translate(54, 52)
      ..rotate(math.pi / 4)
      ..translate(-54, -52);
    final arrow = Path()
      ..moveTo(54, 39)
      ..lineTo(63.5, 62)
      ..lineTo(54, 57)
      ..lineTo(44.5, 62)
      ..close();
    canvas
      ..drawPath(arrow, Paint()..color = arrowColor)
      ..restore();
  }

  @override
  bool shouldRepaint(_AppLogoPainter old) =>
      old.bubbleColor != bubbleColor || old.arrowColor != arrowColor;
}
