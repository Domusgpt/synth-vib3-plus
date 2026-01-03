/**
 * VIB3+ Native Flutter Widget
 *
 * Complete Flutter widget for VIB3+ 4D visualization using native GPU shaders.
 * NO WebView, NO wireframe - pure Flutter FragmentShader rendering.
 *
 * Features:
 * - 60 FPS animation loop with vsync
 * - Touch/gesture interaction for rotation
 * - Automatic audio reactivity integration
 * - All three visual systems (Quantum, Holographic, Faceted)
 * - All 24 geometries with smooth transitions
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/vib3_engine.dart';
import '../rendering/vib3_shader_renderer.dart';
import '../audio/audio_reactive_modulator.dart';
import '../../debug/debug_console.dart';

/// Main VIB3+ visualization widget - Native shader rendering only
class VIB3Widget extends StatefulWidget {
  final VisualSystem system;
  final int geometryIndex;
  final AudioReactivityData? audioData;
  final double audioReactivityStrength;
  final bool demoMode;
  final double hueShift;
  final double glowIntensity;
  final double autoRotateSpeed;
  final bool enableInteraction;
  final ValueChanged<VIB3EngineState>? onStateChanged;

  const VIB3Widget({
    super.key,
    this.system = VisualSystem.quantum,
    this.geometryIndex = 0,
    this.audioData,
    this.audioReactivityStrength = 0.5,
    this.demoMode = false,
    this.hueShift = 200.0,
    this.glowIntensity = 1.0,
    this.autoRotateSpeed = 0.3,
    this.enableInteraction = true,
    this.onStateChanged,
  });

  @override
  State<VIB3Widget> createState() => _VIB3WidgetState();
}

class _VIB3WidgetState extends State<VIB3Widget>
    with SingleTickerProviderStateMixin {

  late Ticker _ticker;
  double _time = 0.0;
  double _lastTickTime = 0.0;

  late VIB3EngineState _state;
  late AudioReactiveModulator _modulator;
  late TestAudioGenerator _testAudioGen;

  // Shader state
  ui.FragmentShader? _shader;
  bool _shaderLoadError = false;
  String? _shaderErrorMessage;

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
    _modulator = AudioReactiveModulator(config: _getModulationConfig());
    _testAudioGen = TestAudioGenerator();
    _loadShader();
    _ticker = createTicker(_onTick);
    _ticker.start();
    // Update debug status with initial state
    _updateDebugStatus();
  }

  void _updateDebugStatus() {
    DebugStatus().update(
      visualSystem: widget.system.name.toUpperCase(),
      geometryIndex: widget.geometryIndex,
      morphParameter: _state.morphParameter,
      gridDensity: _state.tessellationDensity.toDouble(),
    );
  }

  Future<void> _loadShader() async {
    try {
      final program = await VIB3ShaderLoader.load();
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
        DebugStatus().update(shaderLoaded: true, shaderError: null);
      }
    } catch (e) {
      debugPrint('VIB3 Shader load error: $e');
      if (mounted) {
        setState(() {
          _shaderLoadError = true;
          _shaderErrorMessage = e.toString();
        });
        DebugStatus().update(shaderLoaded: false, shaderError: e.toString());
      }
    }
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

  ModulationConfig _getModulationConfig() {
    switch (widget.system) {
      case VisualSystem.quantum:
        return ModulationConfig.quantum();
      case VisualSystem.holographic:
        return ModulationConfig.holographic();
      case VisualSystem.faceted:
        return ModulationConfig.faceted();
    }
  }

  @override
  void didUpdateWidget(VIB3Widget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.system != widget.system ||
        oldWidget.geometryIndex != widget.geometryIndex ||
        oldWidget.hueShift != widget.hueShift ||
        oldWidget.glowIntensity != widget.glowIntensity ||
        oldWidget.autoRotateSpeed != widget.autoRotateSpeed) {
      setState(() {
        _state = _state.copyWith(
          system: widget.system,
          geometryIndex: widget.geometryIndex,
          hueShift: widget.hueShift,
          glowIntensity: widget.glowIntensity,
          autoRotateSpeed: widget.autoRotateSpeed,
          audioReactivityStrength: widget.audioReactivityStrength,
        );

        if (oldWidget.system != widget.system) {
          _modulator = AudioReactiveModulator(config: _getModulationConfig());
        }
      });

      // Update debug status when parameters change
      _updateDebugStatus();
    }
  }

  void _onTick(Duration elapsed) {
    final elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
    final deltaTime = elapsedSeconds - _lastTickTime;
    _lastTickTime = elapsedSeconds;
    _time = elapsedSeconds;

    AudioReactivityData audioData;
    if (widget.demoMode) {
      audioData = _testAudioGen.generate(_time);
    } else {
      audioData = widget.audioData ?? AudioReactivityData.silent;
    }

    _modulator.update(audioData, _time);
    _updateState(deltaTime);

    // Update FPS in debug status (every ~0.5 seconds)
    if ((elapsed.inMilliseconds % 500) < 20) {
      final fps = deltaTime > 0 ? (1.0 / deltaTime) : 60.0;
      DebugStatus().update(fps: fps, shaderTime: _time);
    }

    if (mounted) setState(() {});
  }

  void _updateState(double deltaTime) {
    var newState = _state.copyWith(
      rotationXY: _state.rotationXY + _interactionRotationXY,
      rotationXZ: _state.rotationXZ + _interactionRotationXZ,
      rotationXW: _state.rotationXW + _interactionRotationXW,
      rotationYW: _state.rotationYW + _interactionRotationYW,
    );

    if (widget.autoRotateSpeed > 0) {
      final rotSpeed = widget.autoRotateSpeed * deltaTime;
      final audioBoost = 1.0 + _modulator.smoothedAudio.bassEnergy *
          widget.audioReactivityStrength;

      newState = newState.copyWith(
        rotationXY: newState.rotationXY + rotSpeed * 0.7 * audioBoost,
        rotationXZ: newState.rotationXZ + rotSpeed * 0.5 * audioBoost,
        rotationYZ: newState.rotationYZ + rotSpeed * 0.3,
        rotationXW: newState.rotationXW + rotSpeed * 0.4,
        rotationYW: newState.rotationYW + rotSpeed * 0.25,
        rotationZW: newState.rotationZW + rotSpeed * 0.15,
      );
    }

    newState = _modulator.applyToState(newState);

    _interactionRotationXY *= 0.95;
    _interactionRotationXZ *= 0.95;
    _interactionRotationXW *= 0.95;
    _interactionRotationYW *= 0.95;

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
    Widget content;

    if (_shaderLoadError) {
      content = _buildErrorWidget();
    } else if (_shader == null) {
      content = _buildLoadingWidget();
    } else {
      content = CustomPaint(
        painter: VIB3ShaderPainter(
          shader: _shader!,
          state: _state,
          time: _time,
        ),
        size: Size.infinite,
      );
    }

    if (widget.enableInteraction) {
      content = GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: content,
      );
    }

    return content;
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyan, strokeWidth: 3),
            SizedBox(height: 20),
            Text(
              'VIB3+ INITIALIZING',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'SHADER ERROR',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _shaderErrorMessage ?? 'Unknown error',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateless shader widget
class VIB3StaticWidget extends StatelessWidget {
  final VIB3EngineState state;
  final double time;

  const VIB3StaticWidget({
    super.key,
    required this.state,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return VIB3ShaderWidget(state: state, time: time);
  }
}

/// Controller for programmatic VIB3+ control
class VIB3Controller extends ChangeNotifier {
  VIB3EngineState _state;
  final AudioReactiveModulator _modulator;

  VIB3Controller({
    VIB3EngineState? initialState,
    ModulationConfig? modulationConfig,
  }) : _state = initialState ?? const VIB3EngineState(),
       _modulator = AudioReactiveModulator(config: modulationConfig);

  VIB3EngineState get state => _state;

  void setSystem(VisualSystem system) {
    _state = _state.copyWith(system: system);
    notifyListeners();
  }

  void setGeometry(int index) {
    _state = _state.copyWith(geometryIndex: index % 24);
    notifyListeners();
  }

  void nextGeometry() => setGeometry((_state.geometryIndex + 1) % 24);
  void previousGeometry() => setGeometry((_state.geometryIndex - 1 + 24) % 24);

  void setRotation({
    double? xy, double? xz, double? yz,
    double? xw, double? yw, double? zw,
  }) {
    _state = _state.copyWith(
      rotationXY: xy ?? _state.rotationXY,
      rotationXZ: xz ?? _state.rotationXZ,
      rotationYZ: yz ?? _state.rotationYZ,
      rotationXW: xw ?? _state.rotationXW,
      rotationYW: yw ?? _state.rotationYW,
      rotationZW: zw ?? _state.rotationZW,
    );
    notifyListeners();
  }

  void setVisualParameters({
    double? hueShift,
    double? saturation,
    double? glowIntensity,
    double? vertexBrightness,
    double? rgbSplitAmount,
    double? morphParameter,
    double? chaosAmount,
  }) {
    _state = _state.copyWith(
      hueShift: hueShift ?? _state.hueShift,
      saturation: saturation ?? _state.saturation,
      glowIntensity: glowIntensity ?? _state.glowIntensity,
      vertexBrightness: vertexBrightness ?? _state.vertexBrightness,
      rgbSplitAmount: rgbSplitAmount ?? _state.rgbSplitAmount,
      morphParameter: morphParameter ?? _state.morphParameter,
      chaosAmount: chaosAmount ?? _state.chaosAmount,
    );
    notifyListeners();
  }

  void updateAudio(AudioReactivityData data, double time) {
    _modulator.update(data, time);
    _state = _modulator.applyToState(_state);
    notifyListeners();
  }

  void reset() {
    _state = const VIB3EngineState();
    _modulator.reset();
    notifyListeners();
  }
}

/// Controlled VIB3+ widget
class VIB3ControlledWidget extends StatefulWidget {
  final VIB3Controller controller;
  final bool enableInteraction;

  const VIB3ControlledWidget({
    super.key,
    required this.controller,
    this.enableInteraction = true,
  });

  @override
  State<VIB3ControlledWidget> createState() => _VIB3ControlledWidgetState();
}

class _VIB3ControlledWidgetState extends State<VIB3ControlledWidget>
    with SingleTickerProviderStateMixin {

  late Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    _time = elapsed.inMicroseconds / 1000000.0;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VIB3StaticWidget(state: widget.controller.state, time: _time);
  }
}
