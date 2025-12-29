// Synth-VIB3+ Widget Tests
//
// Tests for the holographic synthesizer application
// Verifies core functionality of audio-visual coupling system
//
// Note: Full widget tests require platform dependencies (PCM audio, WebView).
// These tests focus on pure Dart components that can run headlessly.

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
  });
}
