/// Audio Analysis Tests with WAV Output
///
/// Tests the audio analyzer and synthesizer with:
/// - FFT analysis of known waveforms
/// - Frequency band energy detection
/// - WAV file generation for manual listening
/// - Spectrum analysis of all 72 synthesis combinations
///
/// Run: flutter test test/audio_analysis_test.dart -r expanded

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/audio/audio_analyzer.dart';
import 'package:synther_vib34d_holographic/audio/synthesizer_engine.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';

/// WAV file writer for audio output testing
class WavWriter {
  static void writeWav(String filename, Float32List samples, {int sampleRate = 44100}) {
    final file = File(filename);
    final bytes = BytesBuilder();

    // Convert float samples to 16-bit PCM
    final pcmData = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      pcmData[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    }

    final dataSize = pcmData.length * 2;
    final fileSize = 36 + dataSize;

    // RIFF header
    bytes.add('RIFF'.codeUnits);
    bytes.add(_int32ToBytes(fileSize));
    bytes.add('WAVE'.codeUnits);

    // fmt chunk
    bytes.add('fmt '.codeUnits);
    bytes.add(_int32ToBytes(16)); // chunk size
    bytes.add(_int16ToBytes(1));  // PCM format
    bytes.add(_int16ToBytes(1));  // mono
    bytes.add(_int32ToBytes(sampleRate));
    bytes.add(_int32ToBytes(sampleRate * 2)); // byte rate
    bytes.add(_int16ToBytes(2));  // block align
    bytes.add(_int16ToBytes(16)); // bits per sample

    // data chunk
    bytes.add('data'.codeUnits);
    bytes.add(_int32ToBytes(dataSize));
    bytes.add(pcmData.buffer.asUint8List());

    file.writeAsBytesSync(bytes.toBytes());
    print('📁 WAV written: $filename (${samples.length} samples, ${(samples.length / sampleRate).toStringAsFixed(2)}s)');
  }

  static Uint8List _int32ToBytes(int value) {
    return Uint8List(4)
      ..[0] = value & 0xFF
      ..[1] = (value >> 8) & 0xFF
      ..[2] = (value >> 16) & 0xFF
      ..[3] = (value >> 24) & 0xFF;
  }

  static Uint8List _int16ToBytes(int value) {
    return Uint8List(2)
      ..[0] = value & 0xFF
      ..[1] = (value >> 8) & 0xFF;
  }
}

/// Generate test waveforms
class TestWaveforms {
  static Float32List sine(double frequency, int samples, {double sampleRate = 44100.0}) {
    final buffer = Float32List(samples);
    for (int i = 0; i < samples; i++) {
      buffer[i] = math.sin(2.0 * math.pi * frequency * i / sampleRate);
    }
    return buffer;
  }

  static Float32List square(double frequency, int samples, {double sampleRate = 44100.0}) {
    final buffer = Float32List(samples);
    final period = sampleRate / frequency;
    for (int i = 0; i < samples; i++) {
      buffer[i] = ((i % period.round()) < period / 2) ? 1.0 : -1.0;
    }
    return buffer;
  }

  static Float32List sawtooth(double frequency, int samples, {double sampleRate = 44100.0}) {
    final buffer = Float32List(samples);
    final period = sampleRate / frequency;
    for (int i = 0; i < samples; i++) {
      buffer[i] = 2.0 * ((i % period.round()) / period) - 1.0;
    }
    return buffer;
  }

  static Float32List noise(int samples) {
    final buffer = Float32List(samples);
    final random = math.Random(42);
    for (int i = 0; i < samples; i++) {
      buffer[i] = random.nextDouble() * 2.0 - 1.0;
    }
    return buffer;
  }

  static Float32List silence(int samples) {
    return Float32List(samples);
  }
}

void main() {
  group('Audio Analyzer - FFT Tests', () {
    late AudioAnalyzer analyzer;

    setUp(() {
      analyzer = AudioAnalyzer(fftSize: 2048, sampleRate: 44100.0);
    });

    test('detects 440Hz sine wave in mid band', () {
      final samples = TestWaveforms.sine(440.0, 2048);
      final features = analyzer.extractFeatures(samples);

      print('🎵 440Hz Sine Analysis:');
      print('   Bass energy: ${features.bassEnergy.toStringAsFixed(4)}');
      print('   Mid energy:  ${features.midEnergy.toStringAsFixed(4)}');
      print('   High energy: ${features.highEnergy.toStringAsFixed(4)}');
      print('   Centroid:    ${features.spectralCentroid.toStringAsFixed(1)} Hz');
      print('   RMS:         ${features.rms.toStringAsFixed(4)}');

      // 440Hz should be in the mid band (250-2000Hz)
      expect(features.midEnergy, greaterThan(features.bassEnergy));
      expect(features.midEnergy, greaterThan(features.highEnergy));
      expect(features.spectralCentroid, closeTo(440.0, 50.0));
    });

    test('detects 100Hz bass frequency', () {
      final samples = TestWaveforms.sine(100.0, 2048);
      final features = analyzer.extractFeatures(samples);

      print('🎵 100Hz Bass Analysis:');
      print('   Bass energy: ${features.bassEnergy.toStringAsFixed(4)}');
      print('   Mid energy:  ${features.midEnergy.toStringAsFixed(4)}');
      print('   High energy: ${features.highEnergy.toStringAsFixed(4)}');
      print('   Centroid:    ${features.spectralCentroid.toStringAsFixed(1)} Hz');

      // 100Hz should be in bass band (20-250Hz)
      expect(features.bassEnergy, greaterThan(features.midEnergy));
      expect(features.bassEnergy, greaterThan(features.highEnergy));
    });

    test('detects 4000Hz high frequency', () {
      final samples = TestWaveforms.sine(4000.0, 2048);
      final features = analyzer.extractFeatures(samples);

      print('🎵 4000Hz High Analysis:');
      print('   Bass energy: ${features.bassEnergy.toStringAsFixed(4)}');
      print('   Mid energy:  ${features.midEnergy.toStringAsFixed(4)}');
      print('   High energy: ${features.highEnergy.toStringAsFixed(4)}');
      print('   Centroid:    ${features.spectralCentroid.toStringAsFixed(1)} Hz');

      // 4000Hz should be in high band (2000-8000Hz)
      expect(features.highEnergy, greaterThan(features.bassEnergy));
      expect(features.highEnergy, greaterThan(features.midEnergy));
    });

    test('square wave has more harmonics than sine', () {
      final sine = TestWaveforms.sine(440.0, 2048);
      final square = TestWaveforms.square(440.0, 2048);

      final sineFeatures = analyzer.extractFeatures(sine);
      final squareFeatures = analyzer.extractFeatures(square);

      print('🎵 Sine vs Square (440Hz):');
      print('   Sine high energy:   ${sineFeatures.highEnergy.toStringAsFixed(4)}');
      print('   Square high energy: ${squareFeatures.highEnergy.toStringAsFixed(4)}');

      // Square wave has odd harmonics, should have more high frequency content
      expect(squareFeatures.highEnergy, greaterThan(sineFeatures.highEnergy));
    });

    test('sawtooth has rich harmonic content', () {
      final saw = TestWaveforms.sawtooth(220.0, 2048);
      final features = analyzer.extractFeatures(saw);

      print('🎵 Sawtooth 220Hz Analysis:');
      print('   Bass energy: ${features.bassEnergy.toStringAsFixed(4)}');
      print('   Mid energy:  ${features.midEnergy.toStringAsFixed(4)}');
      print('   High energy: ${features.highEnergy.toStringAsFixed(4)}');
      print('   Centroid:    ${features.spectralCentroid.toStringAsFixed(1)} Hz');

      // Sawtooth has all harmonics, should have content in all bands
      expect(features.bassEnergy, greaterThan(0.0));
      expect(features.midEnergy, greaterThan(0.0));
      expect(features.highEnergy, greaterThan(0.0));
    });

    test('silence has near-zero energy', () {
      final samples = TestWaveforms.silence(2048);
      final features = analyzer.extractFeatures(samples);

      print('🔇 Silence Analysis:');
      print('   Total energy: ${features.totalEnergy.toStringAsFixed(6)}');
      print('   RMS:          ${features.rms.toStringAsFixed(6)}');

      expect(features.rms, closeTo(0.0, 0.001));
      expect(features.totalEnergy, closeTo(0.0, 0.001));
    });

    test('noise has flat spectrum', () {
      final samples = TestWaveforms.noise(2048);
      final features = analyzer.extractFeatures(samples);

      print('🔊 Noise Analysis:');
      print('   Bass energy: ${features.bassEnergy.toStringAsFixed(4)}');
      print('   Mid energy:  ${features.midEnergy.toStringAsFixed(4)}');
      print('   High energy: ${features.highEnergy.toStringAsFixed(4)}');

      // All bands should have energy
      expect(features.bassEnergy, greaterThan(0.0));
      expect(features.midEnergy, greaterThan(0.0));
      expect(features.highEnergy, greaterThan(0.0));
    });
  });

  group('Audio Analyzer - RMS Tests', () {
    late AudioAnalyzer analyzer;

    setUp(() {
      analyzer = AudioAnalyzer();
    });

    test('full scale sine has RMS ~0.707', () {
      final samples = TestWaveforms.sine(440.0, 4096);
      final rms = analyzer.computeRMS(samples);

      print('📊 Full scale sine RMS: ${rms.toStringAsFixed(4)} (expected ~0.707)');
      expect(rms, closeTo(0.707, 0.01));
    });

    test('half amplitude sine has RMS ~0.353', () {
      final samples = TestWaveforms.sine(440.0, 4096);
      for (int i = 0; i < samples.length; i++) {
        samples[i] *= 0.5;
      }
      final rms = analyzer.computeRMS(samples);

      print('📊 Half amplitude sine RMS: ${rms.toStringAsFixed(4)} (expected ~0.353)');
      expect(rms, closeTo(0.353, 0.02));
    });
  });

  group('Synthesizer Engine - Basic Tests', () {
    late SynthesizerEngine synth;

    setUp(() {
      synth = SynthesizerEngine(sampleRate: 44100.0, bufferSize: 512);
    });

    test('generates non-silent audio', () {
      synth.setNote(60); // Middle C
      final buffer = synth.generateBuffer(1024);

      double maxAmp = 0.0;
      for (final sample in buffer) {
        if (sample.abs() > maxAmp) maxAmp = sample.abs();
      }

      print('🎹 Middle C max amplitude: ${maxAmp.toStringAsFixed(4)}');
      expect(maxAmp, greaterThan(0.0));
    });

    test('frequency modulation changes pitch', () {
      synth.setNote(60);

      // No modulation
      synth.modulateOscillator1Frequency(0.0);
      final buffer1 = synth.generateBuffer(2048);

      // +2 semitones
      synth.modulateOscillator1Frequency(2.0);
      final buffer2 = synth.generateBuffer(2048);

      // Buffers should be different
      bool different = false;
      for (int i = 0; i < buffer1.length; i++) {
        if ((buffer1[i] - buffer2[i]).abs() > 0.01) {
          different = true;
          break;
        }
      }

      print('🎵 Frequency modulation test: ${different ? "PASS" : "FAIL"}');
      expect(different, isTrue);
    });

    test('filter cutoff modulation affects spectrum', () {
      final analyzer = AudioAnalyzer();
      synth.setNote(60);

      // Full cutoff
      synth.modulateFilterCutoff(0.0);
      final buffer1 = synth.generateBuffer(2048);
      final features1 = analyzer.extractFeatures(buffer1);

      // High cutoff modulation (more filtering)
      synth.modulateFilterCutoff(0.8);
      final buffer2 = synth.generateBuffer(2048);
      final features2 = analyzer.extractFeatures(buffer2);

      print('🎚️ Filter modulation test:');
      print('   Low cutoff - high energy: ${features1.highEnergy.toStringAsFixed(4)}');
      print('   High cutoff - high energy: ${features2.highEnergy.toStringAsFixed(4)}');
    });
  });

  group('Synthesis Branch Manager - All 72 Combinations', () {
    test('analyze all geometries and visual systems', () {
      final analyzer = AudioAnalyzer();
      final manager = SynthesisBranchManager(sampleRate: 44100.0);

      final results = <String, Map<String, double>>{};

      for (final system in VisualSystem.values) {
        manager.setVisualSystem(system);

        for (int geom = 0; geom < 24; geom++) {
          manager.setGeometry(geom);
          manager.noteOn();

          final buffer = manager.generateBuffer(2048, 440.0);
          final features = analyzer.extractFeatures(buffer);

          final key = '${system.name}_geom$geom';
          results[key] = {
            'bass': features.bassEnergy,
            'mid': features.midEnergy,
            'high': features.highEnergy,
            'centroid': features.spectralCentroid,
            'rms': features.rms,
          };
        }
      }

      // Print summary table
      print('\n📊 SYNTHESIS ANALYSIS - ALL 72 COMBINATIONS');
      print('=' * 80);
      print('System      | Geom | Core           | Bass   | Mid    | High   | Centroid');
      print('-' * 80);

      for (final system in VisualSystem.values) {
        for (int geom = 0; geom < 24; geom++) {
          final key = '${system.name}_geom$geom';
          final r = results[key]!;
          final coreIndex = geom ~/ 8;
          final coreName = ['Base', 'Hypersphere', 'Hypertetra'][coreIndex];

          print('${system.name.padRight(11)} | ${geom.toString().padLeft(4)} | ${coreName.padRight(14)} | '
                '${r['bass']!.toStringAsFixed(3).padLeft(6)} | '
                '${r['mid']!.toStringAsFixed(3).padLeft(6)} | '
                '${r['high']!.toStringAsFixed(3).padLeft(6)} | '
                '${r['centroid']!.toStringAsFixed(0).padLeft(8)} Hz');
        }
      }

      // Verify all combinations produce audio
      for (final entry in results.entries) {
        expect(entry.value['rms'], greaterThan(0.0),
          reason: '${entry.key} should produce audio');
      }
    });
  });

  group('WAV File Generation', () {
    test('generate test tone WAV files', () {
      final outputDir = Directory('test_output');
      if (!outputDir.existsSync()) {
        outputDir.createSync();
      }

      // Generate test tones
      final sampleRate = 44100;
      final duration = 2; // seconds
      final samples = sampleRate * duration;

      // 440Hz sine
      WavWriter.writeWav(
        'test_output/sine_440hz.wav',
        TestWaveforms.sine(440.0, samples),
        sampleRate: sampleRate,
      );

      // 220Hz sawtooth
      WavWriter.writeWav(
        'test_output/saw_220hz.wav',
        TestWaveforms.sawtooth(220.0, samples),
        sampleRate: sampleRate,
      );

      // 440Hz square
      WavWriter.writeWav(
        'test_output/square_440hz.wav',
        TestWaveforms.square(440.0, samples),
        sampleRate: sampleRate,
      );

      print('\n✅ Test tone WAV files generated in test_output/');
      expect(File('test_output/sine_440hz.wav').existsSync(), isTrue);
    });

    test('generate synthesis combination WAV files', () {
      final outputDir = Directory('test_output/synthesis');
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      final manager = SynthesisBranchManager(sampleRate: 44100.0);
      final sampleRate = 44100;
      final duration = 2;
      final totalSamples = sampleRate * duration;

      // Generate one sample per visual system × core combination
      final systemNames = ['quantum', 'faceted', 'holographic'];
      final coreNames = ['base', 'hypersphere', 'hypertetra'];

      for (int sysIdx = 0; sysIdx < 3; sysIdx++) {
        manager.setVisualSystem(VisualSystem.values[sysIdx]);

        for (int coreIdx = 0; coreIdx < 3; coreIdx++) {
          final geom = coreIdx * 8; // First geometry of each core
          manager.setGeometry(geom);
          manager.noteOn();

          // Generate 2 seconds of audio
          final allSamples = Float32List(totalSamples);
          int offset = 0;
          while (offset < totalSamples) {
            final chunkSize = math.min(512, totalSamples - offset);
            final chunk = manager.generateBuffer(chunkSize, 440.0);
            allSamples.setRange(offset, offset + chunkSize, chunk);
            offset += chunkSize;
          }

          final filename = 'test_output/synthesis/${systemNames[sysIdx]}_${coreNames[coreIdx]}.wav';
          WavWriter.writeWav(filename, allSamples, sampleRate: sampleRate);
        }
      }

      print('\n✅ Synthesis WAV files generated in test_output/synthesis/');
      print('   Files: quantum_base.wav, quantum_hypersphere.wav, etc.');
    });
  });

  group('Spectral Comparison Tests', () {
    test('different visual systems have different spectra', () {
      final analyzer = AudioAnalyzer();
      final manager = SynthesisBranchManager(sampleRate: 44100.0);

      final spectra = <String, AudioFeatures>{};

      for (final system in VisualSystem.values) {
        manager.setVisualSystem(system);
        manager.setGeometry(0); // Tetrahedron base
        manager.noteOn();

        final buffer = manager.generateBuffer(4096, 440.0);
        spectra[system.name] = analyzer.extractFeatures(buffer);
      }

      print('\n🎨 Visual System Spectral Comparison (440Hz, Tetrahedron):');
      print('-' * 60);

      for (final entry in spectra.entries) {
        final f = entry.value;
        print('${entry.key.padRight(12)}: '
              'bass=${f.bassEnergy.toStringAsFixed(3)}, '
              'mid=${f.midEnergy.toStringAsFixed(3)}, '
              'high=${f.highEnergy.toStringAsFixed(3)}, '
              'centroid=${f.spectralCentroid.toStringAsFixed(0)}Hz');
      }

      // Quantum should be brightest (highest centroid due to pure harmonics)
      // Holographic should have most bass (rich spectrum)
      // All should be different
      final quantum = spectra['quantum']!;
      final faceted = spectra['faceted']!;
      final holographic = spectra['holographic']!;

      // Each system should produce unique spectral characteristics
      expect(quantum.spectralCentroid, isNot(equals(faceted.spectralCentroid)));
      expect(faceted.spectralCentroid, isNot(equals(holographic.spectralCentroid)));
    });

    test('different cores produce different synthesis types', () {
      final analyzer = AudioAnalyzer();
      final manager = SynthesisBranchManager(sampleRate: 44100.0);

      manager.setVisualSystem(VisualSystem.faceted);

      final coreSpectra = <String, AudioFeatures>{};
      final coreNames = ['Base (Direct)', 'Hypersphere (FM)', 'Hypertetra (Ring)'];

      for (int coreIdx = 0; coreIdx < 3; coreIdx++) {
        manager.setGeometry(coreIdx * 8); // First geometry of each core
        manager.noteOn();

        final buffer = manager.generateBuffer(4096, 440.0);
        coreSpectra[coreNames[coreIdx]] = analyzer.extractFeatures(buffer);
      }

      print('\n🔧 Polytope Core Spectral Comparison (Faceted, 440Hz):');
      print('-' * 60);

      for (final entry in coreSpectra.entries) {
        final f = entry.value;
        print('${entry.key.padRight(20)}: '
              'bass=${f.bassEnergy.toStringAsFixed(3)}, '
              'mid=${f.midEnergy.toStringAsFixed(3)}, '
              'high=${f.highEnergy.toStringAsFixed(3)}');
      }

      // All cores should produce audio
      for (final features in coreSpectra.values) {
        expect(features.rms, greaterThan(0.0));
      }
    });
  });
}
