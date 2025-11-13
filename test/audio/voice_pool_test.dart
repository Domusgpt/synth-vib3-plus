/**
 * Voice Pool Unit Tests
 *
 * Tests for polyphonic voice management system:
 * - Voice allocation strategies
 * - Voice stealing algorithm
 * - Note retriggering
 * - Envelope state machine
 * - Audio buffer rendering
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synth_vib3_plus/audio/voice_pool.dart';
import 'package:synth_vib3_plus/audio/synth_voice.dart';

void main() {
  group('VoicePool Tests', () {
    late VoicePool voicePool;

    setUp(() {
      voicePool = VoicePool(sampleRate: 44100.0);
    });

    test('VoicePool initializes with 8 idle voices', () {
      expect(voicePool.voices.length, equals(8));
      expect(voicePool.activeVoiceCount, equals(0));
      expect(voicePool.activeNotes, isEmpty);
    });

    test('Allocate first voice from idle pool', () {
      final voice = voicePool.allocateVoice(60); // Middle C

      expect(voice.voiceId, equals(0)); // Should get first voice
      expect(voice.isActive, isTrue);
      expect(voice.midiNote, equals(60));
      expect(voicePool.activeVoiceCount, equals(1));
      expect(voicePool.activeNotes, contains(60));
    });

    test('Allocate multiple voices (polyphonic)', () {
      voicePool.allocateVoice(60); // C
      voicePool.allocateVoice(64); // E
      voicePool.allocateVoice(67); // G

      expect(voicePool.activeVoiceCount, equals(3));
      expect(voicePool.activeNotes, containsAll([60, 64, 67]));
    });

    test('Retrigger same note restarts envelope', () {
      final voice1 = voicePool.allocateVoice(60);
      final voiceId1 = voice1.voiceId;

      // Simulate some time passing
      voice1.age = 1.0;

      // Retrigger same note
      final voice2 = voicePool.allocateVoice(60);
      final voiceId2 = voice2.voiceId;

      expect(voiceId1, equals(voiceId2)); // Same voice
      expect(voice2.age, equals(0.0)); // Age reset
      expect(voice2.state, equals(EnvelopeState.attack)); // Envelope reset
      expect(voicePool.activeVoiceCount, equals(1)); // Still only 1 active
    });

    test('Release voice triggers release phase', () {
      voicePool.allocateVoice(60);
      voicePool.releaseVoice(60);

      final voice = voicePool.voices[0];
      expect(voice.state, equals(EnvelopeState.release));
    });

    test('Voice stealing when all 8 voices busy', () {
      // Allocate all 8 voices
      for (int i = 0; i < 8; i++) {
        final voice = voicePool.allocateVoice(60 + i);
        voice.age = i.toDouble(); // Make voice 0 oldest
      }

      expect(voicePool.activeVoiceCount, equals(8));

      // Allocate 9th voice - should steal oldest (voice 0)
      final newVoice = voicePool.allocateVoice(100);

      expect(voicePool.activeVoiceCount, equals(8)); // Still 8
      expect(newVoice.voiceId, equals(0)); // Stole voice 0
      expect(newVoice.midiNote, equals(100));
      expect(voicePool.activeNotes, contains(100));
      expect(voicePool.activeNotes, isNot(contains(60))); // Old note removed
    });

    test('Release all voices (panic)', () {
      // Allocate multiple voices
      voicePool.allocateVoice(60);
      voicePool.allocateVoice(64);
      voicePool.allocateVoice(67);

      expect(voicePool.activeVoiceCount, equals(3));

      // Panic
      voicePool.releaseAllVoices();

      // All should be in release state
      for (final voice in voicePool.voices) {
        if (voice.isActive) {
          expect(voice.state, equals(EnvelopeState.release));
        }
      }
    });

    test('Render buffer sums all active voices', () {
      // Allocate 3 voices
      voicePool.allocateVoice(60);
      voicePool.allocateVoice(64);
      voicePool.allocateVoice(67);

      // Render small buffer
      final buffer = voicePool.renderBuffer(frames: 64);

      expect(buffer.length, equals(128)); // 64 frames × 2 channels
      expect(buffer.any((sample) => sample != 0.0), isTrue); // Should have audio
    });

    test('Envelope parameters sync to all voices', () {
      voicePool.setEnvelopeParams(
        attack: 0.05,
        decay: 0.2,
        sustain: 0.6,
        release: 0.5,
      );

      for (final voice in voicePool.voices) {
        expect(voice.attackTime, equals(0.05));
        expect(voice.decayTime, equals(0.2));
        expect(voice.sustainLevel, equals(0.6));
        expect(voice.releaseTime, equals(0.5));
      }
    });

    test('Get state returns accurate voice allocation info', () {
      voicePool.allocateVoice(60);
      voicePool.allocateVoice(64);

      final state = voicePool.getState();

      expect(state['totalVoices'], equals(8));
      expect(state['activeVoices'], equals(2));
      expect(state['activeNotes'], equals([60, 64]));
      expect(state['voiceDetails'], hasLength(8));
    });
  });

  group('SynthVoice Envelope Tests', () {
    late SynthVoice voice;

    setUp(() {
      voice = SynthVoice(voiceId: 0, sampleRate: 44100.0);
      voice.attackTime = 0.01; // 10ms
      voice.decayTime = 0.02; // 20ms
      voice.sustainLevel = 0.7;
      voice.releaseTime = 0.05; // 50ms
    });

    test('Voice starts in idle state', () {
      expect(voice.state, equals(EnvelopeState.idle));
      expect(voice.envelopeValue, equals(0.0));
      expect(voice.isActive, isFalse);
    });

    test('Note on triggers attack phase', () {
      voice.noteOn(60);

      expect(voice.state, equals(EnvelopeState.attack));
      expect(voice.midiNote, equals(60));
      expect(voice.isActive, isTrue);
      expect(voice.age, equals(0.0));
    });

    test('Attack phase ramps up to 1.0', () {
      voice.noteOn(60);

      // Generate samples through attack phase
      const deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 441; i++) {
        // 10ms = 441 samples at 44.1kHz
        voice.generateSample(deltaTime: deltaTime, detune: 0.0);
      }

      // Should be near 1.0 after attack time
      expect(voice.state, equals(EnvelopeState.decay));
      expect(voice.envelopeValue, closeTo(1.0, 0.1));
    });

    test('Decay phase ramps down to sustain level', () {
      voice.noteOn(60);

      // Go through attack
      const deltaTime = 1.0 / 44100.0;
      for (int i = 0; i < 441; i++) {
        voice.generateSample(deltaTime: deltaTime, detune: 0.0);
      }

      // Go through decay
      for (int i = 0; i < 882; i++) {
        // 20ms = 882 samples
        voice.generateSample(deltaTime: deltaTime, detune: 0.0);
      }

      expect(voice.state, equals(EnvelopeState.sustain));
      expect(voice.envelopeValue, closeTo(0.7, 0.1));
    });

    test('Note off triggers release phase', () {
      voice.noteOn(60);
      voice.noteOff();

      expect(voice.state, equals(EnvelopeState.release));
    });

    test('Release phase returns to idle', () {
      voice.noteOn(60);
      voice.noteOff();

      const deltaTime = 1.0 / 44100.0;
      // Generate through release phase (50ms = 2205 samples)
      for (int i = 0; i < 2205; i++) {
        voice.generateSample(deltaTime: deltaTime, detune: 0.0);
      }

      expect(voice.state, equals(EnvelopeState.idle));
      expect(voice.isActive, isFalse);
    });

    test('MIDI to frequency conversion', () {
      voice.noteOn(69); // A4
      expect(voice.frequency, closeTo(440.0, 0.1));

      voice.noteOn(60); // Middle C
      expect(voice.frequency, closeTo(261.63, 0.1));

      voice.noteOn(72); // C5
      expect(voice.frequency, closeTo(523.25, 0.1));
    });
  });
}
