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
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio/audio_analyzer.dart';
import '../audio/synthesizer_engine.dart';

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

    debugPrint('✅ AudioProvider initialized');
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
      // Generate buffer from synthesizer
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

  /// Play a note (MIDI note number)
  void playNote(int midiNote) {
    _currentNote = midiNote;
    synthesizerEngine.setNote(midiNote);

    if (!_isPlaying) {
      startAudio();
    }

    notifyListeners();
  }

  /// Stop current note
  void stopNote() {
    stopAudio();
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

  @override
  void dispose() {
    stopAudio();
    _audioPlayer.dispose();
    super.dispose();
  }
}
