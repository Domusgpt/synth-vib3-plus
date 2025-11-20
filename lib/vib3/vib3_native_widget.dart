/**
 * VIB3+ Native Widget
 *
 * Flutter widget that displays native VIB3+ visualization
 * Replaces WebView with pure Dart/Flutter rendering
 *
 * Integrates with:
 * - VisualProvider for visual parameters
 * - AudioProvider for audio reactivity
 * - ParameterBridge for bidirectional coupling
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../providers/visual_provider.dart';
import '../providers/audio_provider.dart';
import 'rendering/vib3_native_renderer.dart';

/// Native VIB3+ visualization widget
class VIB3NativeWidget extends StatefulWidget {
  const VIB3NativeWidget({Key? key}) : super(key: key);

  @override
  State<VIB3NativeWidget> createState() => _VIB3NativeWidgetState();
}

class _VIB3NativeWidgetState extends State<VIB3NativeWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late Stopwatch _stopwatch;
  double _time = 0.0;

  // FPS tracking
  int _frameCount = 0;
  double _fps = 60.0;
  DateTime _lastFpsUpdate = DateTime.now();

  // Audio reactivity values (smoothed)
  double _bassEnergy = 0.0;
  double _midEnergy = 0.0;
  double _highEnergy = 0.0;
  double _rmsAmplitude = 0.0;

  Timer? _audioUpdateTimer;

  @override
  void initState() {
    super.initState();

    _stopwatch = Stopwatch()..start();

    // Start animation ticker
    _ticker = createTicker(_onTick)..start();

    // Start audio reactivity updates (60 Hz to match visual frame rate)
    _audioUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 Hz
      _updateAudioReactivity,
    );

    // Notify VisualProvider that animation started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);
      visualProvider.startAnimation();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audioUpdateTimer?.cancel();

    // Notify VisualProvider that animation stopped
    final visualProvider = Provider.of<VisualProvider>(context, listen: false);
    visualProvider.stopAnimation();

    super.dispose();
  }

  /// Animation tick callback
  void _onTick(Duration elapsed) {
    setState(() {
      _time = _stopwatch.elapsed.inMicroseconds / 1000000.0;

      // Update FPS counter
      _frameCount++;
      final now = DateTime.now();
      final timeSinceLastUpdate = now.difference(_lastFpsUpdate).inMilliseconds;

      if (timeSinceLastUpdate >= 1000) {
        _fps = _frameCount / (timeSinceLastUpdate / 1000.0);
        _frameCount = 0;
        _lastFpsUpdate = now;

        // Update VisualProvider with current FPS
        final visualProvider = Provider.of<VisualProvider>(context, listen: false);
        visualProvider.updateFPS(_fps);
      }
    });
  }

  /// Update audio reactivity values
  void _updateAudioReactivity(Timer timer) {
    if (!mounted) return;

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // Get current FFT analysis (if available)
    // For now, use placeholder values - will be connected to actual FFT
    final newBassEnergy = audioProvider.isPlaying ? 0.3 : 0.0;
    final newMidEnergy = audioProvider.isPlaying ? 0.4 : 0.0;
    final newHighEnergy = audioProvider.isPlaying ? 0.2 : 0.0;
    final newRmsAmplitude = audioProvider.isPlaying ? 0.5 : 0.0;

    // Smooth audio reactivity with exponential moving average
    const smoothing = 0.3;
    setState(() {
      _bassEnergy = _bassEnergy * (1.0 - smoothing) + newBassEnergy * smoothing;
      _midEnergy = _midEnergy * (1.0 - smoothing) + newMidEnergy * smoothing;
      _highEnergy = _highEnergy * (1.0 - smoothing) + newHighEnergy * smoothing;
      _rmsAmplitude = _rmsAmplitude * (1.0 - smoothing) + newRmsAmplitude * smoothing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VisualProvider, AudioProvider>(
      builder: (context, visualProvider, audioProvider, child) {
        // Build render configuration from provider state
        final config = VIB3RenderConfig(
          system: visualProvider.currentSystem,
          geometryIndex: visualProvider.currentGeometry,
          rotationXY: _time * 0.5,
          rotationXZ: _time * 0.7,
          rotationYZ: _time * 0.3,
          rotationXW: visualProvider.rotationXW,
          rotationYW: visualProvider.rotationYW,
          rotationZW: visualProvider.rotationZW,
          rotationSpeed: visualProvider.rotationSpeed,
          tessellationDensity: visualProvider.tessellationDensity,
          vertexBrightness: visualProvider.vertexBrightness,
          hueShift: visualProvider.hueShift,
          glowIntensity: visualProvider.glowIntensity,
          rgbSplitAmount: visualProvider.rgbSplitAmount,
          morphParameter: visualProvider.morphParameter,
          projectionDistance: visualProvider.projectionDistance,
          layerSeparation: visualProvider.layerSeparation,
          bassEnergy: _bassEnergy,
          midEnergy: _midEnergy,
          highEnergy: _highEnergy,
          rmsAmplitude: _rmsAmplitude,
        );

        return Stack(
          children: [
            // Main visualization
            CustomPaint(
              painter: VIB3NativeRenderer(
                config: config,
                time: _time,
              ),
              size: Size.infinite,
            ),

            // FPS counter (debug overlay)
            if (visualProvider.currentFPS > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_fps.toStringAsFixed(0)} FPS',
                    style: TextStyle(
                      color: _fps >= 55 ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

            // Geometry info (debug overlay)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${visualProvider.currentSystem.toUpperCase()} • Geometry ${visualProvider.currentGeometry}',
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
