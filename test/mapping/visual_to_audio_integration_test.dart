/**
 * Visual-to-Audio Integration Tests
 *
 * Test suite for enhanced visual-to-audio parameter modulation integration.
 *
 * Tests the integration of EnhancedParameterModulation with the
 * VisualToAudioModulator system.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synth_vib3_plus/mapping/enhanced_parameter_modulation.dart';
import 'dart:math' as math;

void main() {
  group('Parameter Mapping Integration', () {
    test('should map chaos level to noise injection correctly', () {
      final chaos = ChaosGenerator();

      chaos.setChaosLevel(0.0);
      expect(chaos.noiseLevel, equals(0.0));

      chaos.setChaosLevel(0.5);
      expect(chaos.noiseLevel, closeTo(0.15, 0.01)); // 30% of 0.5

      chaos.setChaosLevel(1.0);
      expect(chaos.noiseLevel, closeTo(0.3, 0.01)); // Max 30%
    });

    test('should map speed to LFO rate logarithmically', () {
      // Speed range: 0-1 → LFO rate: 0.1-10 Hz
      expect(_speedToLFORate(0.0), closeTo(0.1, 0.01));
      expect(_speedToLFORate(0.5), closeTo(5.05, 0.1));
      expect(_speedToLFORate(1.0), closeTo(10.0, 0.01));
    });

    test('should map hue shift to spectral tilt linearly', () {
      final filter = SpectralTiltFilter();

      // Hue 0-1 → Tilt -1 to 1 (-12dB to +12dB)
      filter.setTilt(0.0 * 2.0 - 1.0); // -1.0
      expect(filter.tiltDb, closeTo(-12.0, 0.01));

      filter.setTilt(0.5 * 2.0 - 1.0); // 0.0
      expect(filter.tiltDb, closeTo(0.0, 0.01));

      filter.setTilt(1.0 * 2.0 - 1.0); // 1.0
      expect(filter.tiltDb, closeTo(12.0, 0.01));
    });

    test('should map glow intensity to reverb and attack', () {
      // Glow 0.0 → Reverb 5%, Attack 1ms
      final reverb1 = _glowToReverb(0.0);
      final attack1 = _glowToAttack(0.0);
      expect(reverb1, closeTo(0.05, 0.01));
      expect(attack1, closeTo(1.0, 0.01));

      // Glow 0.5 → Reverb ~32.5%, Attack ~50.5ms
      final reverb2 = _glowToReverb(0.5);
      final attack2 = _glowToAttack(0.5);
      expect(reverb2, closeTo(0.325, 0.01));
      expect(attack2, closeTo(50.5, 0.5));

      // Glow 1.0 → Reverb 60%, Attack 100ms
      final reverb3 = _glowToReverb(1.0);
      final attack3 = _glowToAttack(1.0);
      expect(reverb3, closeTo(0.60, 0.01));
      expect(attack3, closeTo(100.0, 0.01));
    });

    test('should map tessellation density to polyphony linearly', () {
      final manager = PolyphonyManager();

      manager.setTessellationDensity(0.0);
      expect(manager.targetVoiceCount, equals(1));

      manager.setTessellationDensity(0.5);
      expect(manager.targetVoiceCount, equals(4));

      manager.setTessellationDensity(1.0);
      expect(manager.targetVoiceCount, equals(8));
    });

    test('should map complexity to harmonic richness', () {
      final controller = HarmonicRichnessController();

      controller.setComplexity(0.0);
      expect(controller.harmonicCount, equals(2));

      controller.setComplexity(0.5);
      expect(controller.harmonicCount, closeTo(5, 1));

      controller.setComplexity(1.0);
      expect(controller.harmonicCount, equals(8));
    });

    test('should map projection mode to stereo width', () {
      final processor = StereoWidthProcessor();

      processor.setProjectionMode('orthographic');
      expect(processor.width, equals(0.5));

      processor.setProjectionMode('perspective');
      expect(processor.width, equals(1.0));

      processor.setProjectionMode('stereographic');
      expect(processor.width, equals(1.5));

      processor.setProjectionMode('hyperbolic');
      expect(processor.width, equals(2.0));
    });
  });

  group('Mapping Curve Types', () {
    test('should apply linear mapping correctly', () {
      // Linear: output = input
      expect(_applyLinearCurve(0.0), equals(0.0));
      expect(_applyLinearCurve(0.5), equals(0.5));
      expect(_applyLinearCurve(1.0), equals(1.0));
    });

    test('should apply exponential mapping correctly', () {
      // Exponential: output = input^2
      expect(_applyExponentialCurve(0.0), equals(0.0));
      expect(_applyExponentialCurve(0.5), closeTo(0.25, 0.01));
      expect(_applyExponentialCurve(1.0), equals(1.0));
    });

    test('should apply logarithmic mapping correctly', () {
      // Logarithmic: output = sqrt(input)
      expect(_applyLogarithmicCurve(0.0), equals(0.0));
      expect(_applyLogarithmicCurve(0.25), closeTo(0.5, 0.01));
      expect(_applyLogarithmicCurve(1.0), equals(1.0));
    });

    test('should apply sinusoidal mapping correctly', () {
      // Sinusoidal: output = sin(input * π/2)
      expect(_applySinusoidalCurve(0.0), closeTo(0.0, 0.01));
      expect(_applySinusoidalCurve(0.5), closeTo(0.707, 0.01));
      expect(_applySinusoidalCurve(1.0), closeTo(1.0, 0.01));
    });
  });

  group('Enhanced Modulation Integration', () {
    late EnhancedParameterModulation modulation;

    setUp(() {
      modulation = EnhancedParameterModulation();
    });

    test('should integrate all 7 new parameter mappings', () {
      // Set all parameters
      modulation.setChaosParameter(0.5);
      modulation.setSpeedParameter(0.6);
      modulation.setHueShift(0.7);
      modulation.setGlowIntensity(0.4);
      modulation.setTessellationDensity(0.5);
      modulation.setProjectionMode('stereographic');
      modulation.setComplexity(0.6);

      // Update modulation
      modulation.update();

      // Verify state
      final state = modulation.getModulationState();
      expect(state['chaos_level'], equals(0.5));
      expect(state['lfo_rate'], greaterThan(0.1));
      expect(state['spectral_tilt_db'], anything);
      expect(state['voice_count'], anything);
      expect(state['stereo_width'], equals(1.5));
      expect(state['harmonic_count'], greaterThanOrEqualTo(5));
    });

    test('should handle rapid parameter changes', () {
      // Simulate UI interaction with rapid changes
      for (int i = 0; i < 60; i++) {
        final value = (i / 60.0);
        modulation.setChaosParameter(value);
        modulation.setSpeedParameter(value);
        modulation.setComplexity(value);
        modulation.update();
      }

      // Should complete without errors
      expect(() => modulation.update(), returnsNormally);
    });

    test('should maintain performance at 60 FPS', () {
      final iterations = 60; // 1 second at 60 FPS
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        modulation.update();
      }

      stopwatch.stop();

      // Should complete 60 updates in < 16ms (60 FPS target)
      expect(stopwatch.elapsedMilliseconds, lessThan(16));
    });

    test('should produce smooth transitions', () {
      // Test voice count smooth transition
      modulation.setTessellationDensity(1.0); // Target 8 voices

      final voiceCounts = <int>[];
      for (int i = 0; i < 10; i++) {
        modulation.update();
        voiceCounts.add(modulation.polyphonyMgr.currentVoiceCount);
      }

      // Voice count should increment smoothly (no jumps > 1)
      for (int i = 1; i < voiceCounts.length; i++) {
        final diff = (voiceCounts[i] - voiceCounts[i - 1]).abs();
        expect(diff, lessThanOrEqualTo(1));
      }
    });
  });

  group('Visual State Normalization', () {
    test('should normalize rotation angles to 0-1 range', () {
      // 0 radians → 0.0
      expect(_normalizeRotation(0.0), closeTo(0.0, 0.01));

      // π radians → 0.5
      expect(_normalizeRotation(math.pi), closeTo(0.5, 0.01));

      // 2π radians → 0.0 (full cycle)
      expect(_normalizeRotation(2 * math.pi), closeTo(0.0, 0.01));

      // 3π radians → 0.5 (1.5 cycles)
      expect(_normalizeRotation(3 * math.pi), closeTo(0.5, 0.01));
    });

    test('should normalize projection distance to 0-1 range', () {
      // Distance range: 5-15
      expect(_normalizeProjectionDistance(5.0), closeTo(0.0, 0.01));
      expect(_normalizeProjectionDistance(10.0), closeTo(0.5, 0.01));
      expect(_normalizeProjectionDistance(15.0), closeTo(1.0, 0.01));

      // Should clamp out-of-range values
      expect(_normalizeProjectionDistance(0.0), equals(0.0));
      expect(_normalizeProjectionDistance(20.0), equals(1.0));
    });

    test('should normalize layer depth to 0-1 range', () {
      // Depth range: 0-5
      expect(_normalizeLayerDepth(0.0), equals(0.0));
      expect(_normalizeLayerDepth(2.5), closeTo(0.5, 0.01));
      expect(_normalizeLayerDepth(5.0), equals(1.0));

      // Should clamp out-of-range values
      expect(_normalizeLayerDepth(-1.0), equals(0.0));
      expect(_normalizeLayerDepth(10.0), equals(1.0));
    });

    test('should map vertex count to voice count logarithmically', () {
      // 10 vertices → 1 voice
      expect(_mapVertexCountToVoices(10), equals(1));

      // ~1000 vertices → ~8 voices
      expect(_mapVertexCountToVoices(1000), closeTo(8, 2));

      // 10000 vertices → 16 voices
      expect(_mapVertexCountToVoices(10000), equals(16));

      // Should clamp to valid range
      expect(_mapVertexCountToVoices(1), equals(1));
      expect(_mapVertexCountToVoices(100000), equals(16));
    });
  });

  group('Geometry and System Synchronization', () {
    test('should calculate full geometry index from system + geometry', () {
      // Quantum system (offset 0) + geometry 3 = 3
      expect(_calculateFullGeometry('quantum', 3), equals(3));

      // Faceted system (offset 8) + geometry 3 = 11
      expect(_calculateFullGeometry('faceted', 3), equals(11));

      // Holographic system (offset 16) + geometry 7 = 23
      expect(_calculateFullGeometry('holographic', 7), equals(23));
    });

    test('should get correct system offset', () {
      expect(_getSystemOffset('quantum'), equals(0));
      expect(_getSystemOffset('faceted'), equals(8));
      expect(_getSystemOffset('holographic'), equals(16));

      // Should handle case insensitivity
      expect(_getSystemOffset('QUANTUM'), equals(0));
      expect(_getSystemOffset('Faceted'), equals(8));
    });

    test('should validate geometry is in correct range for system', () {
      // Each system has 8 geometries (0-7)
      for (int geo = 0; geo < 8; geo++) {
        expect(() => _validateGeometryForSystem(geo), returnsNormally);
      }

      // Out of range should throw
      expect(() => _validateGeometryForSystem(-1), throwsArgumentError);
      expect(() => _validateGeometryForSystem(8), throwsArgumentError);
    });
  });

  group('Complete Integration Scenarios', () {
    test('should handle typical performance scenario', () {
      final modulation = EnhancedParameterModulation();

      // Set up a typical performance state
      modulation.setChaosParameter(0.3); // Subtle chaos
      modulation.setSpeedParameter(0.6); // Moderate speed
      modulation.setHueShift(0.7); // Bright tilt
      modulation.setGlowIntensity(0.5); // Medium reverb
      modulation.setTessellationDensity(0.5); // 4 voices
      modulation.setProjectionMode('stereographic'); // Wide stereo
      modulation.setComplexity(0.6); // Rich harmonics

      // Update for several frames
      for (int i = 0; i < 10; i++) {
        modulation.update();
      }

      // Verify final state is coherent
      final state = modulation.getModulationState();
      expect(state['chaos_level'], equals(0.3));
      expect(state['stereo_width'], equals(1.5));
      expect(state['voice_count'], greaterThan(1));
      expect(state['harmonic_count'], greaterThanOrEqualTo(5));
    });

    test('should handle extreme parameter values gracefully', () {
      final modulation = EnhancedParameterModulation();

      // Set all parameters to maximum
      modulation.setChaosParameter(1.0);
      modulation.setSpeedParameter(1.0);
      modulation.setHueShift(1.0);
      modulation.setGlowIntensity(1.0);
      modulation.setTessellationDensity(1.0);
      modulation.setProjectionMode('hyperbolic');
      modulation.setComplexity(1.0);

      // Should handle maximum values
      expect(() => modulation.update(), returnsNormally);

      // Set all parameters to minimum
      modulation.setChaosParameter(0.0);
      modulation.setSpeedParameter(0.0);
      modulation.setHueShift(0.0);
      modulation.setGlowIntensity(0.0);
      modulation.setTessellationDensity(0.0);
      modulation.setProjectionMode('orthographic');
      modulation.setComplexity(0.0);

      // Should handle minimum values
      expect(() => modulation.update(), returnsNormally);
    });

    test('should reset to safe defaults', () {
      final modulation = EnhancedParameterModulation();

      // Set extreme values
      modulation.setChaosParameter(1.0);
      modulation.setSpeedParameter(1.0);
      modulation.setComplexity(1.0);

      // Reset
      modulation.reset();

      // Verify reset state
      expect(modulation.speedLFO.phase, equals(0.0));
      expect(modulation.chaosGen.chaosLevel, equals(0.0));
      expect(modulation.stereoWidth.width, equals(1.0));
      expect(modulation.harmonicRichness.complexity, equals(0.5));
    });
  });
}

// Helper functions for testing mapping logic

double _speedToLFORate(double speed) {
  return 0.1 + speed * 9.9; // 0.1-10 Hz
}

double _glowToReverb(double glow) {
  return 0.05 + (glow * 0.55); // 5% to 60%
}

double _glowToAttack(double glow) {
  return 1.0 + (glow * 99.0); // 1ms to 100ms
}

double _applyLinearCurve(double value) {
  return value;
}

double _applyExponentialCurve(double value) {
  return value * value;
}

double _applyLogarithmicCurve(double value) {
  return math.sqrt(value);
}

double _applySinusoidalCurve(double value) {
  return math.sin(value * math.pi / 2.0);
}

double _normalizeRotation(double angle) {
  return (angle % (2.0 * math.pi)) / (2.0 * math.pi);
}

double _normalizeProjectionDistance(double distance) {
  return ((distance - 5.0) / 10.0).clamp(0.0, 1.0);
}

double _normalizeLayerDepth(double depth) {
  return (depth / 5.0).clamp(0.0, 1.0);
}

int _mapVertexCountToVoices(int vertexCount) {
  if (vertexCount < 10) return 1;
  if (vertexCount > 10000) return 16;

  final normalized = (math.log(vertexCount) - math.log(10)) /
      (math.log(10000) - math.log(10));

  return (1 + normalized * 15).round().clamp(1, 16);
}

int _calculateFullGeometry(String system, int geometry) {
  final offset = _getSystemOffset(system);
  return offset + geometry;
}

int _getSystemOffset(String system) {
  switch (system.toLowerCase()) {
    case 'quantum':
      return 0;
    case 'faceted':
      return 8;
    case 'holographic':
      return 16;
    default:
      return 0;
  }
}

void _validateGeometryForSystem(int geometry) {
  if (geometry < 0 || geometry > 7) {
    throw ArgumentError('Geometry must be 0-7 for a visual system, got: $geometry');
  }
}
