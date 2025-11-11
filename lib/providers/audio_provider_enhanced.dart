/**
 * Enhanced Audio Provider with Dual-Engine Support
 *
 * Manages both PCM and SoLoud audio engines, providing:
 * - Engine switching and comparison
 * - Unified interface for parameter control
 * - Performance metrics for both engines
 * - Missing parameter implementations (glow intensity, etc.)
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/audio_analyzer.dart';
import '../audio/synthesizer_engine.dart';
import '../audio/soloud_synthesizer_engine.dart';
import '../synthesis/synthesis_branch_manager.dart';
import '../utils/logger.dart';

/// Audio engine selection
enum AudioEngineType {
  pcmSound,  // Legacy flutter_pcm_sound engine
  soLoud,    // New flutter_soloud engine (lower latency)
}

class AudioProviderEnhanced with ChangeNotifier {
  // Core audio systems
  late final SynthesizerEngine synthesizerEngine;
  SoLoudSynthesizerEngine? soLoudEngine;
  late final AudioAnalyzer audioAnalyzer;
  late final SynthesisBranchManager synthesisBranchManager;

  // Current active engine
  AudioEngineType _activeEngine = AudioEngineType.soLoud;
  bool _soLoudInitialized = false;

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

  // Enhanced parameters
  double _glowIntensity = 0.3;
  double _reverbMix = 0.3;
  double _attackTime = 10.0; // milliseconds

  // Audio generation timer
  Timer? _audioGenerationTimer;

  // Performance metrics
  int _buffersGenerated = 0;
  DateTime _lastMetricsCheck = DateTime.now();
  final List<int> _latencySamples = [];

  // Engine comparison data
  final Map<AudioEngineType, Map<String, dynamic>> _engineMetrics = {
    AudioEngineType.pcmSound: {},
    AudioEngineType.soLoud: {},
  };

  AudioProviderEnhanced() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize PCM engine (legacy)
    synthesizerEngine = SynthesizerEngine(
      sampleRate: sampleRate,
      bufferSize: bufferSize,
    );

    audioAnalyzer = AudioAnalyzer(
      fftSize: 2048,
      sampleRate: sampleRate,
    );

    synthesisBranchManager = SynthesisBranchManager(
      sampleRate: sampleRate,
    );

    // Initialize SoLoud engine
    try {
      soLoudEngine = SoLoudSynthesizerEngine(sampleRate: sampleRate);
      await soLoudEngine!.init();
      _soLoudInitialized = true;

      Logger.info(
        'Dual-engine audio provider initialized',
        category: LogCategory.audio,
        metadata: {
          'pcm_ready': true,
          'soloud_ready': _soLoudInitialized,
          'default_engine': _activeEngine.name,
        },
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to initialize SoLoud engine, falling back to PCM',
        category: LogCategory.audio,
        error: e,
        stackTrace: stackTrace,
      );
      _activeEngine = AudioEngineType.pcmSound;
      _soLoudInitialized = false;
    }

    notifyListeners();
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
  AudioEngineType get activeEngine => _activeEngine;
  bool get soLoudAvailable => _soLoudInitialized;

  /// Switch between audio engines
  Future<void> switchEngine(AudioEngineType engine) async {
    if (engine == _activeEngine) return;

    if (engine == AudioEngineType.soLoud && !_soLoudInitialized) {
      Logger.warning(
        'Cannot switch to SoLoud: engine not initialized',
        category: LogCategory.audio,
      );
      return;
    }

    final bool wasPlaying = _isPlaying;
    final int currentNoteBackup = _currentNote;

    // Stop current playback
    if (wasPlaying) {
      await stopAudio();
    }

    _activeEngine = engine;

    Logger.info(
      'Switched audio engine',
      category: LogCategory.audio,
      metadata: {'new_engine': engine.name},
    );

    // Sync state to new engine
    _syncStateToEngine();

    // Resume playback if needed
    if (wasPlaying) {
      await playNote(currentNoteBackup);
    }

    notifyListeners();
  }

  /// Sync current state to active engine
  void _syncStateToEngine() {
    switch (_activeEngine) {
      case AudioEngineType.pcmSound:
        // State already synced in main properties
        break;
      case AudioEngineType.soLoud:
        if (soLoudEngine != null) {
          soLoudEngine!.setGeometry(synthesisBranchManager.currentGeometry);
          soLoudEngine!.setVisualSystem(synthesisBranchManager.visualSystem);
        }
        break;
    }
  }

  /// Get current audio buffer for analysis
  Float32List? getCurrentBuffer() => _currentBuffer;

  /// Get current voice count
  int getVoiceCount() => synthesizerEngine.voiceCount;

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

    Logger.debug('Audio started', category: LogCategory.audio, metadata: {
      'engine': _activeEngine.name,
    });
  }

  /// Stop audio generation and playback
  Future<void> stopAudio() async {
    _audioGenerationTimer?.cancel();
    _isPlaying = false;

    // Stop SoLoud voices if active
    if (_activeEngine == AudioEngineType.soLoud && soLoudEngine != null) {
      soLoudEngine!.stopAll();
    }

    await _audioPlayer.stop();
    notifyListeners();

    Logger.debug('Audio stopped', category: LogCategory.audio);
  }

  /// Generate next audio buffer
  void _generateAudioBuffer() {
    final Stopwatch timer = Stopwatch()..start();

    try {
      // Calculate frequency from MIDI note
      final double frequency = _midiNoteToFrequency(_currentNote);

      // Generate buffer based on active engine
      switch (_activeEngine) {
        case AudioEngineType.pcmSound:
          _currentBuffer = synthesisBranchManager.generateBuffer(
            bufferSize,
            frequency,
          );
          break;

        case AudioEngineType.soLoud:
          if (soLoudEngine != null) {
            // SoLoud handles playback internally, just get FFT data
            _currentBuffer = soLoudEngine!.getFFTData();
          }
          break;
      }

      // Analyze the buffer
      if (_currentBuffer != null && _currentBuffer!.isNotEmpty) {
        _currentFeatures = audioAnalyzer.extractFeatures(_currentBuffer!);
      }

      _buffersGenerated++;

      timer.stop();
      final int latency = timer.elapsedMilliseconds;
      _latencySamples.add(latency);
      if (_latencySamples.length > 100) {
        _latencySamples.removeAt(0);
      }

      // Update engine metrics
      _updateEngineMetrics(latency);

      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error(
        'Error generating audio buffer',
        category: LogCategory.audio,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update performance metrics for current engine
  void _updateEngineMetrics(int latencyMs) {
    _engineMetrics[_activeEngine] = {
      'avg_latency_ms': _averageLatency,
      'buffers_generated': _buffersGenerated,
      'is_playing': _isPlaying,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get average latency
  double get _averageLatency {
    if (_latencySamples.isEmpty) return 0.0;
    final int sum = _latencySamples.reduce((int a, int b) => a + b);
    return sum / _latencySamples.length;
  }

  /// Convert MIDI note to frequency (Hz)
  double _midiNoteToFrequency(int midiNote) {
    // A4 (MIDI 69) = 440 Hz
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }

  /// Play a note (MIDI note number)
  Future<void> playNote(int midiNote) async {
    _currentNote = midiNote;

    switch (_activeEngine) {
      case AudioEngineType.pcmSound:
        synthesizerEngine.setNote(midiNote);
        synthesisBranchManager.noteOn();
        break;

      case AudioEngineType.soLoud:
        if (soLoudEngine != null) {
          final double frequency = _midiNoteToFrequency(midiNote);
          await soLoudEngine!.playNote(frequency, volume: _masterVolume);
        }
        break;
    }

    if (!_isPlaying) {
      await startAudio();
    }

    notifyListeners();
  }

  /// Stop current note
  Future<void> stopNote() async {
    synthesisBranchManager.noteOff();

    if (soLoudEngine != null) {
      soLoudEngine!.stopAll();
    }

    await stopAudio();
  }

  /// Set geometry (0-23) for synthesis
  void setGeometry(int geometry) {
    synthesisBranchManager.setGeometry(geometry);

    if (soLoudEngine != null) {
      soLoudEngine!.setGeometry(geometry);
    }

    Logger.debug(
      'Geometry changed',
      category: LogCategory.synthesis,
      metadata: {
        'geometry': geometry,
        'config': synthesisBranchManager.configString,
      },
    );

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

    synthesisBranchManager.setVisualSystem(system);

    if (soLoudEngine != null) {
      soLoudEngine!.setVisualSystem(system);
    }

    Logger.debug(
      'Visual system changed',
      category: LogCategory.synthesis,
      metadata: {'system': system.name},
    );

    notifyListeners();
  }

  /// Set glow intensity (NEW - missing method)
  void setGlowIntensity(double intensity) {
    _glowIntensity = intensity.clamp(0.0, 1.0);

    // Map glow to reverb mix (5% to 60%)
    _reverbMix = 0.05 + (_glowIntensity * 0.55);
    synthesizerEngine.setReverbMix(_reverbMix);

    if (soLoudEngine != null) {
      soLoudEngine!.setReverb(
        mix: _reverbMix,
        roomSize: 0.7,
        damping: 0.5,
      );
    }

    // Map glow to attack time (1ms to 100ms)
    _attackTime = 1.0 + (_glowIntensity * 99.0);

    Logger.debug(
      'Glow intensity updated',
      category: LogCategory.mapping,
      metadata: {
        'glow': _glowIntensity.toStringAsFixed(2),
        'reverb_mix': _reverbMix.toStringAsFixed(2),
        'attack_ms': _attackTime.toStringAsFixed(1),
      },
    );

    notifyListeners();
  }

  /// Get current synthesis configuration
  String getSynthesisConfig() => synthesisBranchManager.configString;

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

  /// Get audio features for specific band
  double getBassEnergy() => _currentFeatures?.bassEnergy ?? 0.0;
  double getMidEnergy() => _currentFeatures?.midEnergy ?? 0.0;
  double getHighEnergy() => _currentFeatures?.highEnergy ?? 0.0;
  double getSpectralCentroid() => _currentFeatures?.spectralCentroid ?? 0.0;
  double getRMS() => _currentFeatures?.rms ?? 0.0;
  double getStereoWidth() => _currentFeatures?.stereoWidth ?? 0.0;

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    final DateTime now = DateTime.now();
    final int elapsed = now.difference(_lastMetricsCheck).inMilliseconds;
    final double buffersPerSecond =
        elapsed > 0 ? (_buffersGenerated * 1000.0 / elapsed) : 0.0;

    return {
      'buffersPerSecond': buffersPerSecond.toStringAsFixed(1),
      'isPlaying': _isPlaying,
      'currentNote': _currentNote,
      'masterVolume': _masterVolume,
      'voiceCount': synthesizerEngine.voiceCount,
      'activeEngine': _activeEngine.name,
      'avgLatencyMs': _averageLatency.toStringAsFixed(2),
    };
  }

  /// Compare performance between engines
  Map<String, dynamic> compareEnginePerformance() => {
        'pcm': _engineMetrics[AudioEngineType.pcmSound] ?? {},
        'soloud': _engineMetrics[AudioEngineType.soLoud] ?? {},
        'current_engine': _activeEngine.name,
        'soloud_available': _soLoudInitialized,
      };

  @override
  Future<void> dispose() async {
    await stopAudio();
    await _audioPlayer.dispose();

    if (soLoudEngine != null) {
      await soLoudEngine!.dispose();
    }

    super.dispose();
  }
}
