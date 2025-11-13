/**
 * Synth Voice - Polyphonic Voice with Synthesis Branch Manager
 *
 * Represents a single voice in the polyphonic synthesizer.
 * Each voice has its own:
 * - SynthesisBranchManager (Direct/FM/Ring Mod synthesis)
 * - MIDI note and frequency
 * - ADSR envelope state (layered on top of branch manager envelope)
 * - Age tracking for voice stealing
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;
import '../synthesis/synthesis_branch_manager.dart';

/// Envelope states for ADSR
enum EnvelopeState {
  idle,      // Not playing
  attack,    // 0.0 → 1.0
  decay,     // 1.0 → sustain level
  sustain,   // Hold sustain level
  release,   // sustain → 0.0
}

/// Single voice in polyphonic synth
class SynthVoice {
  final int voiceId;
  final double sampleRate;

  // Synthesis engine (each voice has its own!)
  late final SynthesisBranchManager synth;

  // Note state
  int midiNote = 60;
  double frequency = 440.0;
  bool isActive = false;

  // Envelope state (layered on top of branch manager envelope)
  EnvelopeState state = EnvelopeState.idle;
  double envelopeValue = 0.0;
  double envelopeTime = 0.0;

  // Envelope parameters (will be updated from global settings)
  double attackTime = 0.01;
  double decayTime = 0.1;
  double sustainLevel = 0.7;
  double releaseTime = 0.3;

  // Age tracking for voice stealing
  double age = 0.0;

  SynthVoice({
    required this.voiceId,
    required this.sampleRate,
  }) {
    // Each voice gets its own synthesis branch manager
    synth = SynthesisBranchManager(sampleRate: sampleRate);
  }

  /// Trigger note-on
  void noteOn(int note) {
    midiNote = note;
    frequency = _midiToFrequency(note);

    // Trigger branch manager envelope
    synth.noteOn();

    // Trigger voice envelope (layered)
    state = EnvelopeState.attack;
    envelopeTime = 0.0;
    envelopeValue = 0.0;
    age = 0.0;
    isActive = true;
  }

  /// Trigger note-off
  void noteOff() {
    // Trigger branch manager release
    synth.noteOff();

    // Trigger voice envelope release
    if (state != EnvelopeState.idle) {
      state = EnvelopeState.release;
      envelopeTime = 0.0;
    }
  }

  /// Generate one sample using synthesis branch manager
  double generateSample({
    required double deltaTime,
    required double detune, // ±semitones
  }) {
    if (!isActive && state == EnvelopeState.idle) {
      return 0.0;
    }

    age += deltaTime;

    // Update voice envelope
    _updateEnvelope(deltaTime);

    // Apply detuning to frequency
    final detuneRatio = math.pow(2.0, detune / 12.0);
    final actualFreq = frequency * detuneRatio;

    // Generate sample using branch manager (Direct/FM/Ring Mod)
    // Branch manager has its own envelope, we layer ours on top
    final buffer = synth.generateBuffer(1, actualFreq);
    final branchSample = buffer[0];

    // Apply voice envelope (layered on top for additional articulation)
    return branchSample * envelopeValue;
  }

  /// Update ADSR envelope state machine
  void _updateEnvelope(double deltaTime) {
    envelopeTime += deltaTime;

    switch (state) {
      case EnvelopeState.idle:
        envelopeValue = 0.0;
        isActive = false;
        break;

      case EnvelopeState.attack:
        if (attackTime > 0.0) {
          envelopeValue = (envelopeTime / attackTime).clamp(0.0, 1.0);
          if (envelopeTime >= attackTime) {
            state = EnvelopeState.decay;
            envelopeTime = 0.0;
          }
        } else {
          // Instant attack
          envelopeValue = 1.0;
          state = EnvelopeState.decay;
          envelopeTime = 0.0;
        }
        break;

      case EnvelopeState.decay:
        if (decayTime > 0.0) {
          final progress = envelopeTime / decayTime;
          envelopeValue = 1.0 - (progress * (1.0 - sustainLevel));
          envelopeValue = envelopeValue.clamp(sustainLevel, 1.0);
          if (envelopeTime >= decayTime) {
            state = EnvelopeState.sustain;
            envelopeValue = sustainLevel;
          }
        } else {
          // Instant decay
          envelopeValue = sustainLevel;
          state = EnvelopeState.sustain;
        }
        break;

      case EnvelopeState.sustain:
        envelopeValue = sustainLevel;
        // Stay here until note-off
        break;

      case EnvelopeState.release:
        if (releaseTime > 0.0) {
          final progress = envelopeTime / releaseTime;
          envelopeValue = sustainLevel * (1.0 - progress);
          envelopeValue = envelopeValue.clamp(0.0, 1.0);
          if (envelopeTime >= releaseTime) {
            state = EnvelopeState.idle;
            envelopeValue = 0.0;
            isActive = false;
          }
        } else {
          // Instant release
          state = EnvelopeState.idle;
          envelopeValue = 0.0;
          isActive = false;
        }
        break;
    }
  }

  /// Convert MIDI note to frequency
  double _midiToFrequency(int note) {
    return 440.0 * math.pow(2.0, (note - 69) / 12.0);
  }

  /// Check if voice is idle (can be reused)
  bool get isIdle => state == EnvelopeState.idle;

  /// Update envelope parameters
  void updateEnvelope({
    required double attack,
    required double decay,
    required double sustain,
    required double release,
  }) {
    attackTime = attack;
    decayTime = decay;
    sustainLevel = sustain;
    releaseTime = release;
  }
}
