/**
 * VIB3+ 4D Visualization Engine
 *
 * Core engine managing:
 * - Animation loop (60 FPS target)
 * - 6D rotation state (XY, XZ, YZ, XW, YW, ZW)
 * - Visual system switching (Quantum, Holographic, Faceted)
 * - Audio-reactive parameter modulation
 * - Geometry morphing and tessellation
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Visual system types
enum VisualSystem {
  quantum,     // Pure harmonic synthesis aesthetic - high resonance
  holographic, // Spectral rich multi-layer depth field
  faceted,     // Geometric hybrid with dual-layer structure
}

/// Audio reactivity data from FFT analysis
class AudioReactivityData {
  final double bassEnergy;    // 20-250 Hz normalized 0-1
  final double midEnergy;     // 250-2000 Hz normalized 0-1
  final double highEnergy;    // 2000-8000 Hz normalized 0-1
  final double rmsAmplitude;  // Overall amplitude 0-1
  final double spectralCentroid; // Brightness measure in Hz

  const AudioReactivityData({
    this.bassEnergy = 0.0,
    this.midEnergy = 0.0,
    this.highEnergy = 0.0,
    this.rmsAmplitude = 0.0,
    this.spectralCentroid = 1000.0,
  });

  /// Silent audio (no reactivity)
  static const AudioReactivityData silent = AudioReactivityData();

  /// Create from FFT bins
  factory AudioReactivityData.fromFFT(List<double> bins, int sampleRate) {
    if (bins.isEmpty) return silent;

    final binCount = bins.length;
    final freqPerBin = sampleRate / (binCount * 2);

    // Calculate bass (20-250 Hz)
    final bassStart = (20 / freqPerBin).floor().clamp(0, binCount - 1);
    final bassEnd = (250 / freqPerBin).ceil().clamp(0, binCount - 1);
    var bassSum = 0.0;
    for (var i = bassStart; i <= bassEnd; i++) {
      bassSum += bins[i];
    }
    final bassEnergy = (bassSum / (bassEnd - bassStart + 1)).clamp(0.0, 1.0);

    // Calculate mid (250-2000 Hz)
    final midStart = (250 / freqPerBin).floor().clamp(0, binCount - 1);
    final midEnd = (2000 / freqPerBin).ceil().clamp(0, binCount - 1);
    var midSum = 0.0;
    for (var i = midStart; i <= midEnd; i++) {
      midSum += bins[i];
    }
    final midEnergy = (midSum / (midEnd - midStart + 1)).clamp(0.0, 1.0);

    // Calculate high (2000-8000 Hz)
    final highStart = (2000 / freqPerBin).floor().clamp(0, binCount - 1);
    final highEnd = (8000 / freqPerBin).ceil().clamp(0, binCount - 1);
    var highSum = 0.0;
    for (var i = highStart; i <= highEnd; i++) {
      highSum += bins[i];
    }
    final highEnergy = (highSum / (highEnd - highStart + 1)).clamp(0.0, 1.0);

    // Calculate RMS
    var rmsSum = 0.0;
    for (final bin in bins) {
      rmsSum += bin * bin;
    }
    final rmsAmplitude = math.sqrt(rmsSum / binCount).clamp(0.0, 1.0);

    // Calculate spectral centroid
    var weightedSum = 0.0;
    var totalEnergy = 0.0;
    for (var i = 0; i < binCount; i++) {
      final freq = i * freqPerBin;
      weightedSum += freq * bins[i];
      totalEnergy += bins[i];
    }
    final spectralCentroid = totalEnergy > 0
        ? weightedSum / totalEnergy
        : 1000.0;

    return AudioReactivityData(
      bassEnergy: bassEnergy,
      midEnergy: midEnergy,
      highEnergy: highEnergy,
      rmsAmplitude: rmsAmplitude,
      spectralCentroid: spectralCentroid,
    );
  }

  @override
  String toString() =>
    'AudioReactivity(bass: ${bassEnergy.toStringAsFixed(2)}, '
    'mid: ${midEnergy.toStringAsFixed(2)}, '
    'high: ${highEnergy.toStringAsFixed(2)}, '
    'rms: ${rmsAmplitude.toStringAsFixed(2)})';
}

/// Complete VIB3+ engine state
class VIB3EngineState {
  // System selection
  final VisualSystem system;
  final int geometryIndex; // 0-23

  // 6D rotation angles (radians)
  final double rotationXY;
  final double rotationXZ;
  final double rotationYZ;
  final double rotationXW;
  final double rotationYW;
  final double rotationZW;

  // Animation parameters
  final double animationSpeed;     // Base animation speed multiplier
  final double autoRotateSpeed;    // Auto-rotation speed (0 = disabled)

  // Visual parameters
  final int tessellationDensity;   // Grid subdivision level 3-10
  final double vertexBrightness;   // Vertex intensity 0-1
  final double hueShift;           // Color hue offset 0-360°
  final double saturation;         // Color saturation 0-1
  final double glowIntensity;      // Bloom/glow amount 0-3
  final double rgbSplitAmount;     // Chromatic aberration 0-10
  final double morphParameter;     // Geometry morphing 0-1
  final double chaosAmount;        // Noise/randomization 0-1

  // Projection parameters
  final double projectionDistance; // Camera distance 5-20
  final double fieldOfView;        // FOV in degrees 30-120
  final double layerSeparation;    // Holographic depth 0-5

  // Audio reactivity
  final AudioReactivityData audioData;
  final double audioReactivityStrength; // 0-1 how much audio affects visuals

  const VIB3EngineState({
    this.system = VisualSystem.quantum,
    this.geometryIndex = 0,
    this.rotationXY = 0.0,
    this.rotationXZ = 0.0,
    this.rotationYZ = 0.0,
    this.rotationXW = 0.0,
    this.rotationYW = 0.0,
    this.rotationZW = 0.0,
    this.animationSpeed = 1.0,
    this.autoRotateSpeed = 0.3,
    this.tessellationDensity = 5,
    this.vertexBrightness = 0.8,
    this.hueShift = 200.0,
    this.saturation = 0.8,
    this.glowIntensity = 1.0,
    this.rgbSplitAmount = 0.0,
    this.morphParameter = 0.0,
    this.chaosAmount = 0.2,
    this.projectionDistance = 8.0,
    this.fieldOfView = 60.0,
    this.layerSeparation = 2.0,
    this.audioData = AudioReactivityData.silent,
    this.audioReactivityStrength = 0.5,
  });

  /// Create quantum system preset
  factory VIB3EngineState.quantum({int geometryIndex = 0}) {
    return VIB3EngineState(
      system: VisualSystem.quantum,
      geometryIndex: geometryIndex,
      hueShift: 200.0,
      saturation: 0.9,
      glowIntensity: 1.2,
      vertexBrightness: 0.9,
    );
  }

  /// Create holographic system preset
  factory VIB3EngineState.holographic({int geometryIndex = 0}) {
    return VIB3EngineState(
      system: VisualSystem.holographic,
      geometryIndex: geometryIndex,
      hueShift: 280.0,
      saturation: 0.75,
      glowIntensity: 2.0,
      layerSeparation: 3.0,
      rgbSplitAmount: 2.0,
      vertexBrightness: 0.7,
    );
  }

  /// Create faceted system preset
  factory VIB3EngineState.faceted({int geometryIndex = 0}) {
    return VIB3EngineState(
      system: VisualSystem.faceted,
      geometryIndex: geometryIndex,
      hueShift: 160.0,
      saturation: 0.85,
      glowIntensity: 0.8,
      vertexBrightness: 0.85,
    );
  }

  /// Copy with modifications
  VIB3EngineState copyWith({
    VisualSystem? system,
    int? geometryIndex,
    double? rotationXY,
    double? rotationXZ,
    double? rotationYZ,
    double? rotationXW,
    double? rotationYW,
    double? rotationZW,
    double? animationSpeed,
    double? autoRotateSpeed,
    int? tessellationDensity,
    double? vertexBrightness,
    double? hueShift,
    double? saturation,
    double? glowIntensity,
    double? rgbSplitAmount,
    double? morphParameter,
    double? chaosAmount,
    double? projectionDistance,
    double? fieldOfView,
    double? layerSeparation,
    AudioReactivityData? audioData,
    double? audioReactivityStrength,
  }) {
    return VIB3EngineState(
      system: system ?? this.system,
      geometryIndex: geometryIndex ?? this.geometryIndex,
      rotationXY: rotationXY ?? this.rotationXY,
      rotationXZ: rotationXZ ?? this.rotationXZ,
      rotationYZ: rotationYZ ?? this.rotationYZ,
      rotationXW: rotationXW ?? this.rotationXW,
      rotationYW: rotationYW ?? this.rotationYW,
      rotationZW: rotationZW ?? this.rotationZW,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      autoRotateSpeed: autoRotateSpeed ?? this.autoRotateSpeed,
      tessellationDensity: tessellationDensity ?? this.tessellationDensity,
      vertexBrightness: vertexBrightness ?? this.vertexBrightness,
      hueShift: hueShift ?? this.hueShift,
      saturation: saturation ?? this.saturation,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      rgbSplitAmount: rgbSplitAmount ?? this.rgbSplitAmount,
      morphParameter: morphParameter ?? this.morphParameter,
      chaosAmount: chaosAmount ?? this.chaosAmount,
      projectionDistance: projectionDistance ?? this.projectionDistance,
      fieldOfView: fieldOfView ?? this.fieldOfView,
      layerSeparation: layerSeparation ?? this.layerSeparation,
      audioData: audioData ?? this.audioData,
      audioReactivityStrength: audioReactivityStrength ?? this.audioReactivityStrength,
    );
  }

  /// Get effective rotation with audio modulation
  double getEffectiveRotation(double baseRotation, double audioInfluence) {
    final audioMod = audioData.rmsAmplitude * audioReactivityStrength * audioInfluence;
    return baseRotation * (1.0 + audioMod);
  }

  /// Get core index (synthesis branch) from geometry
  int get coreIndex => geometryIndex ~/ 8;

  /// Get base geometry index
  int get baseIndex => geometryIndex % 8;

  /// Check if FM synthesis core (Hypersphere)
  bool get isFMCore => coreIndex == 1;

  /// Check if Ring Mod core (Hypertetrahedron)
  bool get isRingModCore => coreIndex == 2;

  @override
  String toString() => 'VIB3EngineState(${system.name}, geom: $geometryIndex)';
}

/// VIB3+ Engine controller
class VIB3Engine extends ChangeNotifier {
  VIB3EngineState _state;
  double _time = 0.0;
  bool _isRunning = false;

  // Performance tracking
  int _frameCount = 0;
  double _lastFpsTime = 0.0;
  double _currentFps = 60.0;

  // Random generator for chaos effects
  final math.Random _random = math.Random();

  VIB3Engine({VIB3EngineState? initialState})
      : _state = initialState ?? const VIB3EngineState();

  /// Current engine state
  VIB3EngineState get state => _state;

  /// Current animation time
  double get time => _time;

  /// Whether engine is running
  bool get isRunning => _isRunning;

  /// Current FPS
  double get currentFps => _currentFps;

  /// Update engine state
  void updateState(VIB3EngineState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Update specific parameters
  void setSystem(VisualSystem system) {
    _state = _state.copyWith(system: system);
    notifyListeners();
  }

  void setGeometry(int geometryIndex) {
    _state = _state.copyWith(geometryIndex: geometryIndex % 24);
    notifyListeners();
  }

  void setRotation({
    double? xy, double? xz, double? yz,
    double? xw, double? yw, double? zw,
  }) {
    _state = _state.copyWith(
      rotationXY: xy,
      rotationXZ: xz,
      rotationYZ: yz,
      rotationXW: xw,
      rotationYW: yw,
      rotationZW: zw,
    );
    notifyListeners();
  }

  void setVisualParameters({
    int? tessellationDensity,
    double? vertexBrightness,
    double? hueShift,
    double? saturation,
    double? glowIntensity,
    double? rgbSplitAmount,
    double? morphParameter,
    double? chaosAmount,
  }) {
    _state = _state.copyWith(
      tessellationDensity: tessellationDensity,
      vertexBrightness: vertexBrightness,
      hueShift: hueShift,
      saturation: saturation,
      glowIntensity: glowIntensity,
      rgbSplitAmount: rgbSplitAmount,
      morphParameter: morphParameter,
      chaosAmount: chaosAmount,
    );
    notifyListeners();
  }

  void setAudioData(AudioReactivityData data) {
    _state = _state.copyWith(audioData: data);
    notifyListeners();
  }

  /// Advance animation by delta time
  void tick(double deltaSeconds) {
    _time += deltaSeconds * _state.animationSpeed;

    // Auto-rotation
    if (_state.autoRotateSpeed > 0) {
      final rotSpeed = _state.autoRotateSpeed * deltaSeconds;
      final audioBoost = 1.0 + _state.audioData.bassEnergy * _state.audioReactivityStrength;

      _state = _state.copyWith(
        rotationXY: _state.rotationXY + rotSpeed * 0.7 * audioBoost,
        rotationXZ: _state.rotationXZ + rotSpeed * 0.5 * audioBoost,
        rotationYZ: _state.rotationYZ + rotSpeed * 0.3,
        rotationXW: _state.rotationXW + rotSpeed * 0.4,
        rotationYW: _state.rotationYW + rotSpeed * 0.25,
        rotationZW: _state.rotationZW + rotSpeed * 0.15,
      );
    }

    // Track FPS
    _frameCount++;
    if (_time - _lastFpsTime >= 1.0) {
      _currentFps = _frameCount / (_time - _lastFpsTime);
      _frameCount = 0;
      _lastFpsTime = _time;
    }

    notifyListeners();
  }

  /// Start engine
  void start() {
    _isRunning = true;
    notifyListeners();
  }

  /// Stop engine
  void stop() {
    _isRunning = false;
    notifyListeners();
  }

  /// Reset engine state
  void reset() {
    _time = 0.0;
    _state = const VIB3EngineState();
    notifyListeners();
  }

  /// Get chaos-influenced value
  double getChaosValue(double base, double maxVariation) {
    if (_state.chaosAmount <= 0) return base;
    final variation = (_random.nextDouble() * 2.0 - 1.0) * maxVariation * _state.chaosAmount;
    return base + variation;
  }

  /// Get audio-modulated value
  double getAudioModulatedValue(double base, double audioInfluence, {
    double bassWeight = 1.0,
    double midWeight = 0.0,
    double highWeight = 0.0,
  }) {
    if (_state.audioReactivityStrength <= 0) return base;

    final audioValue =
      _state.audioData.bassEnergy * bassWeight +
      _state.audioData.midEnergy * midWeight +
      _state.audioData.highEnergy * highWeight;

    return base + audioValue * audioInfluence * _state.audioReactivityStrength;
  }
}
