import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import '../models/alert_data.dart';

/// Resultado de un frame procesado
class FrameResult {
  final AlertData alerta;
  final List<Detection> detections;
  FrameResult({required this.alerta, required this.detections});
}

/// Una detección individual de YOLO
class Detection {
  final String label;
  final double confidence;
  final Rect rect; // coordenadas normalizadas [0,1]
  Detection({required this.label, required this.confidence, required this.rect});
}

class DetectionService {
  // Singleton
  static final DetectionService _i = DetectionService._();
  factory DetectionService() => _i;
  DetectionService._();

  bool _modelLoaded = false;

  // Timers de estado (en segundos desde epoch)
  double _tOjosCerrados  = 0;
  double _tOjosBloqueados = 0;
  double _tBostezo        = 0;

  // Para limitar la frecuencia de inferencia
  bool _running = false;

  // ── Inicialización ───────────────────────────────────
  Future<void> init() async {
    if (_modelLoaded) return;

    await Tflite.loadModel(
      model:  'assets/models/yolov8_tats.tflite',
      labels: 'assets/models/labels.txt',
      numThreads: 2,
      isAsset: true,
      useGpuDelegate: false,
    );
    _modelLoaded = true;
  }

  Future<void> dispose() async {
    await Tflite.close();
    _modelLoaded = false;
  }

  void resetTimers() {
    _tOjosCerrados   = 0;
    _tOjosBloqueados = 0;
    _tBostezo        = 0;
  }

  // ── Procesar un CameraImage ──────────────────────────
  Future<FrameResult?> processFrame(CameraImage image, int sensorOrientation) async {
    if (!_modelLoaded || _running) return null;
    _running = true;

    try {
      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

      // Correr YOLO
      final raw = await Tflite.detectObjectOnFrame(
        bytesList:       image.planes.map((p) => p.bytes).toList(),
        model:           'YOLO',
        imageHeight:     image.height,
        imageWidth:      image.width,
        imageMean:       0,
        imageStd:        255,
        threshold:       0.35,
        numResultsPerClass: 2,
      );

      // Parsear detecciones
      final detections = <Detection>[];
      bool detectoPersona    = false;
      bool detectoBostezo    = false;
      AlertLevel nivel       = AlertLevel.normal;
      String textoAlerta     = 'Conduciendo con normalidad';

      if (raw != null) {
        for (final r in raw) {
          final label      = (r['detectedClass'] as String).toLowerCase();
          final confidence = (r['confidenceInClass'] as double);
          final box        = r['rect'] as Map;

          final det = Detection(
            label:      label,
            confidence: confidence,
            rect: Rect.fromLTWH(
              (box['x'] as double),
              (box['y'] as double),
              (box['w'] as double),
              (box['h'] as double),
            ),
          );
          detections.add(det);

          // ── Lógica de alertas por clase ──────────────
          if (label == 'cell phone' || label == 'telephone') {
            nivel       = AlertLevel.critico;
            textoAlerta = '!!! ALERTA: DISTRACCIÓN POR CELULAR !!!';
          } else if (label == 'lighter') {
            nivel       = AlertLevel.critico;
            textoAlerta = '!!! ALERTA ROJA: PROHIBIDO FUMAR !!!';
          } else if (label == 'cup' || label == 'bottle' || label == 'glass') {
            if (nivel != AlertLevel.critico) {
              nivel       = AlertLevel.advertencia;
              textoAlerta = 'WARN: Conductor tomando bebida';
            }
          } else if (label == 'person') {
            detectoPersona = true;
          } else if (label == 'mouth') {
            // Ratio h/w > 0.7 → bostezo
            if (det.rect.height > det.rect.width * 0.7) {
              detectoBostezo = true;
            }
          }
        }
      }

      // ── Bostezo ──────────────────────────────────────
      if (detectoBostezo) {
        if (_tBostezo == 0) _tBostezo = now;
        if (now - _tBostezo > 0.8 && nivel == AlertLevel.normal) {
          nivel       = AlertLevel.advertencia;
          textoAlerta = '!!! ADVERTENCIA: BOSTEZO / FATIGA !!!';
        }
      } else {
        _tBostezo = 0;
      }

      // ── Ojos / sueño ─────────────────────────────────
      if (detectoPersona) {
        // Buscamos detecciones de "eye" en YOLO
        final eyes = detections.where((d) => d.label == 'eye' || d.label == 'eyes').toList();

        if (eyes.isEmpty) {
          // Sin ojos detectados
          if (_tOjosCerrados == 0) {
            _tOjosCerrados   = now;
            _tOjosBloqueados = now;
          }
          if (now - _tOjosCerrados > 1.3) {
            nivel       = AlertLevel.critico;
            textoAlerta = '!!! ALERTA CRÍTICA: CONDUCTOR DORMIDO !!!';
          } else if (now - _tOjosBloqueados > 5.0 && nivel == AlertLevel.normal) {
            nivel       = AlertLevel.advertencia;
            textoAlerta = 'WARN: Vista bloqueada (¿Lentes de sol?)';
          }
        } else {
          _tOjosCerrados   = 0;
          _tOjosBloqueados = 0;
        }
      }

      return FrameResult(
        alerta: AlertData(texto: textoAlerta, nivel: nivel),
        detections: detections,
      );
    } finally {
      _running = false;
    }
  }
}
