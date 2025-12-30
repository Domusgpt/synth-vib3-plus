/// VIB3+ Native Shader Widget
///
/// Renders VIB3+ visualization using Flutter's native FragmentProgram
/// This is the TRUE native port of the WebGL shaders - GPU accelerated
///
/// A Paul Phillips Manifestation

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../providers/visual_provider.dart';
import '../../providers/audio_provider.dart';

/// Native VIB3+ shader visualization widget
class VIB3ShaderWidget extends StatefulWidget {
  const VIB3ShaderWidget({super.key});

  @override
  State<VIB3ShaderWidget> createState() => _VIB3ShaderWidgetState();
}

class _VIB3ShaderWidgetState extends State<VIB3ShaderWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late Stopwatch _stopwatch;
  double _time = 0.0;

  // Shader programs for each system
  ui.FragmentProgram? _facetedProgram;
  ui.FragmentProgram? _quantumProgram;
  ui.FragmentProgram? _holographicProgram;

  bool _shadersLoaded = false;
  String? _loadError;

  // Audio reactivity (smoothed)
  double _bassEnergy = 0.0;
  double _midEnergy = 0.0;
  double _highEnergy = 0.0;

  // Touch position
  Offset _touchPosition = const Offset(0.5, 0.5);
  double _touchIntensity = 0.0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = createTicker(_onTick)..start();
    _loadShaders();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadShaders() async {
    try {
      // Load the faceted shader (we'll add quantum and holographic later)
      _facetedProgram = await ui.FragmentProgram.fromAsset(
        'assets/shaders/faceted.frag',
      );

      setState(() {
        _shadersLoaded = true;
      });
      debugPrint('✅ VIB3+ shaders loaded successfully');
    } catch (e) {
      setState(() {
        _loadError = e.toString();
      });
      debugPrint('❌ Failed to load VIB3+ shaders: $e');
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    setState(() {
      _time = _stopwatch.elapsed.inMicroseconds / 1000.0; // Time in milliseconds

      // Update audio reactivity
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.isPlaying) {
        final features = audioProvider.currentFeatures;
        if (features != null) {
          const smoothing = 0.15;
          _bassEnergy = _bassEnergy * (1 - smoothing) +
              (features.bassEnergy / 2.0).clamp(0.0, 1.0) * smoothing;
          _midEnergy = _midEnergy * (1 - smoothing) +
              (features.midEnergy / 1.5).clamp(0.0, 1.0) * smoothing;
          _highEnergy = _highEnergy * (1 - smoothing) +
              features.highEnergy.clamp(0.0, 1.0) * smoothing;
        }
      }

      // Decay touch intensity
      _touchIntensity *= 0.95;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _touchPosition = Offset(
        details.localPosition.dx / size.width,
        details.localPosition.dy / size.height,
      );
      _touchIntensity = 1.0;
    });
  }

  void _onTapDown(TapDownDetails details, Size size) {
    setState(() {
      _touchPosition = Offset(
        details.localPosition.dx / size.width,
        details.localPosition.dy / size.height,
      );
      _touchIntensity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Shader load error:\n$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (!_shadersLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.cyan),
            SizedBox(height: 16),
            Text(
              'Loading VIB3+ shaders...',
              style: TextStyle(color: Colors.cyan),
            ),
          ],
        ),
      );
    }

    return Consumer<VisualProvider>(
      builder: (context, visualProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
              onPanUpdate: (details) => _onPanUpdate(details, size),
              onTapDown: (details) => _onTapDown(details, size),
              child: CustomPaint(
                size: size,
                painter: _VIB3ShaderPainter(
                  program: _facetedProgram!,
                  time: _time,
                  resolution: size,
                  mouse: _touchPosition,
                  geometry: visualProvider.currentGeometry.toDouble(),
                  gridDensity: visualProvider.tessellationDensity.toDouble(),
                  morphFactor: visualProvider.morphParameter,
                  chaos: 0.2, // Could expose this
                  speed: visualProvider.rotationSpeed,
                  hue: visualProvider.hueShift,
                  intensity: visualProvider.vertexBrightness,
                  saturation: 0.8, // Could expose this
                  rot4dXW: visualProvider.rotationXW,
                  rot4dYW: visualProvider.rotationYW,
                  rot4dZW: visualProvider.rotationZW,
                  mouseIntensity: _touchIntensity,
                  clickIntensity: _touchIntensity,
                  bassEnergy: _bassEnergy,
                  midEnergy: _midEnergy,
                  highEnergy: _highEnergy,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Custom painter that renders the VIB3+ shader
class _VIB3ShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final Size resolution;
  final Offset mouse;
  final double geometry;
  final double gridDensity;
  final double morphFactor;
  final double chaos;
  final double speed;
  final double hue;
  final double intensity;
  final double saturation;
  final double rot4dXW;
  final double rot4dYW;
  final double rot4dZW;
  final double mouseIntensity;
  final double clickIntensity;
  final double bassEnergy;
  final double midEnergy;
  final double highEnergy;

  _VIB3ShaderPainter({
    required this.program,
    required this.time,
    required this.resolution,
    required this.mouse,
    required this.geometry,
    required this.gridDensity,
    required this.morphFactor,
    required this.chaos,
    required this.speed,
    required this.hue,
    required this.intensity,
    required this.saturation,
    required this.rot4dXW,
    required this.rot4dYW,
    required this.rot4dZW,
    required this.mouseIntensity,
    required this.clickIntensity,
    required this.bassEnergy,
    required this.midEnergy,
    required this.highEnergy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Set uniforms in order matching the shader
    int idx = 0;

    // u_resolution (vec2)
    shader.setFloat(idx++, size.width);
    shader.setFloat(idx++, size.height);

    // u_time (float)
    shader.setFloat(idx++, time);

    // u_mouse (vec2)
    shader.setFloat(idx++, mouse.dx);
    shader.setFloat(idx++, mouse.dy);

    // u_geometry (float)
    shader.setFloat(idx++, geometry);

    // u_gridDensity (float) - modulated by mid energy
    shader.setFloat(idx++, gridDensity + midEnergy * 5.0);

    // u_morphFactor (float)
    shader.setFloat(idx++, morphFactor);

    // u_chaos (float) - modulated by high energy
    shader.setFloat(idx++, chaos + highEnergy * 0.3);

    // u_speed (float) - modulated by bass energy
    shader.setFloat(idx++, speed * (1.0 + bassEnergy * 0.5));

    // u_hue (float) - shift with audio
    shader.setFloat(idx++, hue + bassEnergy * 30.0);

    // u_intensity (float) - pulse with bass
    shader.setFloat(idx++, intensity * (1.0 + bassEnergy * 0.3));

    // u_saturation (float)
    shader.setFloat(idx++, saturation);

    // u_rot4dXW, u_rot4dYW, u_rot4dZW (floats)
    shader.setFloat(idx++, rot4dXW);
    shader.setFloat(idx++, rot4dYW);
    shader.setFloat(idx++, rot4dZW);

    // u_mouseIntensity (float)
    shader.setFloat(idx++, mouseIntensity);

    // u_clickIntensity (float)
    shader.setFloat(idx++, clickIntensity);

    final paint = Paint()..shader = shader;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_VIB3ShaderPainter oldDelegate) => true;
}
