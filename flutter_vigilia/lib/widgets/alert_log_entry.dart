import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_data.dart';
import '../theme/t.dart';

class AlertLogEntry extends StatelessWidget {
  final AlertData alerta;
  const AlertLogEntry({super.key, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final hora = DateFormat('HH:mm:ss').format(alerta.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: alerta.color.withOpacity(0.06),
        border: Border(
          left: BorderSide(color: alerta.color, width: 2.5),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
            alerta.texto,
            style: const TextStyle(fontSize: 11, color: T.text, height: 1.3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          hora,
          style: const TextStyle(fontSize: 10, color: T.textDim, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ]),
    );
  }
}
