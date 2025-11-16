/**
 * Audio Provider
 *
 * Manages the synthesizer engine and audio analyzer, providing
 * state management for the audio synthesis system.
 *
 * Responsibilities:
 * - SynthesizerEngine instance and control
 * - AudioAnalyzer instance
 * - Audio buffer management
 * - Microphone input handling
 * - Audio output to speakers
 * - Current audio feature state
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'dart:math' as dart;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio/audio_analyzer.dart';
import '../audio/synthesizer_engine.dart';
import '../synthesis/synthesis_branch_manager.dart';

class AudioProvider with ChangeNotifier {
  // Core audio systems
  late final SynthesizerEngine synthesizerEngine;
  late final AudioAnalyzer audioAnalyzer;

  // Audio I/O
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Audio buffer management
  Float32List? _currentBuffer;
  final int bufferSize = 512;
  final double sampleRate = 44100.0;

  // Current audio features (from analysis)
  AudioFeatures? _currentFeatures;

  // Synthesizer state
  int _currentNote = 60; // Middle C
  bool _isPlaying = false;
  double _masterVolume = 0.7;
  double _pitchBend = 0.0; // Semitones
  double _vibratoDepth = 0.0;
  double _mixBalance = 0.5; // Oscillator mix (0=osc1, 1=osc2)
  int _currentGeometry = 0; // Track geometry for UI display

  // Audio generation timer
  Timer? _audioGenerationTimer;

  // Performance metrics
  int _buffersGenerated = 0;
  DateTime _lastMetricsCheck = DateTime.now();

  AudioProvider() {
    _initialize();
  }

  void _initialize() {
    synthesizerEngine = SynthesizerEngine(
      sampleRate: sampleRate,
      bufferSize: bufferSize,
    );

    audioAnalyzer = AudioAnalyzer(
      fftSize: 2048,
      sampleRate: sampleRate,
    );

    debugPrint('✅ AudioProvider initialized with unified synthesis system');
  }

  // Getters
  SynthesizerEngine get synth => synthesizerEngine;
  AudioAnalyzer get analyzer => audioAnalyzer;
  Float32List? get currentBuffer => _currentBuffer;
  AudioFeatures? get currentFeatures => _currentFeatures;
  int get currentNote => _currentNote;
  bool get isPlaying => _isPlaying;
  double get masterVolume => _masterVolume;
  int get voiceCount => synthesizerEngine.voiceCount;

  /// Get current audio buffer for analysis
  Float32List? getCurrentBuffer() {
    return _currentBuffer;
  }

  /// Get current voice count
  int getVoiceCount() {
    return synthesizerEngine.voiceCount;
  }

  /// Start audio generation and playback
  Future<void> startAudio() async {
    if (_isPlaying) return;

    _isPlaying = true;
    _lastMetricsCheck = DateTime.now();
    _buffersGenerated = 0;

    // Generate audio buffers at regular intervals
    _audioGenerationTimer = Timer.periodic(
      Duration(milliseconds: (bufferSize * 1000 / sampleRate).round()),
      (_) => _generateAudioBuffer(),
    );

    notifyListeners();
    debugPrint('▶️  Audio started');
  }

  /// Stop audio generation and playback
  Future<void> stopAudio() async {
    _audioGenerationTimer?.cancel();
    _isPlaying = false;
    await _audioPlayer.stop();
    notifyListeners();
    debugPrint('⏸️  Audio stopped');
  }

  /// Generate next audio buffer
  void _generateAudioBuffer() {
    try {
      // Generate buffer from synthesizer engine (polyphonic with synthesis branches)
      _currentBuffer = synthesizerEngine.generateBuffer(bufferSize);

      // Analyze the buffer
      if (_currentBuffer != null && _currentBuffer!.isNotEmpty) {
        _currentFeatures = audioAnalyzer.extractFeatures(_currentBuffer!);
      }

      _buffersGenerated++;

      // TODO: Send buffer to audio output
      // This requires platform-specific audio API integration
      // For now, just store the buffer for analysis

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error generating audio buffer: $e');
    }
  }

  /// Convert MIDI note to frequency (Hz)
  double _midiNoteToFrequency(int midiNote) {
    // A4 (MIDI 69) = 440 Hz
    // Each semitone is 2^(1/12) ratio
    return 440.0 * dart.math.pow(2.0, (midiNote - 69) / 12.0);
  }

  /// Play a note (MIDI note number) - DEPRECATED, use noteOn() instead
  void playNote(int midiNote) {
    _currentNote = midiNote;
    synthesizerEngine.setNote(midiNote);

    if (!_isPlaying) {
      startAudio();
    }

    notifyListeners();
  }

  /// Stop current note - DEPRECATED, use noteOff() instead
  void stopNote() {
    stopAudio();
  }

  /// Set geometry (0-23) for synthesis
  void setGeometry(int geometry) {
    _currentGeometry = geometry;
    synthesizerEngine.setGeometry(geometry);
    debugPrint('🎵 Geometry set to: $geometry (routing to ${_getSynthesisBranch(geometry)})');
    notifyListeners();
  }

  /// Set visual system (updates sound family)
  void setVisualSystem(String systemName) {
    VisualSystem system;
    switch (systemName.toLowerCase()) {
      case 'quantum':
        system = VisualSystem.quantum;
        break;
      case 'faceted':
        system = VisualSystem.faceted;
        break;
      case 'holographic':
        system = VisualSystem.holographic;
        break;
      default:
        system = VisualSystem.quantum;
    }
    synthesizerEngine.setVisualSystem(system);
    debugPrint('🎨 Visual system set to: ${system.name}');
    notifyListeners();
  }

  /// Get synthesis branch name from geometry
  String _getSynthesisBranch(int geometry) {
    final coreIndex = geometry ~/ 8;
    switch (coreIndex) {
      case 0: return 'Direct Synthesis';
      case 1: return 'FM Synthesis';
      case 2: return 'Ring Modulation';
      default: return 'Unknown';
    }
  }

  /// Get current synthesis configuration
  String getSynthesisConfig() {
    return 'Unified Polyphonic Synthesis System';
  }

  /// Set master volume
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    synthesizerEngine.masterVolume = _masterVolume;
    notifyListeners();
  }

  /// Set oscillator waveform
  void setOscillator1Waveform(Waveform waveform) {
    synthesizerEngine.oscillator1.waveform = waveform;
    notifyListeners();
  }

  void setOscillator2Waveform(Waveform waveform) {
    synthesizerEngine.oscillator2.waveform = waveform;
    notifyListeners();
  }

  /// Set filter parameters
  void setFilterType(FilterType type) {
    synthesizerEngine.filter.type = type;
    notifyListeners();
  }

  void setFilterCutoff(double cutoff) {
    synthesizerEngine.filter.baseCutoff = cutoff.clamp(20.0, 20000.0);
    notifyListeners();
  }

  void setFilterResonance(double resonance) {
    synthesizerEngine.filter.resonance = resonance.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Set reverb parameters
  void setReverbRoomSize(double roomSize) {
    synthesizerEngine.reverb.roomSize = roomSize.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setReverbDamping(double damping) {
    synthesizerEngine.reverb.damping = damping.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Set delay parameters
  void setDelayFeedback(double feedback) {
    synthesizerEngine.delay.feedback = feedback.clamp(0.0, 0.95);
    notifyListeners();
  }

  void setDelayMix(double mix) {
    synthesizerEngine.delay.mix = mix.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Set voice count (called by visual modulator)
  void setVoiceCount(int count) {
    synthesizerEngine.setVoiceCount(count);
    notifyListeners();
  }

  /// Process microphone input (for audio-reactive mode)
  Future<void> startMicrophoneInput() async {
    // TODO: Implement microphone input
    // This requires platform-specific audio input API
    // Will use flutter_sound or audio_session for microphone capture
    debugPrint('🎤 Microphone input not yet implemented');
  }

  void stopMicrophoneInput() {
    // TODO: Stop microphone input
  }

  /// Get audio feature for specific band
  double getBassEnergy() => _currentFeatures?.bassEnergy ?? 0.0;
  double getMidEnergy() => _currentFeatures?.midEnergy ?? 0.0;
  double getHighEnergy() => _currentFeatures?.highEnergy ?? 0.0;
  double getSpectralCentroid() => _currentFeatures?.spectralCentroid ?? 0.0;
  double getRMS() => _currentFeatures?.rms ?? 0.0;
  double getStereoWidth() => _currentFeatures?.stereoWidth ?? 0.0;

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastMetricsCheck).inMilliseconds;
    final buffersPerSecond = elapsed > 0 ? (_buffersGenerated * 1000.0 / elapsed) : 0.0;

    return {
      'buffersPerSecond': buffersPerSecond.toStringAsFixed(1),
      'isPlaying': _isPlaying,
      'currentNote': _currentNote,
      'masterVolume': _masterVolume,
      'voiceCount': synthesizerEngine.voiceCount,
    };
  }

  // Additional methods for UI component compatibility

  /// Note on (polyphonic support) - triggers voice allocation
  void noteOn(int midiNote) {
    synthesizerEngine.noteOn(midiNote);

    // Ensure audio is running
    if (!_isPlaying) {
      startAudio();
    }

    notifyListeners();
  }

  /// Note off (polyphonic support) - triggers voice release
  void noteOff(int midiNote) {
    synthesizerEngine.noteOff(midiNote);
    notifyListeners();
  }

  /// Get active notes list (from voice pool)
  List<int> get activeNotes => synthesizerEngine.activeNotes;

  /// Set pitch bend in semitones
  void setPitchBend(double semitones) {
    _pitchBend = semitones.clamp(-12.0, 12.0);
    // Apply pitch bend to synth engine
    // TODO: Implement in synthesizer_engine.dart
    notifyListeners();
  }

  /// Set vibrato depth
  void setVibratoDepth(double depth) {
    _vibratoDepth = depth.clamp(0.0, 2.0);
    // Apply vibrato to synth engine
    // TODO: Implement in synthesizer_engine.dart
    notifyListeners();
  }

  /// Set oscillator mix balance
  void setMixBalance(double balance) {
    _mixBalance = balance.clamp(0.0, 1.0);
    synthesizerEngine.mixBalance = _mixBalance;
    notifyListeners();
  }

  /// Get mix balance
  double get mixBalance => _mixBalance;

  /// Get system colors (placeholder - will be populated from VisualProvider)
  dynamic get systemColors {
    // This should be injected from VisualProvider
    return null;
  }

  /// Oscillator 1 detune
  double get oscillator1Detune => synthesizerEngine.oscillator1.detune;
  void setOscillator1Detune(double cents) {
    synthesizerEngine.oscillator1.detune = cents.clamp(-100.0, 100.0);
    notifyListeners();
  }

  /// Oscillator 2 detune
  double get oscillator2Detune => synthesizerEngine.oscillator2.detune;
  void setOscillator2Detune(double cents) {
    synthesizerEngine.oscillator2.detune = cents.clamp(-100.0, 100.0);
    notifyListeners();
  }

  /// Envelope getters
  double get envelopeAttack => synthesizerEngine.envelope.attack;
  double get envelopeDecay => synthesizerEngine.envelope.decay;
  double get envelopeSustain => synthesizerEngine.envelope.sustain;
  double get envelopeRelease => synthesizerEngine.envelope.release;

  /// Envelope setters (synced with voice pool)
  void setEnvelopeAttack(double attack) {
    synthesizerEngine.setEnvelopeAttack(attack);
    notifyListeners();
  }

  void setEnvelopeDecay(double decay) {
    synthesizerEngine.setEnvelopeDecay(decay);
    notifyListeners();
  }

  void setEnvelopeSustain(double sustain) {
    synthesizerEngine.setEnvelopeSustain(sustain);
    notifyListeners();
  }

  void setEnvelopeRelease(double release) {
    synthesizerEngine.setEnvelopeRelease(release);
    notifyListeners();
  }

  /// Filter getters
  double get filterCutoff => synthesizerEngine.filter.baseCutoff;
  double get filterResonance => synthesizerEngine.filter.resonance;
  double get filterEnvelopeAmount => synthesizerEngine.filter.envelopeAmount;

  /// Filter envelope amount setter
  void setFilterEnvelopeAmount(double amount) {
    synthesizerEngine.filter.envelopeAmount = amount.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Reverb getters
  double get reverbMix => synthesizerEngine.reverb.mix;
  double get reverbRoomSize => synthesizerEngine.reverb.roomSize;
  double get reverbDamping => synthesizerEngine.reverb.damping;

  /// Reverb mix setter
  void setReverbMix(double mix) {
    synthesizerEngine.reverb.mix = mix.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Delay getters
  double get delayTime => synthesizerEngine.delay.time;
  double get delayFeedback => synthesizerEngine.delay.feedback;
  double get delayMix => synthesizerEngine.delay.mix;

  /// Delay time setter
  void setDelayTime(double time) {
    synthesizerEngine.delay.time = time.clamp(0.001, 2.0);
    notifyListeners();
  }

  /// Get current synthesis branch
  String get currentSynthesisBranch {
    final coreIndex = _currentGeometry ~/ 8;
    switch (coreIndex) {
      case 0: return 'Direct';
      case 1: return 'FM';
      case 2: return 'Ring Mod';
      default: return 'Unknown';
    }
  }

  /// Set synthesis branch (by geometry index)
  void setSynthesisBranch(int geometryIndex) {
    setGeometry(geometryIndex);
  }

  /// Update LFO frequencies from visual rotation speeds
  void updateLFOsFromRotationSpeeds({
    required double rotationSpeedXW,
    required double rotationSpeedYW,
    required double rotationSpeedZW,
  }) {
    synthesizerEngine.updateLFOsFromRotationSpeeds(
      rotationSpeedXW: rotationSpeedXW,
      rotationSpeedYW: rotationSpeedYW,
      rotationSpeedZW: rotationSpeedZW,
    );
  }

  /// Set LFO modulation depths
  void setLFODepths({
    double? vibratoDepth,
    double? filterDepth,
    double? tremoloDepth,
  }) {
    synthesizerEngine.setLFODepths(
      vibratoDepth: vibratoDepth,
      filterDepth: filterDepth,
      tremoloDepth: tremoloDepth,
    );
    notifyListeners();
  }

  /// Get LFO state for debugging/UI
  Map<String, dynamic> getLFOState() {
    return synthesizerEngine.getLFOState();
  }

  @override
  void dispose() {
    stopAudio();
    _audioPlayer.dispose();
    super.dispose();
  }
}
