/**
 * VoicePool - Polyphonic Voice Management
 *
 * Manages 8 concurrent voices with intelligent allocation:
 * - First idle voice (preferred)
 * - Voice stealing (oldest voice if all busy)
 * - Note retriggering (restart if same note playing)
 *
 * A Paul Phillips Manifestation
 */

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'synth_voice.dart';

class VoicePool {
  // Voice configuration
  static const int maxVoices = 8;
  final double sampleRate;

  // Voice instances
  late final List<SynthVoice> voices;

  // Note-to-voice tracking (for quick lookup)
  final Map<int, SynthVoice> _noteToVoiceMap = {};

  VoicePool({required this.sampleRate}) {
    // Initialize 8 voices
    voices = List.generate(
      maxVoices,
      (index) => SynthVoice(voiceId: index, sampleRate: sampleRate),
    );

    debugPrint('✅ VoicePool initialized: $maxVoices voices @ ${sampleRate}Hz');
  }

  /// Allocate a voice for a MIDI note
  /// Returns the voice that will play this note
  SynthVoice allocateVoice(int midiNote) {
    // Strategy 1: Check if this note is already playing (retrigger)
    if (_noteToVoiceMap.containsKey(midiNote)) {
      final voice = _noteToVoiceMap[midiNote]!;
      debugPrint('🔁 Retriggering note $midiNote on voice ${voice.voiceId}');
      voice.noteOn(midiNote);
      return voice;
    }

    // Strategy 2: Find first idle voice
    for (final voice in voices) {
      if (!voice.isActive) {
        debugPrint('🆕 Allocating idle voice ${voice.voiceId} for note $midiNote');
        voice.noteOn(midiNote);
        _noteToVoiceMap[midiNote] = voice;
        return voice;
      }
    }

    // Strategy 3: Voice stealing - steal oldest voice
    final oldestVoice = _findOldestVoice();
    debugPrint('🔄 Stealing voice ${oldestVoice.voiceId} (age: ${oldestVoice.age.toStringAsFixed(2)}s) for note $midiNote');

    // Remove old note mapping
    _noteToVoiceMap.removeWhere((note, voice) => voice == oldestVoice);

    // Assign new note
    oldestVoice.noteOn(midiNote);
    _noteToVoiceMap[midiNote] = oldestVoice;

    return oldestVoice;
  }

  /// Release a voice playing a specific MIDI note
  void releaseVoice(int midiNote) {
    final voice = _noteToVoiceMap[midiNote];
    if (voice != null) {
      debugPrint('🔽 Releasing note $midiNote from voice ${voice.voiceId}');
      voice.noteOff();
      // Don't remove from map yet - voice is in release phase
      // Will be removed when voice becomes truly idle
    } else {
      debugPrint('⚠️  Attempted to release note $midiNote but no voice found');
    }
  }

  /// Release all active voices (panic/all notes off)
  void releaseAllVoices() {
    debugPrint('⏹️  Releasing all voices (panic)');
    for (final voice in voices) {
      if (voice.isActive) {
        voice.noteOff();
      }
    }
    // Note-to-voice map will be cleaned up in next render cycle
  }

  /// Render audio buffer by summing all active voices
  /// Returns stereo interleaved Float32List [L, R, L, R, ...]
  Float32List renderBuffer({
    required int frames,
    double detune = 0.0,
    double mixBalance = 0.5,
  }) {
    final buffer = Float32List(frames * 2); // Stereo interleaved
    final deltaTime = 1.0 / sampleRate;

    // Clean up idle voices from note map
    _noteToVoiceMap.removeWhere((note, voice) => !voice.isActive);

    // Sum all voices
    int activeCount = 0;
    for (final voice in voices) {
      if (voice.isActive) {
        activeCount++;

        for (int i = 0; i < frames; i++) {
          // Generate sample from this voice
          final sample = voice.generateSample(
            deltaTime: deltaTime,
            detune: detune,
          );

          // Mix into stereo buffer (duplicate mono to L+R for now)
          buffer[i * 2] += sample;     // Left
          buffer[i * 2 + 1] += sample; // Right
        }
      }
    }

    // Normalize by active voice count to prevent clipping
    if (activeCount > 0) {
      final normalization = 1.0 / activeCount;
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] *= normalization;
      }
    }

    return buffer;
  }

  /// Find the oldest active voice (for stealing)
  SynthVoice _findOldestVoice() {
    SynthVoice? oldest;
    double maxAge = -1.0;

    for (final voice in voices) {
      if (voice.isActive && voice.age > maxAge) {
        maxAge = voice.age;
        oldest = voice;
      }
    }

    // If no active voice found (shouldn't happen), return first voice
    return oldest ?? voices[0];
  }

  /// Update envelope parameters for all voices
  void setEnvelopeParams({
    double? attack,
    double? decay,
    double? sustain,
    double? release,
  }) {
    for (final voice in voices) {
      if (attack != null) voice.attackTime = attack;
      if (decay != null) voice.decayTime = decay;
      if (sustain != null) voice.sustainLevel = sustain;
      if (release != null) voice.releaseTime = release;
    }
  }

  /// Get active voice count
  int get activeVoiceCount {
    return voices.where((v) => v.isActive).length;
  }

  /// Get list of currently playing notes
  List<int> get activeNotes {
    return _noteToVoiceMap.keys.toList();
  }

  /// Get voice allocation state for debugging/UI
  Map<String, dynamic> getState() {
    return {
      'totalVoices': maxVoices,
      'activeVoices': activeVoiceCount,
      'activeNotes': activeNotes,
      'voiceDetails': voices.map((v) => {
        'id': v.voiceId,
        'active': v.isActive,
        'note': v.midiNote,
        'state': v.state.toString().split('.').last,
        'envelope': v.envelopeValue.toStringAsFixed(3),
        'age': v.age.toStringAsFixed(2),
      }).toList(),
    };
  }
}
