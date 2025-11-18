/**
 * VIB34D + Synther Parameter Bridge
 *
 * Orchestrates bidirectional parameter flow between audio synthesis
 * and 4D visual rendering systems.
 *
 * Audio → Visual: Real-time FFT analysis modulates visual parameters
 * Visual → Audio: Quaternion rotations and geometry state modulate synthesis
 *
 * A Paul Phillips Manifestation
 * Paul@clearseassolutions.com
 */

import 'dart:async';
import 'dart:typed_data';
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

  // Error tracking
  int _consecutiveErrors = 0;
  int _totalErrors = 0;
  DateTime? _lastErrorTime;
  String? _lastErrorMessage;
  static const int _maxConsecutiveErrors = 10;

  // Performance warnings
  bool _fpsWarningShown = false;
  static const double _targetFPS = 60.0;
  static const double _warningFPSThreshold = 30.0;

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

    // 60 FPS update rate
    _updateTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 Hz
      (_) => _update(),
    );

    notifyListeners();
  }

  /// Stop the parameter bridge
  void stop() {
    _updateTimer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// Main update loop called at 60 FPS
  void _update() {
    try {
      // Audio → Visual modulation (if enabled in preset)
      if (_currentPreset.audioReactiveEnabled) {
        try {
          final audioBuffer = audioProvider.getCurrentBuffer();
          if (audioBuffer != null && audioBuffer.isNotEmpty) {
            audioToVisual.updateFromAudio(audioBuffer);
          }
        } catch (e, stackTrace) {
          _handleError('Audio→Visual modulation', e, stackTrace);
        }
      }

      // Visual → Audio modulation (if enabled in preset)
      if (_currentPreset.visualReactiveEnabled) {
        try {
          visualToAudio.updateFromVisuals();
        } catch (e, stackTrace) {
          _handleError('Visual→Audio modulation', e, stackTrace);
        }
      }

      // Update FPS counter
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_lastFPSCheck).inMilliseconds;
      if (elapsed >= 1000) {
        _currentFPS = _frameCount / (elapsed / 1000.0);
        _frameCount = 0;
        _lastFPSCheck = now;

        // Check for performance issues
        _checkPerformance();
      }

      // Reset consecutive error count on successful update
      if (_consecutiveErrors > 0) {
        debugPrint('✅ ParameterBridge recovered after $_consecutiveErrors errors');
        _consecutiveErrors = 0;
      }
    } catch (e, stackTrace) {
      _handleError('ParameterBridge update', e, stackTrace);
    }
  }

  /// Handle errors with tracking and automatic recovery
  void _handleError(String context, Object error, StackTrace stackTrace) {
    _consecutiveErrors++;
    _totalErrors++;
    _lastErrorTime = DateTime.now();
    _lastErrorMessage = '$context: $error';

    // Log error with context
    debugPrint('❌ $context error ($_consecutiveErrors consecutive): $error');

    // Log stack trace for first error or critical errors
    if (_consecutiveErrors == 1 || _consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('Stack trace: $stackTrace');
    }

    // Automatic shutdown if too many consecutive errors
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('🛑 CRITICAL: Too many consecutive errors ($_consecutiveErrors). Stopping parameter bridge.');
      debugPrint('📝 Last error: $_lastErrorMessage');
      stop();
    }
  }

  /// Check performance and warn if FPS is low
  void _checkPerformance() {
    if (_currentFPS < _warningFPSThreshold && !_fpsWarningShown) {
      debugPrint('⚠️  WARNING: Parameter bridge FPS low: ${_currentFPS.toStringAsFixed(1)} (target: $_targetFPS)');
      debugPrint('📝 This may cause audio-visual coupling lag. Consider reducing visual complexity.');
      _fpsWarningShown = true;
    } else if (_currentFPS >= _targetFPS * 0.9 && _fpsWarningShown) {
      // Reset warning if performance recovers
      debugPrint('✅ Parameter bridge FPS recovered: ${_currentFPS.toStringAsFixed(1)}');
      _fpsWarningShown = false;
    }
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    return {
      'totalErrors': _totalErrors,
      'consecutiveErrors': _consecutiveErrors,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
      'lastErrorMessage': _lastErrorMessage,
      'isHealthy': _consecutiveErrors == 0,
    };
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
