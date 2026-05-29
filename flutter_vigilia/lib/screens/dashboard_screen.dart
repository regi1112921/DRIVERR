import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/alert_data.dart';
import '../services/detection_service.dart';
import '../widgets/hud_frame.dart';
import '../widgets/status_card.dart';
import '../widgets/alert_log_entry.dart';
import '../widgets/detection_overlay.dart';
import '../theme/t.dart';

class DashboardScreen extends StatefulWidget {
  final CameraDescription camera;

  const DashboardScreen({
    super.key,
    required this.camera,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  // camara
  CameraController? _camCtrl;
  bool _camReady = false;

  // deteccion
  final _svc = DetectionService();
  AlertData _alerta = AlertData.normal();
  List<Detection> _detections = [];

  // historial
  final List<AlertData> _log = [];
  AlertLevel _ultimoNivel = AlertLevel.normal;
  int _totalAlertas = 0;

  // uptime
  late final DateTime _startTime;
  late final Timer _uptimeTimer;
  String _uptime = '00:00:00';

  // procesamiento
  bool _procesando = false;

  @override
  void initState() {
    super.initState();

    _startTime = DateTime.now();

    _uptimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateUptime(),
    );

    _initCamera();
  }

  void _updateUptime() {
    final d = DateTime.now().difference(_startTime);

    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');

    if (mounted) {
      setState(() {
        _uptime = '$h:$m:$s';
      });
    }
  }

  Future<void> _initCamera() async {

    print('iniciando servicio');

    try {

      // inicializar modelos ia
      await _svc.init();

      print('servicio listo');

      _camCtrl = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,

        // mejor compatibilidad para mac
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      print('inicializando camara');

      await _camCtrl!.initialize();

      print('camara inicializada');

      // iniciar stream
      await _camCtrl!.startImageStream(_onFrame);

      print('stream iniciado');

      if (mounted) {
        setState(() {
          _camReady = true;
        });
      }

    } catch (e) {

      print('ERROR CAMARA: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de cámara: $e'),
            backgroundColor: T.red,
          ),
        );
      }
    }
  }

  void _onFrame(CameraImage image) async {

    try {

      if (_procesando) return;

      _procesando = true;

      final result = await _svc.processFrame(
        image,
        widget.camera.sensorOrientation,
      );

      if (result == null || !mounted) {
        _procesando = false;
        return;
      }

      setState(() {
        _alerta = result.alerta;
        _detections = result.detections;
      });

      // guardar historial
      if (
        result.alerta.nivel != AlertLevel.normal &&
        _ultimoNivel == AlertLevel.normal
      ) {

        _totalAlertas++;

        _log.insert(0, result.alerta);

        if (_log.length > 30) {
          _log.removeLast();
        }
      }

      _ultimoNivel = result.alerta.nivel;

    } catch (e) {

      print('ERROR FRAME: $e');

    } finally {

      _procesando = false;
    }
  }

  Future<void> _detener() async {

    try {

      await _camCtrl?.stopImageStream();

    } catch (_) {}

    await _camCtrl?.dispose();

    await _svc.dispose();

    _uptimeTimer.cancel();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {

    _uptimeTimer.cancel();

    _camCtrl?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final isLandscape =
        MediaQuery.of(context).orientation ==
        Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [

            _buildHeader(),

            Expanded(
              child: isLandscape

                  ? Row(
                      children: [

                        Expanded(
                          flex: 3,
                          child: _buildCamSection(),
                        ),

                        SizedBox(
                          width: 280,
                          child: _buildSidePanel(),
                        ),
                      ],
                    )

                  : Column(
                      children: [

                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: _buildCamSection(),
                        ),

                        Expanded(
                          child: _buildSidePanel(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // header
  Widget _buildHeader() {

    return Container(
      height: 52,

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),

      decoration: const BoxDecoration(
        color: T.bg2,

        border: Border(
          bottom: BorderSide(
            color: T.border,
          ),
        ),
      ),

      child: Row(
        children: [

          const Icon(
            Icons.remove_red_eye_outlined,
            color: T.cyan,
            size: 20,
          ),

          const SizedBox(width: 8),

          const Text(
            'vigilIA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 10),

          const _BlinkDot(color: T.red),

          const SizedBox(width: 4),

          const Text(
            'EN VIVO',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: T.red,
            ),
          ),

          const Spacer(),

          _StatPill(
            label: 'UPTIME',
            value: _uptime,
          ),

          const SizedBox(width: 8),

          _StatPill(
            label: 'ALERTAS',
            value: '$_totalAlertas',
            valueColor:
                _totalAlertas > 0
                    ? T.orange
                    : null,
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: _detener,

            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color: T.red.withOpacity(0.1),

                border: Border.all(
                  color: T.red.withOpacity(0.4),
                ),

                borderRadius: BorderRadius.circular(3),
              ),

              child: const Row(
                children: [

                  Icon(
                    Icons.stop_rounded,
                    color: T.red,
                    size: 14,
                  ),

                  SizedBox(width: 4),

                  Text(
                    'DETENER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: T.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // seccion camara
  Widget _buildCamSection() {

    return Container(
      color: Colors.black,

      child:
          _camReady && _camCtrl != null

              ? HudFrame(
                  child: Stack(
                    fit: StackFit.expand,

                    children: [

                      CameraPreview(_camCtrl!),

                      LayoutBuilder(
                        builder: (_, constraints) {

                          return DetectionOverlay(
                            detections: _detections,

                            previewSize: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                          );
                        },
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,

                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 250,
                          ),

                          color:
                              _alerta.color.withOpacity(0.22),

                          padding:
                              const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),

                          child: Text(
                            _alerta.texto,

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: _alerta.color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )

              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [

                      CircularProgressIndicator(
                        color: T.cyan,
                        strokeWidth: 2,
                      ),

                      SizedBox(height: 14),

                      Text(
                        'Iniciando cámara y modelos...',
                        style: TextStyle(
                          color: T.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // panel lateral
  Widget _buildSidePanel() {

    return Container(
      decoration: const BoxDecoration(
        color: T.bg2,

        border: Border(
          left: BorderSide(
            color: T.border,
          ),
        ),
      ),

      child: ListView(
        padding: const EdgeInsets.all(14),

        children: [

          StatusCard(alerta: _alerta),

          const SizedBox(height: 16),

          _buildLeyenda(),

          const SizedBox(height: 16),

          const _SectionTitle(
            title: 'HISTORIAL DE ALERTAS',
          ),

          const SizedBox(height: 8),

          if (_log.isEmpty)

            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
              ),

              child: Text(
                'Sin alertas registradas',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
                  color: T.textDim,
                ),
              ),
            )

          else

            ..._log.map(
              (a) => AlertLogEntry(alerta: a),
            ),
        ],
      ),
    );
  }

  Widget _buildLeyenda() {

    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        _SectionTitle(
          title: 'NIVELES DE ALERTA',
        ),

        SizedBox(height: 8),

        _LegendRow(
          color: T.green,
          label: 'Normal',
          desc: 'Conducción correcta',
        ),

        _LegendRow(
          color: T.orange,
          label: 'Advertencia',
          desc: 'Fatiga / bostezo / bebida',
        ),

        _LegendRow(
          color: T.red,
          label: 'Crítico',
          desc: 'Dormido / celular / fumar',
        ),
      ],
    );
  }
}

// widgets auxiliares

class _StatPill extends StatelessWidget {

  final String label;
  final String value;
  final Color? valueColor;

  const _StatPill({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: T.bg3,

        border: Border.all(
          color: T.border,
        ),

        borderRadius: BorderRadius.circular(3),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [

          Text(
            label,

            style: const TextStyle(
              fontSize: 8,
              color: T.textDim,
              letterSpacing: 1.5,
            ),
          ),

          Text(
            value,

            style: TextStyle(
              fontSize: 12,
              color: valueColor ?? T.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {

  final Color color;

  const _BlinkDot({
    required this.color,
  });

  @override
  State<_BlinkDot> createState() =>
      _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {

  late AnimationController _c;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {

    _c.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FadeTransition(
      opacity: _c,

      child: Container(
        width: 7,
        height: 7,

        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {

  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    return Text(
      title,

      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 2,
        color: T.textDim,
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {

  final Color color;
  final String label;
  final String desc;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
      ),

      child: Row(
        children: [

          Container(
            width: 8,
            height: 8,

            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 90,

            child: Text(
              label,

              style: const TextStyle(
                fontSize: 12,
                color: T.text,
              ),
            ),
          ),

          Expanded(
            child: Text(
              desc,

              style: const TextStyle(
                fontSize: 11,
                color: T.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
