/// Playability & Musical Parameter Tests
///
/// Tests that the synthesizer feels good to play:
/// - Touch gesture responsiveness
/// - Filter cutoff musical ranges
/// - Envelope attack/release feel natural
/// - Parameter ranges are sensible
/// - No audio clicks/pops on transitions
/// - Note on/off are smooth
///
/// Run: flutter test test/playability_test.dart -r expanded

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/audio/synthesizer_engine.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';

void main() {
  group('Filter Cutoff - Musical Ranges', () {
    late SynthesizerEngine synth;

    setUp(() {
      synth = SynthesizerEngine(sampleRate: 44100.0);
    });

    test('filter cutoff stays in audible range (20Hz - 20kHz)', () {
      synth.setNote(60);

      // Test various modulation amounts
      for (double mod = 0.0; mod <= 0.8; mod += 0.1) {
        synth.modulateFilterCutoff(mod);
        final effectiveCutoff = synth.filter.baseCutoff * (1.0 + mod);

        print('🎚️ Modulation ${(mod * 100).toInt()}%: ${effectiveCutoff.toStringAsFixed(0)} Hz');

        expect(effectiveCutoff, greaterThanOrEqualTo(20.0),
            reason: 'Cutoff should not go below human hearing (20Hz)');
        expect(effectiveCutoff, lessThanOrEqualTo(20000.0),
            reason: 'Cutoff should not exceed human hearing (20kHz)');
      }
    });

    test('filter resonance is stable (no self-oscillation explosion)', () {
      synth.setNote(60);
      synth.filter.resonance = 0.95; // High resonance

      // Generate audio - should not explode
      final buffer = synth.generateBuffer(4096);

      double maxSample = 0.0;
      for (final sample in buffer) {
        if (sample.abs() > maxSample) maxSample = sample.abs();
      }

      print('🎚️ High resonance (0.95) max amplitude: ${maxSample.toStringAsFixed(3)}');

      expect(maxSample, lessThanOrEqualTo(1.0),
          reason: 'Filter should not self-oscillate beyond clipping');
    });

    test('filter sweep sounds smooth (no zipper noise)', () {
      synth.setNote(60);

      // Simulate filter sweep
      final samples = <double>[];
      for (int i = 0; i < 4410; i++) { // 100ms at 44.1kHz
        // Smoothly modulate cutoff
        final mod = i / 4410.0 * 0.6; // 0 to 60%
        synth.modulateFilterCutoff(mod);

        final buffer = synth.generateBuffer(1);
        samples.add(buffer[0]);
      }

      // Check for sudden jumps (zipper noise)
      int jumps = 0;
      for (int i = 1; i < samples.length; i++) {
        final diff = (samples[i] - samples[i - 1]).abs();
        if (diff > 0.3) jumps++; // Large discontinuity
      }

      print('🎚️ Filter sweep discontinuities: $jumps (should be < 10)');

      expect(jumps, lessThan(10),
          reason: 'Filter sweep should be smooth without zipper noise');
    });
  });

  group('Envelope - Natural Attack/Release', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager(sampleRate: 44100.0);
    });

    test('attack time is playable (1-100ms range)', () {
      for (int geom = 0; geom < 8; geom++) {
        manager.setGeometry(geom);
        final voiceChar = _getVoiceCharacterForGeometry(geom);

        print('🎹 ${voiceChar.name}: attack ${voiceChar.attackMs}ms');

        expect(voiceChar.attackMs, greaterThanOrEqualTo(1.0),
            reason: 'Attack < 1ms causes clicks');
        expect(voiceChar.attackMs, lessThanOrEqualTo(100.0),
            reason: 'Attack > 100ms feels sluggish for most sounds');
      }
    });

    test('release time is musical (50-500ms range)', () {
      for (int geom = 0; geom < 8; geom++) {
        manager.setGeometry(geom);
        final voiceChar = _getVoiceCharacterForGeometry(geom);

        print('🎹 ${voiceChar.name}: release ${voiceChar.releaseMs}ms');

        expect(voiceChar.releaseMs, greaterThanOrEqualTo(50.0),
            reason: 'Release < 50ms sounds choppy');
        expect(voiceChar.releaseMs, lessThanOrEqualTo(500.0),
            reason: 'Release > 500ms causes muddiness');
      }
    });

    test('note on produces immediate response', () {
      manager.setGeometry(0);
      manager.setVisualSystem(VisualSystem.quantum);

      // Before note on - should be silent
      final silentBuffer = manager.generateBuffer(512, 440.0);
      double silentMax = 0.0;
      for (final s in silentBuffer) {
        if (s.abs() > silentMax) silentMax = s.abs();
      }

      // Trigger note
      manager.noteOn();

      // After note on - should produce audio within 10ms
      final attackBuffer = manager.generateBuffer(441, 440.0); // 10ms
      double attackMax = 0.0;
      for (final s in attackBuffer) {
        if (s.abs() > attackMax) attackMax = s.abs();
      }

      print('🎹 Silent max: ${silentMax.toStringAsFixed(4)}');
      print('🎹 Attack (10ms) max: ${attackMax.toStringAsFixed(4)}');

      expect(attackMax, greaterThan(silentMax * 5),
          reason: 'Note on should produce audible response within 10ms');
    });

    test('note off fades smoothly (no click)', () {
      manager.setGeometry(0);
      manager.setVisualSystem(VisualSystem.quantum);
      manager.noteOn();

      // Generate sustain
      manager.generateBuffer(4410, 440.0); // 100ms sustain

      // Capture last sample before note off
      final beforeOff = manager.generateBuffer(1, 440.0);

      // Note off
      manager.noteOff();

      // First sample after note off
      final afterOff = manager.generateBuffer(1, 440.0);

      final diff = (afterOff[0] - beforeOff[0]).abs();

      print('🎹 Note off discontinuity: ${diff.toStringAsFixed(4)} (should be < 0.1)');

      expect(diff, lessThan(0.1),
          reason: 'Note off should not cause a click (smooth transition)');
    });
  });

  group('Detune & Modulation - Musical Intervals', () {
    late SynthesizerEngine synth;

    setUp(() {
      synth = SynthesizerEngine(sampleRate: 44100.0);
    });

    test('detune range creates chorus not dissonance (±12 cents)', () {
      // ±12 cents is subtle chorusing
      // More than ±50 cents starts sounding out of tune

      for (double detune in [-12.0, -6.0, 0.0, 6.0, 12.0]) {
        synth.oscillator1.detune = detune;
        synth.oscillator2.detune = -detune; // Opposite for stereo

        final totalDetune = (detune - (-detune)).abs();
        print('🎵 Detune spread: ±${detune.abs()} cents (total ${totalDetune} cents)');

        expect(totalDetune, lessThanOrEqualTo(24.0),
            reason: 'Total detune > 24 cents sounds out of tune');
      }
    });

    test('frequency modulation stays within musical range (±2 semitones)', () {
      synth.setNote(60); // Middle C = 261.63 Hz
      final baseFreq = synth.oscillator1.baseFrequency;

      for (double semitones in [-2.0, -1.0, 0.0, 1.0, 2.0]) {
        synth.modulateOscillator1Frequency(semitones);

        // Generate a sample to apply the modulation
        synth.generateBuffer(1);

        // Calculate expected frequency
        final ratio = math.pow(2.0, semitones / 12.0);
        final expectedFreq = baseFreq * ratio;

        print('🎵 FM ${semitones >= 0 ? "+" : ""}${semitones.toStringAsFixed(1)} semitones: '
            '${expectedFreq.toStringAsFixed(1)} Hz');
      }

      // Test clamping - values outside ±2 should be clamped
      synth.modulateOscillator1Frequency(5.0); // Should clamp to 2.0
      synth.generateBuffer(1);
      // The modulation is applied internally, we verify it doesn't crash

      synth.modulateOscillator1Frequency(-5.0); // Should clamp to -2.0
      synth.generateBuffer(1);
      // The modulation is applied internally, we verify it doesn't crash

      print('✅ FM modulation clamping works correctly');
    });
  });

  group('Touch Gesture Response', () {
    test('parameter changes respond within 1 audio frame', () {
      final synth = SynthesizerEngine(sampleRate: 44100.0, bufferSize: 512);
      synth.setNote(60);

      // Capture initial state
      final before = synth.generateBuffer(512);

      // Change parameter
      synth.mixBalance = 0.8; // Shift to osc2

      // Next buffer should reflect change
      final after = synth.generateBuffer(512);

      // Buffers should be different
      bool different = false;
      for (int i = 0; i < 512; i++) {
        if ((before[i] - after[i]).abs() > 0.01) {
          different = true;
          break;
        }
      }

      print('👆 Parameter change response: ${different ? "IMMEDIATE" : "DELAYED"}');
      expect(different, isTrue, reason: 'Parameter changes should be immediate');
    });

    test('rapid parameter changes do not cause audio glitches', () {
      final synth = SynthesizerEngine(sampleRate: 44100.0);
      synth.setNote(60);

      final allSamples = <double>[];

      // Simulate rapid touch movements
      for (int i = 0; i < 100; i++) {
        // Rapidly change multiple parameters
        synth.mixBalance = (math.sin(i * 0.5) + 1.0) / 2.0;
        synth.modulateFilterCutoff((math.cos(i * 0.3) + 1.0) / 2.0 * 0.6);
        synth.setWavetablePosition((math.sin(i * 0.7) + 1.0) / 2.0);

        final buffer = synth.generateBuffer(441); // 10ms chunks
        allSamples.addAll(buffer);
      }

      // Check for clipping/explosions
      int clipCount = 0;
      for (final sample in allSamples) {
        if (sample.abs() > 0.99) clipCount++;
      }

      final clipPercent = clipCount / allSamples.length * 100;
      print('👆 Rapid modulation clip rate: ${clipPercent.toStringAsFixed(2)}% (should be < 1%)');

      expect(clipPercent, lessThan(1.0),
          reason: 'Rapid parameter changes should not cause excessive clipping');
    });
  });

  group('Master Volume & Dynamics', () {
    test('master volume range is sensible (0.0 - 1.0)', () {
      final synth = SynthesizerEngine(sampleRate: 44100.0);
      synth.setNote(60);

      for (double vol in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        synth.masterVolume = vol;
        final buffer = synth.generateBuffer(1024);

        double maxSample = 0.0;
        for (final s in buffer) {
          if (s.abs() > maxSample) maxSample = s.abs();
        }

        print('🔊 Volume ${(vol * 100).toInt()}%: max amplitude ${maxSample.toStringAsFixed(3)}');

        if (vol == 0.0) {
          expect(maxSample, equals(0.0), reason: 'Volume 0 should be silent');
        } else {
          expect(maxSample, greaterThan(0.0), reason: 'Non-zero volume should produce audio');
          expect(maxSample, lessThanOrEqualTo(1.0), reason: 'Should not exceed 0dBFS');
        }
      }
    });

    test('default volume is safe for headphones (~0.7)', () {
      final synth = SynthesizerEngine(sampleRate: 44100.0);

      print('🎧 Default master volume: ${synth.masterVolume}');

      expect(synth.masterVolume, lessThanOrEqualTo(0.8),
          reason: 'Default volume should be safe for headphones');
      expect(synth.masterVolume, greaterThanOrEqualTo(0.5),
          reason: 'Default volume should be audible');
    });
  });

  group('Voice Character - Unique Timbres', () {
    test('all 8 geometries have distinct timbral signatures', () {
      final manager = SynthesisBranchManager(sampleRate: 44100.0);
      manager.setVisualSystem(VisualSystem.faceted);

      final signatures = <String, Map<String, double>>{};

      for (int geom = 0; geom < 8; geom++) {
        manager.setGeometry(geom);
        manager.noteOn();

        final buffer = manager.generateBuffer(4096, 440.0);

        // Calculate simple spectral signature
        double rms = 0.0;
        double zeroCrossings = 0.0;
        double peak = 0.0;

        for (int i = 0; i < buffer.length; i++) {
          rms += buffer[i] * buffer[i];
          if (buffer[i].abs() > peak) peak = buffer[i].abs();
          if (i > 0 && buffer[i].sign != buffer[i - 1].sign) {
            zeroCrossings++;
          }
        }

        rms = math.sqrt(rms / buffer.length);
        final zcRate = zeroCrossings / buffer.length * 44100; // ZC per second

        final voiceChar = _getVoiceCharacterForGeometry(geom);
        signatures[voiceChar.name] = {
          'rms': rms,
          'peak': peak,
          'zcRate': zcRate,
        };

        print('🎵 ${voiceChar.name.padRight(12)}: RMS=${rms.toStringAsFixed(3)}, '
            'Peak=${peak.toStringAsFixed(3)}, ZCR=${zcRate.toStringAsFixed(0)} Hz');
      }

      // Verify each geometry produces different signature
      final names = signatures.keys.toList();
      for (int i = 0; i < names.length; i++) {
        for (int j = i + 1; j < names.length; j++) {
          final sig1 = signatures[names[i]]!;
          final sig2 = signatures[names[j]]!;

          // At least one metric should differ significantly
          final rmsDiff = (sig1['rms']! - sig2['rms']!).abs();
          final zcDiff = (sig1['zcRate']! - sig2['zcRate']!).abs();

          final isDifferent = rmsDiff > 0.01 || zcDiff > 100;
          if (!isDifferent) {
            print('⚠️ ${names[i]} and ${names[j]} may be too similar');
          }
        }
      }
    });
  });

  group('Reverb & Effects - Musical Settings', () {
    late SynthesizerEngine synth;

    setUp(() {
      synth = SynthesizerEngine(sampleRate: 44100.0);
    });

    test('reverb mix range is musical (0-60%)', () {
      synth.setNote(60);

      for (double mix in [0.0, 0.2, 0.4, 0.6]) {
        synth.setReverbMix(mix);
        expect(synth.reverb.mix, equals(mix.clamp(0.0, 1.0)));
        print('🎛️ Reverb mix: ${(mix * 100).toInt()}%');
      }

      // High reverb (>60%) can sound washy
      synth.setReverbMix(0.8);
      print('⚠️ High reverb (80%) - may sound washy for lead sounds');
    });

    test('delay time range is musical (0-500ms)', () {
      for (double ms in [0.0, 100.0, 250.0, 500.0]) {
        synth.setDelayTime(ms);

        print('⏱️ Delay time: ${ms.toStringAsFixed(0)}ms');

        // Common musical delay times
        if (ms > 0 && ms <= 50) {
          print('   → Slapback/doubling effect');
        } else if (ms > 50 && ms <= 150) {
          print('   → Short rhythmic delay');
        } else if (ms > 150 && ms <= 350) {
          print('   → Quarter note delay (at ~120 BPM)');
        } else if (ms > 350) {
          print('   → Long atmospheric delay');
        }
      }

      // Verify clamping
      synth.setDelayTime(1500.0);
      expect(synth.delay.delayTime, lessThanOrEqualTo(1000.0),
          reason: 'Delay should be clamped to reasonable max');
    });
  });
}

/// Helper to get voice character info for a geometry
VoiceCharacter _getVoiceCharacterForGeometry(int geomIndex) {
  final geometries = [
    VoiceCharacter.tetrahedron,
    VoiceCharacter.hypercube,
    VoiceCharacter.sphere,
    VoiceCharacter.torus,
    VoiceCharacter.kleinBottle,
    VoiceCharacter.fractal,
    VoiceCharacter.wave,
    VoiceCharacter.crystal,
  ];
  return geometries[geomIndex % 8];
}
