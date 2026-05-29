import 'package:flutter/material.dart';
import '../theme/t.dart';

class HudFrame extends StatelessWidget {
  final Widget child;
  final Color color;
  final double cornerSize;
  final double strokeWidth;

  const HudFrame({
    super.key,
    required this.child,
    this.color = T.cyan,
    this.cornerSize = 20,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      Positioned.fill(
        child: CustomPaint(
          painter: _CornerPainter(color, cornerSize, strokeWidth),
        ),
      ),
    ]);
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double size;
  final double sw;
  _CornerPainter(this.color, this.size, this.sw);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // TL
    c.drawLine(Offset(0, size), Offset.zero, p);
    c.drawLine(Offset.zero, Offset(size, 0), p);
    // TR
    c.drawLine(Offset(s.width - size, 0), Offset(s.width, 0), p);
    c.drawLine(Offset(s.width, 0), Offset(s.width, size), p);
    // BL
    c.drawLine(Offset(0, s.height - size), Offset(0, s.height), p);
    c.drawLine(Offset(0, s.height), Offset(size, s.height), p);
    // BR
    c.drawLine(Offset(s.width - size, s.height), Offset(s.width, s.height), p);
    c.drawLine(Offset(s.width, s.height - size), Offset(s.width, s.height), p);
  }

  @override
  bool shouldRepaint(_CornerPainter o) => color != o.color;
}
