/**
 * UI State Provider
 *
 * Manages all UI state including panel visibility, layout configuration,
 * XY pad settings, orb controller position, and keyboard mode.
 *
 * This provider works alongside AudioProvider and VisualProvider to provide
 * comprehensive state management for the entire application.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Device type detection
enum DeviceType {
  phone,
  tablet,
}

/// Keyboard layout modes
enum KeyboardLayout {
  scrolling,  // 2 octaves visible, horizontal scroll
  locked,     // Fixed range with adjustable size
  thumbPads,  // Ergonomic thumb pads (portrait only)
}

/// XY axis assignment options
enum XYAxisParameter {
  pitch,
  filterCutoff,
  resonance,
  fmDepth,
  ringModMix,
  morph,
  chaos,
  brightness,
  reverb,
  oscillatorMix,
  morphParameter,
  rotationSpeed,
}

/// Parameter range configuration
class ParameterRange {
  final double min;
  final double max;
  final double step;
  final String unit;

  const ParameterRange({
    required this.min,
    required this.max,
    this.step = 0.01,
    this.unit = '',
  });
}

class UIStateProvider with ChangeNotifier {
  // Panel visibility states
  final Map<String, bool> _panelStates = {
    'synthesis': false,
    'effects': false,
    'geometry': false,
    'mapping': false,
  };

  // Layout configuration
  Orientation _currentOrientation = Orientation.portrait;
  DeviceType _deviceType = DeviceType.phone;

  // Orb controller configuration
  Offset _orbPosition = const Offset(50, 300);
  bool _orbVisible = true;
  double _orbPitchBendRange = 2.0; // ±2 semitones default
  double _orbVibratoDepth = 1.0;   // 1 semitone max

  // Keyboard mode
  bool _keyboardMode = false;
  KeyboardLayout _keyboardLayout = KeyboardLayout.scrolling;
  int _keyboardOctaveStart = 3; // C3
  double _keySize = 1.0; // 1.0 = medium, 0.75 = small, 1.5 = large

  // Thumb pads (portrait mode)
  bool _thumbPadsVisible = true;
  String _leftPadParameter = 'octave';    // Fixed
  String _rightPadParameter = 'volume';   // Assignable

  // XY pad configuration
  XYAxisParameter _xyAxisX = XYAxisParameter.pitch;
  XYAxisParameter _xyAxisY = XYAxisParameter.filterCutoff;

  // Pitch configuration (X-axis when pitch is assigned)
  int _pitchRangeStart = 48;  // C3 (MIDI note)
  int _pitchRangeEnd = 72;    // C5 (MIDI note)
  String _pitchScale = 'chromatic'; // chromatic, major, minor, pentatonic, blues
  int _pitchRootNote = 0;     // C (0-11 for C-B)

  // Parameter ranges (Y-axis assignments)
  final Map<XYAxisParameter, ParameterRange> _parameterRanges = {
    XYAxisParameter.pitch: const ParameterRange(min: 0, max: 127, unit: 'note'),
    XYAxisParameter.filterCutoff: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.resonance: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.fmDepth: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.ringModMix: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.morph: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.chaos: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.brightness: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.reverb: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.oscillatorMix: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.morphParameter: const ParameterRange(min: 0.0, max: 1.0, unit: '%'),
    XYAxisParameter.rotationSpeed: const ParameterRange(min: 0.1, max: 5.0, unit: 'x'),
  };

  // Visual feedback configuration
  bool _showTouchRipples = true;
  bool _showNoteGrid = false; // Grid overlay on XY pad
  double _touchRippleDuration = 0.8; // seconds

  // Top bezel visibility
  bool _topBezelVisible = true;
  bool _topBezelExpanded = false;

  // Performance metrics display
  bool _showFPS = true;
  bool _showGeometryInfo = true;

  // Tilt integration
  bool _tiltEnabled = false;
  String _tiltXMapping = 'orbHorizontal'; // What X-tilt controls
  String _tiltYMapping = 'orbVertical';   // What Y-tilt controls
  double _tiltSensitivity = 1.0;          // Multiplier

  UIStateProvider() {
    debugPrint('✅ UIStateProvider initialized');
  }

  // Getters
  Map<String, bool> get panelStates => _panelStates;
  Orientation get currentOrientation => _currentOrientation;
  DeviceType get deviceType => _deviceType;
  Offset get orbPosition => _orbPosition;
  bool get orbVisible => _orbVisible;
  double get orbPitchBendRange => _orbPitchBendRange;
  double get orbVibratoDepth => _orbVibratoDepth;
  bool get keyboardMode => _keyboardMode;
  KeyboardLayout get keyboardLayout => _keyboardLayout;
  int get keyboardOctaveStart => _keyboardOctaveStart;
  double get keySize => _keySize;
  bool get thumbPadsVisible => _thumbPadsVisible;
  String get leftPadParameter => _leftPadParameter;
  String get rightPadParameter => _rightPadParameter;
  XYAxisParameter get xyAxisX => _xyAxisX;
  XYAxisParameter get xyAxisY => _xyAxisY;
  int get pitchRangeStart => _pitchRangeStart;
  int get pitchRangeEnd => _pitchRangeEnd;
  String get pitchScale => _pitchScale;
  int get pitchRootNote => _pitchRootNote;
  bool get showTouchRipples => _showTouchRipples;
  bool get showNoteGrid => _showNoteGrid;
  double get touchRippleDuration => _touchRippleDuration;
  bool get topBezelVisible => _topBezelVisible;
  bool get topBezelExpanded => _topBezelExpanded;
  bool get showFPS => _showFPS;
  bool get showGeometryInfo => _showGeometryInfo;
  bool get tiltEnabled => _tiltEnabled;
  String get tiltXMapping => _tiltXMapping;
  String get tiltYMapping => _tiltYMapping;
  double get tiltSensitivity => _tiltSensitivity;

  /// Check if a specific panel is open
  bool isPanelOpen(String panelName) {
    return _panelStates[panelName] ?? false;
  }

  /// Check if any panel is open
  bool get anyPanelOpen {
    return _panelStates.values.any((isOpen) => isOpen);
  }

  /// Get parameter range for an axis parameter
  ParameterRange getParameterRange(XYAxisParameter param) {
    return _parameterRanges[param] ?? const ParameterRange(min: 0.0, max: 1.0);
  }

  /// Toggle panel open/closed
  void togglePanel(String panelName) {
    if (_panelStates.containsKey(panelName)) {
      _panelStates[panelName] = !_panelStates[panelName]!;
      notifyListeners();
      debugPrint('🎛️ Panel "$panelName" ${_panelStates[panelName]! ? "opened" : "closed"}');
    }
  }

  /// Close all panels
  void closeAllPanels() {
    bool anyChanged = false;
    _panelStates.forEach((key, value) {
      if (value) {
        _panelStates[key] = false;
        anyChanged = true;
      }
    });
    if (anyChanged) {
      notifyListeners();
      debugPrint('🎛️ All panels closed');
    }
  }

  /// Update orientation (called from LayoutBuilder)
  void updateOrientation(Orientation orientation) {
    if (_currentOrientation != orientation) {
      _currentOrientation = orientation;

      // Auto-hide thumb pads in landscape
      if (orientation == Orientation.landscape) {
        _thumbPadsVisible = false;
      } else {
        _thumbPadsVisible = true;
      }

      notifyListeners();
      debugPrint('📐 Orientation changed to: ${orientation.name}');
    }
  }

  /// Update device type (called on init based on screen size)
  void updateDeviceType(DeviceType type) {
    if (_deviceType != type) {
      _deviceType = type;
      notifyListeners();
      debugPrint('📱 Device type: ${type.name}');
    }
  }

  /// Set orb controller position
  void setOrbPosition(Offset position) {
    _orbPosition = position;
    notifyListeners();
  }

  /// Toggle orb controller visibility
  void toggleOrbVisibility() {
    _orbVisible = !_orbVisible;
    notifyListeners();
    debugPrint('🎯 Orb controller ${_orbVisible ? "shown" : "hidden"}');
  }

  /// Set orb pitch bend range (semitones)
  void setOrbPitchBendRange(double range) {
    _orbPitchBendRange = range.clamp(1.0, 12.0);
    notifyListeners();
  }

  /// Set orb vibrato depth (semitones)
  void setOrbVibratoDepth(double depth) {
    _orbVibratoDepth = depth.clamp(0.1, 2.0);
    notifyListeners();
  }

  /// Toggle keyboard mode
  void toggleKeyboardMode() {
    _keyboardMode = !_keyboardMode;
    notifyListeners();
    debugPrint('🎹 Keyboard mode ${_keyboardMode ? "enabled" : "disabled"}');
  }

  /// Set keyboard layout
  void setKeyboardLayout(KeyboardLayout layout) {
    _keyboardLayout = layout;
    notifyListeners();
    debugPrint('🎹 Keyboard layout: ${layout.name}');
  }

  /// Set keyboard octave start
  void setKeyboardOctaveStart(int octave) {
    _keyboardOctaveStart = octave.clamp(0, 8);
    notifyListeners();
  }

  /// Set keyboard key size
  void setKeySize(double size) {
    _keySize = size.clamp(0.5, 2.0);
    notifyListeners();
  }

  /// Toggle thumb pads visibility
  void toggleThumbPads() {
    _thumbPadsVisible = !_thumbPadsVisible;
    notifyListeners();
    debugPrint('👍 Thumb pads ${_thumbPadsVisible ? "visible" : "hidden"}');
  }

  /// Set right thumb pad parameter (left is always octave)
  void setRightPadParameter(String parameter) {
    _rightPadParameter = parameter;
    notifyListeners();
    debugPrint('👍 Right pad parameter: $parameter');
  }

  /// Set XY axis X parameter
  void setXYAxisX(XYAxisParameter parameter) {
    _xyAxisX = parameter;
    notifyListeners();
    debugPrint('📍 XY pad X-axis: ${parameter.name}');
  }

  /// Set XY axis Y parameter
  void setXYAxisY(XYAxisParameter parameter) {
    _xyAxisY = parameter;
    notifyListeners();
    debugPrint('📍 XY pad Y-axis: ${parameter.name}');
  }

  /// Set pitch range (MIDI notes)
  void setPitchRange(int start, int end) {
    _pitchRangeStart = start.clamp(0, 127);
    _pitchRangeEnd = end.clamp(0, 127);
    if (_pitchRangeStart >= _pitchRangeEnd) {
      _pitchRangeEnd = _pitchRangeStart + 12; // Minimum 1 octave
    }
    notifyListeners();
    debugPrint('🎵 Pitch range: $_pitchRangeStart - $_pitchRangeEnd');
  }

  /// Set pitch scale
  void setPitchScale(String scale) {
    _pitchScale = scale;
    notifyListeners();
    debugPrint('🎵 Pitch scale: $scale');
  }

  /// Set pitch root note (0-11 for C-B)
  void setPitchRootNote(int rootNote) {
    _pitchRootNote = rootNote.clamp(0, 11);
    notifyListeners();
    debugPrint('🎵 Pitch root note: $_pitchRootNote');
  }

  /// Toggle touch ripples
  void toggleTouchRipples() {
    _showTouchRipples = !_showTouchRipples;
    notifyListeners();
  }

  /// Toggle note grid overlay
  void toggleNoteGrid() {
    _showNoteGrid = !_showNoteGrid;
    notifyListeners();
  }

  /// Toggle top bezel visibility
  void toggleTopBezel() {
    _topBezelVisible = !_topBezelVisible;
    notifyListeners();
  }

  /// Toggle top bezel expanded state
  void toggleTopBezelExpanded() {
    _topBezelExpanded = !_topBezelExpanded;
    notifyListeners();
  }

  /// Toggle FPS display
  void toggleFPS() {
    _showFPS = !_showFPS;
    notifyListeners();
  }

  /// Toggle geometry info display
  void toggleGeometryInfo() {
    _showGeometryInfo = !_showGeometryInfo;
    notifyListeners();
  }

  /// Toggle tilt control
  void toggleTilt() {
    _tiltEnabled = !_tiltEnabled;
    notifyListeners();
    debugPrint('📱 Tilt control ${_tiltEnabled ? "enabled" : "disabled"}');
  }

  /// Set tilt X-axis mapping
  void setTiltXMapping(String mapping) {
    _tiltXMapping = mapping;
    notifyListeners();
  }

  /// Set tilt Y-axis mapping
  void setTiltYMapping(String mapping) {
    _tiltYMapping = mapping;
    notifyListeners();
  }

  /// Set tilt sensitivity
  void setTiltSensitivity(double sensitivity) {
    _tiltSensitivity = sensitivity.clamp(0.1, 3.0);
    notifyListeners();
  }

  /// Convert XY pad position to MIDI note (respects scale/key)
  int xyPositionToMidiNote(double normalizedX) {
    final range = _pitchRangeEnd - _pitchRangeStart;
    final rawNote = _pitchRangeStart + (normalizedX * range).round();

    // Apply scale quantization if not chromatic
    if (_pitchScale != 'chromatic') {
      return _quantizeToScale(rawNote);
    }

    return rawNote.clamp(0, 127);
  }

  /// Quantize MIDI note to current scale
  int _quantizeToScale(int midiNote) {
    final noteInOctave = (midiNote - _pitchRootNote) % 12;
    final octave = (midiNote - _pitchRootNote) ~/ 12;

    // Scale intervals (semitones from root)
    final scales = {
      'major': [0, 2, 4, 5, 7, 9, 11],
      'minor': [0, 2, 3, 5, 7, 8, 10],
      'pentatonic': [0, 2, 4, 7, 9],
      'blues': [0, 3, 5, 6, 7, 10],
      'chromatic': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    };

    final scaleIntervals = scales[_pitchScale] ?? scales['chromatic']!;

    // Find closest note in scale
    int closestInterval = scaleIntervals[0];
    int minDistance = (noteInOctave - closestInterval).abs();

    for (final interval in scaleIntervals) {
      final distance = (noteInOctave - interval).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestInterval = interval;
      }
    }

    return _pitchRootNote + (octave * 12) + closestInterval;
  }

  // Additional methods for UI component compatibility

  /// Check if panel is expanded (alias for isPanelOpen)
  bool isPanelExpanded(String panelId) => isPanelOpen(panelId);

  /// Expand a specific panel
  void expandPanel(String panelId) {
    if (_panelStates.containsKey(panelId)) {
      _panelStates[panelId] = true;
      notifyListeners();
      debugPrint('🎛️ Panel "$panelId" expanded');
    }
  }

  /// Collapse a specific panel
  void collapsePanel(String panelId) {
    if (_panelStates.containsKey(panelId)) {
      _panelStates[panelId] = false;
      notifyListeners();
      debugPrint('🎛️ Panel "$panelId" collapsed');
    }
  }

  /// Collapse all panels (alias for closeAllPanels)
  void collapseAllPanels() => closeAllPanels();

  /// Check if any panel is expanded (alias for anyPanelOpen)
  bool isAnyPanelExpanded() => anyPanelOpen;

  /// Set orb controller active state (for drag tracking)
  bool _orbControllerActive = false;
  bool get orbControllerActive => _orbControllerActive;

  void setOrbControllerActive(bool active) {
    _orbControllerActive = active;
    notifyListeners();
  }

  /// Set orb controller position (alias for setOrbPosition)
  void setOrbControllerPosition(Offset position) => setOrbPosition(position);

  /// Get orb controller position (alias for orbPosition)
  Offset get orbControllerPosition => orbPosition;

  /// XY pad show grid (alias for showNoteGrid)
  bool get xyPadShowGrid => showNoteGrid;

  /// Set XY pad show grid
  void setXYPadShowGrid(bool value) {
    _showNoteGrid = value;
    notifyListeners();
  }

  /// Orb controller visible (alias for orbVisible)
  bool get orbControllerVisible => orbVisible;

  /// Set orb controller visible
  void setOrbControllerVisible(bool value) {
    _orbVisible = value;
    notifyListeners();
    debugPrint('🎯 Orb controller ${_orbVisible ? "shown" : "hidden"}');
  }

  /// Get current system colors (placeholder - will be populated from VisualProvider)
  dynamic get currentSystemColors {
    // This will be injected from SynthTheme based on current visual system
    // For now, return null and let UI components handle it
    return null;
  }

  /// Set pitch range start
  void setPitchRangeStart(int value) {
    _pitchRangeStart = value.clamp(0, 127);
    if (_pitchRangeStart >= _pitchRangeEnd) {
      _pitchRangeEnd = _pitchRangeStart + 12;
    }
    notifyListeners();
    debugPrint('🎵 Pitch range start: $_pitchRangeStart');
  }

  /// Set pitch range end
  void setPitchRangeEnd(int value) {
    _pitchRangeEnd = value.clamp(0, 127);
    if (_pitchRangeEnd <= _pitchRangeStart) {
      _pitchRangeStart = _pitchRangeEnd - 12;
    }
    notifyListeners();
    debugPrint('🎵 Pitch range end: $_pitchRangeEnd');
  }

  /// Set tilt enabled
  void setTiltEnabled(bool enabled) {
    _tiltEnabled = enabled;
    notifyListeners();
    debugPrint('📱 Tilt control ${_tiltEnabled ? "enabled" : "disabled"}');
  }

  /// Get UI configuration as JSON (for saving presets)
  Map<String, dynamic> toJson() {
    return {
      'orbPitchBendRange': _orbPitchBendRange,
      'orbVibratoDepth': _orbVibratoDepth,
      'keyboardLayout': _keyboardLayout.name,
      'keyboardOctaveStart': _keyboardOctaveStart,
      'keySize': _keySize,
      'xyAxisX': _xyAxisX.name,
      'xyAxisY': _xyAxisY.name,
      'pitchRangeStart': _pitchRangeStart,
      'pitchRangeEnd': _pitchRangeEnd,
      'pitchScale': _pitchScale,
      'pitchRootNote': _pitchRootNote,
      'tiltEnabled': _tiltEnabled,
      'tiltXMapping': _tiltXMapping,
      'tiltYMapping': _tiltYMapping,
      'tiltSensitivity': _tiltSensitivity,
    };
  }

  /// Load UI configuration from JSON
  void fromJson(Map<String, dynamic> json) {
    _orbPitchBendRange = json['orbPitchBendRange'] ?? 2.0;
    _orbVibratoDepth = json['orbVibratoDepth'] ?? 1.0;
    _keyboardOctaveStart = json['keyboardOctaveStart'] ?? 3;
    _keySize = json['keySize'] ?? 1.0;
    _pitchRangeStart = json['pitchRangeStart'] ?? 48;
    _pitchRangeEnd = json['pitchRangeEnd'] ?? 72;
    _pitchScale = json['pitchScale'] ?? 'chromatic';
    _pitchRootNote = json['pitchRootNote'] ?? 0;
    _tiltEnabled = json['tiltEnabled'] ?? false;
    _tiltXMapping = json['tiltXMapping'] ?? 'orbHorizontal';
    _tiltYMapping = json['tiltYMapping'] ?? 'orbVertical';
    _tiltSensitivity = json['tiltSensitivity'] ?? 1.0;

    // Parse enum values
    if (json['keyboardLayout'] != null) {
      try {
        _keyboardLayout = KeyboardLayout.values.firstWhere(
          (e) => e.name == json['keyboardLayout'],
          orElse: () => KeyboardLayout.scrolling,
        );
      } catch (e) {
        _keyboardLayout = KeyboardLayout.scrolling;
      }
    }

    if (json['xyAxisX'] != null) {
      try {
        _xyAxisX = XYAxisParameter.values.firstWhere(
          (e) => e.name == json['xyAxisX'],
          orElse: () => XYAxisParameter.pitch,
        );
      } catch (e) {
        _xyAxisX = XYAxisParameter.pitch;
      }
    }

    if (json['xyAxisY'] != null) {
      try {
        _xyAxisY = XYAxisParameter.values.firstWhere(
          (e) => e.name == json['xyAxisY'],
          orElse: () => XYAxisParameter.filterCutoff,
        );
      } catch (e) {
        _xyAxisY = XYAxisParameter.filterCutoff;
      }
    }

    notifyListeners();
    debugPrint('✅ UI configuration loaded from JSON');
  }
}
