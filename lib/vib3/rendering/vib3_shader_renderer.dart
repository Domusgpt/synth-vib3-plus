/**
 * VIB3+ Shader-Based Renderer
 *
 * Native Flutter implementation using FragmentShader API.
 * Renders VIB3+ 4D visualization with per-pixel SDF computation
 * matching VIB3-CORE WebGL rendering quality.
 *
 * A Paul Phillips Manifestation
 * (c) 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/vib3_engine.dart';
import '../../debug/debug_console.dart';

/// Shader uniform indices (must match shader uniform order)
class _ShaderUniforms {
  static const int resolutionX = 0;
  static const int resolutionY = 1;
  static const int time = 2;
  static const int system = 3;
  static const int geometry = 4;
  static const int rotXY = 5;
  static const int rotXZ = 6;
  static const int rotYZ = 7;
  static const int rotXW = 8;
  static const int rotYW = 9;
  static const int rotZW = 10;
  static const int hue = 11;
  static const int saturation = 12;
  static const int brightness = 13;
  static const int glowIntensity = 14;
  static const int rgbSplit = 15;
  static const int morphFactor = 16;
  static const int chaos = 17;
  static const int gridDensity = 18;
  static const int bassEnergy = 19;
  static const int midEnergy = 20;
  static const int highEnergy = 21;
  static const int rmsAmplitude = 22;
}

/// Loads and caches the VIB3+ shader
class VIB3ShaderLoader {
  static ui.FragmentProgram? _program;
  static bool _loading = false;
  static final List<VoidCallback> _callbacks = [];

  /// Load shader asynchronously
  static Future<ui.FragmentProgram> load() async {
    if (_program != null) return _program!;

    if (_loading) {
      // Wait for existing load to complete
      final completer = Completer<ui.FragmentProgram>();
      _callbacks.add(() => completer.complete(_program));
      return completer.future;
    }

    _loading = true;
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/vib3_core.frag');
      for (final callback in _callbacks) {
        callback();
      }
      _callbacks.clear();
      return _program!;
    } finally {
      _loading = false;
    }
  }

  /// Check if shader is loaded
  static bool get isLoaded => _program != null;

  /// Get loaded program (throws if not loaded)
  static ui.FragmentProgram get program {
    if (_program == null) {
      throw StateError('Shader not loaded. Call load() first.');
    }
    return _program!;
  }
}

/// CustomPainter that renders VIB3+ using the fragment shader
class VIB3ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final VIB3EngineState state;
  final double time;

  VIB3ShaderPainter({
    required this.shader,
    required this.state,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set all uniforms (must match shader uniform order)
    shader.setFloat(_ShaderUniforms.resolutionX, size.width);
    shader.setFloat(_ShaderUniforms.resolutionY, size.height);
    shader.setFloat(_ShaderUniforms.time, time);

    final systemFloat = _systemToFloat(state.system);
    // DEBUG: Log system value periodically (every ~60 frames)
    if ((time * 60).toInt() % 60 == 0) {
      debugPrint('🎨 SHADER: system=${state.system} → u_system=$systemFloat, geo=${state.geometryIndex}');
    }
    shader.setFloat(_ShaderUniforms.system, systemFloat);
    shader.setFloat(_ShaderUniforms.geometry, state.geometryIndex.toDouble());

    // 6D Rotation
    shader.setFloat(_ShaderUniforms.rotXY, state.rotationXY);
    shader.setFloat(_ShaderUniforms.rotXZ, state.rotationXZ);
    shader.setFloat(_ShaderUniforms.rotYZ, state.rotationYZ);
    shader.setFloat(_ShaderUniforms.rotXW, state.rotationXW);
    shader.setFloat(_ShaderUniforms.rotYW, state.rotationYW);
    shader.setFloat(_ShaderUniforms.rotZW, state.rotationZW);

    // Visual parameters
    shader.setFloat(_ShaderUniforms.hue, state.hueShift);
    shader.setFloat(_ShaderUniforms.saturation, state.saturation);
    shader.setFloat(_ShaderUniforms.brightness, state.vertexBrightness);
    shader.setFloat(_ShaderUniforms.glowIntensity, state.glowIntensity);
    shader.setFloat(_ShaderUniforms.rgbSplit, state.rgbSplitAmount);
    shader.setFloat(_ShaderUniforms.morphFactor, state.morphParameter);
    shader.setFloat(_ShaderUniforms.chaos, state.chaosAmount);
    shader.setFloat(_ShaderUniforms.gridDensity, state.tessellationDensity.toDouble());

    // Audio reactivity
    shader.setFloat(_ShaderUniforms.bassEnergy, state.audioData.bassEnergy);
    shader.setFloat(_ShaderUniforms.midEnergy, state.audioData.midEnergy);
    shader.setFloat(_ShaderUniforms.highEnergy, state.audioData.highEnergy);
    shader.setFloat(_ShaderUniforms.rmsAmplitude, state.audioData.rmsAmplitude);

    // Draw fullscreen quad with shader
    final paint = Paint()..shader = shader;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  double _systemToFloat(VisualSystem system) {
    switch (system) {
      case VisualSystem.quantum:
        return 0.0;
      case VisualSystem.faceted:
        return 1.0;
      case VisualSystem.holographic:
        return 2.0;
    }
  }

  @override
  bool shouldRepaint(VIB3ShaderPainter oldDelegate) {
    // Always repaint for animation
    return true;
  }
}

/// Widget that renders VIB3+ using the native shader
class VIB3ShaderWidget extends StatefulWidget {
  final VIB3EngineState state;
  final double time;

  const VIB3ShaderWidget({
    super.key,
    required this.state,
    required this.time,
  });

  @override
  State<VIB3ShaderWidget> createState() => _VIB3ShaderWidgetState();
}

class _VIB3ShaderWidgetState extends State<VIB3ShaderWidget> {
  ui.FragmentShader? _shader;
  bool _loadError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await VIB3ShaderLoader.load();
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
        DebugConsole.success('VIB3+ shader loaded successfully');
        DebugStatus().update(shaderLoaded: true, shaderError: null);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = true;
          _errorMessage = e.toString();
        });
        DebugConsole.error('Shader load failed: $e');
        DebugStatus().update(shaderLoaded: false, shaderError: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError) {
      return _buildErrorWidget();
    }

    if (_shader == null) {
      return _buildLoadingWidget();
    }

    return CustomPaint(
      painter: VIB3ShaderPainter(
        shader: _shader!,
        state: widget.state,
        time: widget.time,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.cyan,
            ),
            SizedBox(height: 16),
            Text(
              'Loading VIB3+ Shader...',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Shader Load Error',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated VIB3+ shader widget with internal ticker
class VIB3AnimatedShaderWidget extends StatefulWidget {
  final VisualSystem system;
  final int geometryIndex;
  final AudioReactivityData? audioData;
  final double audioReactivityStrength;
  final double hueShift;
  final double glowIntensity;
  final double autoRotateSpeed;
  final bool enableInteraction;
  final ValueChanged<VIB3EngineState>? onStateChanged;

  // External rotation overrides (from sliders/VisualProvider)
  final double? externalRotationXY;
  final double? externalRotationXZ;
  final double? externalRotationYZ;
  final double? externalRotationXW;
  final double? externalRotationYW;
  final double? externalRotationZW;

  // Other visual parameters
  final double? saturation;
  final double? morphParameter;
  final double? chaosAmount;
  final int? tessellationDensity;

  const VIB3AnimatedShaderWidget({
    super.key,
    this.system = VisualSystem.quantum,
    this.geometryIndex = 0,
    this.audioData,
    this.audioReactivityStrength = 0.5,
    this.hueShift = 200.0,
    this.glowIntensity = 1.0,
    this.autoRotateSpeed = 0.3,
    this.enableInteraction = true,
    this.onStateChanged,
    // External rotations
    this.externalRotationXY,
    this.externalRotationXZ,
    this.externalRotationYZ,
    this.externalRotationXW,
    this.externalRotationYW,
    this.externalRotationZW,
    // Other params
    this.saturation,
    this.morphParameter,
    this.chaosAmount,
    this.tessellationDensity,
  });

  @override
  State<VIB3AnimatedShaderWidget> createState() => _VIB3AnimatedShaderWidgetState();
}

class _VIB3AnimatedShaderWidgetState extends State<VIB3AnimatedShaderWidget>
    with SingleTickerProviderStateMixin {

  late Ticker _ticker;
  double _time = 0.0;
  double _lastTickTime = 0.0;
  int _frameCount = 0;
  double _lastFpsUpdateTime = 0.0;
  double _fps = 0.0;

  late VIB3EngineState _state;

  // Interaction state
  double _interactionRotationXY = 0.0;
  double _interactionRotationXZ = 0.0;
  double _interactionRotationXW = 0.0;
  double _interactionRotationYW = 0.0;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _initializeState() {
    _state = VIB3EngineState(
      system: widget.system,
      geometryIndex: widget.geometryIndex,
      hueShift: widget.hueShift,
      glowIntensity: widget.glowIntensity,
      autoRotateSpeed: widget.autoRotateSpeed,
      audioReactivityStrength: widget.audioReactivityStrength,
    );
  }

  @override
  void didUpdateWidget(VIB3AnimatedShaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if any props changed
    final needsUpdate = oldWidget.system != widget.system ||
        oldWidget.geometryIndex != widget.geometryIndex ||
        oldWidget.hueShift != widget.hueShift ||
        oldWidget.glowIntensity != widget.glowIntensity ||
        oldWidget.autoRotateSpeed != widget.autoRotateSpeed ||
        oldWidget.saturation != widget.saturation ||
        oldWidget.morphParameter != widget.morphParameter ||
        oldWidget.chaosAmount != widget.chaosAmount ||
        oldWidget.tessellationDensity != widget.tessellationDensity ||
        oldWidget.externalRotationXY != widget.externalRotationXY ||
        oldWidget.externalRotationXZ != widget.externalRotationXZ ||
        oldWidget.externalRotationYZ != widget.externalRotationYZ ||
        oldWidget.externalRotationXW != widget.externalRotationXW ||
        oldWidget.externalRotationYW != widget.externalRotationYW ||
        oldWidget.externalRotationZW != widget.externalRotationZW;

    if (needsUpdate) {
      setState(() {
        _state = _state.copyWith(
          system: widget.system,
          geometryIndex: widget.geometryIndex,
          hueShift: widget.hueShift,
          glowIntensity: widget.glowIntensity,
          autoRotateSpeed: widget.autoRotateSpeed,
          audioReactivityStrength: widget.audioReactivityStrength,
          saturation: widget.saturation ?? _state.saturation,
          morphParameter: widget.morphParameter ?? _state.morphParameter,
          chaosAmount: widget.chaosAmount ?? _state.chaosAmount,
          tessellationDensity: widget.tessellationDensity ?? _state.tessellationDensity,
        );
      });
    }
  }

  void _onTick(Duration elapsed) {
    final elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
    final deltaTime = elapsedSeconds - _lastTickTime;
    _lastTickTime = elapsedSeconds;
    _time = elapsedSeconds;

    // FPS calculation
    _frameCount++;
    if (elapsedSeconds - _lastFpsUpdateTime >= 1.0) {
      _fps = _frameCount / (elapsedSeconds - _lastFpsUpdateTime);
      _frameCount = 0;
      _lastFpsUpdateTime = elapsedSeconds;

      // Update debug status with visual state
      final systemName = _state.system.toString().split('.').last;
      DebugStatus().update(
        visualSystem: systemName,
        geometryIndex: _state.geometryIndex,
        morphParameter: _state.morphParameter,
        gridDensity: _state.tessellationDensity.toDouble(),
        fps: _fps,
        shaderTime: _time,
      );
    }

    _updateState(deltaTime);

    if (mounted) {
      setState(() {});
    }
  }

  void _updateState(double deltaTime) {
    // Get audio data
    final audioData = widget.audioData ?? AudioReactivityData.silent;

    // Start with current rotations
    double newRotXY = _state.rotationXY;
    double newRotXZ = _state.rotationXZ;
    double newRotYZ = _state.rotationYZ;
    double newRotXW = _state.rotationXW;
    double newRotYW = _state.rotationYW;
    double newRotZW = _state.rotationZW;

    // If external rotations provided (from sliders), use them directly
    // Otherwise apply auto-rotation + interaction
    final hasExternalRotation = widget.externalRotationXY != null ||
        widget.externalRotationXZ != null ||
        widget.externalRotationYZ != null ||
        widget.externalRotationXW != null ||
        widget.externalRotationYW != null ||
        widget.externalRotationZW != null;

    if (hasExternalRotation) {
      // Use external values when provided (add auto-rotation on top)
      final rotSpeed = widget.autoRotateSpeed * deltaTime;
      final audioBoost = 1.0 + audioData.bassEnergy * widget.audioReactivityStrength * 0.3;

      newRotXY = (widget.externalRotationXY ?? 0) + rotSpeed * 0.2 * audioBoost;
      newRotXZ = (widget.externalRotationXZ ?? 0) + rotSpeed * 0.15 * audioBoost;
      newRotYZ = (widget.externalRotationYZ ?? 0) + rotSpeed * 0.1;
      newRotXW = (widget.externalRotationXW ?? 0) + rotSpeed * 0.12;
      newRotYW = (widget.externalRotationYW ?? 0) + rotSpeed * 0.08;
      newRotZW = (widget.externalRotationZW ?? 0) + rotSpeed * 0.05;
    } else {
      // Apply interaction rotations
      newRotXY += _interactionRotationXY;
      newRotXZ += _interactionRotationXZ;
      newRotXW += _interactionRotationXW;
      newRotYW += _interactionRotationYW;

      // Apply auto-rotation
      if (widget.autoRotateSpeed > 0) {
        final rotSpeed = widget.autoRotateSpeed * deltaTime;
        final audioBoost = 1.0 + audioData.bassEnergy * widget.audioReactivityStrength;

        newRotXY += rotSpeed * 0.7 * audioBoost;
        newRotXZ += rotSpeed * 0.5 * audioBoost;
        newRotYZ += rotSpeed * 0.3;
        newRotXW += rotSpeed * 0.4;
        newRotYW += rotSpeed * 0.25;
        newRotZW += rotSpeed * 0.15;
      }

      // Decay interaction rotations
      _interactionRotationXY *= 0.95;
      _interactionRotationXZ *= 0.95;
      _interactionRotationXW *= 0.95;
      _interactionRotationYW *= 0.95;
    }

    var newState = _state.copyWith(
      rotationXY: newRotXY,
      rotationXZ: newRotXZ,
      rotationYZ: newRotYZ,
      rotationXW: newRotXW,
      rotationYW: newRotYW,
      rotationZW: newRotZW,
      audioData: audioData,
    );

    _state = newState;
    widget.onStateChanged?.call(_state);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_lastPanPosition != null) {
      final delta = details.localFocalPoint - _lastPanPosition!;
      _lastPanPosition = details.localFocalPoint;

      _interactionRotationXY += delta.dx * 0.01;
      _interactionRotationXZ += delta.dy * 0.01;
    }

    if (details.pointerCount >= 2) {
      _interactionRotationXW += details.rotation * 0.1;
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastPanPosition = null;

    final velocity = details.velocity.pixelsPerSecond;
    _interactionRotationXY += velocity.dx * 0.0001;
    _interactionRotationXZ += velocity.dy * 0.0001;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = VIB3ShaderWidget(
      state: _state,
      time: _time,
    );

    if (widget.enableInteraction) {
      child = GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: child,
      );
    }

    return child;
  }
}
