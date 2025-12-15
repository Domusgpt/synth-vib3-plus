/**
 * VIB3+ Native Widget
 *
 * Flutter CustomPainter-based visualization widget that bypasses WebView.
 * Uses the native VIB3NativeRenderer for performant, reliable 4D rendering.
 *
 * Features:
 * - Direct Flutter rendering (no WebView overhead)
 * - 60 FPS animation loop
 * - Full audio reactivity support
 * - Integration with VisualProvider
 *
 * Use this widget when WebView fails to load or for better performance.
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../vib3/rendering/vib3_native_renderer.dart';
import '../providers/visual_provider.dart';
import '../providers/audio_provider.dart';
import '../audio/audio_analyzer.dart';

class VIB3NativeWidget extends StatefulWidget {
  /// Callback when geometry changes
  final Function(int geometryIndex)? onGeometryChanged;

  /// Callback when visual system changes
  final Function(String system)? onSystemChanged;

  /// Enable/disable audio reactivity
  final bool audioReactive;

  const VIB3NativeWidget({
    Key? key,
    this.onGeometryChanged,
    this.onSystemChanged,
    this.audioReactive = true,
  }) : super(key: key);

  @override
  State<VIB3NativeWidget> createState() => _VIB3NativeWidgetState();
}

class _VIB3NativeWidgetState extends State<VIB3NativeWidget>
    with SingleTickerProviderStateMixin {
  // Animation controller for 60 FPS rendering
  late AnimationController _animationController;

  // Time tracking for animation
  double _time = 0.0;
  DateTime _lastFrame = DateTime.now();

  // Audio features for reactivity
  AudioFeatures? _audioFeatures;

  // Rotation accumulation (continuous rotation)
  double _rotationXY = 0.0;
  double _rotationXZ = 0.0;
  double _rotationYZ = 0.0;
  double _rotationXW = 0.0;
  double _rotationYW = 0.0;
  double _rotationZW = 0.0;

  @override
  void initState() {
    super.initState();

    // 60 FPS animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _animationController.addListener(_onFrame);
  }

  @override
  void dispose() {
    _animationController.removeListener(_onFrame);
    _animationController.dispose();
    super.dispose();
  }

  void _onFrame() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastFrame).inMicroseconds / 1000000.0;
    _lastFrame = now;

    // Update time
    _time += deltaTime;

    // Get providers
    final visualProvider = context.read<VisualProvider>();
    final audioProvider = context.read<AudioProvider>();

    // Get audio features for reactivity
    if (widget.audioReactive && audioProvider.isInitialized) {
      final buffer = audioProvider.getCurrentBuffer();
      if (buffer != null) {
        _audioFeatures = audioProvider.analyzer.analyze(buffer);
      }
    }

    // Update rotations based on visual provider speed
    final speed = visualProvider.rotationSpeed;
    _rotationXY += deltaTime * 0.5 * speed;
    _rotationXZ += deltaTime * 0.3 * speed;
    _rotationYZ += deltaTime * 0.2 * speed;
    _rotationXW += deltaTime * 0.4 * speed;
    _rotationYW += deltaTime * 0.25 * speed;
    _rotationZW += deltaTime * 0.35 * speed;

    // Trigger repaint
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VisualProvider, AudioProvider>(
      builder: (context, visualProvider, audioProvider, child) {
        // Build render configuration from providers
        final config = VIB3RenderConfig(
          system: visualProvider.currentSystemName,
          geometryIndex: visualProvider.geometryIndex,
          rotationXY: _rotationXY,
          rotationXZ: _rotationXZ,
          rotationYZ: _rotationYZ,
          rotationXW: _rotationXW,
          rotationYW: _rotationYW,
          rotationZW: _rotationZW,
          rotationSpeed: visualProvider.rotationSpeed,
          tessellationDensity: visualProvider.tessellationDensity,
          vertexBrightness: visualProvider.vertexBrightness,
          hueShift: visualProvider.hueShift,
          glowIntensity: visualProvider.glowIntensity,
          morphParameter: visualProvider.morphParameter,
          projectionDistance: 8.0,
          layerSeparation: 2.0,
          // Audio reactivity
          bassEnergy: _audioFeatures?.bassEnergy ?? 0.0,
          midEnergy: _audioFeatures?.midEnergy ?? 0.0,
          highEnergy: _audioFeatures?.highEnergy ?? 0.0,
          rmsAmplitude: _audioFeatures?.rmsAmplitude ?? 0.0,
        );

        return RepaintBoundary(
          child: CustomPaint(
            painter: VIB3NativeRenderer(
              config: config,
              time: _time,
            ),
            size: Size.infinite,
            isComplex: true,
            willChange: true,
          ),
        );
      },
    );
  }
}

/// Wrapper widget that provides a loading indicator and error handling
class VIB3NativeWidgetWithFallback extends StatelessWidget {
  final bool audioReactive;
  final Function(int)? onGeometryChanged;
  final Function(String)? onSystemChanged;

  const VIB3NativeWidgetWithFallback({
    Key? key,
    this.audioReactive = true,
    this.onGeometryChanged,
    this.onSystemChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // Show loading indicator while audio provider initializes
        if (!audioProvider.isInitialized) {
          return Container(
            color: const Color(0xFF0A0A0A),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFFF)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing VIB3+...',
                    style: TextStyle(
                      color: Color(0xFF00FFFF),
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Render the native widget
        return VIB3NativeWidget(
          audioReactive: audioReactive,
          onGeometryChanged: onGeometryChanged,
          onSystemChanged: onSystemChanged,
        );
      },
    );
  }
}
