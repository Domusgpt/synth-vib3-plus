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
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import '../audio/audio_analyzer.dart';
import '../audio/synthesizer_engine.dart';
import '../synthesis/synthesis_branch_manager.dart'; // Includes VisualSystem enum

class AudioProvider with ChangeNotifier {
  // Core audio systems
  late final SynthesizerEngine synthesizerEngine;
  late final AudioAnalyzer audioAnalyzer;
  late final SynthesisBranchManager synthesisBranchManager;

  // PCM audio output state
  bool _pcmInitialized = false;

  // Initialization tracking
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

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
  final List<int> _activeNotes = [];
  double _pitchBend = 0.0; // Semitones
  double _vibratoDepth = 0.0;
  double _mixBalance = 0.5; // Oscillator mix (0=osc1, 1=osc2)

  // Parameter smoothing (exponential moving average)
  double _smoothedFilterCutoff = 1000.0;
  double _smoothedResonance = 0.5;
  double _smoothedOsc1Detune = 0.0;
  double _smoothedOsc2Detune = 0.0;
  double _smoothedReverbMix = 0.3;
  final double _smoothingFactor = 0.95; // Higher = smoother but slower (0.9-0.99)

  // Audio generation timer (for visual→audio parameter sync only)
  Timer? _parameterSyncTimer;

  // PCM feed state
  bool _pcmStarted = false;
  int _feedCount = 0;

  // Performance metrics
  int _buffersGenerated = 0;
  DateTime _lastMetricsCheck = DateTime.now();

  /// Check if provider is fully initialized
  bool get isInitialized => _isInitialized;

  /// Check if PCM audio is available
  bool get isPcmAvailable => _pcmInitialized;

  /// Future that completes when initialization is done
  Future<void> get initialized => _initCompleter.future;

  AudioProvider() {
    _initializeSync();
    _initializeAsync();
  }

  /// Synchronous initialization (engines that don't need async)
  void _initializeSync() {
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

    debugPrint('✅ AudioProvider sync initialization complete');
  }

  /// Asynchronous initialization (PCM setup)
  Future<void> _initializeAsync() async {
    try {
      debugPrint('🔧 [AudioProvider] Setting up PCM: sampleRate=${sampleRate.toInt()}, channels=1');

      // Initialize PCM player (static API)
      await FlutterPcmSound.setup(
        sampleRate: sampleRate.toInt(),
        channelCount: 1, // Mono
      );

      // Set feed threshold - callback fires when buffer falls below this
      // Use a larger threshold for smoother playback
      FlutterPcmSound.setFeedThreshold(bufferSize * 4);

      // CRITICAL: Set the feed callback - this is how flutter_pcm_sound works!
      // The callback is invoked when the PCM player needs more samples
      FlutterPcmSound.setFeedCallback(_onPcmFeedRequest);

      _pcmInitialized = true;
      debugPrint('✅ PCM audio output initialized successfully');
      debugPrint('   Sample rate: ${sampleRate.toInt()} Hz');
      debugPrint('   Buffer size: $bufferSize samples');
      debugPrint('   Feed threshold: ${bufferSize * 4} samples');
      debugPrint('   Latency: ${(bufferSize * 1000 / sampleRate).toStringAsFixed(1)} ms');
    } catch (e, stackTrace) {
      _pcmInitialized = false;
      debugPrint('❌ [AudioProvider] PCM initialization failed: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('⚠️ Software synthesis will work but no audio output!');
    }

    _isInitialized = true;
    _initCompleter.complete();
    notifyListeners();
    debugPrint('✅ AudioProvider fully initialized');
    debugPrint('   PCM available: $_pcmInitialized');
  }

  /// PCM feed callback - invoked when the PCM player needs more samples
  /// This is the core of flutter_pcm_sound's callback-based design
  void _onPcmFeedRequest(int remainingFrames) async {
    if (!_isPlaying) {
      // Not playing, don't feed anything (allows buffer to drain and stop)
      if (remainingFrames == 0) {
        debugPrint('🔇 [AudioProvider] PCM buffer drained, playback stopped');
        _pcmStarted = false;
      }
      return;
    }

    // Generate and feed audio
    _feedCount++;
    // Log first 5 callbacks and then every 100th for debugging
    final shouldLog = _feedCount <= 5 || _feedCount % 100 == 0;

    if (_feedCount <= 5) {
      debugPrint('🎧 [AudioProvider] PCM CALLBACK #$_feedCount fired! remaining=$remainingFrames, note=$_currentNote');
    } else if (shouldLog) {
      debugPrint('🔊 [AudioProvider] Feed callback #$_feedCount, remaining: $remainingFrames');
    }

    try {
      // Update visual→audio parameters
      if (parameterBridge != null && parameterBridge.visualToAudio != null) {
        parameterBridge.visualToAudio.updateFromVisuals();
      }

      // Calculate frequency from MIDI note
      final frequency = _midiNoteToFrequency(_currentNote);

      // Apply parameter smoothing
      _applyParameterSmoothing();

      // Generate buffer from synthesis branch manager
      _currentBuffer = synthesisBranchManager.generateBuffer(bufferSize, frequency);

      if (_currentBuffer != null && _currentBuffer!.isNotEmpty) {
        // Check if buffer has actual audio content
        if (shouldLog) {
          double maxSample = 0;
          for (int i = 0; i < _currentBuffer!.length; i++) {
            if (_currentBuffer![i].abs() > maxSample) {
              maxSample = _currentBuffer![i].abs();
            }
          }
          debugPrint('🔊 [AudioProvider] Buffer max amplitude: ${maxSample.toStringAsFixed(4)}');
        }

        // Analyze the buffer for audio reactivity
        _currentFeatures = audioAnalyzer.extractFeatures(_currentBuffer!);

        // Convert Float32List to Int16List (PCM16) and feed
        final int16Buffer = Int16List(bufferSize);
        for (int i = 0; i < bufferSize; i++) {
          final sample = _currentBuffer![i].clamp(-1.0, 1.0);
          int16Buffer[i] = (sample * 32767 * _masterVolume).round();
        }

        await FlutterPcmSound.feed(PcmArrayInt16.fromList(int16Buffer.toList()));
        _buffersGenerated++;

        if (shouldLog) {
          debugPrint('🔊 [AudioProvider] PCM feed successful, total buffers: $_buffersGenerated');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AudioProvider] Error in feed callback: $e');
    }
  }

  /// Apply parameter smoothing for audio quality
  void _applyParameterSmoothing() {
    _smoothedFilterCutoff = _smoothedFilterCutoff * _smoothingFactor +
                             synthesizerEngine.filter.baseCutoff * (1 - _smoothingFactor);
    _smoothedResonance = _smoothedResonance * _smoothingFactor +
                          synthesizerEngine.filter.resonance * (1 - _smoothingFactor);
    _smoothedOsc1Detune = _smoothedOsc1Detune * _smoothingFactor +
                           synthesizerEngine.oscillator1.detune * (1 - _smoothingFactor);
    _smoothedOsc2Detune = _smoothedOsc2Detune * _smoothingFactor +
                           synthesizerEngine.oscillator2.detune * (1 - _smoothingFactor);
  }

  /// Ensure initialization is complete before performing operations
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initCompleter.future;
    }
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
    debugPrint('▶️  [AudioProvider] startAudio() called - already playing: $_isPlaying');
    if (_isPlaying) return;

    // CRITICAL: Wait for initialization to complete before starting audio
    if (!_isInitialized) {
      debugPrint('⏳ [AudioProvider] Waiting for initialization...');
      await _initCompleter.future;
    }

    // Try to initialize PCM if it failed earlier
    if (!_pcmInitialized) {
      debugPrint('🔄 [AudioProvider] PCM not initialized, retrying...');
      await _retryPcmInit();
    }

    // Final check - warn if PCM still not available
    if (!_pcmInitialized) {
      debugPrint('⚠️  [AudioProvider] WARNING: Starting without PCM - no audio output!');
      return; // Can't play without PCM
    }

    _isPlaying = true;
    _lastMetricsCheck = DateTime.now();
    _buffersGenerated = 0;
    _feedCount = 0;

    // CRITICAL: Start the PCM player - this is required for flutter_pcm_sound!
    // The feed callback will be invoked automatically once playback starts
    if (!_pcmStarted) {
      debugPrint('▶️  [AudioProvider] Starting PCM playback...');
      await FlutterPcmSound.start();
      _pcmStarted = true;
      debugPrint('✅ [AudioProvider] PCM playback started');
    }

    // Feed initial samples to get playback going
    // This triggers the callback chain
    _feedInitialSamples();

    notifyListeners();
    debugPrint('▶️  [AudioProvider] Audio started! PCM available: $_pcmInitialized');
  }

  /// Feed initial samples to kickstart playback
  void _feedInitialSamples() async {
    debugPrint('🔊 [AudioProvider] Feeding initial samples for note $_currentNote...');
    try {
      // Feed several buffers to ensure smooth startup
      for (int i = 0; i < 4; i++) {
        final frequency = _midiNoteToFrequency(_currentNote);
        debugPrint('🔊 [AudioProvider] Generating buffer $i with freq=${frequency.toStringAsFixed(1)}Hz');
        _currentBuffer = synthesisBranchManager.generateBuffer(bufferSize, frequency);

        if (_currentBuffer != null) {
          // Calculate max amplitude for debugging
          double maxAmp = 0;
          for (int j = 0; j < _currentBuffer!.length; j++) {
            if (_currentBuffer![j].abs() > maxAmp) maxAmp = _currentBuffer![j].abs();
          }
          debugPrint('🔊 [AudioProvider] Buffer $i max amplitude: ${maxAmp.toStringAsFixed(4)}');

          final int16Buffer = Int16List(bufferSize);
          for (int j = 0; j < bufferSize; j++) {
            final sample = _currentBuffer![j].clamp(-1.0, 1.0);
            int16Buffer[j] = (sample * 32767 * _masterVolume).round();
          }
          await FlutterPcmSound.feed(PcmArrayInt16.fromList(int16Buffer.toList()));
          _buffersGenerated++;
        } else {
          debugPrint('❌ [AudioProvider] Buffer $i was null!');
        }
      }
      debugPrint('✅ [AudioProvider] Initial samples fed: $_buffersGenerated buffers');
    } catch (e, stackTrace) {
      debugPrint('❌ [AudioProvider] Error feeding initial samples: $e');
      debugPrint('   Stack: $stackTrace');
    }
  }

  /// Retry PCM initialization (called if initial setup failed)
  Future<bool> _retryPcmInit() async {
    if (_pcmInitialized) return true;

    try {
      debugPrint('🔧 [AudioProvider] Retrying PCM setup...');
      await FlutterPcmSound.setup(
        sampleRate: sampleRate.toInt(),
        channelCount: 1,
      );
      FlutterPcmSound.setFeedThreshold(bufferSize * 4);
      FlutterPcmSound.setFeedCallback(_onPcmFeedRequest);
      _pcmInitialized = true;
      debugPrint('✅ [AudioProvider] PCM retry successful!');
      return true;
    } catch (e) {
      debugPrint('❌ [AudioProvider] PCM retry failed: $e');
      return false;
    }
  }

  /// Stop audio generation and playback
  Future<void> stopAudio() async {
    debugPrint('⏸️  [AudioProvider] stopAudio() called');
    _isPlaying = false;
    // Note: We don't call FlutterPcmSound.stop() here
    // Instead, the feed callback will stop feeding samples
    // and the buffer will naturally drain, stopping playback
    notifyListeners();
    debugPrint('⏸️  Audio stopped (buffer draining)');
  }

  // Reference to parameter bridge (set externally)
  dynamic parameterBridge;

  /// Convert MIDI note to frequency (Hz)
  double _midiNoteToFrequency(int midiNote) {
    // A4 (MIDI 69) = 440 Hz
    // Each semitone is 2^(1/12) ratio
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }

  /// Play a note (MIDI note number)
  void playNote(int midiNote) {
    debugPrint('🎹 [AudioProvider] playNote($midiNote) - isPlaying=$_isPlaying');
    _currentNote = midiNote;
    synthesizerEngine.setNote(midiNote);
    synthesisBranchManager.noteOn(); // Trigger envelope in branch manager
    debugPrint('🎹 [AudioProvider] synthesisBranchManager.noteOn() called');

    if (!_isPlaying) {
      debugPrint('🎹 [AudioProvider] Starting audio...');
      startAudio();
    }

    notifyListeners();
  }

  /// Stop current note
  void stopNote() {
    synthesisBranchManager.noteOff(); // Start release phase
    stopAudio();
  }

  /// Set geometry (0-23) for synthesis
  void setGeometry(int geometry) {
    synthesisBranchManager.setGeometry(geometry);
    debugPrint('🎵 Geometry set to: $geometry (${synthesisBranchManager.configString})');
    notifyListeners();
  }

  /// Set visual system (Quantum/Faceted/Holographic) → updates sound family
  void setSystem(String systemName) {
    final systemMap = {
      'quantum': VisualSystem.quantum,
      'faceted': VisualSystem.faceted,
      'holographic': VisualSystem.holographic,
    };

    final system = systemMap[systemName.toLowerCase()];
    if (system != null) {
      synthesisBranchManager.setVisualSystem(system);
      debugPrint('🎨 System set to: $systemName → ${system.name} sound family');
      notifyListeners();
    }
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
    debugPrint('🎨 Visual system set to: ${system.name}');
    notifyListeners();
  }

  /// Get current synthesis configuration
  String getSynthesisConfig() {
    return synthesisBranchManager.configString;
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

  /// Note on (polyphonic support)
  /// Uses the callback-based flutter_pcm_sound API for audio playback
  void noteOn(int midiNote) {
    debugPrint('🎹 [AudioProvider] noteOn($midiNote) called - isPlaying=$_isPlaying, pcm=$_pcmInitialized, pcmStarted=$_pcmStarted');

    // Add note immediately
    if (!_activeNotes.contains(midiNote)) {
      _activeNotes.add(midiNote);
    }

    // Set up synthesis immediately
    _currentNote = midiNote;
    synthesizerEngine.setNote(midiNote);
    synthesisBranchManager.noteOn();
    debugPrint('🎹 [AudioProvider] Envelope triggered via synthesisBranchManager.noteOn()');

    // Start audio playback using PCM callback system
    if (!_isPlaying) {
      debugPrint('🎹 [AudioProvider] Starting audio via startAudio()...');
      startAudio(); // This uses the callback-based PCM system
    } else {
      // Already playing - feed some samples for the new note to be heard
      debugPrint('🎹 [AudioProvider] Already playing, continuing with new note');
    }

    notifyListeners();
    debugPrint('🎹 Note $midiNote active, total notes: ${_activeNotes.length}');
  }

  void _playNoteInternal(int midiNote) {
    // Legacy - redirect to noteOn
    noteOn(midiNote);
  }

  /// Note off (polyphonic support)
  void noteOff(int midiNote) {
    _activeNotes.remove(midiNote);
    if (_activeNotes.isEmpty) {
      stopNote();
    } else {
      // Continue playing the most recent note
      playNote(_activeNotes.last);
    }
  }

  /// Get active notes list
  List<int> get activeNotes => List.unmodifiable(_activeNotes);

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

  /// Set FM depth (for FM synthesis)
  void setFMDepth(double depth) {
    // FM depth is handled by synthesis branch manager
    // Store for future use or pass to synthesizer
    notifyListeners();
  }

  /// Set ring modulation mix (for ring mod synthesis)
  void setRingModMix(double mix) {
    // Ring mod mix is handled by synthesis branch manager
    // Store for future use or pass to synthesizer
    notifyListeners();
  }

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

  /// Envelope setters
  void setEnvelopeAttack(double attack) {
    synthesizerEngine.envelope.attack = attack.clamp(0.001, 5.0);
    notifyListeners();
  }

  void setEnvelopeDecay(double decay) {
    synthesizerEngine.envelope.decay = decay.clamp(0.001, 5.0);
    notifyListeners();
  }

  void setEnvelopeSustain(double sustain) {
    synthesizerEngine.envelope.sustain = sustain.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setEnvelopeRelease(double release) {
    synthesizerEngine.envelope.release = release.clamp(0.001, 10.0);
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
    final coreIndex = synthesisBranchManager.currentGeometry ~/ 8;
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

  @override
  void dispose() {
    debugPrint('🛑 [AudioProvider] dispose() called');
    stopAudio();
    // Release PCM resources
    if (_pcmInitialized) {
      try {
        FlutterPcmSound.release();
        debugPrint('✅ [AudioProvider] PCM resources released');
      } catch (e) {
        debugPrint('⚠️ [AudioProvider] Error releasing PCM: $e');
      }
    }
    super.dispose();
  }
}
