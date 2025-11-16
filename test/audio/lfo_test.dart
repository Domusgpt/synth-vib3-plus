/**
 * LFO Unit Tests
 *
 * Tests for Low Frequency Oscillator system:
 * - Waveform generation accuracy
 * - Phase accumulation and wrapping
 * - Frequency to period conversion
 * - LFO pool rotation speed mapping
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synth_vib3_plus/audio/lfo.dart';
import 'dart:math' as math;

void main() {
  group('LFO Waveform Tests', () {
    late LFO lfo;

    setUp(() {
      lfo = LFO(sampleRate: 44100.0, frequency: 1.0, depth: 1.0);
    });

    test('Sine waveform generates correct range', () {
      lfo.setWaveform(LFOWaveform.sine);

      // Generate one cycle
      final samples = <double>[];
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 44100; i++) {
        samples.add(lfo.nextSample(deltaTime));
      }

      // Check range
      final min = samples.reduce(math.min);
      final max = samples.reduce(math.max);

      expect(min, closeTo(-1.0, 0.01));
      expect(max, closeTo(1.0, 0.01));
    });

    test('Triangle waveform generates correct range', () {
      lfo.setWaveform(LFOWaveform.triangle);

      final samples = <double>[];
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 44100; i++) {
        samples.add(lfo.nextSample(deltaTime));
      }

      final min = samples.reduce(math.min);
      final max = samples.reduce(math.max);

      expect(min, closeTo(-1.0, 0.1));
      expect(max, closeTo(1.0, 0.1));
    });

    test('Square waveform is exactly ±1.0', () {
      lfo.setWaveform(LFOWaveform.square);

      final samples = <double>[];
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 100; i++) {
        final sample = lfo.nextSample(deltaTime);
        samples.add(sample);
        expect(sample.abs(), equals(1.0)); // Should be exactly ±1
      }
    });

    test('Sawtooth waveform generates correct range', () {
      lfo.setWaveform(LFOWaveform.sawtooth);

      final samples = <double>[];
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 44100; i++) {
        samples.add(lfo.nextSample(deltaTime));
      }

      final min = samples.reduce(math.min);
      final max = samples.reduce(math.max);

      expect(min, closeTo(-1.0, 0.1));
      expect(max, closeTo(1.0, 0.1));
    });

    test('Random waveform stays within range', () {
      lfo.setWaveform(LFOWaveform.random);

      final samples = <double>[];
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 44100; i++) {
        final sample = lfo.nextSample(deltaTime);
        samples.add(sample);
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });

    test('Phase wraps correctly at 2π', () {
      lfo.setFrequency(1.0); // 1 Hz
      lfo.setWaveform(LFOWaveform.sine);

      // Generate 2 full cycles
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 88200; i++) {
        lfo.nextSample(deltaTime);
      }

      // Phase should have wrapped twice and be near 0
      expect(lfo.phaseNormalized, closeTo(0.0, 0.01));
    });

    test('Frequency affects period correctly', () {
      // 1 Hz should complete 1 cycle per second
      lfo.setFrequency(1.0);
      lfo.setWaveform(LFOWaveform.sine);

      final deltaTime = 1.0 / 44100.0;
      double firstSample = lfo.nextSample(deltaTime);

      // Advance 1 second (should return to start)
      for (int i = 0; i < 44099; i++) {
        lfo.nextSample(deltaTime);
      }

      double lastSample = lfo.nextSample(deltaTime);

      // Should be back near the start value
      expect(lastSample, closeTo(firstSample, 0.1));
    });

    test('Depth scales amplitude correctly', () {
      lfo.setWaveform(LFOWaveform.sine);
      lfo.setDepth(0.5);

      final samples = <double>[];
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 44100; i++) {
        samples.add(lfo.nextSample(deltaTime));
      }

      final min = samples.reduce(math.min);
      final max = samples.reduce(math.max);

      // With 0.5 depth, range should be ±0.5
      expect(min, closeTo(-0.5, 0.05));
      expect(max, closeTo(0.5, 0.05));
    });

    test('Reset returns phase to 0', () {
      lfo.setFrequency(1.0);

      // Advance to middle of cycle
      final deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 22050; i++) {
        lfo.nextSample(deltaTime);
      }

      expect(lfo.phaseNormalized, greaterThan(0.4));

      // Reset
      lfo.reset();

      expect(lfo.phaseNormalized, equals(0.0));
    });
  });

  group('LFOPool Tests', () {
    late LFOPool pool;

    setUp(() {
      pool = LFOPool(sampleRate: 44100.0);
    });

    test('LFOPool initializes with 3 LFOs', () {
      expect(pool.pitchLFO, isNotNull);
      expect(pool.filterLFO, isNotNull);
      expect(pool.ampLFO, isNotNull);
    });

    test('Rotation speed mapping: slow rotation → slow LFO', () {
      pool.updateFromRotationSpeeds(
        rotationSpeedXW: 0.1,
        rotationSpeedYW: 0.1,
        rotationSpeedZW: 0.1,
      );

      // 0.1 rotation speed → 0.1 Hz LFO
      expect(pool.pitchLFO.frequency, closeTo(0.1, 0.01));
      expect(pool.filterLFO.frequency, closeTo(0.1, 0.01));
      expect(pool.ampLFO.frequency, closeTo(0.1, 0.01));
    });

    test('Rotation speed mapping: medium rotation → medium LFO', () {
      pool.updateFromRotationSpeeds(
        rotationSpeedXW: 1.0,
        rotationSpeedYW: 1.0,
        rotationSpeedZW: 1.0,
      );

      // 1.0 rotation speed → 1.0 Hz LFO
      expect(pool.pitchLFO.frequency, closeTo(1.0, 0.1));
      expect(pool.filterLFO.frequency, closeTo(1.0, 0.1));
      expect(pool.ampLFO.frequency, closeTo(1.0, 0.1));
    });

    test('Rotation speed mapping: fast rotation → fast LFO', () {
      pool.updateFromRotationSpeeds(
        rotationSpeedXW: 2.0,
        rotationSpeedYW: 2.0,
        rotationSpeedZW: 2.0,
      );

      // 2.0 rotation speed → 10 Hz LFO (exponential mapping)
      expect(pool.pitchLFO.frequency, closeTo(10.0, 0.5));
      expect(pool.filterLFO.frequency, closeTo(10.0, 0.5));
      expect(pool.ampLFO.frequency, closeTo(10.0, 0.5));
    });

    test('Independent rotation speeds map to independent LFOs', () {
      pool.updateFromRotationSpeeds(
        rotationSpeedXW: 0.5,
        rotationSpeedYW: 1.0,
        rotationSpeedZW: 1.5,
      );

      // Each LFO should have different frequency
      expect(pool.pitchLFO.frequency, isNot(equals(pool.filterLFO.frequency)));
      expect(pool.filterLFO.frequency, isNot(equals(pool.ampLFO.frequency)));
      expect(pool.pitchLFO.frequency, lessThan(pool.filterLFO.frequency));
      expect(pool.filterLFO.frequency, lessThan(pool.ampLFO.frequency));
    });

    test('Set depths updates all LFOs', () {
      pool.setDepths(
        vibratoDepth: 0.3,
        filterDepth: 0.7,
        tremoloDepth: 0.5,
      );

      expect(pool.pitchLFO.depth, equals(0.3));
      expect(pool.filterLFO.depth, equals(0.7));
      expect(pool.ampLFO.depth, equals(0.5));
    });

    test('Sync all resets all LFO phases', () {
      final deltaTime = 1.0 / 44100.0;

      // Advance all LFOs to different phases
      for (int i = 0; i < 10000; i++) {
        pool.pitchLFO.nextSample(deltaTime);
        pool.filterLFO.nextSample(deltaTime);
        pool.ampLFO.nextSample(deltaTime);
      }

      expect(pool.pitchLFO.phaseNormalized, greaterThan(0.0));

      // Sync all
      pool.syncAll();

      expect(pool.pitchLFO.phaseNormalized, equals(0.0));
      expect(pool.filterLFO.phaseNormalized, equals(0.0));
      expect(pool.ampLFO.phaseNormalized, equals(0.0));
    });

    test('Get state returns valid debug info', () {
      final state = pool.getState();

      expect(state, containsKey('pitchLFO'));
      expect(state, containsKey('filterLFO'));
      expect(state, containsKey('ampLFO'));

      final pitchState = state['pitchLFO'] as Map<String, dynamic>;
      expect(pitchState, containsKey('frequency'));
      expect(pitchState, containsKey('waveform'));
      expect(pitchState, containsKey('depth'));
      expect(pitchState, containsKey('phase'));
      expect(pitchState, containsKey('value'));
    });
  });
}
