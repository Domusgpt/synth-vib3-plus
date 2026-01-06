/**
 * Visual Provider
 *
 * Manages the VIB34D visualization system state, providing
 * parameter control and state queries for the visual system.
 *
 * Responsibilities:
 * - VIB34D system state (Quantum, Holographic, Faceted)
 * - 4D rotation angles (XW, YW, ZW planes)
 * - Visual parameters (tessellation, brightness, hue, glow, etc.)
 * - Geometry state (vertex count, morph parameter, complexity)
 * - Projection parameters (distance, layer depth)
 * - WebView bridge to JavaScript systems
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../ui/theme/synth_theme.dart';
import '../vib3/core/vib3_engine.dart' show VisualSystem;

class VisualProvider with ChangeNotifier {
  // Current VIB34D system - using shared enum for type safety
  VisualSystem _currentSystemEnum = VisualSystem.faceted;

  // Full 6D Rotation angles (radians, 0-2π)
  // 3D-like rotations (map to oscillator detuning per CLAUDE.md)
  double _rotationXY = 0.0;  // → Oscillator 1 detune (±12 cents)
  double _rotationXZ = 0.0;  // → Oscillator 2 detune (±12 cents)
  double _rotationYZ = 0.0;  // → Combined detuning (±7 cents)

  // 4D rotations (into 4th dimension)
  double _rotationXW = 0.0;  // → FM depth (Hypersphere) / filter mod
  double _rotationYW = 0.0;  // → Ring mod depth (Hypertetrahedron)
  double _rotationZW = 0.0;  // → Filter cutoff modulation (±40%)

  // Rotation velocity (for advanced modulation)
  double _rotationVelocityXW = 0.0;
  double _rotationVelocityYW = 0.0;
  double _rotationVelocityZW = 0.0;

  // Visual parameters - BASE values (set by user/UI)
  double _baseRotationSpeed = 1.0;       // Base rotation speed multiplier
  double _baseTessellationDensity = 8.0;   // Grid density (2-30)
  double _baseVertexBrightness = 0.8;    // Vertex intensity (0-1)
  double _baseHueShift = 180.0;          // Color hue offset (0-360°)
  double _baseGlowIntensity = 1.0;       // Bloom/glow amount (0-3)
  double _baseRgbSplitAmount = 0.0;      // Chromatic aberration (0-10)
  double _baseSaturation = 0.7;          // Color saturation (0-1)

  // Audio modulation OFFSETS (set by audio reactivity, added to base)
  double _modRotationSpeed = 0.0;
  double _modTessellationDensity = 0.0;
  double _modVertexBrightness = 0.0;
  double _modHueShift = 0.0;
  double _modGlowIntensity = 0.0;
  double _modRgbSplitAmount = 0.0;
  double _modSaturation = 0.0;

  // Geometry state
  int _activeVertexCount = 120;      // Current vertex count
  double _morphParameter = 0.0;       // Geometry morph (0-1)
  int _currentGeometry = 0;           // Geometry index (0-7)
  double _geometryComplexity = 0.5;   // Complexity measure (0-1)

  // Projection parameters
  double _projectionDistance = 8.0;   // Camera distance (5-15)
  double _layerSeparation = 2.0;      // Holographic layer depth (0-5)

  // WebView controller (for JavaScript bridge)
  WebViewController? _webViewController;

  // Animation state
  bool _isAnimating = false;
  DateTime _lastUpdateTime = DateTime.now();
  double _currentFPS = 60.0; // Track actual FPS

  // CRITICAL: Batched parameter updates to prevent WebView overload
  final Map<String, dynamic> _pendingJSUpdates = {};
  Timer? _jsUpdateTimer;
  bool _jsUpdateScheduled = false;
  static const _jsUpdateInterval = Duration(milliseconds: 50); // 20 Hz max to JS

  VisualProvider() {
    debugPrint('✅ VisualProvider initialized');
  }

  // Getters
  VisualSystem get currentSystemEnum => _currentSystemEnum;
  String get currentSystem => _currentSystemEnum.name;  // For backward compat
  String get currentSystemName => _currentSystemEnum.name;

  // 6D Rotation getters
  double get rotationXY => _rotationXY;
  double get rotationXZ => _rotationXZ;
  double get rotationYZ => _rotationYZ;
  double get rotationXW => _rotationXW;
  double get rotationYW => _rotationYW;
  double get rotationZW => _rotationZW;
  // Getters return BASE + MODULATION (audio reactivity is additive)
  double get rotationSpeed => (_baseRotationSpeed + _modRotationSpeed).clamp(0.1, 5.0);
  double get tessellationDensity => (_baseTessellationDensity + _modTessellationDensity).clamp(2.0, 30.0);
  double get vertexBrightness => (_baseVertexBrightness + _modVertexBrightness).clamp(0.0, 1.0);
  double get hueShift => (_baseHueShift + _modHueShift) % 360.0;
  double get glowIntensity => (_baseGlowIntensity + _modGlowIntensity).clamp(0.0, 3.0);
  double get rgbSplitAmount => (_baseRgbSplitAmount + _modRgbSplitAmount).clamp(0.0, 10.0);
  double get saturation => (_baseSaturation + _modSaturation).clamp(0.0, 1.0);
  // Chaos is derived from rgbSplitAmount (0-10 → 0-1)
  double get chaosAmount => (rgbSplitAmount / 10.0).clamp(0.0, 1.0);

  // Base value getters (for UI display)
  double get baseRotationSpeed => _baseRotationSpeed;
  double get baseTessellationDensity => _baseTessellationDensity;
  double get baseVertexBrightness => _baseVertexBrightness;
  double get baseHueShift => _baseHueShift;
  double get baseGlowIntensity => _baseGlowIntensity;
  double get baseRgbSplitAmount => _baseRgbSplitAmount;
  double get baseSaturation => _baseSaturation;
  int get activeVertexCount => _activeVertexCount;
  double get morphParameter => _morphParameter;
  int get currentGeometry => _currentGeometry;
  int get geometryIndex => _currentGeometry; // Alias for VIB3+ API
  double get projectionDistance => _projectionDistance;
  double get layerSeparation => _layerSeparation;
  bool get isAnimating => _isAnimating;

  /// Initialize WebView controller for VIB34D systems
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
    debugPrint('✅ WebView controller attached to VisualProvider');
  }

  /// Switch between VIB34D systems (accepts enum or string)
  Future<void> switchSystem(dynamic system) async {
    VisualSystem newSystem;
    if (system is VisualSystem) {
      newSystem = system;
    } else if (system is String) {
      newSystem = switch (system.toLowerCase()) {
        'quantum' => VisualSystem.quantum,
        'holographic' => VisualSystem.holographic,
        _ => VisualSystem.faceted,
      };
    } else {
      return;
    }

    if (_currentSystemEnum == newSystem) return;

    debugPrint('🔄 Switching from ${_currentSystemEnum.name} to ${newSystem.name}...');
    _currentSystemEnum = newSystem;
    final systemName = newSystem.name;

    // Update JavaScript system via WebView with proper canvas management
    // VIB3+ uses window.switchSystem(), but we need to ensure canvas is properly reset
    if (_webViewController != null) {
      try {
        // First, check if switchSystem exists and call it
        final result = await _webViewController!.runJavaScriptReturningResult(
          '''
          (function() {
            try {
              if (typeof window.switchSystem === 'function') {
                console.log('🔄 Calling switchSystem("$systemName")');
                window.switchSystem("$systemName");
                return 'SUCCESS: System switched to $systemName';
              } else if (typeof window.vib3plus !== 'undefined' && typeof window.vib3plus.switchSystem === 'function') {
                console.log('🔄 Calling vib3plus.switchSystem("$systemName")');
                window.vib3plus.switchSystem("$systemName");
                return 'SUCCESS: System switched to $systemName via vib3plus';
              } else {
                console.error('❌ switchSystem function not found!');
                console.log('Available window properties:', Object.keys(window).filter(k => k.includes('switch') || k.includes('vib') || k.includes('system')));
                return 'ERROR: switchSystem function not available';
              }
            } catch (e) {
              console.error('❌ Error in switchSystem:', e);
              return 'ERROR: ' + e.message;
            }
          })();
          '''
        );
        debugPrint('📱 JavaScript result: $result');
      } catch (e) {
        debugPrint('❌ Error switching system in JavaScript: $e');
      }
    } else {
      debugPrint('⚠️  WebView controller not initialized yet');
    }

    // Update vertex count based on system
    switch (systemName) {
      case 'quantum':
        _activeVertexCount = 120; // Tesseract has 120 cells
        _geometryComplexity = 0.8;
        break;
      case 'holographic':
        _activeVertexCount = 500; // 5 layers × 100 vertices
        _geometryComplexity = 0.9;
        break;
      case 'faceted':
        _activeVertexCount = 50; // Simpler geometry
        _geometryComplexity = 0.3;
        break;
    }

    notifyListeners();
  }

  /// Set rotation speed BASE value (from UI)
  /// VIB3+ parameter: 'speed'
  void setRotationSpeed(double speed) {
    _baseRotationSpeed = speed.clamp(0.1, 5.0);

    // Update JavaScript with combined value
    _updateJavaScriptParameter('speed', rotationSpeed);

    notifyListeners();
  }

  /// Set rotation speed MODULATION (from audio reactivity)
  void setRotationSpeedModulation(double offset) {
    _modRotationSpeed = offset;
    _updateJavaScriptParameter('speed', rotationSpeed);
    // Don't notify - audio reactivity updates at 60 FPS
  }

  /// Set tessellation/grid density BASE value (from UI)
  /// VIB3+ parameter: 'gridDensity' - Range: 2-30
  void setTessellationDensity(double density) {
    _baseTessellationDensity = density.clamp(2.0, 30.0);

    // Update JavaScript with combined value
    _updateJavaScriptParameter('gridDensity', tessellationDensity);

    notifyListeners();
  }

  /// Set tessellation MODULATION (from audio reactivity)
  void setTessellationDensityModulation(double offset) {
    _modTessellationDensity = offset;
    _updateJavaScriptParameter('gridDensity', tessellationDensity);
  }

  /// Set vertex brightness BASE value (from UI)
  /// VIB3+ parameter: 'intensity'
  void setVertexBrightness(double brightness) {
    _baseVertexBrightness = brightness.clamp(0.0, 1.0);

    // Update JavaScript with combined value
    _updateJavaScriptParameter('intensity', vertexBrightness);

    notifyListeners();
  }

  /// Set vertex brightness MODULATION (from audio reactivity)
  void setVertexBrightnessModulation(double offset) {
    _modVertexBrightness = offset;
    _updateJavaScriptParameter('intensity', vertexBrightness);
  }

  /// Set hue shift BASE value (from UI)
  /// VIB3+ parameter: 'hue' (0-360)
  void setHueShift(double hue) {
    _baseHueShift = hue % 360.0;

    // Update JavaScript with combined value
    _updateJavaScriptParameter('hue', hueShift);

    notifyListeners();
  }

  /// Set hue shift MODULATION (from audio reactivity)
  void setHueShiftModulation(double offset) {
    _modHueShift = offset;
    _updateJavaScriptParameter('hue', hueShift);
  }

  /// Set glow intensity BASE value (from UI)
  /// VIB3+ parameter: 'saturation' (closest match for glow effect)
  void setGlowIntensity(double intensity) {
    _baseGlowIntensity = intensity.clamp(0.0, 3.0);

    // Update JavaScript - map to saturation for visual effect
    final saturationValue = (glowIntensity / 3.0).clamp(0.0, 1.0);
    _updateJavaScriptParameter('saturation', saturationValue);

    notifyListeners();
  }

  /// Set glow intensity MODULATION (from audio reactivity)
  void setGlowIntensityModulation(double offset) {
    _modGlowIntensity = offset;
    final saturationValue = (glowIntensity / 3.0).clamp(0.0, 1.0);
    _updateJavaScriptParameter('saturation', saturationValue);
  }

  /// Set RGB split amount BASE value (from UI)
  /// VIB3+ parameter: 'chaos' (closest match for distortion effects)
  void setRGBSplitAmount(double amount) {
    _baseRgbSplitAmount = amount.clamp(0.0, 10.0);

    // Update JavaScript - map to chaos for visual distortion effect
    final chaosValue = (rgbSplitAmount / 10.0).clamp(0.0, 1.0);
    _updateJavaScriptParameter('chaos', chaosValue);

    notifyListeners();
  }

  /// Set RGB split MODULATION (from audio reactivity)
  void setRGBSplitAmountModulation(double offset) {
    _modRgbSplitAmount = offset;
    final chaosValue = (rgbSplitAmount / 10.0).clamp(0.0, 1.0);
    _updateJavaScriptParameter('chaos', chaosValue);
  }

  /// Set saturation BASE value (from UI)
  /// VIB3+ parameter: 'saturation'
  void setSaturation(double sat) {
    _baseSaturation = sat.clamp(0.0, 1.0);
    _updateJavaScriptParameter('saturation', saturation);
    notifyListeners();
  }

  /// Set saturation MODULATION (from audio reactivity)
  void setSaturationModulation(double offset) {
    _modSaturation = offset;
    _updateJavaScriptParameter('saturation', saturation);
  }

  /// Update rotation angles (internal animation or external control)
  void updateRotations(double deltaTime) {
    final dt = deltaTime * rotationSpeed;  // Use getter (base + modulation)

    // Store old values for velocity calculation
    final oldXW = _rotationXW;
    final oldYW = _rotationYW;
    final oldZW = _rotationZW;

    // Update angles
    _rotationXW = (_rotationXW + dt * 0.5) % (2.0 * math.pi);
    _rotationYW = (_rotationYW + dt * 0.7) % (2.0 * math.pi);
    _rotationZW = (_rotationZW + dt * 0.3) % (2.0 * math.pi);

    // Calculate velocity from the actual change
    _rotationVelocityXW = (_rotationXW - oldXW) / deltaTime;
    _rotationVelocityYW = (_rotationYW - oldYW) / deltaTime;
    _rotationVelocityZW = (_rotationZW - oldZW) / deltaTime;

    // Update JavaScript
    _updateJavaScriptParameter('rot4dXW', _rotationXW);
    _updateJavaScriptParameter('rot4dYW', _rotationYW);
    _updateJavaScriptParameter('rot4dZW', _rotationZW);

    notifyListeners();
  }

  /// Get rotation angle for specific plane (for visual→audio modulation)
  double getRotationAngle(String plane) {
    switch (plane.toUpperCase()) {
      case 'XY':
        return _rotationXY;
      case 'XZ':
        return _rotationXZ;
      case 'YZ':
        return _rotationYZ;
      case 'XW':
        return _rotationXW;
      case 'YW':
        return _rotationYW;
      case 'ZW':
        return _rotationZW;
      default:
        return 0.0;
    }
  }

  /// Set rotation XY (affects oscillator 1 detune)
  void setRotationXY(double angle) {
    _rotationXY = angle % (2.0 * math.pi);
    notifyListeners();
  }

  /// Set rotation XZ (affects oscillator 2 detune)
  void setRotationXZ(double angle) {
    _rotationXZ = angle % (2.0 * math.pi);
    notifyListeners();
  }

  /// Set rotation YZ (affects combined detuning)
  void setRotationYZ(double angle) {
    _rotationYZ = angle % (2.0 * math.pi);
    notifyListeners();
  }

  /// Get rotation velocity (for advanced modulation)
  double getRotationVelocity() {
    return math.sqrt(
      _rotationVelocityXW * _rotationVelocityXW +
      _rotationVelocityYW * _rotationVelocityYW +
      _rotationVelocityZW * _rotationVelocityZW
    );
  }

  /// Get morph parameter (for wavetable modulation)
  double getMorphParameter() {
    return _morphParameter;
  }

  /// Set morph parameter
  /// VIB3+ parameter: 'morphFactor'
  void setMorphParameter(double morph) {
    _morphParameter = morph.clamp(0.0, 1.0);
    // VIB3+ uses 'morphFactor' not 'morphParameter'
    _updateJavaScriptParameter('morphFactor', _morphParameter);
    notifyListeners();
  }

  /// Get projection distance (for reverb modulation)
  double getProjectionDistance() {
    return _projectionDistance;
  }

  /// Set projection distance
  /// Note: VIB3+ doesn't have a direct equivalent, but we store it for internal use
  void setProjectionDistance(double distance) {
    _projectionDistance = distance.clamp(5.0, 15.0);
    // VIB3+ doesn't support projectionDistance directly - skip JS update
    notifyListeners();
  }

  /// Get layer separation (for delay modulation)
  double getLayerSeparation() {
    return _layerSeparation;
  }

  /// Set layer separation
  /// Note: VIB3+ doesn't have a direct equivalent, but we store it for internal use
  void setLayerSeparation(double separation) {
    _layerSeparation = separation.clamp(0.0, 5.0);
    // VIB3+ doesn't support layerSeparation directly - skip JS update
    notifyListeners();
  }

  /// Get active vertex count (for voice count modulation)
  int getActiveVertexCount() {
    return _activeVertexCount;
  }

  /// Get geometry complexity (for harmonic richness modulation)
  double getGeometryComplexity() {
    return _geometryComplexity;
  }

  /// Set current geometry (0-23: 3 synthesis branches × 8 base geometries)
  Future<void> setGeometry(int geometryIndex) async {
    _currentGeometry = geometryIndex.clamp(0, 23); // 24 geometries total

    // Use VIB3+ selectGeometry API
    if (_webViewController != null) {
      try {
        await _webViewController!.runJavaScript(
          'if (window.selectGeometry) { window.selectGeometry($geometryIndex); }'
        );
        debugPrint('✅ Geometry set to $geometryIndex (${_getGeometryLabel(geometryIndex)})');
      } catch (e) {
        debugPrint('❌ Error setting geometry: $e');
      }
    }

    // Update vertex count based on geometry
    _activeVertexCount = _getVertexCountForGeometry(_currentGeometry);

    notifyListeners();
  }

  /// Get human-readable geometry label for debugging
  String _getGeometryLabel(int index) {
    final coreIndex = index ~/ 8;
    final baseGeometry = index % 8;
    const baseNames = ['Tetrahedron', 'Hypercube', 'Sphere', 'Torus', 'Klein Bottle', 'Fractal', 'Wave', 'Crystal'];
    const coreNames = ['Base', 'Hypersphere', 'Hypertetrahedron'];
    return '${coreNames[coreIndex]} ${baseNames[baseGeometry]}';
  }

  /// Get vertex count for specific geometry
  int _getVertexCountForGeometry(int index) {
    // Approximate vertex counts for different 4D geometries
    const vertexCounts = [
      16,   // 0: Tesseract (hypercube)
      120,  // 1: 120-cell
      600,  // 2: 600-cell
      8,    // 3: 16-cell
      24,   // 4: 24-cell
      50,   // 5: Torus
      100,  // 6: Sphere
      32,   // 7: Klein bottle
    ];

    return index < vertexCounts.length ? vertexCounts[index] : 100;
  }

  /// Queue a JavaScript parameter update (batched to prevent WebView overload)
  /// VIB3+ uses window.updateParameter(name, value) API
  void _updateJavaScriptParameter(String name, dynamic value) {
    if (_webViewController == null) return;

    // Queue the update
    _pendingJSUpdates[name] = value;

    // Schedule a batched flush if not already scheduled
    if (!_jsUpdateScheduled) {
      _jsUpdateScheduled = true;
      _jsUpdateTimer?.cancel();
      _jsUpdateTimer = Timer(_jsUpdateInterval, _flushJSUpdates);
    }
  }

  /// Flush all pending JavaScript updates in a single call
  Future<void> _flushJSUpdates() async {
    _jsUpdateScheduled = false;

    if (_webViewController == null || _pendingJSUpdates.isEmpty) return;

    // Take a snapshot of pending updates and clear the queue
    final updates = Map<String, dynamic>.from(_pendingJSUpdates);
    _pendingJSUpdates.clear();

    try {
      // Build a single JavaScript call that updates all parameters
      final jsStatements = updates.entries.map((e) {
        final value = e.value is String ? '"${e.value}"' : e.value;
        return 'if(window.updateParameter)window.updateParameter("${e.key}",$value);';
      }).join('');

      await _webViewController!.runJavaScript(jsStatements);
    } catch (e) {
      debugPrint('⚠️  Error flushing JS parameters: $e');
    }
  }

  /// Force immediate flush of all pending JS updates (use sparingly)
  Future<void> flushJSUpdatesNow() async {
    _jsUpdateTimer?.cancel();
    _jsUpdateScheduled = false;
    await _flushJSUpdates();
  }

  /// Start animation loop
  void startAnimation() {
    _isAnimating = true;
    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }

  /// Stop animation loop
  void stopAnimation() {
    _isAnimating = false;
    notifyListeners();
  }

  /// Get visual state for debugging/UI
  Map<String, dynamic> getVisualState() {
    return {
      'system': _currentSystemEnum.name,
      'rotationXY': _rotationXY,
      'rotationXZ': _rotationXZ,
      'rotationYZ': _rotationYZ,
      'rotationXW': _rotationXW,
      'rotationYW': _rotationYW,
      'rotationZW': _rotationZW,
      'rotationSpeed': rotationSpeed,  // Use getter (base + modulation)
      'tessellationDensity': tessellationDensity,
      'vertexBrightness': vertexBrightness,
      'hueShift': hueShift,
      'glowIntensity': glowIntensity,
      'rgbSplitAmount': rgbSplitAmount,
      'saturation': saturation,
      'activeVertexCount': _activeVertexCount,
      'morphParameter': _morphParameter,
      'projectionDistance': _projectionDistance,
      'layerSeparation': _layerSeparation,
      'isAnimating': _isAnimating,
    };
  }

  /// Reset all audio modulation offsets to zero
  /// Call this when audio playback stops
  void resetAudioModulation() {
    _modRotationSpeed = 0.0;
    _modTessellationDensity = 0.0;
    _modVertexBrightness = 0.0;
    _modHueShift = 0.0;
    _modGlowIntensity = 0.0;
    _modRgbSplitAmount = 0.0;
    _modSaturation = 0.0;
    notifyListeners();
  }

  // Additional methods for UI component compatibility

  /// Get system colors based on current system
  SystemColors get systemColors {
    return SystemColors.fromName(_currentSystemEnum.name);
  }

  /// Get current FPS
  double get currentFPS => _currentFPS;

  /// Update FPS (called from rendering loop)
  void updateFPS(double fps) {
    _currentFPS = fps;
    notifyListeners();
  }

  /// Set system (alias for switchSystem)
  Future<void> setSystem(String systemName) async {
    await switchSystem(systemName);
  }

  /// Set rotation XW
  void setRotationXW(double angle) {
    _rotationXW = angle % (2.0 * math.pi);
    _updateJavaScriptParameter('rot4dXW', _rotationXW);
    notifyListeners();
  }

  /// Set rotation YW
  void setRotationYW(double angle) {
    _rotationYW = angle % (2.0 * math.pi);
    _updateJavaScriptParameter('rot4dYW', _rotationYW);
    notifyListeners();
  }

  /// Set rotation ZW
  void setRotationZW(double angle) {
    _rotationZW = angle % (2.0 * math.pi);
    _updateJavaScriptParameter('rot4dZW', _rotationZW);
    notifyListeners();
  }

  @override
  void dispose() {
    _jsUpdateTimer?.cancel();
    stopAnimation();
    super.dispose();
  }
}
