/**
 * LFO (Low Frequency Oscillator)
 *
 * Sub-audio oscillator for modulating synthesis parameters.
 * Creates cyclic modulation for:
 * - Vibrato (pitch modulation)
 * - Tremolo (amplitude modulation)
 * - Filter sweeps (cutoff modulation)
 * - Timbre evolution
 *
 * Typical frequency range: 0.1 Hz (6 BPM) - 20 Hz (sub-audio)
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;

/// LFO waveform types
enum LFOWaveform {
  sine,      // Smooth, natural modulation (vibrato, gentle sweeps)
  triangle,  // Linear ramps up/down (filter sweeps)
  square,    // Hard on/off switching (tremolo gates, rhythmic)
  sawtooth,  // Asymmetric ramp (rising filter sweep)
  random,    // Sample & hold noise (experimental, unpredictable)
}

/// Low Frequency Oscillator for parameter modulation
class LFO {
  final double sampleRate;

  // LFO configuration
  double frequency;        // Hz (0.1 - 20 Hz typical)
  LFOWaveform waveform;
  double depth;            // Modulation depth (0.0 - 1.0)

  // Phase state
  double _phase = 0.0;      // Current position (0 - 2π)
  double _lastRandomValue = 0.0; // For sample & hold random
  double _randomPhaseThreshold = 0.0; // When to sample next random value

  // Random number generator for random waveform
  final math.Random _random = math.Random();

  LFO({
    required this.sampleRate,
    this.frequency = 1.0,
    this.waveform = LFOWaveform.sine,
    this.depth = 1.0,
  }) {
    _generateRandomThreshold();
  }

  /// Generate next LFO sample (returns value in range -1.0 to +1.0)
  double nextSample(double deltaTime) {
    // Generate waveform based on current phase
    final sample = _generateWaveform(_phase);

    // Advance phase
    final phaseIncrement = (2.0 * math.pi * frequency) / sampleRate;
    _phase += phaseIncrement;

    // Wrap phase at 2π
    if (_phase >= 2.0 * math.pi) {
      _phase -= 2.0 * math.pi;

      // For random waveform, generate new threshold at cycle start
      if (waveform == LFOWaveform.random) {
        _generateRandomThreshold();
      }
    }

    // Apply depth scaling
    return sample * depth;
  }

  /// Generate waveform sample at current phase
  double _generateWaveform(double phase) {
    switch (waveform) {
      case LFOWaveform.sine:
        return math.sin(phase);

      case LFOWaveform.triangle:
        // Convert phase (0 - 2π) to triangle wave (-1 to +1)
        final normalizedPhase = phase / (2.0 * math.pi);
        if (normalizedPhase < 0.25) {
          // Rising: 0 → 1
          return normalizedPhase * 4.0;
        } else if (normalizedPhase < 0.75) {
          // Falling: 1 → -1
          return 2.0 - (normalizedPhase * 4.0);
        } else {
          // Rising: -1 → 0
          return -4.0 + (normalizedPhase * 4.0);
        }

      case LFOWaveform.square:
        // 50% duty cycle square wave
        return phase < math.pi ? 1.0 : -1.0;

      case LFOWaveform.sawtooth:
        // Rising sawtooth: -1 → +1
        return 2.0 * (phase / (2.0 * math.pi)) - 1.0;

      case LFOWaveform.random:
        // Sample & hold random (steps)
        // Hold current random value until threshold
        if (phase > _randomPhaseThreshold && _phase < phase) {
          // Crossed threshold, sample new random value
          _lastRandomValue = _random.nextDouble() * 2.0 - 1.0; // -1 to +1
        }
        return _lastRandomValue;
    }
  }

  /// Generate new random phase threshold for random waveform
  void _generateRandomThreshold() {
    // Random point in cycle to sample next value (creates varied rhythm)
    _randomPhaseThreshold = _random.nextDouble() * 2.0 * math.pi;
  }

  /// Reset phase to start of cycle
  void reset() {
    _phase = 0.0;
    if (waveform == LFOWaveform.random) {
      _lastRandomValue = _random.nextDouble() * 2.0 - 1.0;
      _generateRandomThreshold();
    }
  }

  /// Set frequency (in Hz)
  void setFrequency(double hz) {
    frequency = hz.clamp(0.01, 100.0); // Practical limits
  }

  /// Set depth (modulation amount)
  void setDepth(double d) {
    depth = d.clamp(0.0, 1.0);
  }

  /// Set waveform type
  void setWaveform(LFOWaveform wf) {
    waveform = wf;
    // Reset phase when changing waveform to avoid discontinuities
    if (wf == LFOWaveform.random && waveform != LFOWaveform.random) {
      _lastRandomValue = _random.nextDouble() * 2.0 - 1.0;
      _generateRandomThreshold();
    }
  }

  /// Sync LFO to external trigger (reset phase to 0)
  /// Useful for synchronized modulation across multiple LFOs
  void sync() {
    reset();
  }

  /// Get current phase position (0 - 1 for UI display)
  double get phaseNormalized => _phase / (2.0 * math.pi);

  /// Get current LFO value without advancing (for UI visualization)
  double get currentValue => _generateWaveform(_phase) * depth;
}

/// LFO Pool - manages multiple LFOs for different modulation targets
class LFOPool {
  final double sampleRate;

  // Three independent LFOs for different modulation targets
  late final LFO pitchLFO;    // LFO 1: Vibrato (pitch modulation)
  late final LFO filterLFO;   // LFO 2: Filter sweeps
  late final LFO ampLFO;      // LFO 3: Tremolo (amplitude modulation)

  LFOPool({required this.sampleRate}) {
    pitchLFO = LFO(
      sampleRate: sampleRate,
      frequency: 5.0,
      waveform: LFOWaveform.sine,
      depth: 0.5, // Subtle vibrato by default
    );

    filterLFO = LFO(
      sampleRate: sampleRate,
      frequency: 0.5,
      waveform: LFOWaveform.triangle,
      depth: 0.6, // Moderate filter sweep
    );

    ampLFO = LFO(
      sampleRate: sampleRate,
      frequency: 2.0,
      waveform: LFOWaveform.sine,
      depth: 0.3, // Gentle tremolo
    );
  }

  /// Update all LFO frequencies from visual rotation speeds
  void updateFromRotationSpeeds({
    required double rotationSpeedXW,
    required double rotationSpeedYW,
    required double rotationSpeedZW,
  }) {
    // Map visual rotation speeds (0.1 - 2.0) to LFO frequencies (0.1 - 10 Hz)
    // Using exponential curve for musical feel
    pitchLFO.setFrequency(_mapRotationToFrequency(rotationSpeedXW));
    filterLFO.setFrequency(_mapRotationToFrequency(rotationSpeedYW));
    ampLFO.setFrequency(_mapRotationToFrequency(rotationSpeedZW));
  }

  /// Map visual rotation speed to LFO frequency
  /// Input: 0.1 - 2.0 (visual rotation)
  /// Output: 0.1 - 10 Hz (LFO frequency)
  double _mapRotationToFrequency(double rotationSpeed) {
    // Exponential mapping: slow rotations = slow LFO, fast rotations = fast LFO
    // 0.1 → 0.1 Hz (very slow, 6 BPM)
    // 1.0 → 1.0 Hz (60 BPM)
    // 2.0 → 10 Hz (600 BPM, audio-rate modulation)
    return 0.1 * math.pow(10, rotationSpeed);
  }

  /// Set modulation depths (vibrato, filter, tremolo)
  void setDepths({
    double? vibratoDepth,
    double? filterDepth,
    double? tremoloDepth,
  }) {
    if (vibratoDepth != null) pitchLFO.setDepth(vibratoDepth);
    if (filterDepth != null) filterLFO.setDepth(filterDepth);
    if (tremoloDepth != null) ampLFO.setDepth(tremoloDepth);
  }

  /// Sync all LFOs (reset phases to 0)
  void syncAll() {
    pitchLFO.sync();
    filterLFO.sync();
    ampLFO.sync();
  }

  /// Get state for debugging/UI
  Map<String, dynamic> getState() {
    return {
      'pitchLFO': {
        'frequency': pitchLFO.frequency.toStringAsFixed(2),
        'waveform': pitchLFO.waveform.name,
        'depth': pitchLFO.depth.toStringAsFixed(2),
        'phase': pitchLFO.phaseNormalized.toStringAsFixed(3),
        'value': pitchLFO.currentValue.toStringAsFixed(3),
      },
      'filterLFO': {
        'frequency': filterLFO.frequency.toStringAsFixed(2),
        'waveform': filterLFO.waveform.name,
        'depth': filterLFO.depth.toStringAsFixed(2),
        'phase': filterLFO.phaseNormalized.toStringAsFixed(3),
        'value': filterLFO.currentValue.toStringAsFixed(3),
      },
      'ampLFO': {
        'frequency': ampLFO.frequency.toStringAsFixed(2),
        'waveform': ampLFO.waveform.name,
        'depth': ampLFO.depth.toStringAsFixed(2),
        'phase': ampLFO.phaseNormalized.toStringAsFixed(3),
        'value': ampLFO.currentValue.toStringAsFixed(3),
      },
    };
  }
}
