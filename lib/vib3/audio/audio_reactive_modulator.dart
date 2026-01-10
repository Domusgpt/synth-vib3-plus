/**
 * VIB3+ Audio-Reactive Modulation System
 *
 * Transforms audio analysis data into visual parameter modulations.
 * This is the bridge between synthesizer output and visual rendering.
 *
 * Modulation mappings:
 * - Bass energy (20-250 Hz) → Rotation speed, scale pulsing
 * - Mid energy (250-2000 Hz) → Tessellation, stroke width
 * - High energy (2000-8000 Hz) → Vertex brightness, particle count
 * - Spectral centroid → Hue shift (dark→red, bright→cyan)
 * - RMS amplitude → Glow intensity, overall energy
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'dart:math' as math;
import '../core/vib3_engine.dart';

/// Audio analysis data with history for smoothing
class AudioAnalysisBuffer {
  final int bufferSize;
  final List<AudioReactivityData> _buffer = [];

  // Smoothed values
  double _smoothedBass = 0.0;
  double _smoothedMid = 0.0;
  double _smoothedHigh = 0.0;
  double _smoothedRms = 0.0;
  double _smoothedCentroid = 1000.0;

  // Attack/release rates (higher = faster response)
  final double attackRate;
  final double releaseRate;

  AudioAnalysisBuffer({
    this.bufferSize = 8,
    this.attackRate = 0.3,
    this.releaseRate = 0.1,
  });

  /// Add new audio data and update smoothed values
  void push(AudioReactivityData data) {
    _buffer.add(data);
    if (_buffer.length > bufferSize) {
      _buffer.removeAt(0);
    }

    // Apply attack/release envelope
    _smoothedBass = _applyEnvelope(_smoothedBass, data.bassEnergy);
    _smoothedMid = _applyEnvelope(_smoothedMid, data.midEnergy);
    _smoothedHigh = _applyEnvelope(_smoothedHigh, data.highEnergy);
    _smoothedRms = _applyEnvelope(_smoothedRms, data.rmsAmplitude);
    _smoothedCentroid = _smoothedCentroid * 0.9 + data.spectralCentroid * 0.1;
  }

  double _applyEnvelope(double current, double target) {
    if (target > current) {
      return current + (target - current) * attackRate;
    } else {
      return current + (target - current) * releaseRate;
    }
  }

  /// Get smoothed audio data
  AudioReactivityData get smoothed => AudioReactivityData(
    bassEnergy: _smoothedBass,
    midEnergy: _smoothedMid,
    highEnergy: _smoothedHigh,
    rmsAmplitude: _smoothedRms,
    spectralCentroid: _smoothedCentroid,
  );

  /// Get peak values from buffer
  AudioReactivityData get peaks {
    if (_buffer.isEmpty) return AudioReactivityData.silent;

    var maxBass = 0.0;
    var maxMid = 0.0;
    var maxHigh = 0.0;
    var maxRms = 0.0;
    var maxCentroid = 0.0;

    for (final data in _buffer) {
      if (data.bassEnergy > maxBass) maxBass = data.bassEnergy;
      if (data.midEnergy > maxMid) maxMid = data.midEnergy;
      if (data.highEnergy > maxHigh) maxHigh = data.highEnergy;
      if (data.rmsAmplitude > maxRms) maxRms = data.rmsAmplitude;
      if (data.spectralCentroid > maxCentroid) maxCentroid = data.spectralCentroid;
    }

    return AudioReactivityData(
      bassEnergy: maxBass,
      midEnergy: maxMid,
      highEnergy: maxHigh,
      rmsAmplitude: maxRms,
      spectralCentroid: maxCentroid,
    );
  }

  /// Detect beat (bass transient)
  bool detectBeat() {
    if (_buffer.length < 2) return false;

    final current = _buffer.last.bassEnergy;
    final previous = _buffer[_buffer.length - 2].bassEnergy;

    // Beat detection: sudden increase in bass
    return current > 0.4 && current - previous > 0.2;
  }

  /// Get beat intensity (0-1)
  double get beatIntensity {
    if (_buffer.isEmpty) return 0.0;
    return (_buffer.last.bassEnergy * 1.5).clamp(0.0, 1.0);
  }

  /// Clear buffer
  void clear() {
    _buffer.clear();
    _smoothedBass = 0.0;
    _smoothedMid = 0.0;
    _smoothedHigh = 0.0;
    _smoothedRms = 0.0;
    _smoothedCentroid = 1000.0;
  }
}

/// Modulation parameter configuration
class ModulationConfig {
  // Rotation modulation
  final double rotationBassInfluence;     // How much bass affects rotation speed
  final double rotationMidInfluence;

  // Scale/size modulation
  final double scaleBassInfluence;        // Bass → pulsing scale
  final double scaleRmsInfluence;

  // Tessellation modulation
  final double tessellationMidInfluence;  // Mid → grid density
  final double tessellationHighInfluence;

  // Brightness modulation
  final double brightnessHighInfluence;   // High → vertex brightness
  final double brightnessRmsInfluence;

  // Hue modulation
  final double hueCentroidInfluence;      // Spectral centroid → hue shift
  final double hueBassInfluence;

  // Glow modulation
  final double glowRmsInfluence;          // RMS → glow intensity
  final double glowBassInfluence;

  // Chaos modulation
  final double chaosHighInfluence;        // High freq → chaos/noise

  const ModulationConfig({
    this.rotationBassInfluence = 0.5,
    this.rotationMidInfluence = 0.3,
    this.scaleBassInfluence = 0.2,
    this.scaleRmsInfluence = 0.1,
    this.tessellationMidInfluence = 0.4,
    this.tessellationHighInfluence = 0.2,
    this.brightnessHighInfluence = 0.3,
    this.brightnessRmsInfluence = 0.2,
    this.hueCentroidInfluence = 0.5,
    this.hueBassInfluence = 0.2,
    this.glowRmsInfluence = 0.4,
    this.glowBassInfluence = 0.3,
    this.chaosHighInfluence = 0.3,
  });

  /// Quantum system preset (subtle, clean)
  factory ModulationConfig.quantum() => const ModulationConfig(
    rotationBassInfluence: 0.4,
    rotationMidInfluence: 0.2,
    scaleBassInfluence: 0.15,
    brightnessHighInfluence: 0.4,
    glowRmsInfluence: 0.5,
    chaosHighInfluence: 0.1,
  );

  /// Holographic system preset (dramatic, layered)
  factory ModulationConfig.holographic() => const ModulationConfig(
    rotationBassInfluence: 0.6,
    rotationMidInfluence: 0.4,
    scaleBassInfluence: 0.25,
    tessellationMidInfluence: 0.5,
    brightnessHighInfluence: 0.35,
    hueCentroidInfluence: 0.6,
    glowRmsInfluence: 0.6,
    glowBassInfluence: 0.4,
    chaosHighInfluence: 0.25,
  );

  /// Faceted system preset (punchy, geometric)
  factory ModulationConfig.faceted() => const ModulationConfig(
    rotationBassInfluence: 0.5,
    rotationMidInfluence: 0.35,
    scaleBassInfluence: 0.18,
    tessellationMidInfluence: 0.35,
    brightnessHighInfluence: 0.45,
    glowRmsInfluence: 0.35,
    chaosHighInfluence: 0.15,
  );
}

/// Main audio-reactive modulator
class AudioReactiveModulator {
  final AudioAnalysisBuffer _buffer;
  final ModulationConfig config;

  // Beat detection state
  double _beatDecay = 0.0;

  // Modulated output values
  double modulatedRotationSpeed = 1.0;
  double modulatedScale = 1.0;
  int modulatedTessellation = 5;
  double modulatedBrightness = 0.8;
  double modulatedHueShift = 0.0;
  double modulatedGlowIntensity = 1.0;
  double modulatedChaos = 0.2;

  AudioReactiveModulator({
    ModulationConfig? config,
    int bufferSize = 8,
    double attackRate = 0.3,
    double releaseRate = 0.1,
  }) : config = config ?? const ModulationConfig(),
       _buffer = AudioAnalysisBuffer(
         bufferSize: bufferSize,
         attackRate: attackRate,
         releaseRate: releaseRate,
       );

  /// Push new audio data and update modulations
  void update(AudioReactivityData data, double time) {
    _buffer.push(data);
    final smoothed = _buffer.smoothed;

    // Beat detection
    if (_buffer.detectBeat()) {
      _beatDecay = 1.0;
    } else {
      _beatDecay *= 0.92; // Decay rate
    }

    // Calculate modulated values
    _updateRotationSpeed(smoothed);
    _updateScale(smoothed);
    _updateTessellation(smoothed);
    _updateBrightness(smoothed);
    _updateHueShift(smoothed);
    _updateGlowIntensity(smoothed);
    _updateChaos(smoothed);
  }

  void _updateRotationSpeed(AudioReactivityData audio) {
    final bassContrib = audio.bassEnergy * config.rotationBassInfluence;
    final midContrib = audio.midEnergy * config.rotationMidInfluence;

    modulatedRotationSpeed = 1.0 + bassContrib + midContrib + _beatDecay * 0.3;
  }

  void _updateScale(AudioReactivityData audio) {
    final bassContrib = audio.bassEnergy * config.scaleBassInfluence;
    final rmsContrib = audio.rmsAmplitude * config.scaleRmsInfluence;

    // Add beat punch
    final beatPunch = _beatDecay * 0.1;

    modulatedScale = 1.0 + bassContrib + rmsContrib + beatPunch;
  }

  void _updateTessellation(AudioReactivityData audio) {
    final midContrib = audio.midEnergy * config.tessellationMidInfluence;
    final highContrib = audio.highEnergy * config.tessellationHighInfluence;

    // Base tessellation 3-8, modulated by audio
    final modulation = (midContrib + highContrib) * 5;
    modulatedTessellation = (5 + modulation).round().clamp(3, 10);
  }

  void _updateBrightness(AudioReactivityData audio) {
    final highContrib = audio.highEnergy * config.brightnessHighInfluence;
    final rmsContrib = audio.rmsAmplitude * config.brightnessRmsInfluence;

    modulatedBrightness = (0.6 + highContrib + rmsContrib).clamp(0.4, 1.0);
  }

  void _updateHueShift(AudioReactivityData audio) {
    // Map spectral centroid (roughly 100-5000 Hz range) to hue shift
    final normalizedCentroid = ((audio.spectralCentroid - 500) / 3000)
        .clamp(0.0, 1.0);

    final centroidContrib = normalizedCentroid * config.hueCentroidInfluence * 180;
    final bassContrib = audio.bassEnergy * config.hueBassInfluence * 30;

    // Dark sounds → red (0°), bright sounds → cyan (180°)
    modulatedHueShift = centroidContrib - bassContrib;
  }

  void _updateGlowIntensity(AudioReactivityData audio) {
    final rmsContrib = audio.rmsAmplitude * config.glowRmsInfluence;
    final bassContrib = audio.bassEnergy * config.glowBassInfluence;

    // Base glow 0.5-2.5
    modulatedGlowIntensity = (1.0 + rmsContrib + bassContrib + _beatDecay * 0.5)
        .clamp(0.5, 3.0);
  }

  void _updateChaos(AudioReactivityData audio) {
    final highContrib = audio.highEnergy * config.chaosHighInfluence;

    // Base chaos 0-0.5
    modulatedChaos = (0.1 + highContrib).clamp(0.0, 0.5);
  }

  /// Apply modulations to engine state
  VIB3EngineState applyToState(VIB3EngineState state) {
    return state.copyWith(
      animationSpeed: state.animationSpeed * modulatedRotationSpeed,
      tessellationDensity: modulatedTessellation,
      vertexBrightness: modulatedBrightness,
      hueShift: state.hueShift + modulatedHueShift,
      glowIntensity: modulatedGlowIntensity,
      chaosAmount: modulatedChaos,
      audioData: _buffer.smoothed,
    );
  }

  /// Get current beat intensity (0-1)
  double get beatIntensity => _beatDecay;

  /// Check if currently on beat
  bool get isOnBeat => _beatDecay > 0.5;

  /// Get smoothed audio data
  AudioReactivityData get smoothedAudio => _buffer.smoothed;

  /// Get peak audio data
  AudioReactivityData get peakAudio => _buffer.peaks;

  /// Clear buffer and reset
  void reset() {
    _buffer.clear();
    _beatDecay = 0.0;
    modulatedRotationSpeed = 1.0;
    modulatedScale = 1.0;
    modulatedTessellation = 5;
    modulatedBrightness = 0.8;
    modulatedHueShift = 0.0;
    modulatedGlowIntensity = 1.0;
    modulatedChaos = 0.2;
  }
}

/// Helper to generate test audio data for demos
class TestAudioGenerator {
  final math.Random _random = math.Random();

  /// Generate simulated audio reactivity data
  AudioReactivityData generate(double time, {
    double bassFrequency = 0.5,    // Bass pulse frequency in Hz
    double bassIntensity = 0.6,
    double midVariation = 0.4,
    double highVariation = 0.3,
  }) {
    // Simulate bass beat
    final bassPhase = time * bassFrequency * math.pi * 2;
    final bassPulse = (math.sin(bassPhase) + 1) / 2;
    final bassEnergy = bassPulse * bassIntensity + _random.nextDouble() * 0.1;

    // Simulate mid-range activity
    final midEnergy = 0.3 + math.sin(time * 1.7) * midVariation +
        _random.nextDouble() * 0.1;

    // Simulate high-frequency sparkle
    final highEnergy = 0.2 + _random.nextDouble() * highVariation;

    // RMS follows bass with some high contribution
    final rmsAmplitude = (bassEnergy * 0.6 + midEnergy * 0.3 + highEnergy * 0.1)
        .clamp(0.0, 1.0);

    // Spectral centroid varies with content
    final spectralCentroid = 800 + math.sin(time * 0.3) * 600 +
        highEnergy * 1500;

    return AudioReactivityData(
      bassEnergy: bassEnergy.clamp(0.0, 1.0),
      midEnergy: midEnergy.clamp(0.0, 1.0),
      highEnergy: highEnergy.clamp(0.0, 1.0),
      rmsAmplitude: rmsAmplitude,
      spectralCentroid: spectralCentroid,
    );
  }
}
