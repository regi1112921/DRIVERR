import 'package:flutter/material.dart';
import '../theme/t.dart';

enum AlertLevel { normal, advertencia, critico }

class AlertData {
  final String texto;
  final AlertLevel nivel;
  final DateTime timestamp;

  AlertData({
    required this.texto,
    required this.nivel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AlertData.normal() => AlertData(
        texto: 'Conduciendo con normalidad',
        nivel: AlertLevel.normal,
      );

  Color get color {
    switch (nivel) {
      case AlertLevel.critico:     return T.red;
      case AlertLevel.advertencia: return T.orange;
      case AlertLevel.normal:      return T.green;
    }
  }

  String get levelLabel {
    switch (nivel) {
      case AlertLevel.critico:     return 'CRÍTICO';
      case AlertLevel.advertencia: return 'ADVERTENCIA';
      case AlertLevel.normal:      return 'NORMAL';
    }
  }

  IconData get icon {
    switch (nivel) {
      case AlertLevel.critico:     return Icons.warning_rounded;
      case AlertLevel.advertencia: return Icons.warning_amber_rounded;
      case AlertLevel.normal:      return Icons.check_circle_rounded;
    }
  }
}
