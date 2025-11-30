// Synthesis Branch Manager - Musically Tuned Edition
//
// Routes geometry selection to appropriate synthesis branch based on polytope core:
// - Base Core (0-7) → Direct Synthesis
// - Hypersphere Core (8-15) → FM Synthesis
// - Hypertetrahedron Core (16-23) → Ring Modulation
//
// Applies sound family characteristics from visual system:
// - Quantum → Pure/Harmonic (sine-dominant, musical harmonics)
// - Faceted → Geometric/Hybrid (rich harmonics, balanced spectrum)
// - Holographic → Spectral/Rich (complex overtones, evolving timbre)
//
// Applies voice character from base geometry (0-7)
//
// MUSICALLY TUNED**: All parameters optimized for musical intervals,
// harmonic relationships, and pleasing timbres.
//
// A Paul Phillips Manifestation
//
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Visual system types (from VIB3+)
enum VisualSystem {
  quantum,      // Pure harmonic synthesis
  faceted,      // Geometric hybrid synthesis
  holographic,  // Spectral rich synthesis
}

/// Polytope core types (determines synthesis branch)
enum PolytopeCor {
  base,              // Direct synthesis (geometries 0-7)
  hypersphere,       // FM synthesis (geometries 8-15)
  hypertetrahedron,  // Ring modulation (geometries 16-23)
}

/// Base geometry types (determines voice character)
enum BaseGeometry {
  tetrahedron,  // 0: Fundamental - pure tone, minimal complexity
  hypercube,    // 1: Complex - rich harmonics, detuned chorusing
  sphere,       // 2: Smooth - filtered warm tones
  torus,        // 3: Cyclic - rhythmic modulation
  kleinBottle,  // 4: Twisted - stereo movement, spatial
  fractal,      // 5: Recursive - evolving complexity
  wave,         // 6: Flowing - sweeping evolving timbres
  crystal,      // 7: Crystalline - bright percussive attacks
}

/// Sound family characteristics (from visual system) - MUSICALLY TUNED
class SoundFamily {
  final String name;
  final List<double> waveformMix; // [sine, square, triangle, saw]
  final double filterQ;           // Resonance (tuned for musicality)
  final double noiseLevel;        // 0-1 (very low for musical clarity)
  final double reverbMix;         // 0-1 (musical ambience)
  final double brightness;        // Spectral tilt (0-1)
  final List<double> harmonicAmplitudes; // First 8 harmonics

  const SoundFamily({
    required this.name,
    required this.waveformMix,
    required this.filterQ,
    required this.noiseLevel,
    required this.reverbMix,
    required this.brightness,
    required this.harmonicAmplitudes,
  });

  // Quantum system: Pure harmonic - optimized for clarity and consonance
  static const quantum = SoundFamily(
    name: 'Quantum/Pure',
    waveformMix: [0.85, 0.0, 0.15, 0.0],  // Mostly sine with triangle warmth
    filterQ: 8.0,                           // High resonance for clarity
    noiseLevel: 0.005,                      // Minimal noise
    reverbMix: 0.20,                        // Light reverb
    brightness: 0.7,                        // Bright but not harsh
    harmonicAmplitudes: [1.0, 0.5, 0.33, 0.25, 0.20, 0.17, 0.14, 0.13], // Musical harmonics
  );

  // Faceted system: Geometric hybrid - balanced for musical richness
  static const faceted = SoundFamily(
    name: 'Faceted/Geometric',
    waveformMix: [0.35, 0.40, 0.25, 0.0],  // Balanced warm spectrum
    filterQ: 5.5,                            // Moderate resonance
    noiseLevel: 0.01,                        // Very low noise
    reverbMix: 0.30,                         // Medium reverb
    brightness: 0.6,                         // Balanced spectrum
    harmonicAmplitudes: [1.0, 0.7, 0.5, 0.35, 0.25, 0.18, 0.13, 0.10], // Rich but controlled
  );

  // Holographic system: Spectral rich - complex but musical
  static const holographic = SoundFamily(
    name: 'Holographic/Rich',
    waveformMix: [0.25, 0.10, 0.15, 0.50],  // Saw-based with warmth
    filterQ: 4.0,                             // Lower resonance for smoothness
    noiseLevel: 0.02,                         // Low noise for clarity
    reverbMix: 0.45,                          // High reverb for depth
    brightness: 0.5,                          // Warm rich spectrum
    harmonicAmplitudes: [1.0, 0.8, 0.6, 0.45, 0.35, 0.27, 0.21, 0.16], // Complex harmonics
  );
}

/// Voice character (from base geometry) - MUSICALLY TUNED
class VoiceCharacter {
  final String name;
  final double attackMs;
  final double releaseMs;
  final double reverbMix;
  final int harmonicCount;
  final double detuneCents;          // Musical detuning in cents
  final bool hasPhaseModulation;
  final bool hasChorusEffect;
  final bool hasFilterSweep;
  final double harmonicSpread;       // How spread out harmonics are (0-1)

  const VoiceCharacter({
    required this.name,
    required this.attackMs,
    required this.releaseMs,
    required this.reverbMix,
    required this.harmonicCount,
    required this.detuneCents,
    this.hasPhaseModulation = false,
    this.hasChorusEffect = false,
    this.hasFilterSweep = false,
    this.harmonicSpread = 0.5,
  });

  static const tetrahedron = VoiceCharacter(
    name: 'Fundamental',
    attackMs: 10.0,
    releaseMs: 250.0,
    reverbMix: 0.15,
    harmonicCount: 3,
    detuneCents: 0.0,              // Perfect tuning
    harmonicSpread: 0.3,           // Tight harmonics
  );

  static const hypercube = VoiceCharacter(
    name: 'Complex',
    attackMs: 25.0,
    releaseMs: 400.0,
    reverbMix: 0.28,
    harmonicCount: 6,
    detuneCents: 8.0,              // Subtle chorusing (musical interval)
    hasChorusEffect: true,
    harmonicSpread: 0.7,           // Wide harmonic spread
  );

  static const sphere = VoiceCharacter(
    name: 'Smooth',
    attackMs: 60.0,
    releaseMs: 350.0,
    reverbMix: 0.25,
    harmonicCount: 4,
    detuneCents: 0.0,
    harmonicSpread: 0.4,           // Controlled spread
  );

  static const torus = VoiceCharacter(
    name: 'Cyclic',
    attackMs: 15.0,
    releaseMs: 200.0,
    reverbMix: 0.20,
    harmonicCount: 5,
    detuneCents: 5.0,              // Slight shimmer
    hasPhaseModulation: true,
    hasFilterSweep: true,
    harmonicSpread: 0.6,
  );

  static const kleinBottle = VoiceCharacter(
    name: 'Twisted',
    attackMs: 35.0,
    releaseMs: 300.0,
    reverbMix: 0.35,
    harmonicCount: 5,
    detuneCents: 12.0,             // More chorusing (near quarter-tone)
    hasChorusEffect: true,
    harmonicSpread: 0.8,           // Very wide
  );

  static const fractal = VoiceCharacter(
    name: 'Recursive',
    attackMs: 30.0,
    releaseMs: 500.0,
    reverbMix: 0.38,
    harmonicCount: 8,
    detuneCents: 7.0,              // Golden ratio detuning
    harmonicSpread: 0.9,           // Maximum spread
  );

  static const wave = VoiceCharacter(
    name: 'Flowing',
    attackMs: 50.0,
    releaseMs: 450.0,
    reverbMix: 0.42,
    harmonicCount: 6,
    detuneCents: 3.0,              // Gentle shimmer
    hasFilterSweep: true,
    harmonicSpread: 0.7,
  );

  static const crystal = VoiceCharacter(
    name: 'Crystalline',
    attackMs: 2.0,
    releaseMs: 150.0,
    reverbMix: 0.48,
    harmonicCount: 5,
    detuneCents: 0.0,              // Perfect tuning for clarity
    harmonicSpread: 0.5,           // Balanced
  );
}

/// Main synthesis branch manager - MUSICALLY TUNED
class SynthesisBranchManager {
  final double sampleRate;

  // Current state
  int _currentGeometry = 0;        // 0-23
  VisualSystem _visualSystem = VisualSystem.quantum;

  // Derived state
  PolytopeCor _currentCore = PolytopeCor.base;
  BaseGeometry _currentBaseGeometry = BaseGeometry.tetrahedron;
  SoundFamily _currentSoundFamily = SoundFamily.quantum;
  VoiceCharacter _currentVoiceCharacter = VoiceCharacter.tetrahedron;

  // Phase accumulators
  double _phase1 = 0.0;
  double _phase2 = 0.0;

  // Envelope state
  double _envelopeLevel = 0.0;
  int _samplesSinceNoteOn = 0;
  bool _noteIsOn = false;

  // Random number generator for noise
  final _random = math.Random();

  SynthesisBranchManager({this.sampleRate = 44100.0});

  /// Set geometry (0-23) and update all derived state
  void setGeometry(int geometry) {
    if (geometry < 0 || geometry > 23) {
      throw ArgumentError('Geometry must be 0-23, got $geometry');
    }

    _currentGeometry = geometry;

    // Calculate core and base geometry
    final coreIndex = geometry ~/ 8;  // Integer division
    final baseIndex = geometry % 8;   // Modulo

    // Update core (determines synthesis branch)
    _currentCore = PolytopeCor.values[coreIndex];

    // Update base geometry (determines voice character)
    _currentBaseGeometry = BaseGeometry.values[baseIndex];

    // Update voice character
    _currentVoiceCharacter = _getVoiceCharacter(_currentBaseGeometry);

    debugPrint(
      '🎵 Geometry $geometry: ${_currentCore.name} core, '
      '${_currentBaseGeometry.name} geometry',
    );
  }

  /// Set visual system (updates sound family)
  void setVisualSystem(VisualSystem system) {
    _visualSystem = system;
    _currentSoundFamily = _getSoundFamily(system);

    debugPrint('🎨 Visual system: ${system.name} → ${_currentSoundFamily.name}');
  }

  /// Note on (trigger envelope)
  void noteOn() {
    _noteIsOn = true;
    _samplesSinceNoteOn = 0;
  }

  /// Note off (start release)
  void noteOff() {
    _noteIsOn = false;
  }

  /// Get sound family for visual system
  SoundFamily _getSoundFamily(VisualSystem system) {
    switch (system) {
      case VisualSystem.quantum:
        return SoundFamily.quantum;
      case VisualSystem.faceted:
        return SoundFamily.faceted;
      case VisualSystem.holographic:
        return SoundFamily.holographic;
    }
  }

  /// Get voice character for base geometry
  VoiceCharacter _getVoiceCharacter(BaseGeometry geometry) {
    switch (geometry) {
      case BaseGeometry.tetrahedron:
        return VoiceCharacter.tetrahedron;
      case BaseGeometry.hypercube:
        return VoiceCharacter.hypercube;
      case BaseGeometry.sphere:
        return VoiceCharacter.sphere;
      case BaseGeometry.torus:
        return VoiceCharacter.torus;
      case BaseGeometry.kleinBottle:
        return VoiceCharacter.kleinBottle;
      case BaseGeometry.fractal:
        return VoiceCharacter.fractal;
      case BaseGeometry.wave:
        return VoiceCharacter.wave;
      case BaseGeometry.crystal:
        return VoiceCharacter.crystal;
    }
  }

  /// Generate audio buffer with current configuration
  Float32List generateBuffer(int frames, double frequency) {
    // Route to appropriate synthesis branch based on core
    switch (_currentCore) {
      case PolytopeCor.base:
        return _generateDirect(frames, frequency);
      case PolytopeCor.hypersphere:
        return _generateFM(frames, frequency);
      case PolytopeCor.hypertetrahedron:
        return _generateRingMod(frames, frequency);
    }
  }

  /// Calculate envelope level (musical ADSR)
  double _updateEnvelope() {
    final attackSamples = (_currentVoiceCharacter.attackMs * sampleRate / 1000.0).round();
    final releaseSamples = (_currentVoiceCharacter.releaseMs * sampleRate / 1000.0).round();

    if (_noteIsOn) {
      // Attack phase
      if (_samplesSinceNoteOn < attackSamples) {
        _envelopeLevel = _samplesSinceNoteOn / attackSamples;
      } else {
        _envelopeLevel = 1.0; // Sustain at full level
      }
      _samplesSinceNoteOn++;
    } else {
      // Release phase
      _envelopeLevel *= math.exp(-4.5 / releaseSamples); // Exponential decay
    }

    return _envelopeLevel;
  }

  /// Direct synthesis (Base core) - MUSICALLY TUNED
  Float32List _generateDirect(int frames, double frequency) {
    final buffer = Float32List(frames);

    // Apply musical detuning from voice character (in cents)
    final detuneRatio = math.pow(2.0, _currentVoiceCharacter.detuneCents / 1200.0);
    final detunedFreq = frequency * detuneRatio;
    final phaseIncrement = detunedFreq / sampleRate * 2.0 * math.pi;

    for (int i = 0; i < frames; i++) {
      final envelope = _updateEnvelope();
      double sample = 0.0;

      // Generate harmonics based on sound family
      for (int h = 0; h < _currentVoiceCharacter.harmonicCount && h < _currentSoundFamily.harmonicAmplitudes.length; h++) {
        final harmonicNumber = h + 1;
        final harmonicPhase = _phase1 * harmonicNumber;
        final harmonicAmp = _currentSoundFamily.harmonicAmplitudes[h];

        // Apply harmonic spread for richness
        final spreadOffset = _currentVoiceCharacter.harmonicSpread * 0.02 * h;
        final harmonic = math.sin(harmonicPhase + spreadOffset) * harmonicAmp;

        sample += harmonic;
      }

      // Normalize by harmonic count
      sample /= _currentVoiceCharacter.harmonicCount;

      // Mix base waveforms for timbral character
      sample *= _currentSoundFamily.waveformMix[0]; // Sine component
      sample += _currentSoundFamily.waveformMix[1] * _square(_phase1) * 0.3; // Square (quieter)
      sample += _currentSoundFamily.waveformMix[2] * _triangle(_phase1) * 0.4; // Triangle

      // Add minimal musical noise for warmth
      sample += (_random.nextDouble() * 2.0 - 1.0) * _currentSoundFamily.noiseLevel;

      // Apply envelope
      sample *= envelope;

      // Apply brightness filter (simple high-shelf)
      sample = sample * (1.0 - _currentSoundFamily.brightness * 0.3);

      buffer[i] = sample.clamp(-1.0, 1.0) * 0.6; // Headroom for safety

      _phase1 += phaseIncrement;
      if (_phase1 > 2.0 * math.pi) _phase1 -= 2.0 * math.pi;
    }

    return buffer;
  }

  /// FM synthesis (Hypersphere core) - MUSICALLY TUNED
  Float32List _generateFM(int frames, double frequency) {
    final buffer = Float32List(frames);

    // Musical FM ratios (2:1 = octave, produces musical overtones)
    final carrierIncrement = frequency / sampleRate * 2.0 * math.pi;
    final modulatorIncrement = carrierIncrement * 2.0; // Perfect octave

    // FM index based on harmonic richness
    final fmIndex = 1.5 + (_currentVoiceCharacter.harmonicCount * 0.3);

    for (int i = 0; i < frames; i++) {
      final envelope = _updateEnvelope();

      // Modulator (creates sidebands)
      double modulator = math.sin(_phase2) * fmIndex;

      // Carrier with FM
      double sample = math.sin(_phase1 + modulator);

      // Add harmonics for richness
      for (int h = 1; h < math.min(4, _currentVoiceCharacter.harmonicCount); h++) {
        final harmonicAmp = _currentSoundFamily.harmonicAmplitudes[h];
        sample += math.sin((_phase1 + modulator) * (h + 1)) * harmonicAmp * 0.5;
      }

      // Normalize
      sample *= 0.5;

      // Apply envelope
      sample *= envelope;

      buffer[i] = sample.clamp(-1.0, 1.0) * 0.5;

      _phase1 += carrierIncrement;
      _phase2 += modulatorIncrement;

      if (_phase1 > 2.0 * math.pi) _phase1 -= 2.0 * math.pi;
      if (_phase2 > 2.0 * math.pi) _phase2 -= 2.0 * math.pi;
    }

    return buffer;
  }

  /// Ring modulation synthesis (Hypertetrahedron core) - MUSICALLY TUNED
  Float32List _generateRingMod(int frames, double frequency) {
    final buffer = Float32List(frames);

    // Musical ratios: Perfect fifth (3/2) for pleasant inharmonicity
    final osc1Increment = frequency / sampleRate * 2.0 * math.pi;
    final osc2Increment = osc1Increment * 1.5; // Perfect fifth

    for (int i = 0; i < frames; i++) {
      final envelope = _updateEnvelope();

      // Two oscillators with harmonics
      double osc1 = 0.0;
      double osc2 = 0.0;

      // Build oscillators with harmonics
      for (int h = 0; h < math.min(3, _currentVoiceCharacter.harmonicCount); h++) {
        final amp = _currentSoundFamily.harmonicAmplitudes[h];
        osc1 += math.sin(_phase1 * (h + 1)) * amp;
        osc2 += math.sin(_phase2 * (h + 1)) * amp;
      }

      // Normalize
      osc1 *= 0.4;
      osc2 *= 0.4;

      // Ring modulation (creates sum and difference frequencies)
      double sample = osc1 * osc2;

      // Mix in some of the original oscillators for musicality
      sample = sample * 0.7 + osc1 * 0.2 + osc2 * 0.1;

      // Apply envelope
      sample *= envelope;

      buffer[i] = sample.clamp(-1.0, 1.0) * 0.6;

      _phase1 += osc1Increment;
      _phase2 += osc2Increment;

      if (_phase1 > 2.0 * math.pi) _phase1 -= 2.0 * math.pi;
      if (_phase2 > 2.0 * math.pi) _phase2 -= 2.0 * math.pi;
    }

    return buffer;
  }

  // Waveform generators (band-limited for reduced aliasing)
  double _square(double phase) {
    // Soften square wave with harmonics for musical sound
    double sample = 0.0;
    for (int h = 1; h <= 7; h += 2) {
      sample += math.sin(phase * h) / h;
    }
    return sample * 0.7;
  }

  double _triangle(double phase) {
    // Band-limited triangle (fewer harmonics than square)
    double sample = 0.0;
    int sign = 1;
    for (int h = 1; h <= 5; h += 2) {
      sample += sign * math.sin(phase * h) / (h * h);
      sign *= -1;
    }
    return sample * 0.8;
  }

  /// Get current configuration as string (for debugging)
  String get configString {
    return '''
Geometry: $_currentGeometry
Core: ${_currentCore.name} (${_getSynthesisBranchName()})
Base Geometry: ${_currentBaseGeometry.name}
Visual System: ${_visualSystem.name}
Sound Family: ${_currentSoundFamily.name}
Voice Character: ${_currentVoiceCharacter.name}
Attack: ${_currentVoiceCharacter.attackMs}ms
Release: ${_currentVoiceCharacter.releaseMs}ms
Reverb: ${(_currentVoiceCharacter.reverbMix * 100).toStringAsFixed(0)}%
Detune: ${_currentVoiceCharacter.detuneCents} cents
Harmonics: ${_currentVoiceCharacter.harmonicCount}
''';
  }

  String _getSynthesisBranchName() {
    switch (_currentCore) {
      case PolytopeCor.base:
        return 'Direct Synthesis';
      case PolytopeCor.hypersphere:
        return 'FM Synthesis';
      case PolytopeCor.hypertetrahedron:
        return 'Ring Modulation';
    }
  }

  // Getters for external access
  int get currentGeometry => _currentGeometry;
  VisualSystem get visualSystem => _visualSystem;
  PolytopeCor get currentCore => _currentCore;
  BaseGeometry get currentBaseGeometry => _currentBaseGeometry;
  SoundFamily get soundFamily => _currentSoundFamily;
  VoiceCharacter get voiceCharacter => _currentVoiceCharacter;
}
