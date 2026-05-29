import 'package:flutter/material.dart';
import '../models/alert_data.dart';
import '../theme/t.dart';

class StatusCard extends StatefulWidget {
  final AlertData alerta;
  const StatusCard({super.key, required this.alerta});

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
    _fade = Tween(begin: 1.0, end: 0.35).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alerta;
    final isCrit = a.nivel == AlertLevel.critico;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: a.color.withOpacity(0.08),
        border: Border.all(color: a.color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        isCrit
            ? FadeTransition(
                opacity: _fade,
                child: Icon(a.icon, color: a.color, size: 34),
              )
            : Icon(a.icon, color: a.color, size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.levelLabel,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: a.color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                a.texto,
                style: const TextStyle(
                  fontSize: 11,
                  color: T.text,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
