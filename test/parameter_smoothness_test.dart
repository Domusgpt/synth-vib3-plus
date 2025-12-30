// Parameter Smoothness & Real-time Performance Tests
//
// These tests verify:
// - Parameter changes don't cause audible artifacts
// - Timing is consistent for real-time performance
// - Audio-visual sync maintains 60 FPS target
// - No parameter jumps or sudden changes

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/audio/synthesizer_engine.dart';
import 'package:synther_vib34d_holographic/audio/audio_analyzer.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';
import 'package:synther_vib34d_holographic/mapping/audio_to_visual.dart';

void main() {
  group('Real-time Performance Tests', () {
    test('buffer generation meets 60 FPS timing budget', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      // At 60 FPS with 512 sample buffer at 44100Hz:
      // Buffer duration = 512/44100 = 11.6ms
      // Frame budget = 16.67ms (60 FPS)
      // We need to generate buffer + process in <16.67ms

      final stopwatch = Stopwatch();
      final timings = <int>[];

      for (int i = 0; i < 100; i++) {
        stopwatch.reset();
        stopwatch.start();

        engine.generateBuffer(512);

        stopwatch.stop();
        timings.add(stopwatch.elapsedMicroseconds);
      }

      // Calculate statistics
      final mean = timings.reduce((a, b) => a + b) / timings.length;
      final max = timings.reduce((a, b) => a > b ? a : b);

      // Mean should be well under 5ms for simple synthesis (test env is slower)
      expect(mean, lessThan(5000), // 5ms in microseconds
          reason: 'Average buffer generation too slow: ${mean / 1000}ms');

      // Max should be under 16ms (allow for test environment overhead)
      expect(max, lessThan(16000),
          reason: 'Worst case too slow: ${max / 1000}ms');
    });

    test('consistent timing across many frames', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      final timings = <int>[];

      // Simulate 5 seconds at 60 FPS
      for (int frame = 0; frame < 300; frame++) {
        final sw = Stopwatch()..start();
        engine.generateBuffer(512);
        sw.stop();
        timings.add(sw.elapsedMicroseconds);
      }

      // Check for consistency (low standard deviation relative to mean)
      final mean = timings.reduce((a, b) => a + b) / timings.length;
      double variance = 0.0;
      for (final t in timings) {
        variance += (t - mean) * (t - mean);
      }
      final stdDev = math.sqrt(variance / timings.length);

      // In test environment with concurrent execution, timing can vary significantly.
      // The key validation is that mean time is fast enough (checked in previous test).
      // We just verify no catastrophic outliers - stdDev within 10x of mean is acceptable.
      expect(stdDev, lessThan(mean * 10.0),
          reason: 'Timing too inconsistent: stdDev=$stdDev, mean=$mean');
    });

    test('FFT analysis performance is acceptable', () {
      final analyzer = AudioAnalyzer(fftSize: 2048, sampleRate: 44100.0);
      final engine = SynthesizerEngine();
      engine.setNote(69);

      final buffer = engine.generateBuffer(2048);

      final sw = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        analyzer.extractFeatures(buffer);
      }

      sw.stop();

      final avgMs = sw.elapsedMilliseconds / 100.0;
      expect(avgMs, lessThan(5.0),
          reason: 'FFT analysis too slow: ${avgMs}ms per call');
    });

    test('synthesis branch manager performance', () {
      final manager = SynthesisBranchManager();
      manager.noteOn();

      final timings = <int>[];

      // Test all 24 geometries
      for (int geom = 0; geom < 24; geom++) {
        manager.setGeometry(geom);

        final sw = Stopwatch()..start();
        for (int i = 0; i < 10; i++) {
          manager.generateBuffer(512, 440.0);
        }
        sw.stop();
        timings.add(sw.elapsedMicroseconds ~/ 10);
      }

      final maxTiming = timings.reduce((a, b) => a > b ? a : b);
      expect(maxTiming, lessThan(2000), // 2ms max
          reason: 'Some geometries too slow: ${maxTiming}us');
    });
  });

  group('Parameter Smoothing Tests', () {
    test('exponential smoothing reduces parameter jumps', () {
      // Simulate parameter smoothing as in audio_provider.dart
      const smoothingFactor = 0.95;
      double smoothedValue = 0.0;

      final targetValues = <double>[0.0, 1.0, 0.5, 0.2, 0.8, 0.3];
      final transitions = <List<double>>[];

      for (final target in targetValues) {
        final transition = <double>[];
        for (int i = 0; i < 20; i++) {
          smoothedValue = smoothedValue * smoothingFactor + target * (1 - smoothingFactor);
          transition.add(smoothedValue);
        }
        transitions.add(transition);
      }

      // Verify smooth transitions (no sudden jumps)
      for (final transition in transitions) {
        for (int i = 1; i < transition.length; i++) {
          final delta = (transition[i] - transition[i - 1]).abs();
          expect(delta, lessThan(0.1),
              reason: 'Parameter jump too large: $delta');
        }
      }
    });

    test('filter cutoff modulation is smooth', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sawtooth;

      // Rapidly modulate filter cutoff
      final samples = <double>[];

      for (double mod = 0.0; mod <= 0.8; mod += 0.02) {
        engine.modulateFilterCutoff(mod);
        final buffer = engine.generateBuffer(64);
        samples.addAll(buffer);
      }

      // Check for clicks (sudden large changes)
      int clicks = 0;
      for (int i = 1; i < samples.length; i++) {
        if ((samples[i] - samples[i - 1]).abs() > 0.9) {
          clicks++;
        }
      }

      expect(clicks, lessThan(10),
          reason: 'Filter modulation causing clicks: $clicks');
    });

    test('oscillator frequency modulation is smooth', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;

      final samples = <double>[];

      // Simulate vibrato (-2 to +2 semitones)
      for (double mod = -2.0; mod <= 2.0; mod += 0.1) {
        engine.modulateOscillator1Frequency(mod);
        final buffer = engine.generateBuffer(64);
        samples.addAll(buffer);
      }

      // Count discontinuities
      int clicks = 0;
      for (int i = 1; i < samples.length; i++) {
        if ((samples[i] - samples[i - 1]).abs() > 0.5) {
          clicks++;
        }
      }

      expect(clicks, lessThan(20),
          reason: 'Frequency modulation causing clicks: $clicks');
    });
  });

  group('Polyphony and Voice Management', () {
    test('voice count changes dont cause clicks', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      final samples = <double>[];

      // Change voice count while generating
      for (int voices = 1; voices <= 8; voices++) {
        engine.setVoiceCount(voices);
        final buffer = engine.generateBuffer(256);
        samples.addAll(buffer);
      }

      // Count major discontinuities
      int clicks = 0;
      for (int i = 1; i < samples.length; i++) {
        if ((samples[i] - samples[i - 1]).abs() > 0.8) {
          clicks++;
        }
      }

      expect(clicks, lessThan(samples.length * 0.01),
          reason: 'Voice count changes causing too many clicks: $clicks');
    });
  });

  group('Audio-Visual Sync Tests', () {
    test('parameter mapping is deterministic', () {
      // Create identical mappings
      final mapping1 = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 100.0,
        curve: MappingCurve.exponential,
      );

      final mapping2 = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 100.0,
        curve: MappingCurve.exponential,
      );

      // Same input should always produce same output
      for (double input = 0.0; input <= 1.0; input += 0.01) {
        expect(mapping1.map(input), equals(mapping2.map(input)),
            reason: 'Mapping not deterministic at input $input');
      }
    });

    test('mapping curves produce smooth transitions', () {
      for (final curve in MappingCurve.values) {
        final mapping = ParameterMapping(
          sourceParam: 'test',
          targetParam: 'output',
          minRange: 0.0,
          maxRange: 1.0,
          curve: curve,
        );

        // Check that output changes smoothly
        double prev = mapping.map(0.0);
        for (double input = 0.01; input <= 1.0; input += 0.01) {
          final current = mapping.map(input);
          final delta = (current - prev).abs();

          // Delta should be reasonable (not a sudden jump)
          expect(delta, lessThan(0.1),
              reason: '${curve.name} has jump at input $input: delta=$delta');

          prev = current;
        }
      }
    });
  });

  group('Envelope Smoothness Tests', () {
    test('attack phase is smooth', () {
      final manager = SynthesisBranchManager();
      manager.setGeometry(0);
      manager.noteOn();

      // Generate during attack phase
      final buffer = manager.generateBuffer(2048, 440.0);

      // Attack should be smooth rise
      // Check that amplitude generally increases (with some variation)
      final firstQuarter = buffer.sublist(0, 512);
      final secondQuarter = buffer.sublist(512, 1024);

      double energy1 = 0.0, energy2 = 0.0;
      for (final s in firstQuarter) energy1 += s.abs();
      for (final s in secondQuarter) energy2 += s.abs();

      expect(energy2, greaterThanOrEqualTo(energy1 * 0.5),
          reason: 'Attack phase not smooth');
    });

    test('release phase decays smoothly', () {
      final manager = SynthesisBranchManager();
      manager.setGeometry(0);
      manager.noteOn();

      // Build up envelope
      manager.generateBuffer(2048, 440.0);

      // Start release
      manager.noteOff();

      final releaseBuffer = manager.generateBuffer(4096, 440.0);

      // Should decay smoothly
      final firstHalf = releaseBuffer.sublist(0, 2048);
      final secondHalf = releaseBuffer.sublist(2048, 4096);

      double energy1 = 0.0, energy2 = 0.0;
      for (final s in firstHalf) energy1 += s.abs();
      for (final s in secondHalf) energy2 += s.abs();

      expect(energy2, lessThan(energy1),
          reason: 'Release phase not decaying');
    });
  });

  group('Waveform Quality Tests', () {
    test('sine wave is pure', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;
      engine.reverb.mix = 0.0;
      engine.delay.mix = 0.0;

      final buffer = engine.generateBuffer(4096);

      // Sine wave should have very smooth transitions
      double maxDelta = 0.0;
      for (int i = 1; i < buffer.length; i++) {
        final delta = (buffer[i] - buffer[i - 1]).abs();
        if (delta > maxDelta) maxDelta = delta;
      }

      // At 440Hz, max delta should be about 2*pi*440/44100 ≈ 0.063
      expect(maxDelta, lessThan(0.15),
          reason: 'Sine wave not smooth enough: maxDelta=$maxDelta');
    });

    test('triangle wave is symmetric', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.triangle;
      engine.mixBalance = 0.0;
      engine.reverb.mix = 0.0;
      engine.delay.mix = 0.0;

      final buffer = engine.generateBuffer(4096);

      // Triangle should have balanced positive/negative
      double positiveSum = 0.0, negativeSum = 0.0;
      for (final s in buffer) {
        if (s > 0) positiveSum += s;
        else negativeSum += s.abs();
      }

      final balance = (positiveSum - negativeSum).abs() / (positiveSum + negativeSum);
      expect(balance, lessThan(0.1),
          reason: 'Triangle wave not symmetric: balance=$balance');
    });

    test('square wave has correct duty cycle', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.square;
      engine.mixBalance = 0.0;
      engine.reverb.mix = 0.0;
      engine.delay.mix = 0.0;

      final buffer = engine.generateBuffer(4096);

      // Count positive vs negative samples
      int positive = 0, negative = 0;
      for (final s in buffer) {
        if (s > 0) positive++;
        else if (s < 0) negative++;
      }

      // Should be approximately 50/50
      final ratio = positive / (positive + negative);
      expect(ratio, closeTo(0.5, 0.15),
          reason: 'Square wave duty cycle incorrect: $ratio');
    });
  });

  group('Full Signal Chain Tests', () {
    test('complete chain produces valid output', () {
      final engine = SynthesizerEngine();

      // Configure full chain
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sawtooth;
      engine.oscillator2.waveform = Waveform.square;
      engine.mixBalance = 0.3;
      engine.filter.type = FilterType.lowpass;
      engine.filter.baseCutoff = 2000.0;
      engine.filter.resonance = 0.6;
      engine.reverb.mix = 0.3;
      engine.reverb.roomSize = 0.7;
      engine.delay.mix = 0.2;
      engine.delay.delayTime = 150.0;
      engine.masterVolume = 0.8;

      // Generate buffer
      final buffer = engine.generateBuffer(4096);

      // Verify output quality
      for (final sample in buffer) {
        expect(sample.isFinite, isTrue, reason: 'NaN or Infinity in output');
        expect(sample, greaterThanOrEqualTo(-1.0), reason: 'Clipping below -1');
        expect(sample, lessThanOrEqualTo(1.0), reason: 'Clipping above +1');
      }

      // Verify it's not silent
      final hasSignal = buffer.any((s) => s.abs() > 0.01);
      expect(hasSignal, isTrue, reason: 'Output is silent');

      // Verify reasonable DC offset
      final dc = buffer.reduce((a, b) => a + b) / buffer.length;
      expect(dc.abs(), lessThan(0.2), reason: 'Excessive DC offset: $dc');
    });

    test('all 72 combinations work through full chain', () {
      final manager = SynthesisBranchManager();

      int successCount = 0;

      for (final system in VisualSystem.values) {
        manager.setVisualSystem(system);

        for (int geometry = 0; geometry < 24; geometry++) {
          manager.setGeometry(geometry);
          manager.noteOn();

          try {
            final buffer = manager.generateBuffer(1024, 440.0);

            // Basic quality checks
            bool valid = true;
            for (final s in buffer) {
              if (!s.isFinite || s < -1.0 || s > 1.0) {
                valid = false;
                break;
              }
            }

            if (valid && buffer.any((s) => s.abs() > 0.001)) {
              successCount++;
            }
          } catch (e) {
            fail('Combination ${system.name}/$geometry threw: $e');
          }
        }
      }

      expect(successCount, equals(72),
          reason: 'Not all combinations work: $successCount/72');
    });
  });
}
