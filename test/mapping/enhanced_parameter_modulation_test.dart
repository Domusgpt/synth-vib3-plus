/**
 * Enhanced Parameter Modulation Tests
 *
 * Comprehensive test suite for advanced parameter modulation system
 * including LFO, chaos generator, spectral tilt, polyphony, stereo width,
 * and harmonic richness.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synth_vib3_plus/mapping/enhanced_parameter_modulation.dart';
import 'dart:math' as math;

void main() {
  group('LFO (Low-Frequency Oscillator)', () {
    late LFO lfo;

    setUp(() {
      lfo = LFO();
    });

    test('should initialize with default values', () {
      expect(lfo.phase, equals(0.0));
      expect(lfo.rate, equals(1.0));
      expect(lfo.waveform, equals(LFOWaveform.sine));
    });

    test('should generate sine waveform correctly', () {
      lfo.waveform = LFOWaveform.sine;
      lfo.rate = 1.0;

      final value1 = lfo.nextValue(0.0);
      expect(value1, closeTo(0.0, 0.01));

      final value2 = lfo.nextValue(0.25);
      expect(value2, closeTo(1.0, 0.01));

      final value3 = lfo.nextValue(0.25);
      expect(value3, closeTo(0.0, 0.01));
    });

    test('should generate triangle waveform correctly', () {
      lfo.waveform = LFOWaveform.triangle;
      lfo.rate = 1.0;

      final value1 = lfo.nextValue(0.0);
      expect(value1, closeTo(-1.0, 0.01));

      final value2 = lfo.nextValue(0.25);
      expect(value2, closeTo(1.0, 0.01));
    });

    test('should generate square waveform correctly', () {
      lfo.waveform = LFOWaveform.square;
      lfo.rate = 1.0;

      final value1 = lfo.nextValue(0.0);
      expect(value1, equals(1.0));

      final value2 = lfo.nextValue(0.5);
      expect(value2, equals(-1.0));
    });

    test('should generate saw waveform correctly', () {
      lfo.waveform = LFOWaveform.saw;
      lfo.rate = 1.0;

      final value1 = lfo.nextValue(0.0);
      expect(value1, closeTo(-1.0, 0.01));

      final value2 = lfo.nextValue(0.5);
      expect(value2, closeTo(0.0, 0.01));
    });

    test('should generate random waveform with values in range', () {
      lfo.waveform = LFOWaveform.random;

      for (int i = 0; i < 100; i++) {
        final value = lfo.nextValue(0.01);
        expect(value, greaterThanOrEqualTo(-1.0));
        expect(value, lessThanOrEqualTo(1.0));
      }
    });

    test('should wrap phase at 2π', () {
      lfo.rate = 1.0;
      lfo.nextValue(1.0); // Should complete one cycle
      expect(lfo.phase, closeTo(0.0, 0.01));
    });

    test('should reset phase correctly', () {
      lfo.nextValue(0.5);
      expect(lfo.phase, greaterThan(0.0));

      lfo.reset();
      expect(lfo.phase, equals(0.0));
    });

    test('should respect different rates', () {
      lfo.rate = 2.0;
      lfo.nextValue(0.5); // At 2Hz, 0.5s = one full cycle
      expect(lfo.phase, closeTo(0.0, 0.01));

      lfo.rate = 0.5;
      lfo.reset();
      lfo.nextValue(1.0); // At 0.5Hz, 1s = half cycle
      expect(lfo.phase, closeTo(math.pi, 0.01));
    });
  });

  group('ChaosGenerator', () {
    late ChaosGenerator chaos;

    setUp(() {
      chaos = ChaosGenerator();
    });

    test('should initialize with zero chaos level', () {
      expect(chaos.chaosLevel, equals(0.0));
      expect(chaos.noiseLevel, equals(0.0));
    });

    test('should set chaos level correctly', () {
      chaos.setChaosLevel(0.5);
      expect(chaos.chaosLevel, equals(0.5));
      expect(chaos.noiseLevel, closeTo(0.15, 0.01)); // 30% of 0.5
    });

    test('should clamp chaos level to 0-1 range', () {
      chaos.setChaosLevel(1.5);
      expect(chaos.chaosLevel, equals(1.0));

      chaos.setChaosLevel(-0.5);
      expect(chaos.chaosLevel, equals(0.0));
    });

    test('should return zero noise when chaos is zero', () {
      chaos.setChaosLevel(0.0);
      expect(chaos.getNoiseValue(), equals(0.0));
    });

    test('should generate noise in expected range', () {
      chaos.setChaosLevel(1.0);

      for (int i = 0; i < 100; i++) {
        final noise = chaos.getNoiseValue();
        expect(noise.abs(), lessThanOrEqualTo(0.3)); // Max 30%
      }
    });

    test('should return zero modulation when chaos is zero', () {
      chaos.setChaosLevel(0.0);
      final mod = chaos.getChaosModulation(0.01);
      expect(mod, equals(0.0));
    });

    test('should generate bounded chaos modulation', () {
      chaos.setChaosLevel(1.0);

      for (int i = 0; i < 100; i++) {
        final mod = chaos.getChaosModulation(0.01);
        expect(mod, greaterThanOrEqualTo(-1.0));
        expect(mod, lessThanOrEqualTo(1.0));
      }
    });

    test('should produce smooth chaotic evolution (Lorenz attractor)', () {
      chaos.setChaosLevel(0.5);

      final values = <double>[];
      for (int i = 0; i < 100; i++) {
        values.add(chaos.getChaosModulation(0.01));
      }

      // Check that values change smoothly (no huge jumps)
      for (int i = 1; i < values.length; i++) {
        final diff = (values[i] - values[i - 1]).abs();
        expect(diff, lessThan(0.5)); // No sudden jumps
      }
    });

    test('should scale filter randomization with chaos level', () {
      chaos.setChaosLevel(0.0);
      expect(chaos.getFilterRandomization(), equals(0.0));

      chaos.setChaosLevel(0.5);
      expect(chaos.getFilterRandomization(), closeTo(0.25, 0.01)); // 50% of 0.5

      chaos.setChaosLevel(1.0);
      expect(chaos.getFilterRandomization(), closeTo(0.5, 0.01)); // Max 50%
    });
  });

  group('SpectralTiltFilter', () {
    late SpectralTiltFilter filter;

    setUp(() {
      filter = SpectralTiltFilter();
    });

    test('should initialize with zero tilt', () {
      expect(filter.tiltAmount, equals(0.0));
      expect(filter.tiltDb, equals(0.0));
    });

    test('should set tilt amount correctly', () {
      filter.setTilt(0.5);
      expect(filter.tiltAmount, equals(0.5));
      expect(filter.tiltDb, closeTo(6.0, 0.01)); // 50% of ±12dB

      filter.setTilt(-0.5);
      expect(filter.tiltAmount, equals(-0.5));
      expect(filter.tiltDb, closeTo(-6.0, 0.01));
    });

    test('should clamp tilt to -1 to 1 range', () {
      filter.setTilt(1.5);
      expect(filter.tiltAmount, equals(1.0));

      filter.setTilt(-1.5);
      expect(filter.tiltAmount, equals(-1.0));
    });

    test('should pass through signal when tilt is zero', () {
      filter.setTilt(0.0);
      final processed = filter.process(1.0, 1000.0, 44100.0);
      expect(processed, closeTo(1.0, 0.01));
    });

    test('should boost high frequencies with positive tilt', () {
      filter.setTilt(1.0); // +12dB tilt

      final lowFreq = filter.process(1.0, 100.0, 44100.0);
      final highFreq = filter.process(1.0, 10000.0, 44100.0);

      expect(highFreq, greaterThan(lowFreq));
    });

    test('should attenuate high frequencies with negative tilt', () {
      filter.setTilt(-1.0); // -12dB tilt

      final lowFreq = filter.process(1.0, 100.0, 44100.0);
      final highFreq = filter.process(1.0, 10000.0, 44100.0);

      expect(lowFreq, greaterThan(highFreq));
    });

    test('should limit gain to safe range', () {
      filter.setTilt(1.0); // Maximum tilt

      for (int freq = 100; freq < 20000; freq += 100) {
        final processed = filter.process(1.0, freq.toDouble(), 44100.0);
        expect(processed, greaterThanOrEqualTo(0.25));
        expect(processed, lessThanOrEqualTo(4.0));
      }
    });
  });

  group('PolyphonyManager', () {
    late PolyphonyManager manager;

    setUp(() {
      manager = PolyphonyManager();
    });

    test('should initialize with 1 voice', () {
      expect(manager.currentVoiceCount, equals(1));
      expect(manager.targetVoiceCount, equals(1));
      expect(manager.maxVoices, equals(8));
    });

    test('should map tessellation density to voice count', () {
      manager.setTessellationDensity(0.0);
      expect(manager.targetVoiceCount, equals(1));

      manager.setTessellationDensity(0.5);
      expect(manager.targetVoiceCount, equals(4));

      manager.setTessellationDensity(1.0);
      expect(manager.targetVoiceCount, equals(8));
    });

    test('should clamp voice count to 1-8 range', () {
      manager.setTessellationDensity(-0.5);
      expect(manager.targetVoiceCount, equals(1));

      manager.setTessellationDensity(1.5);
      expect(manager.targetVoiceCount, equals(8));
    });

    test('should smoothly transition voice count upward', () {
      manager.setTessellationDensity(1.0); // Target 8 voices
      expect(manager.targetVoiceCount, equals(8));

      // Should increment by 1 each update
      for (int i = 1; i < 8; i++) {
        manager.update();
        expect(manager.currentVoiceCount, equals(i + 1));
      }
    });

    test('should smoothly transition voice count downward', () {
      // Start at 8 voices
      manager.setTessellationDensity(1.0);
      for (int i = 0; i < 7; i++) {
        manager.update();
      }
      expect(manager.currentVoiceCount, equals(8));

      // Target 1 voice
      manager.setTessellationDensity(0.0);
      expect(manager.targetVoiceCount, equals(1));

      // Should decrement by 1 each update
      for (int i = 8; i > 1; i--) {
        manager.update();
        expect(manager.currentVoiceCount, equals(i - 1));
      }
    });

    test('should not change when at target', () {
      manager.setTessellationDensity(0.5);
      for (int i = 0; i < 10; i++) {
        manager.update();
      }

      final count = manager.currentVoiceCount;
      manager.update();
      expect(manager.currentVoiceCount, equals(count));
    });
  });

  group('StereoWidthProcessor', () {
    late StereoWidthProcessor processor;

    setUp(() {
      processor = StereoWidthProcessor();
    });

    test('should initialize with normal stereo width', () {
      expect(processor.width, equals(1.0));
    });

    test('should set width correctly', () {
      processor.setWidth(0.5);
      expect(processor.width, equals(0.5));

      processor.setWidth(2.0);
      expect(processor.width, equals(2.0));
    });

    test('should clamp width to 0-2 range', () {
      processor.setWidth(-0.5);
      expect(processor.width, equals(0.0));

      processor.setWidth(2.5);
      expect(processor.width, equals(2.0));
    });

    test('should map projection modes to width correctly', () {
      processor.setProjectionMode('orthographic');
      expect(processor.width, equals(0.5));

      processor.setProjectionMode('perspective');
      expect(processor.width, equals(1.0));

      processor.setProjectionMode('stereographic');
      expect(processor.width, equals(1.5));

      processor.setProjectionMode('hyperbolic');
      expect(processor.width, equals(2.0));
    });

    test('should pass through when width is 1.0', () {
      processor.setWidth(1.0);
      final result = processor.processStereo(0.8, -0.8);

      expect(result['left'], closeTo(0.8, 0.01));
      expect(result['right'], closeTo(-0.8, 0.01));
    });

    test('should narrow stereo image with width < 1.0', () {
      processor.setWidth(0.0); // Mono
      final result = processor.processStereo(1.0, -1.0);

      // Should sum to mono (both channels equal)
      expect(result['left'], closeTo(result['right']!, 0.01));
    });

    test('should widen stereo image with width > 1.0', () {
      processor.setWidth(2.0); // Ultra-wide
      final result = processor.processStereo(0.5, -0.5);

      // Sides should be more extreme than input
      expect((result['left']! - result['right']!).abs(), greaterThan(1.0));
    });

    test('should preserve mid-side energy balance', () {
      processor.setWidth(1.5);

      final left = 0.8;
      final right = 0.6;
      final result = processor.processStereo(left, right);

      // Mid should be preserved
      final inputMid = (left + right) * 0.5;
      final outputMid = (result['left']! + result['right']!) * 0.5;

      expect(outputMid, closeTo(inputMid, 0.01));
    });
  });

  group('HarmonicRichnessController', () {
    late HarmonicRichnessController controller;

    setUp(() {
      controller = HarmonicRichnessController();
    });

    test('should initialize with default values', () {
      expect(controller.complexity, equals(0.5));
      expect(controller.harmonicCount, greaterThanOrEqualTo(2));
      expect(controller.harmonicCount, lessThanOrEqualTo(8));
    });

    test('should map complexity to harmonic count', () {
      controller.setComplexity(0.0);
      expect(controller.harmonicCount, equals(2));

      controller.setComplexity(0.5);
      expect(controller.harmonicCount, closeTo(5, 1));

      controller.setComplexity(1.0);
      expect(controller.harmonicCount, equals(8));
    });

    test('should clamp complexity to 0-1 range', () {
      controller.setComplexity(-0.5);
      expect(controller.complexity, equals(0.0));

      controller.setComplexity(1.5);
      expect(controller.complexity, equals(1.0));
    });

    test('should return zero amplitude for invalid harmonic numbers', () {
      controller.setComplexity(0.5);

      expect(controller.getHarmonicAmplitude(0), equals(0.0));
      expect(controller.getHarmonicAmplitude(9), equals(0.0));
    });

    test('should produce exponential decay', () {
      controller.setComplexity(0.5);

      final amp1 = controller.getHarmonicAmplitude(1);
      final amp2 = controller.getHarmonicAmplitude(2);
      final amp3 = controller.getHarmonicAmplitude(3);

      expect(amp1, greaterThan(amp2));
      expect(amp2, greaterThan(amp3));
    });

    test('should adjust spread with complexity', () {
      controller.setComplexity(0.0);
      final spread1 = controller.harmonicSpread;

      controller.setComplexity(1.0);
      final spread2 = controller.harmonicSpread;

      expect(spread2, greaterThan(spread1));
    });

    test('should adjust decay with complexity', () {
      controller.setComplexity(0.0);
      final decay1 = controller.harmonicDecay;

      controller.setComplexity(1.0);
      final decay2 = controller.harmonicDecay;

      // Higher complexity = lower decay = longer sustain
      expect(decay1, greaterThan(decay2));
    });

    test('should produce valid amplitudes for all harmonics', () {
      controller.setComplexity(1.0);

      for (int i = 1; i <= controller.harmonicCount; i++) {
        final amp = controller.getHarmonicAmplitude(i);
        expect(amp, greaterThan(0.0));
        expect(amp, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('EnhancedParameterModulation (Integration)', () {
    late EnhancedParameterModulation modulation;

    setUp(() {
      modulation = EnhancedParameterModulation();
    });

    test('should initialize all components', () {
      expect(modulation.speedLFO, isNotNull);
      expect(modulation.chaosGen, isNotNull);
      expect(modulation.spectralTilt, isNotNull);
      expect(modulation.polyphonyMgr, isNotNull);
      expect(modulation.stereoWidth, isNotNull);
      expect(modulation.harmonicRichness, isNotNull);
    });

    test('should update all time-based modulators', () {
      final initialPhase = modulation.speedLFO.phase;

      modulation.update();

      // Phase should advance
      expect(modulation.speedLFO.phase, greaterThan(initialPhase));
    });

    test('should set all parameters correctly', () {
      modulation.setChaosParameter(0.5);
      expect(modulation.chaosGen.chaosLevel, equals(0.5));

      modulation.setSpeedParameter(0.8);
      expect(modulation.speedLFO.rate, closeTo(8.02, 0.1)); // 0.1 + 0.8*9.9

      modulation.setHueShift(0.5);
      expect(modulation.spectralTilt.tiltAmount, closeTo(0.0, 0.01)); // 0.5*2-1=0

      modulation.setTessellationDensity(0.5);
      expect(modulation.polyphonyMgr.targetVoiceCount, equals(4));

      modulation.setProjectionMode('hyperbolic');
      expect(modulation.stereoWidth.width, equals(2.0));

      modulation.setComplexity(0.8);
      expect(modulation.harmonicRichness.complexity, equals(0.8));
    });

    test('should export complete modulation state', () {
      modulation.setSpeedParameter(0.5);
      modulation.setChaosParameter(0.3);
      modulation.setComplexity(0.7);

      final state = modulation.getModulationState();

      expect(state, containsPair('lfo_rate', anything));
      expect(state, containsPair('lfo_phase', anything));
      expect(state, containsPair('chaos_level', 0.3));
      expect(state, containsPair('noise_level', anything));
      expect(state, containsPair('spectral_tilt_db', anything));
      expect(state, containsPair('voice_count', anything));
      expect(state, containsPair('stereo_width', anything));
      expect(state, containsPair('harmonic_count', anything));
      expect(state, containsPair('complexity', 0.7));
    });

    test('should reset all modulators', () {
      // Set non-default values
      modulation.setChaosParameter(0.8);
      modulation.setSpeedParameter(0.9);
      modulation.setComplexity(0.9);

      modulation.reset();

      // Check reset values
      expect(modulation.speedLFO.phase, equals(0.0));
      expect(modulation.chaosGen.chaosLevel, equals(0.0));
      expect(modulation.spectralTilt.tiltAmount, equals(0.0));
      expect(modulation.stereoWidth.width, equals(1.0));
      expect(modulation.harmonicRichness.complexity, equals(0.5));
    });

    test('should handle rapid updates without errors', () {
      // Simulate 60 FPS updates for 1 second
      for (int i = 0; i < 60; i++) {
        expect(() => modulation.update(), returnsNormally);
      }
    });

    test('should integrate all systems coherently', () {
      // Set typical performance values
      modulation.setSpeedParameter(0.6); // Moderate LFO rate
      modulation.setChaosParameter(0.3); // Subtle chaos
      modulation.setHueShift(0.7); // Bright tilt
      modulation.setTessellationDensity(0.5); // 4 voices
      modulation.setProjectionMode('stereographic'); // Wide stereo
      modulation.setComplexity(0.6); // Rich harmonics

      // Update and verify state is coherent
      modulation.update();
      final state = modulation.getModulationState();

      expect(state['lfo_rate'], closeTo(6.04, 0.2)); // 0.1 + 0.6*9.9
      expect(state['chaos_level'], equals(0.3));
      expect(state['voice_count'], equals(4));
      expect(state['stereo_width'], equals(1.5));
      expect(state['harmonic_count'], greaterThanOrEqualTo(5));
    });
  });
}
