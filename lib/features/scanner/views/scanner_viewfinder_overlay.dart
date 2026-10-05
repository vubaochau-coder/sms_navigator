import 'package:flutter/material.dart';

/// Lớp phủ tối mờ với lỗ cắt vuông ở giữa và viền bo góc phát sáng.
class ScannerViewfinderOverlay extends StatelessWidget {
  const ScannerViewfinderOverlay({super.key});

  static const double _cutoutSize = 260;
  static const double _cutoutRadius = 24;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cutout = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: _cutoutSize,
            height: _cutoutSize,
          ),
          const Radius.circular(_cutoutRadius),
        );
        return CustomPaint(
          painter: ViewfinderPainter(rrect: cutout, borderColor: borderColor),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class ViewfinderPainter extends CustomPainter {
  const ViewfinderPainter({required this.rrect, required this.borderColor});

  final RRect rrect;
  final Color borderColor;

  static const double borderWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final mask = Path()..addRect(screen);
    final hole = Path()..addRRect(rrect);
    final combined = Path.combine(PathOperation.difference, mask, hole);
    canvas.drawPath(combined, Paint()..color = Colors.black54);

    final innerRRect = rrect.deflate(borderWidth / 2);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = borderColor.withValues(alpha: 0.20);
    canvas.drawRRect(innerRRect, glowPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..color = borderColor;
    canvas.drawRRect(innerRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ViewfinderPainter oldDelegate) {
    return oldDelegate.rrect != rrect || oldDelegate.borderColor != borderColor;
  }
}
