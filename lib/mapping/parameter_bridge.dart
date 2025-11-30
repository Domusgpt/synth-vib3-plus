// VIB34D + Synther Parameter Bridge
//
// Orchestrates bidirectional parameter flow between audio synthesis and 4D
// visual rendering systems.
//
// Audio → Visual: Real-time FFT analysis modulates visual parameters.
// Visual → Audio: Quaternion rotations and geometry state modulate synthesis.
//
// A Paul Phillips Manifestation
// Paul@clearseassolutions.com
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'audio_to_visual.dart';
import 'visual_to_audio.dart';
import '../models/mapping_preset.dart';
import '../providers/audio_provider.dart';
import '../providers/visual_provider.dart';

class ParameterBridge with ChangeNotifier {
  // Modulation systems
  late final AudioToVisualModulator audioToVisual;
  late final VisualToAudioModulator visualToAudio;

  // Providers
  final AudioProvider audioProvider;
  final VisualProvider visualProvider;

  // Current mapping configuration
  MappingPreset _currentPreset = MappingPreset.defaultPreset();

  // Update timer (60 FPS)
  Timer? _updateTimer;
  bool _isRunning = false;

  // Performance metrics
  int _frameCount = 0;
  DateTime _lastFPSCheck = DateTime.now();
  double _currentFPS = 0.0;

  ParameterBridge({
    required this.audioProvider,
    required this.visualProvider,
  }) {
    // Initialize modulation systems
    audioToVisual = AudioToVisualModulator(
      audioProvider: audioProvider,
      visualProvider: visualProvider,
    );

    visualToAudio = VisualToAudioModulator(
      audioProvider: audioProvider,
      visualProvider: visualProvider,
    );
  }

  // Getters
  MappingPreset get currentPreset => _currentPreset;
  bool get isRunning => _isRunning;
  double get currentFPS => _currentFPS;

  /// Start the parameter bridge update loop
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _lastFPSCheck = DateTime.now();
    _frameCount = 0;

    // CRITICAL: Set this bridge on audio provider so it can update Visual→Audio
    audioProvider.parameterBridge = this;

    // 60 FPS update rate for Audio→Visual
    _updateTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 Hz
      (_) => _updateAudioToVisual(),
    );

    notifyListeners();
    debugPrint('🔗 ParameterBridge started - Visual→Audio synced with buffers');
  }

  /// Stop the parameter bridge
  void stop() {
    _updateTimer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// Main update loop called at 60 FPS
  /// Update Audio→Visual only (Visual→Audio happens in audio buffer generation)
  void _updateAudioToVisual() {
    try {
      // Audio → Visual modulation (if enabled in preset)
      if (_currentPreset.audioReactiveEnabled) {
        final audioBuffer = audioProvider.getCurrentBuffer();
        if (audioBuffer != null && audioBuffer.isNotEmpty) {
          audioToVisual.updateFromAudio(audioBuffer);
        }
      }

      // NOTE: Visual→Audio is now synced with buffer generation (more elegant)

      // Update FPS counter
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_lastFPSCheck).inMilliseconds;
      if (elapsed >= 1000) {
        _currentFPS = _frameCount / (elapsed / 1000.0);
        _frameCount = 0;
        _lastFPSCheck = now;
      }
    } catch (e) {
      debugPrint('ParameterBridge update error: $e');
    }
  }

  /// Load a mapping preset
  Future<void> loadPreset(MappingPreset preset) async {
    _currentPreset = preset;

    // Apply preset to both modulation systems
    audioToVisual.applyPreset(preset);
    visualToAudio.applyPreset(preset);

    notifyListeners();
  }

  /// Save current mappings as a new preset
  Future<MappingPreset> saveAsPreset(String name, String description) async {
    final preset = MappingPreset(
      name: name,
      description: description,
      audioReactiveEnabled: _currentPreset.audioReactiveEnabled,
      visualReactiveEnabled: _currentPreset.visualReactiveEnabled,
      audioToVisualMappings: audioToVisual.exportMappings(),
      visualToAudioMappings: visualToAudio.exportMappings(),
    );

    // TODO: Save to local storage and optionally to Firebase
    return preset;
  }

  /// Toggle audio-reactive mode
  void setAudioReactive(bool enabled) {
    _currentPreset = _currentPreset.copyWith(audioReactiveEnabled: enabled);
    notifyListeners();
  }

  /// Toggle visual-reactive mode
  void setVisualReactive(bool enabled) {
    _currentPreset = _currentPreset.copyWith(visualReactiveEnabled: enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
