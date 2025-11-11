/**
 * Enhanced Parameter Modulation System
 *
 * Advanced parameter mapping layer that provides sophisticated modulation
 * capabilities including LFO, chaos injection, spectral processing, and
 * dynamic polyphony management.
 *
 * This system extends the basic visual-to-audio mappings with real-time
 * modulation, noise injection, and advanced synthesis control.
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// LFO (Low-Frequency Oscillator) for parameter modulation
class LFO {
  double phase = 0.0;
  double rate = 1.0; // Hz
  LFOWaveform waveform = LFOWaveform.sine;

  /// Update and get next LFO value
  double nextValue(double deltaTime) {
    phase += rate * deltaTime * 2.0 * math.pi;
    if (phase >= 2.0 * math.pi) {
      phase -= 2.0 * math.pi;
    }

    return _getWaveformValue();
  }

  double _getWaveformValue() {
    switch (waveform) {
      case LFOWaveform.sine:
        return math.sin(phase);
      case LFOWaveform.triangle:
        final double t = phase / (2.0 * math.pi);
        return t < 0.5 ? (4.0 * t - 1.0) : (3.0 - 4.0 * t);
      case LFOWaveform.square:
        return phase < math.pi ? 1.0 : -1.0;
      case LFOWaveform.saw:
        return 2.0 * (phase / (2.0 * math.pi)) - 1.0;
      case LFOWaveform.random:
        return math.Random().nextDouble() * 2.0 - 1.0;
    }
  }

  void reset() {
    phase = 0.0;
  }
}

enum LFOWaveform { sine, triangle, square, saw, random }

/// Chaos generator for noise injection and randomization
class ChaosGenerator {
  final math.Random _random = math.Random();
  double _chaosLevel = 0.0;
  double _filterRandomization = 0.0;
  double _noiseInjection = 0.0;

  // Lorenz attractor state (for smooth chaotic modulation)
  double _x = 1.0;
  double _y = 1.0;
  double _z = 1.0;

  void setChaosLevel(double level) {
    _chaosLevel = level.clamp(0.0, 1.0);
    _noiseInjection = _chaosLevel * 0.3; // 0-30% noise
    _filterRandomization = _chaosLevel * 0.5; // 0-50% filter randomization
  }

  /// Get chaotic noise value
  double getNoiseValue() {
    if (_chaosLevel < 0.01) return 0.0;
    return (_random.nextDouble() * 2.0 - 1.0) * _noiseInjection;
  }

  /// Get smooth chaotic modulation using Lorenz attractor
  double getChaosModulation(double deltaTime) {
    if (_chaosLevel < 0.01) return 0.0;

    // Lorenz attractor parameters (scaled for audio)
    const double sigma = 10.0;
    const double rho = 28.0;
    const double beta = 8.0 / 3.0;
    const double scale = 0.01;

    // Update Lorenz system
    final double dx = sigma * (_y - _x) * deltaTime * scale;
    final double dy = (_x * (rho - _z) - _y) * deltaTime * scale;
    final double dz = (_x * _y - beta * _z) * deltaTime * scale;

    _x += dx;
    _y += dy;
    _z += dz;

    // Normalize to -1 to 1 and scale by chaos level
    return (_x / 20.0).clamp(-1.0, 1.0) * _chaosLevel;
  }

  /// Get filter randomization amount
  double getFilterRandomization() => _filterRandomization;

  double get noiseLevel => _noiseInjection;
  double get chaosLevel => _chaosLevel;
}

/// Spectral tilt filter for hue shift mapping
class SpectralTiltFilter {
  double _tiltAmount = 0.0; // -1 to 1 (-12dB to +12dB)

  void setTilt(double tilt) {
    _tiltAmount = tilt.clamp(-1.0, 1.0);
  }

  /// Apply spectral tilt to audio sample
  double process(double sample, double frequency, double sampleRate) {
    if (_tiltAmount.abs() < 0.01) return sample;

    // Simple first-order tilt filter
    // Positive tilt = brighter (high shelf boost)
    // Negative tilt = darker (high shelf cut)
    final double cutoff = 1000.0; // Center frequency
    final double normalizedFreq = frequency / sampleRate;
    final double tiltDb = _tiltAmount * 12.0; // ±12dB range

    // Approximate frequency response adjustment
    final double gain = math.pow(
      10.0,
      tiltDb * normalizedFreq * 0.05,
    ).toDouble();

    return sample * gain.clamp(0.25, 4.0); // Limit gain range
  }

  double get tiltAmount => _tiltAmount;
  double get tiltDb => _tiltAmount * 12.0;
}

/// Polyphony manager for tessellation density mapping
class PolyphonyManager {
  int _currentVoiceCount = 1;
  int _targetVoiceCount = 1;
  final int _maxVoices = 8;

  void setTessellationDensity(double density) {
    // Map density (0-1) to voice count (1-8)
    _targetVoiceCount = (1 + density * 7).round().clamp(1, _maxVoices);
  }

  void update() {
    // Smooth voice count changes
    if (_currentVoiceCount < _targetVoiceCount) {
      _currentVoiceCount++;
    } else if (_currentVoiceCount > _targetVoiceCount) {
      _currentVoiceCount--;
    }
  }

  int get currentVoiceCount => _currentVoiceCount;
  int get targetVoiceCount => _targetVoiceCount;
  int get maxVoices => _maxVoices;
}

/// Stereo width processor for projection mode mapping
class StereoWidthProcessor {
  double _width = 1.0; // 0 = mono, 1 = normal, 2 = ultra-wide

  void setProjectionMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'orthographic':
        _width = 0.5; // Narrow stereo
        break;
      case 'perspective':
        _width = 1.0; // Normal stereo
        break;
      case 'stereographic':
        _width = 1.5; // Wide stereo
        break;
      case 'hyperbolic':
        _width = 2.0; // Ultra-wide stereo
        break;
      default:
        _width = 1.0;
    }
  }

  void setWidth(double width) {
    _width = width.clamp(0.0, 2.0);
  }

  /// Process stereo samples
  Map<String, double> processStereo(double left, double right) {
    if ((_width - 1.0).abs() < 0.01) {
      return {'left': left, 'right': right};
    }

    // Mid-side processing
    final double mid = (left + right) * 0.5;
    final double side = (left - right) * 0.5;

    // Apply width
    final double wideSide = side * _width;

    return {
      'left': mid + wideSide,
      'right': mid - wideSide,
    };
  }

  double get width => _width;
}

/// Harmonic richness controller for complexity mapping
class HarmonicRichnessController {
  double _complexity = 0.5;
  int _harmonicCount = 4;
  double _harmonicSpread = 0.5;
  double _harmonicDecay = 0.7;

  void setComplexity(double complexity) {
    _complexity = complexity.clamp(0.0, 1.0);

    // More complexity = more harmonics, wider spread, slower decay
    _harmonicCount = (2 + complexity * 6).round().clamp(2, 8);
    _harmonicSpread = 0.3 + complexity * 0.6; // 0.3 to 0.9
    _harmonicDecay = 0.9 - complexity * 0.3; // 0.9 to 0.6 (faster decay = less sustain)
  }

  /// Get harmonic amplitude for a given harmonic number
  double getHarmonicAmplitude(int harmonicNumber) {
    if (harmonicNumber < 1 || harmonicNumber > _harmonicCount) {
      return 0.0;
    }

    // Exponential decay with spread
    final double baseAmplitude = math.pow(_harmonicDecay, harmonicNumber - 1).toDouble();
    final double spreadFactor = 1.0 + (_harmonicSpread * 0.2 * (harmonicNumber - 1));

    return baseAmplitude * spreadFactor;
  }

  int get harmonicCount => _harmonicCount;
  double get complexity => _complexity;
  double get harmonicSpread => _harmonicSpread;
  double get harmonicDecay => _harmonicDecay;
}

/// Main enhanced parameter modulation system
class EnhancedParameterModulation {
  // Modulation components
  final LFO speedLFO = LFO();
  final ChaosGenerator chaosGen = ChaosGenerator();
  final SpectralTiltFilter spectralTilt = SpectralTiltFilter();
  final PolyphonyManager polyphonyMgr = PolyphonyManager();
  final StereoWidthProcessor stereoWidth = StereoWidthProcessor();
  final HarmonicRichnessController harmonicRichness = HarmonicRichnessController();

  // Timing
  DateTime _lastUpdate = DateTime.now();

  /// Update all modulation systems
  void update() {
    final DateTime now = DateTime.now();
    final double deltaTime = now.difference(_lastUpdate).inMicroseconds / 1000000.0;
    _lastUpdate = now;

    // Update time-based modulators
    speedLFO.nextValue(deltaTime);
    chaosGen.getChaosModulation(deltaTime);
    polyphonyMgr.update();

    // Log performance periodically
    if (math.Random().nextDouble() < 0.01) {
      // ~1% chance = ~0.6 times per second at 60 FPS
      _logPerformanceStats();
    }
  }

  /// Set parameters from visual system
  void setMorphParameter(double morph) {
    // Morph is already handled by wavetable position in base system
    // This could add additional morphing effects if needed
  }

  void setChaosParameter(double chaos) {
    chaosGen.setChaosLevel(chaos);

    if (kDebugMode && chaos > 0.1) {
      Logger.debug(
        'Chaos parameter updated',
        category: LogCategory.mapping,
        metadata: {
          'chaos_level': chaos.toStringAsFixed(2),
          'noise_injection': (chaosGen.noiseLevel * 100).toStringAsFixed(1),
        },
      );
    }
  }

  void setSpeedParameter(double speed) {
    // Map speed (0-1) to LFO rate (0.1-10 Hz)
    speedLFO.rate = 0.1 + speed * 9.9;

    if (kDebugMode && speed > 0.1) {
      Logger.debug(
        'Speed parameter updated',
        category: LogCategory.mapping,
        metadata: {'lfo_rate_hz': speedLFO.rate.toStringAsFixed(2)},
      );
    }
  }

  void setHueShift(double hue) {
    // Map hue (0-1) to spectral tilt (-1 to 1)
    spectralTilt.setTilt(hue * 2.0 - 1.0);

    if (kDebugMode && hue.abs() > 0.1) {
      Logger.debug(
        'Hue shift updated',
        category: LogCategory.mapping,
        metadata: {'spectral_tilt_db': spectralTilt.tiltDb.toStringAsFixed(1)},
      );
    }
  }

  void setGlowIntensity(double glow) {
    // Glow affects reverb and attack in the audio engine
    // This is passed through to the audio provider
  }

  void setTessellationDensity(double density) {
    polyphonyMgr.setTessellationDensity(density);

    if (kDebugMode && (polyphonyMgr.currentVoiceCount != polyphonyMgr.targetVoiceCount)) {
      Logger.debug(
        'Tessellation density updated',
        category: LogCategory.mapping,
        metadata: {
          'target_voices': polyphonyMgr.targetVoiceCount,
          'current_voices': polyphonyMgr.currentVoiceCount,
        },
      );
    }
  }

  void setProjectionMode(String mode) {
    stereoWidth.setProjectionMode(mode);

    Logger.debug(
      'Projection mode updated',
      category: LogCategory.mapping,
      metadata: {
        'mode': mode,
        'stereo_width': stereoWidth.width.toStringAsFixed(2),
      },
    );
  }

  void setComplexity(double complexity) {
    harmonicRichness.setComplexity(complexity);

    if (kDebugMode && complexity > 0.1) {
      Logger.debug(
        'Complexity updated',
        category: LogCategory.mapping,
        metadata: {
          'complexity': complexity.toStringAsFixed(2),
          'harmonics': harmonicRichness.harmonicCount,
          'spread': harmonicRichness.harmonicSpread.toStringAsFixed(2),
        },
      );
    }
  }

  /// Get current modulation state for debugging
  Map<String, dynamic> getModulationState() => {
        'lfo_rate': speedLFO.rate,
        'lfo_phase': speedLFO.phase,
        'chaos_level': chaosGen.chaosLevel,
        'noise_level': chaosGen.noiseLevel,
        'spectral_tilt_db': spectralTilt.tiltDb,
        'voice_count': polyphonyMgr.currentVoiceCount,
        'stereo_width': stereoWidth.width,
        'harmonic_count': harmonicRichness.harmonicCount,
        'complexity': harmonicRichness.complexity,
      };

  void _logPerformanceStats() {
    Logger.debug(
      'Modulation system stats',
      category: LogCategory.performance,
      metadata: {
        'lfo_active': speedLFO.rate > 0.5,
        'chaos_active': chaosGen.chaosLevel > 0.1,
        'voices': polyphonyMgr.currentVoiceCount,
      },
    );
  }

  /// Reset all modulators
  void reset() {
    speedLFO.reset();
    chaosGen.setChaosLevel(0.0);
    spectralTilt.setTilt(0.0);
    polyphonyMgr.setTessellationDensity(0.0);
    stereoWidth.setWidth(1.0);
    harmonicRichness.setComplexity(0.5);
  }
}
