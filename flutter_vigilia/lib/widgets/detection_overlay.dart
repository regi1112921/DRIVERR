import 'package:flutter/material.dart';
import '../services/detection_service.dart';
import '../theme/t.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;
  final Size previewSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoxPainter(detections, previewSize),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size previewSize;

  _BoxPainter(this.detections, this.previewSize);

  Color _colorForLabel(String label) {
    if (label == 'cell phone' || label == 'telephone' || label == 'lighter') {
      return T.red;
    }
    if (label == 'cup' || label == 'bottle' || label == 'glass') return T.orange;
    if (label == 'mouth') return T.orange;
    if (label == 'eye' || label == 'eyes') return T.cyan;
    return T.cyan;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final color = _colorForLabel(d.label);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      // rect tiene coordenadas normalizadas (0-1) desde TFLite YOLO
      final rect = Rect.fromLTWH(
        d.rect.left   * size.width,
        d.rect.top    * size.height,
        d.rect.width  * size.width,
        d.rect.height * size.height,
      );

      canvas.drawRect(rect, paint);

      // Etiqueta
      final label = '${d.label} ${(d.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: ' $label ',
          style: TextStyle(
            color: T.bg,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            background: Paint()..color = color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(rect.left, rect.top - 14));
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => detections != old.detections;
}
