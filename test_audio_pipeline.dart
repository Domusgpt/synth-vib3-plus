/**
 * Comprehensive Audio Pipeline Test
 *
 * Tests the complete audio generation pipeline:
 * 1. Synthesis engine generates audio
 * 2. Audio is converted to PCM16 format
 * 3. Output is written to WAV file for verification
 *
 * Run with: dart test_audio_pipeline.dart
 * Then play: output_test.wav
 */

import 'dart:io';
import 'dart:typed_data';
import 'lib/synthesis/synthesis_branch_manager.dart';

void main() async {
  print('🔊 Synth-VIB3+ Audio Pipeline Test\n');
  print('=' * 60);

  final manager = SynthesisBranchManager(sampleRate: 44100.0);

  // Test configuration
  const sampleRate = 44100;
  const durationSeconds = 5;
  const totalSamples = sampleRate * durationSeconds;
  const bufferSize = 512;
  const frequency = 440.0; // A4 note

  print('Configuration:');
  print('  Sample Rate: $sampleRate Hz');
  print('  Duration: $durationSeconds seconds');
  print('  Total Samples: $totalSamples');
  print('  Test Frequency: $frequency Hz (A4)');
  print('');

  // Generate audio data
  print('Generating audio...');

  // Set up the synthesizer
  manager.setVisualSystem(VisualSystem.quantum);
  manager.setGeometry(0); // Base Tetrahedron

  // Create buffer for all audio
  final allAudio = Float32List(totalSamples);
  int samplesGenerated = 0;

  // Trigger note
  manager.noteOn();

  // Generate audio in chunks
  while (samplesGenerated < totalSamples) {
    final remaining = totalSamples - samplesGenerated;
    final framesToGenerate = remaining < bufferSize ? remaining : bufferSize;

    final buffer = manager.generateBuffer(framesToGenerate, frequency);

    for (int i = 0; i < buffer.length && samplesGenerated < totalSamples; i++) {
      allAudio[samplesGenerated++] = buffer[i];
    }

    // Show progress
    if (samplesGenerated % (sampleRate ~/ 2) == 0) {
      print('  Generated ${(samplesGenerated / totalSamples * 100).toStringAsFixed(0)}%');
    }
  }

  print('  ✅ Audio generation complete');
  print('');

  // Analyze audio
  print('Analyzing audio...');
  double minSample = double.infinity;
  double maxSample = double.negativeInfinity;
  double sumSquares = 0.0;
  int silentSamples = 0;

  for (int i = 0; i < allAudio.length; i++) {
    final sample = allAudio[i];
    if (sample < minSample) minSample = sample;
    if (sample > maxSample) maxSample = sample;
    sumSquares += sample * sample;
    if (sample.abs() < 0.001) silentSamples++;
  }

  final rms = _sqrt(sumSquares / allAudio.length);
  final peakDB = 20 * _log10(maxSample.abs().clamp(0.0001, 1.0));
  final rmsDB = 20 * _log10(rms.clamp(0.0001, 1.0));
  final silencePercent = silentSamples / allAudio.length * 100;

  print('  Min Sample: ${minSample.toStringAsFixed(4)}');
  print('  Max Sample: ${maxSample.toStringAsFixed(4)}');
  print('  RMS Level: ${rms.toStringAsFixed(4)} (${rmsDB.toStringAsFixed(1)} dB)');
  print('  Peak Level: ${peakDB.toStringAsFixed(1)} dB');
  print('  Silent Samples: ${silencePercent.toStringAsFixed(1)}%');
  print('');

  // Check for issues
  print('Diagnosing potential issues...');

  if (rms < 0.01) {
    print('  ⚠️  WARNING: Very low RMS level - audio may be nearly silent');
    print('     This could indicate:');
    print('     - Envelope not triggering (noteOn not called)');
    print('     - Volume/amplitude too low');
    print('     - Synthesis not producing output');
  } else {
    print('  ✅ RMS level is healthy');
  }

  if (silencePercent > 50) {
    print('  ⚠️  WARNING: Over 50% of samples are silent');
    print('     This could indicate:');
    print('     - Short envelope release');
    print('     - Gap between buffer generations');
  } else {
    print('  ✅ Silence percentage is normal');
  }

  if (maxSample.abs() > 0.95) {
    print('  ⚠️  WARNING: Audio is close to clipping');
  } else if (maxSample.abs() < 0.1) {
    print('  ⚠️  WARNING: Peak level is very low');
  } else {
    print('  ✅ Peak level is good (no clipping)');
  }

  print('');

  // Convert to Int16 PCM (same as flutter_pcm_sound does)
  print('Converting to PCM16...');
  final int16Buffer = Int16List(allAudio.length);
  for (int i = 0; i < allAudio.length; i++) {
    final sample = allAudio[i].clamp(-1.0, 1.0);
    int16Buffer[i] = (sample * 32767).round();
  }
  print('  ✅ PCM conversion complete');
  print('');

  // Write WAV file
  print('Writing WAV file...');
  final wavBytes = _createWavFile(int16Buffer, sampleRate, 1);
  final file = File('output_test.wav');
  await file.writeAsBytes(wavBytes);
  print('  ✅ Saved to: ${file.absolute.path}');
  print('');

  // Test all 3 synthesis branches
  print('Testing all synthesis branches...');
  print('-' * 60);

  for (int geo = 0; geo < 24; geo += 8) {
    final coreName = ['Direct', 'FM', 'Ring Mod'][geo ~/ 8];

    manager.setGeometry(geo);
    manager.noteOn();

    // Generate a small test buffer
    final testBuffer = manager.generateBuffer(1000, frequency);

    double testRms = 0.0;
    for (var s in testBuffer) testRms += s * s;
    testRms = _sqrt(testRms / testBuffer.length);

    print('  Geometry $geo ($coreName): RMS = ${testRms.toStringAsFixed(4)}');

    if (testRms < 0.01) {
      print('    ⚠️  LOW OUTPUT - Check ${coreName.toLowerCase()} synthesis');
    }
  }

  print('');
  print('=' * 60);
  print('🎵 Audio Pipeline Test Complete');
  print('');
  print('To verify audio is working:');
  print('1. Play output_test.wav on this machine or copy it');
  print('2. You should hear a 5-second 440Hz tone');
  print('3. If silent, the synthesis pipeline has issues');
  print('4. If audible, the issue is in flutter_pcm_sound or device audio');
  print('');
}

/// Create a WAV file from Int16 samples
Uint8List _createWavFile(Int16List samples, int sampleRate, int channels) {
  final byteRate = sampleRate * channels * 2; // 16-bit = 2 bytes
  final blockAlign = channels * 2;
  final dataSize = samples.length * 2;
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);

  // RIFF header
  buffer.setUint32(0, 0x52494646, Endian.big); // "RIFF"
  buffer.setUint32(4, fileSize, Endian.little);
  buffer.setUint32(8, 0x57415645, Endian.big); // "WAVE"

  // fmt chunk
  buffer.setUint32(12, 0x666D7420, Endian.big); // "fmt "
  buffer.setUint32(16, 16, Endian.little); // Chunk size
  buffer.setUint16(20, 1, Endian.little); // Audio format (PCM)
  buffer.setUint16(22, channels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, 16, Endian.little); // Bits per sample

  // data chunk
  buffer.setUint32(36, 0x64617461, Endian.big); // "data"
  buffer.setUint32(40, dataSize, Endian.little);

  // Write samples
  for (int i = 0; i < samples.length; i++) {
    buffer.setInt16(44 + i * 2, samples[i], Endian.little);
  }

  return buffer.buffer.asUint8List();
}

double _sqrt(double x) {
  if (x < 0) return 0;
  double r = x;
  double y = 1.0;
  while ((r - y).abs() > 0.000001) {
    r = (r + y) / 2;
    y = x / r;
  }
  return r;
}

double _log10(double x) {
  return _ln(x) / _ln(10.0);
}

double _ln(double x) {
  if (x <= 0) return double.negativeInfinity;
  if (x == 1) return 0;

  // Use series expansion
  double sum = 0;
  double term = (x - 1) / (x + 1);
  double power = term;

  for (int n = 1; n <= 100; n += 2) {
    sum += power / n;
    power *= term * term;
  }

  return 2 * sum;
}
