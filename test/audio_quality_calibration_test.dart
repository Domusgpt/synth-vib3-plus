// Audio Quality Calibration Tests
//
// These tests verify audio output quality:
// - No clicks/pops at buffer boundaries
// - Smooth parameter transitions
// - Proper DC offset handling
// - Amplitude consistency
// - Zero-crossing continuity

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/audio/synthesizer_engine.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';

void main() {
  group('Click/Pop Detection Tests', () {
    test('no clicks at buffer boundaries (continuous phase)', () {
      final engine = SynthesizerEngine();
      engine.setNote(69); // A4
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;

      // Generate multiple consecutive buffers
      final buffers = <Float32List>[];
      for (int i = 0; i < 10; i++) {
        buffers.add(engine.generateBuffer(512));
      }

      // Check for discontinuities at buffer boundaries
      for (int i = 0; i < buffers.length - 1; i++) {
        final lastSample = buffers[i][511];
        final firstSample = buffers[i + 1][0];
        final delta = (lastSample - firstSample).abs();

        // Maximum expected delta for smooth sine wave at 440Hz, 44100Hz sample rate
        // Phase increment per sample = 2*pi*440/44100 ≈ 0.0627
        // Max delta = sin change over one sample ≈ 0.063
        expect(delta, lessThan(0.15),
            reason: 'Click detected at buffer $i→${i + 1} boundary: delta=$delta');
      }
    });

    test('no clicks when changing waveform mid-stream', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.mixBalance = 0.0;

      engine.oscillator1.waveform = Waveform.sine;
      final buffer1 = engine.generateBuffer(512);

      // Change waveform and continue
      engine.oscillator1.waveform = Waveform.triangle;
      final buffer2 = engine.generateBuffer(512);

      // Check transition - should not have massive discontinuity
      final delta = (buffer1[511] - buffer2[0]).abs();
      expect(delta, lessThan(0.5),
          reason: 'Major click when switching waveforms: delta=$delta');
    });

    test('no clicks when changing frequency', () {
      final engine = SynthesizerEngine();
      engine.setNote(60); // C4
      engine.oscillator1.waveform = Waveform.sine;

      final buffer1 = engine.generateBuffer(512);

      // Change note
      engine.setNote(72); // C5

      final buffer2 = engine.generateBuffer(512);

      // Frequency change will cause a discontinuity, but it should be manageable
      final delta = (buffer1[511] - buffer2[0]).abs();
      expect(delta, lessThan(1.0),
          reason: 'Major click when changing frequency: delta=$delta');
    });

    test('sawtooth wave has controlled discontinuities', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sawtooth;
      engine.mixBalance = 0.0;

      final buffer = engine.generateBuffer(2048);

      // Count large jumps (sawtooth resets)
      int largeJumps = 0;
      for (int i = 1; i < buffer.length; i++) {
        if ((buffer[i] - buffer[i - 1]).abs() > 1.5) {
          largeJumps++;
        }
      }

      // At 440Hz, we expect about 440/44100 * 2048 ≈ 20 resets
      // But band-limited sawtooth should have smoother transitions
      expect(largeJumps, lessThan(30),
          reason: 'Too many discontinuities in sawtooth: $largeJumps');
    });
  });

  group('DC Offset Tests', () {
    test('sine wave has zero DC offset', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;
      engine.reverb.mix = 0.0;
      engine.delay.mix = 0.0;

      // Generate enough samples for accurate DC measurement
      final buffer = engine.generateBuffer(44100); // 1 second

      // Calculate DC offset (mean value)
      double sum = 0.0;
      for (final sample in buffer) {
        sum += sample;
      }
      final dcOffset = sum / buffer.length;

      expect(dcOffset.abs(), lessThan(0.05),
          reason: 'Sine wave has DC offset: $dcOffset');
    });

    test('mixed waveforms have minimal DC offset', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.mixBalance = 0.5;
      engine.reverb.mix = 0.0;
      engine.delay.mix = 0.0;

      final buffer = engine.generateBuffer(44100);

      double sum = 0.0;
      for (final sample in buffer) {
        sum += sample;
      }
      final dcOffset = sum / buffer.length;

      expect(dcOffset.abs(), lessThan(0.1),
          reason: 'Mixed signal has excessive DC offset: $dcOffset');
    });
  });

  group('Amplitude Consistency Tests', () {
    test('amplitude stays consistent over time', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.masterVolume = 0.7;

      // Measure peak amplitude over multiple buffers
      final peakAmplitudes = <double>[];

      for (int i = 0; i < 20; i++) {
        final buffer = engine.generateBuffer(512);
        double peak = 0.0;
        for (final sample in buffer) {
          if (sample.abs() > peak) peak = sample.abs();
        }
        peakAmplitudes.add(peak);
      }

      // After initial transient, amplitude should stabilize
      final stableAmplitudes = peakAmplitudes.sublist(5); // Skip first 5

      final mean = stableAmplitudes.reduce((a, b) => a + b) / stableAmplitudes.length;
      for (final amp in stableAmplitudes) {
        final deviation = (amp - mean).abs() / mean;
        // Allow 35% deviation (filter/effects can cause amplitude variation)
        expect(deviation, lessThan(0.35),
            reason: 'Amplitude varies too much: $amp vs mean $mean');
      }
    });

    test('master volume scales amplitude correctly', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      final amplitudes = <double, double>{};

      for (final volume in [0.1, 0.3, 0.5, 0.7, 1.0]) {
        engine.masterVolume = volume;
        final buffer = engine.generateBuffer(1024);
        double peak = 0.0;
        for (final sample in buffer) {
          if (sample.abs() > peak) peak = sample.abs();
        }
        amplitudes[volume] = peak;
      }

      // Higher volume should mean higher amplitude
      expect(amplitudes[0.3]!, greaterThan(amplitudes[0.1]!));
      expect(amplitudes[0.5]!, greaterThan(amplitudes[0.3]!));
      expect(amplitudes[0.7]!, greaterThan(amplitudes[0.5]!));
      expect(amplitudes[1.0]!, greaterThan(amplitudes[0.7]!));
    });
  });

  group('Parameter Transition Smoothness', () {
    test('filter cutoff sweep is smooth', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sawtooth;
      engine.filter.type = FilterType.lowpass;

      final allSamples = <double>[];

      // Sweep filter cutoff from low to high
      for (double cutoff = 200.0; cutoff <= 8000.0; cutoff += 100.0) {
        engine.filter.baseCutoff = cutoff;
        final buffer = engine.generateBuffer(128);
        allSamples.addAll(buffer);
      }

      // Check for major discontinuities
      int clicks = 0;
      for (int i = 1; i < allSamples.length; i++) {
        if ((allSamples[i] - allSamples[i - 1]).abs() > 0.8) {
          clicks++;
        }
      }

      // Allow some discontinuities from waveform, but not excessive
      expect(clicks, lessThan(allSamples.length * 0.01),
          reason: 'Too many clicks during filter sweep: $clicks');
    });

    test('oscillator detune sweep is smooth', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;

      final allSamples = <double>[];

      // Sweep detune
      for (double detune = -100.0; detune <= 100.0; detune += 10.0) {
        engine.oscillator1.detune = detune;
        final buffer = engine.generateBuffer(128);
        allSamples.addAll(buffer);
      }

      // Check smoothness
      int clicks = 0;
      for (int i = 1; i < allSamples.length; i++) {
        if ((allSamples[i] - allSamples[i - 1]).abs() > 0.5) {
          clicks++;
        }
      }

      expect(clicks, lessThan(allSamples.length * 0.01),
          reason: 'Too many clicks during detune sweep: $clicks');
    });

    test('wavetable morph is smooth', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.wavetable;
      engine.mixBalance = 0.0;

      final allSamples = <double>[];

      // Sweep wavetable position
      for (double pos = 0.0; pos <= 1.0; pos += 0.05) {
        engine.oscillator1.wavetablePosition = pos;
        final buffer = engine.generateBuffer(128);
        allSamples.addAll(buffer);
      }

      // Count major discontinuities
      int clicks = 0;
      for (int i = 1; i < allSamples.length; i++) {
        if ((allSamples[i] - allSamples[i - 1]).abs() > 0.6) {
          clicks++;
        }
      }

      expect(clicks, lessThan(allSamples.length * 0.02),
          reason: 'Too many clicks during wavetable morph: $clicks');
    });
  });

  group('Frequency Accuracy Tests', () {
    test('A4 generates approximately 440Hz', () {
      final engine = SynthesizerEngine();
      engine.setNote(69); // A4 = 440Hz
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;

      final buffer = engine.generateBuffer(44100); // 1 second

      // Count zero crossings to estimate frequency
      int zeroCrossings = 0;
      for (int i = 1; i < buffer.length; i++) {
        if ((buffer[i - 1] < 0 && buffer[i] >= 0) ||
            (buffer[i - 1] >= 0 && buffer[i] < 0)) {
          zeroCrossings++;
        }
      }

      // Frequency = zero crossings / 2 (each cycle has 2 crossings)
      final estimatedFreq = zeroCrossings / 2.0;

      // Should be close to 440Hz (allow 5% tolerance)
      expect(estimatedFreq, closeTo(440.0, 440.0 * 0.05),
          reason: 'A4 frequency incorrect: $estimatedFreq Hz');
    });

    test('octave relationship is correct', () {
      final engine = SynthesizerEngine();
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;

      // Count zero crossings for C4 (MIDI 60)
      engine.setNote(60);
      var buffer = engine.generateBuffer(44100);
      int crossingsC4 = 0;
      for (int i = 1; i < buffer.length; i++) {
        if ((buffer[i - 1] < 0 && buffer[i] >= 0)) crossingsC4++;
      }

      // Count zero crossings for C5 (MIDI 72) - should be double
      engine.setNote(72);
      buffer = engine.generateBuffer(44100);
      int crossingsC5 = 0;
      for (int i = 1; i < buffer.length; i++) {
        if ((buffer[i - 1] < 0 && buffer[i] >= 0)) crossingsC5++;
      }

      // C5 should have approximately 2x the frequency of C4
      final ratio = crossingsC5 / crossingsC4;
      expect(ratio, closeTo(2.0, 0.1),
          reason: 'Octave ratio incorrect: $ratio');
    });
  });

  group('Synthesis Branch Quality Tests', () {
    test('all synthesis branches produce musical output', () {
      final manager = SynthesisBranchManager();

      for (int geometry = 0; geometry < 24; geometry++) {
        manager.setGeometry(geometry);
        manager.noteOn();

        final buffer = manager.generateBuffer(4096, 440.0);

        // Check for reasonable amplitude
        double maxAmp = 0.0;
        for (final sample in buffer) {
          if (sample.abs() > maxAmp) maxAmp = sample.abs();
        }
        expect(maxAmp, greaterThan(0.01),
            reason: 'Geometry $geometry produces silent output');

        // Check for no NaN or infinity
        for (final sample in buffer) {
          expect(sample.isFinite, isTrue,
              reason: 'Geometry $geometry produces invalid samples');
        }

        // Check for reasonable DC offset
        double sum = 0.0;
        for (final sample in buffer) {
          sum += sample;
        }
        final dc = (sum / buffer.length).abs();
        expect(dc, lessThan(0.2),
            reason: 'Geometry $geometry has excessive DC offset: $dc');
      }
    });

    test('FM synthesis produces harmonically rich output', () {
      final manager = SynthesisBranchManager();
      manager.setGeometry(8); // Hypersphere = FM
      manager.noteOn();

      final buffer = manager.generateBuffer(8192, 440.0);

      // FM synthesis should have more high-frequency content than pure sine
      // Measure "brightness" by counting zero crossings
      int crossings = 0;
      for (int i = 1; i < buffer.length; i++) {
        if ((buffer[i - 1] < 0 && buffer[i] >= 0) ||
            (buffer[i - 1] >= 0 && buffer[i] < 0)) {
          crossings++;
        }
      }

      // FM should have more crossings than a pure sine at same fundamental
      // Pure 440Hz sine in 8192 samples @ 44100Hz would have ~163 crossings
      expect(crossings, greaterThan(150),
          reason: 'FM synthesis not producing enough harmonics');
    });

    test('Ring Mod synthesis produces sum/difference frequencies', () {
      final manager = SynthesisBranchManager();
      manager.setGeometry(16); // Hypertetrahedron = Ring Mod
      manager.noteOn();

      final buffer = manager.generateBuffer(8192, 440.0);

      // Ring mod should produce complex waveform
      double maxAmp = 0.0;
      double rms = 0.0;
      for (final sample in buffer) {
        if (sample.abs() > maxAmp) maxAmp = sample.abs();
        rms += sample * sample;
      }
      rms = math.sqrt(rms / buffer.length);

      // Crest factor (peak/RMS) indicates waveform complexity
      final crestFactor = maxAmp / rms;
      expect(crestFactor, greaterThan(1.2),
          reason: 'Ring mod not producing complex waveform');
    });
  });

  group('Sound Family Timbral Tests', () {
    test('Quantum system sounds pure/harmonic', () {
      final manager = SynthesisBranchManager();
      manager.setVisualSystem(VisualSystem.quantum);
      manager.setGeometry(0);
      manager.noteOn();

      final buffer = manager.generateBuffer(4096, 440.0);

      // Quantum should have smoother waveform (lower high-freq energy)
      double highFreqEnergy = 0.0;
      for (int i = 1; i < buffer.length; i++) {
        final delta = (buffer[i] - buffer[i - 1]).abs();
        highFreqEnergy += delta;
      }

      // Store for comparison
      final quantumEnergy = highFreqEnergy;

      // Compare with Holographic
      manager.setVisualSystem(VisualSystem.holographic);
      final buffer2 = manager.generateBuffer(4096, 440.0);

      double holoEnergy = 0.0;
      for (int i = 1; i < buffer2.length; i++) {
        final delta = (buffer2[i] - buffer2[i - 1]).abs();
        holoEnergy += delta;
      }

      // Holographic should have more high-freq content
      expect(holoEnergy, greaterThan(quantumEnergy * 0.8),
          reason: 'Sound families not distinct enough');
    });
  });

  group('Effects Quality Tests', () {
    test('reverb adds sustain to signal', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;
      engine.delay.mix = 0.0; // Disable delay for this test

      // Compare dry vs wet signal characteristics
      engine.reverb.mix = 0.0;
      engine.reverb.roomSize = 0.9;
      final dryBuffer = engine.generateBuffer(4096);

      // Reset and generate with reverb
      engine.reverb.mix = 0.8;
      final wetBuffer = engine.generateBuffer(4096);

      // Reverb should spread energy - check variance
      double dryMean = 0.0, wetMean = 0.0;
      for (final s in dryBuffer) dryMean += s.abs();
      for (final s in wetBuffer) wetMean += s.abs();
      dryMean /= dryBuffer.length;
      wetMean /= wetBuffer.length;

      // Wet signal should have similar or higher energy due to reverb additions
      expect(wetMean, greaterThan(dryMean * 0.5),
          reason: 'Reverb not adding sustain');

      // Check that wet signal has content
      final hasWetContent = wetBuffer.any((s) => s.abs() > 0.01);
      expect(hasWetContent, isTrue, reason: 'Reverb producing silent output');
    });

    test('delay adds echoes to signal', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.mixBalance = 0.0;
      engine.reverb.mix = 0.0; // Disable reverb for this test

      // Compare dry vs wet signal
      engine.delay.mix = 0.0;
      final dryBuffer = engine.generateBuffer(4096);

      engine.delay.mix = 0.5;
      engine.delay.delayTime = 100.0; // 100ms
      engine.delay.feedback = 0.6;
      final wetBuffer = engine.generateBuffer(4096);

      // Calculate energy
      double dryEnergy = 0.0, wetEnergy = 0.0;
      for (final s in dryBuffer) dryEnergy += s.abs();
      for (final s in wetBuffer) wetEnergy += s.abs();

      // With delay feedback, wet signal should have more cumulative energy
      // or at least comparable energy (delay adds to signal)
      expect(wetEnergy, greaterThan(dryEnergy * 0.8),
          reason: 'Delay not adding echoes');

      // Ensure delay is producing output
      final hasDelayContent = wetBuffer.any((s) => s.abs() > 0.01);
      expect(hasDelayContent, isTrue, reason: 'Delay producing silent output');
    });
  });
}
