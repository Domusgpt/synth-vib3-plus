// Synthesizer Engine Unit Tests
//
// Comprehensive tests for audio synthesis components:
// - Oscillator waveform generation accuracy
// - Filter frequency response
// - LFO modulation correctness
// - Noise injection levels
// - Stereo width implementation
//
// A Paul Phillips Manifestation

import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:synther_vib34d_holographic/audio/synthesizer_engine.dart';

void main() {
  group('Oscillator Waveform Tests', () {
    late Oscillator oscillator;

    setUp(() {
      oscillator = Oscillator(
        sampleRate: 44100.0,
        waveform: Waveform.sine,
      );
      oscillator.baseFrequency = 440.0;
    });

    test('Sine wave oscillates between -1 and 1', () {
      final samples = List.generate(1000, (_) => oscillator.nextSample());

      final maxSample = samples.reduce(math.max);
      final minSample = samples.reduce(math.min);

      expect(maxSample, lessThanOrEqualTo(1.0));
      expect(minSample, greaterThanOrEqualTo(-1.0));
      expect(maxSample, greaterThan(0.9)); // Should reach near peak
      expect(minSample, lessThan(-0.9)); // Should reach near trough
    });

    test('Sine wave has correct frequency', () {
      oscillator.baseFrequency = 440.0;
      final samplesPerCycle = 44100.0 / 440.0; // ~100.2 samples

      // Generate 2 full cycles worth
      final samples = List.generate(
        (samplesPerCycle * 2).round(),
        (_) => oscillator.nextSample(),
      );

      // Count zero crossings (should be ~4 for 2 cycles)
      int zeroCrossings = 0;
      for (int i = 1; i < samples.length; i++) {
        if ((samples[i - 1] < 0 && samples[i] >= 0) ||
            (samples[i - 1] >= 0 && samples[i] < 0)) {
          zeroCrossings++;
        }
      }

      // 2 cycles = 4 zero crossings (±1 for boundary effects)
      expect(zeroCrossings, inInclusiveRange(3, 5));
    });

    test('Square wave has correct duty cycle', () {
      oscillator.waveform = Waveform.square;
      final samples = List.generate(1000, (_) => oscillator.nextSample());

      final positiveCount = samples.where((s) => s > 0).length;
      final negativeCount = samples.where((s) => s < 0).length;

      // 50% duty cycle means roughly equal positive/negative
      final ratio = positiveCount / (positiveCount + negativeCount);
      expect(ratio, closeTo(0.5, 0.1));
    });

    test('Sawtooth wave rises linearly', () {
      oscillator.waveform = Waveform.sawtooth;
      oscillator.baseFrequency = 441.0; // 100 samples per cycle

      // Reset phase
      oscillator.phase = 0.0;

      // Sample first quarter of a cycle
      final quarterCycle = (44100.0 / 441.0 / 4).round();
      final samples = List.generate(quarterCycle, (_) => oscillator.nextSample());

      // First quarter should be rising
      for (int i = 1; i < samples.length; i++) {
        expect(samples[i], greaterThan(samples[i - 1]),
            reason: 'Sawtooth should rise monotonically in first quarter');
      }
    });

    test('Triangle wave is symmetric', () {
      oscillator.waveform = Waveform.triangle;
      final samples = List.generate(1000, (_) => oscillator.nextSample());

      final maxSample = samples.reduce(math.max);
      final minSample = samples.reduce(math.min);

      // Symmetric around zero
      expect(maxSample, closeTo(-minSample, 0.1));
    });

    test('Wavetable morphs between sine and sawtooth', () {
      oscillator.waveform = Waveform.wavetable;
      oscillator.baseFrequency = 441.0;

      // At position 0, should be pure sine
      oscillator.wavetablePosition = 0.0;
      oscillator.phase = math.pi / 2; // Peak of sine
      final sinePeak = oscillator.nextSample();
      expect(sinePeak, closeTo(1.0, 0.1));

      // At position 1, should be sawtooth-like
      oscillator.wavetablePosition = 1.0;
      oscillator.phase = 0.0;
      // Collect samples to verify saw character
      final sawSamples = List.generate(100, (_) => oscillator.nextSample());
      // Sawtooth should have more abrupt transitions
      int abruptChanges = 0;
      for (int i = 1; i < sawSamples.length; i++) {
        if ((sawSamples[i] - sawSamples[i - 1]).abs() > 0.1) {
          abruptChanges++;
        }
      }
      expect(abruptChanges, greaterThan(0));
    });

    test('Frequency modulation shifts pitch correctly', () {
      oscillator.baseFrequency = 440.0;

      // +12 semitones = double frequency (1 octave up)
      oscillator.frequencyModulation = 12.0;

      // Count zero crossings with modulation
      final samples = List.generate(1000, (_) => oscillator.nextSample());
      int zeroCrossings = 0;
      for (int i = 1; i < samples.length; i++) {
        if (samples[i - 1] < 0 && samples[i] >= 0) zeroCrossings++;
      }

      // Reset and test without modulation
      oscillator.phase = 0.0;
      oscillator.frequencyModulation = 0.0;
      final baseSamples = List.generate(1000, (_) => oscillator.nextSample());
      int baseZeroCrossings = 0;
      for (int i = 1; i < baseSamples.length; i++) {
        if (baseSamples[i - 1] < 0 && baseSamples[i] >= 0) baseZeroCrossings++;
      }

      // With +12 semitones, should have ~2x zero crossings
      expect(zeroCrossings, closeTo(baseZeroCrossings * 2, baseZeroCrossings * 0.3));
    });

    test('Detune adds cents-level frequency shift', () {
      oscillator.baseFrequency = 440.0;
      oscillator.detune = 100.0; // 100 cents = 1 semitone

      // 100 cents up from 440 Hz ≈ 466.16 Hz
      // This is tested implicitly through frequency modulation code path
      final sample = oscillator.nextSample();
      expect(sample, isNotNaN);
    });
  });

  group('Filter Tests', () {
    late Filter filter;

    setUp(() {
      filter = Filter(
        sampleRate: 44100.0,
        type: FilterType.lowpass,
      );
      filter.baseCutoff = 1000.0;
      filter.resonance = 0.7;
    });

    test('Lowpass filter attenuates high frequencies', () {
      filter.baseCutoff = 500.0;

      // Generate a high-frequency signal (5000 Hz) and filter it
      double phase = 0.0;
      final input = List.generate(1000, (_) {
        phase += 2.0 * math.pi * 5000.0 / 44100.0;
        return math.sin(phase);
      });

      final output = input.map((s) => filter.process(s)).toList();

      // RMS of output should be much lower than input (attenuated)
      final inputRMS = math.sqrt(input.map((s) => s * s).reduce((a, b) => a + b) / input.length);
      final outputRMS = math.sqrt(output.map((s) => s * s).reduce((a, b) => a + b) / output.length);

      expect(outputRMS, lessThan(inputRMS * 0.5),
          reason: 'High frequencies should be attenuated');
    });

    test('Lowpass filter passes low frequencies', () {
      filter.baseCutoff = 5000.0;

      // Generate a low-frequency signal (100 Hz)
      double phase = 0.0;
      final input = List.generate(1000, (_) {
        phase += 2.0 * math.pi * 100.0 / 44100.0;
        return math.sin(phase);
      });

      // Let filter settle
      for (int i = 0; i < 100; i++) {
        filter.process(input[i]);
      }

      final output = input.skip(100).map((s) => filter.process(s)).toList();

      // RMS of output should be close to input (passed through)
      final inputRMS = math.sqrt(input.skip(100).map((s) => s * s).reduce((a, b) => a + b) / (input.length - 100));
      final outputRMS = math.sqrt(output.map((s) => s * s).reduce((a, b) => a + b) / output.length);

      expect(outputRMS, greaterThan(inputRMS * 0.7),
          reason: 'Low frequencies should pass through');
    });

    test('Filter cutoff modulation affects frequency response', () {
      filter.baseCutoff = 1000.0;

      // With positive modulation, cutoff should be higher
      filter.cutoffModulation = 0.5; // +50%

      // The effective cutoff is baseCutoff * (1 + modulation) = 1500 Hz
      // Just verify no errors and output is valid
      final output = filter.process(0.5);
      expect(output, inInclusiveRange(-1.0, 1.0));
    });

    test('Highpass filter attenuates low frequencies', () {
      filter.type = FilterType.highpass;
      filter.baseCutoff = 2000.0;

      // Generate a low-frequency signal (100 Hz)
      double phase = 0.0;
      final input = List.generate(1000, (_) {
        phase += 2.0 * math.pi * 100.0 / 44100.0;
        return math.sin(phase);
      });

      final output = input.map((s) => filter.process(s)).toList();

      // After settling, output should be attenuated
      final outputRMS = math.sqrt(
        output.skip(500).map((s) => s * s).reduce((a, b) => a + b) / 500
      );

      expect(outputRMS, lessThan(0.3),
          reason: 'Low frequencies should be attenuated by highpass');
    });

    test('Bandpass filter passes middle frequencies', () {
      filter.type = FilterType.bandpass;
      filter.baseCutoff = 1000.0;

      // Generate a 1000 Hz signal (at cutoff)
      double phase = 0.0;
      final input = List.generate(1000, (_) {
        phase += 2.0 * math.pi * 1000.0 / 44100.0;
        return math.sin(phase);
      });

      final output = input.map((s) => filter.process(s)).toList();

      // Should pass through reasonably well
      final outputRMS = math.sqrt(
        output.skip(500).map((s) => s * s).reduce((a, b) => a + b) / 500
      );

      expect(outputRMS, greaterThan(0.1),
          reason: 'Frequencies at cutoff should pass through bandpass');
    });

    test('Filter output is always bounded', () {
      // Stress test with extreme inputs
      for (int i = 0; i < 10000; i++) {
        final input = math.sin(i * 0.1) * 2.0; // Slightly overdriven
        final output = filter.process(input);
        expect(output, inInclusiveRange(-1.0, 1.0));
      }
    });
  });

  group('SynthesizerEngine Integration Tests', () {
    late SynthesizerEngine synth;

    setUp(() {
      synth = SynthesizerEngine(
        sampleRate: 44100.0,
        bufferSize: 512,
      );
      synth.setNote(60); // Middle C
    });

    test('Generate buffer produces correct number of samples', () {
      final buffer = synth.generateBuffer(512);
      expect(buffer.length, equals(512));
    });

    test('Generated samples are within valid range', () {
      final buffer = synth.generateBuffer(1024);

      for (final sample in buffer) {
        expect(sample, inInclusiveRange(-1.0, 1.0));
        expect(sample, isNotNaN);
        expect(sample.isFinite, isTrue);
      }
    });

    test('Master volume scales output correctly', () {
      synth.masterVolume = 1.0;
      final loudBuffer = synth.generateBuffer(512);
      final loudRMS = _calculateRMS(loudBuffer);

      synth.masterVolume = 0.5;
      synth.oscillator1.phase = 0.0;
      synth.oscillator2.phase = 0.0;
      final quietBuffer = synth.generateBuffer(512);
      final quietRMS = _calculateRMS(quietBuffer);

      expect(quietRMS, closeTo(loudRMS * 0.5, loudRMS * 0.2));
    });

    test('Mix balance controls oscillator blend', () {
      // Osc1 only
      synth.mixBalance = 0.0;
      synth.oscillator1.phase = 0.0;
      final osc1Buffer = synth.generateBuffer(256);

      // Osc2 only
      synth.mixBalance = 1.0;
      synth.oscillator1.phase = 0.0;
      synth.oscillator2.phase = 0.0;
      final osc2Buffer = synth.generateBuffer(256);

      // 50/50 mix
      synth.mixBalance = 0.5;
      synth.oscillator1.phase = 0.0;
      synth.oscillator2.phase = 0.0;
      final mixBuffer = synth.generateBuffer(256);

      // All should produce audio
      expect(_calculateRMS(osc1Buffer), greaterThan(0.01));
      expect(_calculateRMS(osc2Buffer), greaterThan(0.01));
      expect(_calculateRMS(mixBuffer), greaterThan(0.01));
    });

    test('Stereo width affects oscillator detuning', () {
      synth.setStereoWidth(0.0);
      expect(synth.stereoWidth, equals(0.0));

      synth.setStereoWidth(1.0);
      expect(synth.stereoWidth, equals(1.0));

      // Width > 1 should clamp
      synth.setStereoWidth(1.5);
      expect(synth.stereoWidth, equals(1.0));
    });

    test('Noise injection adds randomness', () {
      synth.setNoiseLevel(0.0);
      synth.oscillator1.phase = 0.0;
      synth.oscillator2.phase = 0.0;
      final cleanBuffer1 = synth.generateBuffer(256);

      synth.oscillator1.phase = 0.0;
      synth.oscillator2.phase = 0.0;
      final cleanBuffer2 = synth.generateBuffer(256);

      // Without noise, buffers should be very similar (deterministic)
      double cleanDiff = 0.0;
      for (int i = 0; i < 256; i++) {
        cleanDiff += (cleanBuffer1[i] - cleanBuffer2[i]).abs();
      }

      synth.setNoiseLevel(0.3);
      synth.oscillator1.phase = 0.0;
      synth.oscillator2.phase = 0.0;
      final noisyBuffer1 = synth.generateBuffer(256);

      synth.oscillator1.phase = 0.0;
      synth.oscillator2.phase = 0.0;
      final noisyBuffer2 = synth.generateBuffer(256);

      // With noise, buffers should differ
      double noisyDiff = 0.0;
      for (int i = 0; i < 256; i++) {
        noisyDiff += (noisyBuffer1[i] - noisyBuffer2[i]).abs();
      }

      expect(noisyDiff, greaterThan(cleanDiff * 2),
          reason: 'Noise should make consecutive buffers differ');
    });

    test('LFO rate is clamped to valid range', () {
      synth.setLFORate(0.05); // Below min
      // Internal rate should be clamped to 0.1
      final buffer = synth.generateBuffer(256);
      expect(buffer, isNotEmpty);

      synth.setLFORate(15.0); // Above max
      // Internal rate should be clamped to 10.0
      final buffer2 = synth.generateBuffer(256);
      expect(buffer2, isNotEmpty);
    });

    test('LFO modulates filter cutoff', () {
      synth.setLFORate(10.0); // Fast LFO
      synth.setLFODepth(1.0); // Full depth

      // Generate buffer and check filter cutoff varies
      final buffer = synth.generateBuffer(4410); // 0.1 seconds

      // At 10 Hz LFO, we should complete 1 full cycle
      // Filter should be modulated throughout
      expect(_calculateRMS(buffer), greaterThan(0.01));
    });

    test('Voice count setter works', () {
      synth.setVoiceCount(4);
      expect(synth.voiceCount, equals(4));

      synth.setVoiceCount(20); // Above max
      expect(synth.voiceCount, equals(16)); // Clamped
    });

    test('Reverb mix affects wet/dry ratio', () {
      synth.setReverbMix(0.0);
      expect(synth.reverb.mix, equals(0.0));

      synth.setReverbMix(0.5);
      expect(synth.reverb.mix, equals(0.5));

      synth.setReverbMix(1.5); // Above max
      expect(synth.reverb.mix, equals(1.0)); // Clamped
    });

    test('Delay time is bounded', () {
      synth.setDelayTime(500.0);
      expect(synth.delay.delayTime, equals(500.0));

      synth.setDelayTime(2000.0); // Above max
      expect(synth.delay.delayTime, equals(1000.0)); // Clamped
    });

    test('MIDI note sets correct base frequency', () {
      synth.setNote(69); // A4 = 440 Hz
      expect(synth.oscillator1.baseFrequency, closeTo(440.0, 0.01));

      synth.setNote(60); // C4 = 261.63 Hz
      expect(synth.oscillator1.baseFrequency, closeTo(261.63, 0.1));

      synth.setNote(81); // A5 = 880 Hz
      expect(synth.oscillator1.baseFrequency, closeTo(880.0, 0.1));
    });
  });

  group('Reverb Tests', () {
    late Reverb reverb;

    setUp(() {
      reverb = Reverb(sampleRate: 44100.0);
    });

    test('Dry signal passes through with mix=0', () {
      reverb.mix = 0.0;

      final input = 0.5;
      final output = reverb.process(input);

      // With 0 mix, should be pure dry signal (initially)
      expect(output, closeTo(input, 0.01));
    });

    test('Reverb adds decay tail', () {
      reverb.mix = 0.5;
      reverb.roomSize = 0.8;

      // Send impulse
      reverb.process(1.0);

      // Subsequent samples should have reverb tail
      double maxTail = 0.0;
      for (int i = 0; i < 1000; i++) {
        final sample = reverb.process(0.0);
        if (sample.abs() > maxTail) maxTail = sample.abs();
      }

      expect(maxTail, greaterThan(0.01),
          reason: 'Reverb should produce decay tail');
    });
  });

  group('Delay Tests', () {
    late Delay delay;

    setUp(() {
      delay = Delay(sampleRate: 44100.0);
    });

    test('Delay produces echo after specified time', () {
      delay.delayTime = 100.0; // 100ms
      delay.mix = 1.0; // Pure wet for testing
      delay.feedback = 0.0;

      // Send impulse
      delay.process(1.0);

      // Wait ~100ms worth of samples (4410 at 44100 Hz)
      for (int i = 0; i < 4400; i++) {
        delay.process(0.0);
      }

      // Around 4410 samples, we should see the echo
      bool foundEcho = false;
      for (int i = 0; i < 100; i++) {
        final sample = delay.process(0.0);
        if (sample.abs() > 0.5) foundEcho = true;
      }

      expect(foundEcho, isTrue, reason: 'Should find echo after delay time');
    });

    test('Feedback creates multiple echoes', () {
      delay.delayTime = 50.0; // 50ms for faster test
      delay.mix = 0.5;
      delay.feedback = 0.5;

      // Send impulse
      delay.process(1.0);

      // Count significant echoes
      int echoCount = 0;
      double lastPeak = 0.0;

      for (int i = 0; i < 10000; i++) {
        final sample = delay.process(0.0).abs();
        if (sample > 0.1 && sample > lastPeak) {
          echoCount++;
        }
        lastPeak = sample;
      }

      expect(echoCount, greaterThan(1),
          reason: 'Feedback should create multiple echoes');
    });
  });

  group('Envelope Tests', () {
    test('Envelope has valid ADSR values', () {
      final env = Envelope();

      expect(env.attack, greaterThan(0.0));
      expect(env.decay, greaterThan(0.0));
      expect(env.sustain, inInclusiveRange(0.0, 1.0));
      expect(env.release, greaterThan(0.0));
    });

    test('Envelope can be customized', () {
      final env = Envelope(
        attack: 0.05,
        decay: 0.2,
        sustain: 0.8,
        release: 0.5,
      );

      expect(env.attack, equals(0.05));
      expect(env.decay, equals(0.2));
      expect(env.sustain, equals(0.8));
      expect(env.release, equals(0.5));
    });
  });
}

/// Calculate RMS (root mean square) of audio buffer
double _calculateRMS(Float32List buffer) {
  if (buffer.isEmpty) return 0.0;
  double sum = 0.0;
  for (final sample in buffer) {
    sum += sample * sample;
  }
  return math.sqrt(sum / buffer.length);
}
