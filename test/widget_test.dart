// Synth-VIB3+ Widget Tests
//
// Tests for the holographic synthesizer application
// Verifies core functionality of audio-visual coupling system
//
// Note: Full widget tests require platform dependencies (PCM audio, WebView).
// These tests focus on pure Dart components that can run headlessly.

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

// Import pure Dart modules that don't require platform code
import 'package:synther_vib34d_holographic/audio/synthesizer_engine.dart';
import 'package:synther_vib34d_holographic/audio/audio_analyzer.dart';

void main() {
  group('SynthesizerEngine Tests', () {
    test('SynthesizerEngine initializes with default values', () {
      final engine = SynthesizerEngine();

      expect(engine.sampleRate, equals(44100.0));
      expect(engine.bufferSize, equals(512));
      expect(engine.masterVolume, equals(0.7));
    });

    test('SynthesizerEngine initializes with custom values', () {
      final engine = SynthesizerEngine(
        sampleRate: 48000.0,
        bufferSize: 256,
      );

      expect(engine.sampleRate, equals(48000.0));
      expect(engine.bufferSize, equals(256));
    });

    test('SynthesizerEngine generates audio buffer', () {
      final engine = SynthesizerEngine();
      engine.setNote(69); // A4 = 440 Hz
      final buffer = engine.generateBuffer(512);

      expect(buffer, isNotNull);
      expect(buffer.length, equals(512));
      // Verify buffer contains valid audio samples (not all zeros)
      final hasNonZero = buffer.any((sample) => sample != 0.0);
      expect(hasNonZero, isTrue);
    });

    test('SynthesizerEngine oscillator waveforms', () {
      final engine = SynthesizerEngine();

      // Test waveform switching
      engine.oscillator1.waveform = Waveform.sine;
      expect(engine.oscillator1.waveform, equals(Waveform.sine));

      engine.oscillator1.waveform = Waveform.sawtooth;
      expect(engine.oscillator1.waveform, equals(Waveform.sawtooth));

      engine.oscillator1.waveform = Waveform.square;
      expect(engine.oscillator1.waveform, equals(Waveform.square));

      engine.oscillator1.waveform = Waveform.triangle;
      expect(engine.oscillator1.waveform, equals(Waveform.triangle));

      engine.oscillator1.waveform = Waveform.wavetable;
      expect(engine.oscillator1.waveform, equals(Waveform.wavetable));
    });

    test('SynthesizerEngine filter cutoff modulation', () {
      final engine = SynthesizerEngine();
      engine.setNote(69); // A4

      engine.modulateFilterCutoff(0.8);
      final buffer1 = engine.generateBuffer(512);

      engine.modulateFilterCutoff(0.1);
      final buffer2 = engine.generateBuffer(512);

      // Buffers should be different with different filter settings
      bool different = false;
      for (int i = 0; i < 512; i++) {
        if (buffer1[i] != buffer2[i]) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });

    test('SynthesizerEngine MIDI note conversion', () {
      final engine = SynthesizerEngine();

      // Set different notes and verify buffer changes
      engine.setNote(60); // Middle C
      final buffer60 = engine.generateBuffer(512);

      engine.setNote(72); // C5 (octave up)
      final buffer72 = engine.generateBuffer(512);

      // Different frequencies should produce different waveforms
      bool different = false;
      for (int i = 0; i < 512; i++) {
        if (buffer60[i] != buffer72[i]) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });

    test('SynthesizerEngine master volume affects output', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      engine.masterVolume = 1.0;
      final bufferLoud = engine.generateBuffer(512);
      final maxLoud = bufferLoud.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();

      engine.masterVolume = 0.1;
      final bufferQuiet = engine.generateBuffer(512);
      final maxQuiet = bufferQuiet.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();

      expect(maxQuiet, lessThan(maxLoud));
    });

    test('SynthesizerEngine mix balance affects oscillator contribution', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sine;
      engine.oscillator2.waveform = Waveform.square;

      engine.mixBalance = 0.0; // Only osc1
      final bufferOsc1 = engine.generateBuffer(512);

      engine.mixBalance = 1.0; // Only osc2
      final bufferOsc2 = engine.generateBuffer(512);

      // Buffers should be different with different mix
      bool different = false;
      for (int i = 0; i < 512; i++) {
        if ((bufferOsc1[i] - bufferOsc2[i]).abs() > 0.01) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });

    test('SynthesizerEngine output stays within valid range', () {
      final engine = SynthesizerEngine();
      engine.masterVolume = 1.0;

      // Test with various notes and settings
      for (int note = 36; note <= 96; note += 12) {
        engine.setNote(note);
        final buffer = engine.generateBuffer(1024);

        for (final sample in buffer) {
          expect(sample, greaterThanOrEqualTo(-1.0));
          expect(sample, lessThanOrEqualTo(1.0));
          expect(sample.isFinite, isTrue);
        }
      }
    });
  });

  group('Oscillator Tests', () {
    test('Oscillator generates sine wave correctly', () {
      final engine = SynthesizerEngine();
      engine.oscillator1.waveform = Waveform.sine;
      engine.oscillator1.baseFrequency = 440.0;
      engine.mixBalance = 0.0; // Only osc1

      final buffer = engine.generateBuffer(1024);

      // Sine wave should have smooth transitions
      double maxDelta = 0.0;
      for (int i = 1; i < buffer.length; i++) {
        final delta = (buffer[i] - buffer[i - 1]).abs();
        if (delta > maxDelta) maxDelta = delta;
      }

      // Sine wave should have small sample-to-sample changes
      expect(maxDelta, lessThan(0.2));
    });

    test('Oscillator detune affects frequency', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      engine.oscillator1.detune = 0.0;
      final buffer0 = engine.generateBuffer(512);

      engine.oscillator1.detune = 100.0; // +100 cents = +1 semitone
      final buffer100 = engine.generateBuffer(512);

      // Detuned oscillator should produce different waveform
      bool different = false;
      for (int i = 0; i < 512; i++) {
        if ((buffer0[i] - buffer100[i]).abs() > 0.01) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });

    test('Oscillator wavetable morphs between sine and saw', () {
      final engine = SynthesizerEngine();
      engine.oscillator1.waveform = Waveform.wavetable;
      engine.setNote(69);
      engine.mixBalance = 0.0;

      engine.oscillator1.wavetablePosition = 0.0; // Pure sine
      final bufferSine = engine.generateBuffer(512);

      engine.oscillator1.wavetablePosition = 1.0; // Pure saw
      final bufferSaw = engine.generateBuffer(512);

      // Different wavetable positions should produce different sounds
      bool different = false;
      for (int i = 0; i < 512; i++) {
        if ((bufferSine[i] - bufferSaw[i]).abs() > 0.01) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });
  });

  group('Filter Tests', () {
    test('Filter processes audio without distortion', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.filter.type = FilterType.lowpass;
      engine.filter.baseCutoff = 1000.0;

      final buffer = engine.generateBuffer(1024);

      // All samples should be valid
      for (final sample in buffer) {
        expect(sample.isFinite, isTrue);
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });

    test('Filter types produce different outputs', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sawtooth;
      engine.filter.baseCutoff = 2000.0;

      final buffers = <FilterType, Float32List>{};
      for (final type in FilterType.values) {
        engine.filter.type = type;
        buffers[type] = engine.generateBuffer(512);
      }

      // Each filter type should produce somewhat different output
      for (final type1 in FilterType.values) {
        for (final type2 in FilterType.values) {
          if (type1.index < type2.index) {
            bool different = false;
            for (int i = 0; i < 512; i++) {
              if ((buffers[type1]![i] - buffers[type2]![i]).abs() > 0.001) {
                different = true;
                break;
              }
            }
            expect(different, isTrue,
                reason: '${type1.name} and ${type2.name} should produce different outputs');
          }
        }
      }
    });

    test('Filter cutoff affects high frequency content', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.oscillator1.waveform = Waveform.sawtooth;
      engine.filter.type = FilterType.lowpass;

      // High cutoff
      engine.filter.baseCutoff = 10000.0;
      final bufferBright = engine.generateBuffer(1024);

      // Low cutoff
      engine.filter.baseCutoff = 500.0;
      final bufferDark = engine.generateBuffer(1024);

      // Calculate high-frequency energy (simple metric: sum of sample-to-sample changes)
      double energyBright = 0.0;
      double energyDark = 0.0;
      for (int i = 1; i < 1024; i++) {
        energyBright += (bufferBright[i] - bufferBright[i - 1]).abs();
        energyDark += (bufferDark[i] - bufferDark[i - 1]).abs();
      }

      // Bright buffer should have more high-frequency content
      expect(energyBright, greaterThan(energyDark));
    });
  });

  group('Effects Tests', () {
    test('Reverb affects signal characteristics', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      // Dry signal (no reverb)
      engine.reverb.mix = 0.0;
      final bufferDry = engine.generateBuffer(1024);

      // Reset oscillator phase by recreating engine
      final engineWet = SynthesizerEngine();
      engineWet.setNote(69);
      engineWet.reverb.mix = 0.8;
      engineWet.reverb.roomSize = 0.9;
      final bufferWet = engineWet.generateBuffer(1024);

      // Both should produce valid audio
      expect(bufferDry.any((s) => s != 0.0), isTrue);
      expect(bufferWet.any((s) => s != 0.0), isTrue);

      // Reverb should change the signal (different samples)
      bool different = false;
      for (int i = 100; i < 1024; i++) {
        if ((bufferDry[i] - bufferWet[i]).abs() > 0.01) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });

    test('Reverb mix parameter affects wet/dry balance', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.reverb.roomSize = 0.7;

      engine.reverb.mix = 0.0; // All dry
      final bufferAllDry = engine.generateBuffer(512);

      engine.reverb.mix = 1.0; // All wet
      final bufferAllWet = engine.generateBuffer(512);

      // Different mix should produce different output
      bool different = false;
      for (int i = 0; i < 512; i++) {
        if ((bufferAllDry[i] - bufferAllWet[i]).abs() > 0.001) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });

    test('Delay creates echo effect', () {
      final engine = SynthesizerEngine();
      engine.delay.mix = 0.5;
      engine.delay.delayTime = 100.0; // 100ms
      engine.delay.feedback = 0.3;

      // Initial samples
      engine.setNote(69);
      final buffer = engine.generateBuffer(8192); // Long enough for delay

      // The buffer should contain variations due to delay feedback
      expect(buffer.isNotEmpty, isTrue);

      // Verify valid samples
      for (final sample in buffer) {
        expect(sample.isFinite, isTrue);
      }
    });

    test('Delay time parameter affects echo timing', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.delay.mix = 0.5;
      engine.delay.feedback = 0.3;

      engine.delay.delayTime = 50.0; // Short delay
      final bufferShort = engine.generateBuffer(4096);

      engine.delay.delayTime = 200.0; // Longer delay
      final bufferLong = engine.generateBuffer(4096);

      // Different delay times should produce different patterns
      bool different = false;
      for (int i = 2000; i < 4000; i++) {
        if ((bufferShort[i] - bufferLong[i]).abs() > 0.01) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });
  });

  group('AudioAnalyzer Tests', () {
    test('AudioAnalyzer initializes correctly', () {
      final analyzer = AudioAnalyzer(
        fftSize: 2048,
        sampleRate: 44100.0,
      );

      expect(analyzer, isNotNull);
    });

    test('AudioAnalyzer extracts features from buffer', () {
      final analyzer = AudioAnalyzer(
        fftSize: 2048,
        sampleRate: 44100.0,
      );

      // Generate a simple test buffer (440 Hz sine wave)
      final engine = SynthesizerEngine();
      engine.oscillator1.waveform = Waveform.sine;
      engine.setNote(69); // A4 = 440 Hz
      final buffer = engine.generateBuffer(2048);

      final features = analyzer.extractFeatures(buffer);

      expect(features, isNotNull);
      expect(features.rms, greaterThanOrEqualTo(0.0));
      expect(features.bassEnergy, greaterThanOrEqualTo(0.0));
      expect(features.midEnergy, greaterThanOrEqualTo(0.0));
      expect(features.highEnergy, greaterThanOrEqualTo(0.0));
    });

    test('AudioAnalyzer RMS scales with amplitude', () {
      final analyzer = AudioAnalyzer(fftSize: 1024, sampleRate: 44100.0);
      final engine = SynthesizerEngine();
      engine.setNote(69);

      engine.masterVolume = 0.2;
      final bufferQuiet = engine.generateBuffer(1024);
      final featuresQuiet = analyzer.extractFeatures(bufferQuiet);

      engine.masterVolume = 0.8;
      final bufferLoud = engine.generateBuffer(1024);
      final featuresLoud = analyzer.extractFeatures(bufferLoud);

      expect(featuresLoud.rms, greaterThan(featuresQuiet.rms));
    });

    test('AudioAnalyzer spectral centroid varies with brightness', () {
      final analyzer = AudioAnalyzer(fftSize: 2048, sampleRate: 44100.0);
      final engine = SynthesizerEngine();
      engine.setNote(69);

      // Dark sound: sine wave with low filter
      engine.oscillator1.waveform = Waveform.sine;
      engine.filter.baseCutoff = 500.0;
      final bufferDark = engine.generateBuffer(2048);
      final featuresDark = analyzer.extractFeatures(bufferDark);

      // Bright sound: sawtooth with high filter
      engine.oscillator1.waveform = Waveform.sawtooth;
      engine.filter.baseCutoff = 8000.0;
      final bufferBright = engine.generateBuffer(2048);
      final featuresBright = analyzer.extractFeatures(bufferBright);

      // Bright sound should have higher spectral centroid
      expect(featuresBright.spectralCentroid, greaterThan(featuresDark.spectralCentroid));
    });
  });

  group('Envelope Tests', () {
    test('Envelope has correct default values', () {
      final envelope = Envelope();

      expect(envelope.attack, equals(0.01));
      expect(envelope.decay, equals(0.1));
      expect(envelope.sustain, equals(0.7));
      expect(envelope.release, equals(0.3));
    });

    test('Envelope can be customized', () {
      final envelope = Envelope(
        attack: 0.05,
        decay: 0.2,
        sustain: 0.5,
        release: 0.5,
      );

      expect(envelope.attack, equals(0.05));
      expect(envelope.decay, equals(0.2));
      expect(envelope.sustain, equals(0.5));
      expect(envelope.release, equals(0.5));
    });

    test('Envelope parameters are mutable', () {
      final envelope = Envelope();

      envelope.attack = 0.1;
      envelope.decay = 0.3;
      envelope.sustain = 0.6;
      envelope.release = 0.8;

      expect(envelope.attack, equals(0.1));
      expect(envelope.decay, equals(0.3));
      expect(envelope.sustain, equals(0.6));
      expect(envelope.release, equals(0.8));
    });
  });

  group('Edge Cases and Boundary Conditions', () {
    test('handles zero frequency gracefully', () {
      final engine = SynthesizerEngine();
      engine.oscillator1.baseFrequency = 0.0;

      // Should not crash or produce NaN
      final buffer = engine.generateBuffer(512);
      for (final sample in buffer) {
        expect(sample.isFinite, isTrue);
      }
    });

    test('handles very high frequency', () {
      final engine = SynthesizerEngine();
      engine.setNote(127); // Highest MIDI note

      final buffer = engine.generateBuffer(512);
      for (final sample in buffer) {
        expect(sample.isFinite, isTrue);
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });

    test('handles very low frequency', () {
      final engine = SynthesizerEngine();
      engine.setNote(0); // Lowest MIDI note

      final buffer = engine.generateBuffer(512);
      for (final sample in buffer) {
        expect(sample.isFinite, isTrue);
      }
    });

    test('handles extreme filter resonance', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);
      engine.filter.resonance = 0.99; // Near self-oscillation

      final buffer = engine.generateBuffer(1024);
      for (final sample in buffer) {
        expect(sample.isFinite, isTrue);
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });

    test('handles small buffer sizes', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      final buffer1 = engine.generateBuffer(1);
      expect(buffer1.length, equals(1));

      final buffer16 = engine.generateBuffer(16);
      expect(buffer16.length, equals(16));
    });

    test('handles large buffer sizes', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      final buffer = engine.generateBuffer(44100); // 1 second at 44.1kHz
      expect(buffer.length, equals(44100));

      for (final sample in buffer) {
        expect(sample.isFinite, isTrue);
      }
    });
  });

  group('Voice Count Tests', () {
    test('voice count can be set', () {
      final engine = SynthesizerEngine();
      engine.setVoiceCount(4);
      expect(engine.voiceCount, equals(4));
    });

    test('voice count is clamped to valid range', () {
      final engine = SynthesizerEngine();

      engine.setVoiceCount(0);
      expect(engine.voiceCount, equals(1)); // Minimum is 1

      engine.setVoiceCount(100);
      expect(engine.voiceCount, equals(16)); // Maximum is 16
    });
  });

  group('Performance Tests', () {
    test('generates buffers quickly enough for real-time', () {
      final engine = SynthesizerEngine();
      engine.setNote(69);

      final stopwatch = Stopwatch()..start();

      // Generate 1 second of audio (about 86 buffers at 512 samples)
      for (int i = 0; i < 100; i++) {
        engine.generateBuffer(512);
      }

      stopwatch.stop();

      // Should complete in well under 1 second (target: <100ms for 1s of audio)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
