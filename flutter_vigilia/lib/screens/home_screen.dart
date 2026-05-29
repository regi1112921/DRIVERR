import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/t.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onStart() async {
    setState(() { _loading = true; _error = null; });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() { _error = 'No se encontró cámara en el dispositivo.'; _loading = false; });
        return;
      }

      // Preferir cámara frontal para monitoreo de conductor
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, b) => DashboardScreen(camera: cam),
          transitionsBuilder: (_, a, b, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      setState(() { _error = 'Error al acceder a la cámara: $e'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Grid de fondo
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),

        // Contenido central
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Badge superior
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: T.cyanDim,
                      border: Border.all(color: T.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'SISTEMA ACTIVO v2.0  •  100% OFFLINE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: T.cyan,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Logo / ícono de ojo animado
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: T.cyan.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: T.cyan.withOpacity(0.15 + _pulse.value * 0.2),
                            blurRadius: 30 + _pulse.value * 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.remove_red_eye_outlined,
                          color: T.cyan, size: 52),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Título
                  const Text(
                    'vigilIA',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 16,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Traffic Alert & Tiredness System',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: T.cyan,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Feature chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: const [
                      _Chip(label: 'Detección de Sueño',   dot: T.green),
                      _Chip(label: 'Alerta de Bostezo',    dot: T.orange),
                      _Chip(label: 'Celular / Tabaco',     dot: T.red),
                      _Chip(label: 'Bebida al Volante',    dot: T.orange),
                    ],
                  ),

                  const SizedBox(height: 44),

                  // Botón iniciar
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(color: T.cyan, strokeWidth: 2),
                          )
                        : _StartButton(onPressed: _onStart),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: T.red, fontSize: 12),
                    ),
                  ],

                  const SizedBox(height: 40),

                  const Text(
                    'Detección en tiempo real con IA embebida\nSin conexión a internet requerida',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: T.textDim, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Chip decorativo ──────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color dot;
  const _Chip({required this.label, required this.dot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: T.bg3,
        border: Border.all(color: T.border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 11, color: T.text, letterSpacing: 0.5)),
      ]),
    );
  }
}

// ── Botón de inicio estilo HUD ───────────────────────────
class _StartButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _StartButton({required this.onPressed});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) { setState(() => _hovered = false); widget.onPressed(); },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered ? T.cyan.withOpacity(0.9) : T.cyan,
          boxShadow: [
            BoxShadow(
              color: T.cyan.withOpacity(_hovered ? 0.5 : 0.3),
              blurRadius: _hovered ? 24 : 12,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: T.bg, size: 24),
            SizedBox(width: 8),
            Text(
              'INICIAR SISTEMA',
              style: TextStyle(
                color: T.bg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid de fondo ────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0A00E5FF)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
