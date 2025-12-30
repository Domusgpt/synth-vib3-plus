/// VIB3+ Native Shader Widget
///
/// Renders VIB3+ visualization using Flutter's native FragmentProgram
/// This is the TRUE native port of the WebGL shaders - GPU accelerated
/// Supports all 3 systems: Quantum, Faceted, Holographic
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
  int _shadersLoadedCount = 0;

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
      // Load all 3 shaders in parallel
      final results = await Future.wait([
        ui.FragmentProgram.fromAsset('assets/shaders/faceted.frag'),
        ui.FragmentProgram.fromAsset('assets/shaders/quantum.frag'),
        ui.FragmentProgram.fromAsset('assets/shaders/holographic.frag'),
      ]);

      _facetedProgram = results[0];
      _quantumProgram = results[1];
      _holographicProgram = results[2];

      setState(() {
        _shadersLoaded = true;
        _shadersLoadedCount = 3;
      });
      debugPrint('✅ All 3 VIB3+ shaders loaded successfully');
    } catch (e) {
      // Try loading individually to identify which failed
      debugPrint('⚠️ Parallel load failed, trying individual: $e');

      try {
        _facetedProgram = await ui.FragmentProgram.fromAsset('assets/shaders/faceted.frag');
        _shadersLoadedCount++;
        debugPrint('✅ Faceted shader loaded');
      } catch (e) {
        debugPrint('❌ Faceted shader failed: $e');
      }

      try {
        _quantumProgram = await ui.FragmentProgram.fromAsset('assets/shaders/quantum.frag');
        _shadersLoadedCount++;
        debugPrint('✅ Quantum shader loaded');
      } catch (e) {
        debugPrint('❌ Quantum shader failed: $e');
      }

      try {
        _holographicProgram = await ui.FragmentProgram.fromAsset('assets/shaders/holographic.frag');
        _shadersLoadedCount++;
        debugPrint('✅ Holographic shader loaded');
      } catch (e) {
        debugPrint('❌ Holographic shader failed: $e');
      }

      if (_shadersLoadedCount > 0) {
        setState(() {
          _shadersLoaded = true;
        });
        debugPrint('✅ Loaded $_shadersLoadedCount/3 shaders');
      } else {
        setState(() {
          _loadError = e.toString();
        });
        debugPrint('❌ Failed to load any VIB3+ shaders: $e');
      }
    }
  }

  ui.FragmentProgram? _getShaderForSystem(String system) {
    switch (system.toLowerCase()) {
      case 'quantum':
        return _quantumProgram ?? _facetedProgram;
      case 'holographic':
        return _holographicProgram ?? _facetedProgram;
      case 'faceted':
      default:
        return _facetedProgram;
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    setState(() {
      _time = _stopwatch.elapsed.inMicroseconds / 1000.0;

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
        final currentSystem = visualProvider.currentSystem;
        final program = _getShaderForSystem(currentSystem);

        if (program == null) {
          return const Center(
            child: Text('No shader available', style: TextStyle(color: Colors.orange)),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
              onPanUpdate: (details) => _onPanUpdate(details, size),
              onTapDown: (details) => _onTapDown(details, size),
              child: CustomPaint(
                size: size,
                painter: _VIB3ShaderPainter(
                  program: program,
                  systemType: currentSystem,
                  time: _time,
                  resolution: size,
                  mouse: _touchPosition,
                  geometry: visualProvider.currentGeometry.toDouble(),
                  gridDensity: visualProvider.tessellationDensity.toDouble(),
                  morphFactor: visualProvider.morphParameter,
                  chaos: 0.2,
                  speed: visualProvider.rotationSpeed,
                  hue: visualProvider.hueShift,
                  intensity: visualProvider.vertexBrightness,
                  saturation: 0.8,
                  dimension: 3.8, // 4D dimension parameter
                  // VIB3+ 6D ROTATION SYSTEM
                  rot4dXY: visualProvider.rotationXY, // 3D space rotation
                  rot4dXZ: visualProvider.rotationXZ, // 3D space rotation
                  rot4dYZ: visualProvider.rotationYZ, // 3D space rotation
                  rot4dXW: visualProvider.rotationXW, // 4D hyperspace rotation
                  rot4dYW: visualProvider.rotationYW, // 4D hyperspace rotation
                  rot4dZW: visualProvider.rotationZW, // 4D hyperspace rotation
                  mouseIntensity: _touchIntensity,
                  clickIntensity: _touchIntensity,
                  bassEnergy: _bassEnergy,
                  midEnergy: _midEnergy,
                  highEnergy: _highEnergy,
                  layerSeparation: visualProvider.layerSeparation,
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
  final String systemType;
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
  final double dimension;
  // VIB3+ 6D ROTATION SYSTEM
  final double rot4dXY; // 3D space rotation
  final double rot4dXZ; // 3D space rotation
  final double rot4dYZ; // 3D space rotation
  final double rot4dXW; // 4D hyperspace rotation
  final double rot4dYW; // 4D hyperspace rotation
  final double rot4dZW; // 4D hyperspace rotation
  final double mouseIntensity;
  final double clickIntensity;
  final double bassEnergy;
  final double midEnergy;
  final double highEnergy;
  final double layerSeparation;

  _VIB3ShaderPainter({
    required this.program,
    required this.systemType,
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
    required this.dimension,
    required this.rot4dXY,
    required this.rot4dXZ,
    required this.rot4dYZ,
    required this.rot4dXW,
    required this.rot4dYW,
    required this.rot4dZW,
    required this.mouseIntensity,
    required this.clickIntensity,
    required this.bassEnergy,
    required this.midEnergy,
    required this.highEnergy,
    required this.layerSeparation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    int idx = 0;

    // u_resolution (vec2)
    shader.setFloat(idx++, size.width);
    shader.setFloat(idx++, size.height);

    // u_time (float)
    shader.setFloat(idx++, time);

    // u_mouse (vec2)
    shader.setFloat(idx++, mouse.dx);
    shader.setFloat(idx++, mouse.dy);

    // u_geometry (float) - 0-23 for 24-geometry system
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

    // u_dimension (float) - 4D projection depth
    shader.setFloat(idx++, dimension);

    // VIB3+ COMPLETE 6D ROTATION SYSTEM
    // 3D space rotations (modulated by audio)
    shader.setFloat(idx++, rot4dXY + bassEnergy * 0.2);  // u_rot4dXY
    shader.setFloat(idx++, rot4dXZ + midEnergy * 0.15);  // u_rot4dXZ
    shader.setFloat(idx++, rot4dYZ + highEnergy * 0.1);  // u_rot4dYZ
    // 4D hyperspace rotations (modulated by audio)
    shader.setFloat(idx++, rot4dXW + bassEnergy * 0.3);  // u_rot4dXW
    shader.setFloat(idx++, rot4dYW + midEnergy * 0.25);  // u_rot4dYW
    shader.setFloat(idx++, rot4dZW + highEnergy * 0.2);  // u_rot4dZW

    // u_mouseIntensity (float)
    shader.setFloat(idx++, mouseIntensity);

    // u_clickIntensity (float)
    shader.setFloat(idx++, clickIntensity);

    // System-specific uniforms
    if (systemType.toLowerCase() == 'quantum') {
      // u_layerIndex for quantum shader (0-4)
      shader.setFloat(idx++, 2.0); // Content layer by default
    } else if (systemType.toLowerCase() == 'holographic') {
      // u_layerSeparation for holographic shader
      shader.setFloat(idx++, layerSeparation);
    }

    final paint = Paint()..shader = shader;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_VIB3ShaderPainter oldDelegate) => true;
}
