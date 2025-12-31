/**
 * VIB3+ Native Flutter Widget
 *
 * Complete Flutter widget for VIB3+ 4D visualization.
 * Features:
 * - 60 FPS animation loop with vsync
 * - Touch/gesture interaction for rotation
 * - Automatic audio reactivity integration
 * - All three visual systems (Quantum, Holographic, Faceted)
 * - All 24 geometries with smooth transitions
 *
 * Usage:
 * ```dart
 * VIB3Widget(
 *   system: VisualSystem.quantum,
 *   geometryIndex: 0,
 *   audioData: audioAnalysisData,
 *   onStateChanged: (state) => print(state),
 * )
 * ```
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/vib3_engine.dart';
import '../rendering/visual_system_renderer.dart';
import '../audio/audio_reactive_modulator.dart';
import '../effects/post_processing.dart';

/// Main VIB3+ visualization widget
class VIB3Widget extends StatefulWidget {
  /// Visual system type
  final VisualSystem system;

  /// Geometry index (0-23)
  final int geometryIndex;

  /// Audio reactivity data (optional)
  final AudioReactivityData? audioData;

  /// Audio reactivity strength (0-1)
  final double audioReactivityStrength;

  /// Enable demo mode with simulated audio
  final bool demoMode;

  /// Base hue shift (0-360)
  final double hueShift;

  /// Glow intensity (0-3)
  final double glowIntensity;

  /// Auto-rotation speed (0 = disabled)
  final double autoRotateSpeed;

  /// Enable touch interaction
  final bool enableInteraction;

  /// Callback when state changes
  final ValueChanged<VIB3EngineState>? onStateChanged;

  /// Custom post-processing config
  final PostProcessingConfig? effectsConfig;

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
    this.effectsConfig,
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
    _modulator = AudioReactiveModulator(
      config: _getModulationConfig(),
    );
    _testAudioGen = TestAudioGenerator();

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

    // Update state when widget properties change
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

        // Update modulator config if system changed
        if (oldWidget.system != widget.system) {
          _modulator = AudioReactiveModulator(
            config: _getModulationConfig(),
          );
        }
      });
    }
  }

  void _onTick(Duration elapsed) {
    final elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
    final deltaTime = elapsedSeconds - _lastTickTime;
    _lastTickTime = elapsedSeconds;
    _time = elapsedSeconds;

    // Get audio data
    AudioReactivityData audioData;
    if (widget.demoMode) {
      audioData = _testAudioGen.generate(_time);
    } else {
      audioData = widget.audioData ?? AudioReactivityData.silent;
    }

    // Update modulator
    _modulator.update(audioData, _time);

    // Update state with auto-rotation and audio modulation
    _updateState(deltaTime);

    // Trigger repaint
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState(double deltaTime) {
    // Apply interaction rotations
    var newState = _state.copyWith(
      rotationXY: _state.rotationXY + _interactionRotationXY,
      rotationXZ: _state.rotationXZ + _interactionRotationXZ,
      rotationXW: _state.rotationXW + _interactionRotationXW,
      rotationYW: _state.rotationYW + _interactionRotationYW,
    );

    // Apply auto-rotation
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

    // Apply audio modulation
    newState = _modulator.applyToState(newState);

    // Decay interaction rotations
    _interactionRotationXY *= 0.95;
    _interactionRotationXZ *= 0.95;
    _interactionRotationXW *= 0.95;
    _interactionRotationYW *= 0.95;

    _state = newState;

    // Notify listener
    widget.onStateChanged?.call(_state);
  }

  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null) return;

    final delta = details.localPosition - _lastPanPosition!;
    _lastPanPosition = details.localPosition;

    // Map horizontal drag to XY rotation, vertical to XZ rotation
    _interactionRotationXY += delta.dx * 0.01;
    _interactionRotationXZ += delta.dy * 0.01;
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;

    // Add momentum from velocity
    final velocity = details.velocity.pixelsPerSecond;
    _interactionRotationXY += velocity.dx * 0.0001;
    _interactionRotationXZ += velocity.dy * 0.0001;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Two-finger rotation for 4D rotations
    if (details.pointerCount >= 2) {
      _interactionRotationXW += details.rotation * 0.1;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget painter = CustomPaint(
      painter: _VIB3Painter(
        state: _state,
        time: _time,
        effectsConfig: widget.effectsConfig,
      ),
      size: Size.infinite,
    );

    // Add interaction gestures
    if (widget.enableInteraction) {
      painter = GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onScaleUpdate: _handleScaleUpdate,
        child: painter,
      );
    }

    return painter;
  }
}

/// Custom painter for VIB3+ visualization
class _VIB3Painter extends CustomPainter {
  final VIB3EngineState state;
  final double time;
  final PostProcessingConfig? effectsConfig;

  _VIB3Painter({
    required this.state,
    required this.time,
    this.effectsConfig,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final renderer = VisualSystemRendererFactory.create(
      state: state,
      canvasSize: size,
      time: time,
      effectsConfig: effectsConfig,
    );

    renderer.render(canvas);
  }

  @override
  bool shouldRepaint(_VIB3Painter oldDelegate) {
    return time != oldDelegate.time ||
        state.system != oldDelegate.state.system ||
        state.geometryIndex != oldDelegate.state.geometryIndex;
  }
}

/// Stateless version for simple embedding
class VIB3StaticWidget extends StatelessWidget {
  final VIB3EngineState state;
  final double time;
  final PostProcessingConfig? effectsConfig;

  const VIB3StaticWidget({
    super.key,
    required this.state,
    required this.time,
    this.effectsConfig,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VIB3Painter(
        state: state,
        time: time,
        effectsConfig: effectsConfig,
      ),
      size: Size.infinite,
    );
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

  void nextGeometry() {
    setGeometry((_state.geometryIndex + 1) % 24);
  }

  void previousGeometry() {
    setGeometry((_state.geometryIndex - 1 + 24) % 24);
  }

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

/// Controlled VIB3+ widget using a controller
class VIB3ControlledWidget extends StatefulWidget {
  final VIB3Controller controller;
  final bool enableInteraction;
  final PostProcessingConfig? effectsConfig;

  const VIB3ControlledWidget({
    super.key,
    required this.controller,
    this.enableInteraction = true,
    this.effectsConfig,
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
    return VIB3StaticWidget(
      state: widget.controller.state,
      time: _time,
      effectsConfig: widget.effectsConfig,
    );
  }
}
