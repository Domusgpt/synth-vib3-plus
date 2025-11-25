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

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../ui/theme/synth_theme.dart';

class VisualProvider with ChangeNotifier {
  // Current VIB34D system
  String _currentSystem = 'quantum'; // 'quantum', 'holographic', 'faceted'

  // 4D Rotation angles (radians, 0-2π)
  double _rotationXW = 0.0;
  double _rotationYW = 0.0;
  double _rotationZW = 0.0;

  // Rotation velocity (for advanced modulation)
  double _rotationVelocityXW = 0.0;
  double _rotationVelocityYW = 0.0;
  double _rotationVelocityZW = 0.0;

  // Visual parameters
  double _rotationSpeed = 1.0;       // Base rotation speed multiplier
  int _tessellationDensity = 5;      // Subdivision level (3-8)
  double _vertexBrightness = 0.8;    // Vertex intensity (0-1)
  double _hueShift = 180.0;          // Color hue offset (0-360°)
  double _glowIntensity = 1.0;       // Bloom/glow amount (0-3)
  double _rgbSplitAmount = 0.0;      // Chromatic aberration (0-10)

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

  VisualProvider() {
    debugPrint('✅ VisualProvider initialized');
  }

  // Getters
  String get currentSystem => _currentSystem;
  double get rotationXW => _rotationXW;
  double get rotationYW => _rotationYW;
  double get rotationZW => _rotationZW;
  double get rotationSpeed => _rotationSpeed;
  int get tessellationDensity => _tessellationDensity;
  double get vertexBrightness => _vertexBrightness;
  double get hueShift => _hueShift;
  double get glowIntensity => _glowIntensity;
  double get rgbSplitAmount => _rgbSplitAmount;
  int get activeVertexCount => _activeVertexCount;
  double get morphParameter => _morphParameter;
  int get currentGeometry => _currentGeometry;
  double get projectionDistance => _projectionDistance;
  double get layerSeparation => _layerSeparation;
  bool get isAnimating => _isAnimating;

  /// Initialize WebView controller for VIB34D systems
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
    debugPrint('✅ WebView controller attached to VisualProvider');
  }

  /// Switch between VIB34D systems
  Future<void> switchSystem(String systemName) async {
    if (_currentSystem == systemName) return;

    debugPrint('🔄 Switching from $_currentSystem to $systemName...');
    _currentSystem = systemName;

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

  /// Set rotation speed (from audio modulation)
  void setRotationSpeed(double speed) {
    _rotationSpeed = speed.clamp(0.1, 5.0);

    // Update JavaScript
    _updateJavaScriptParameter('rotationSpeed', _rotationSpeed);

    notifyListeners();
  }

  /// Set tessellation density (from audio modulation)
  void setTessellationDensity(int density) {
    _tessellationDensity = density.clamp(3, 10);

    // Update JavaScript
    _updateJavaScriptParameter('tessellationDensity', _tessellationDensity);

    notifyListeners();
  }

  /// Set vertex brightness (from audio modulation)
  void setVertexBrightness(double brightness) {
    _vertexBrightness = brightness.clamp(0.0, 1.0);

    // Update JavaScript
    _updateJavaScriptParameter('vertexBrightness', _vertexBrightness);

    notifyListeners();
  }

  /// Set hue shift (from audio modulation)
  void setHueShift(double hue) {
    _hueShift = hue % 360.0;

    // Update JavaScript
    _updateJavaScriptParameter('hueShift', _hueShift);

    notifyListeners();
  }

  /// Set glow intensity (from audio modulation)
  void setGlowIntensity(double intensity) {
    _glowIntensity = intensity.clamp(0.0, 3.0);

    // Update JavaScript
    _updateJavaScriptParameter('glowIntensity', _glowIntensity);

    notifyListeners();
  }

  /// Set RGB split amount (from audio modulation)
  void setRGBSplitAmount(double amount) {
    _rgbSplitAmount = amount.clamp(0.0, 10.0);

    // Update JavaScript
    _updateJavaScriptParameter('rgbSplitAmount', _rgbSplitAmount);

    notifyListeners();
  }

  /// Update rotation angles (internal animation or external control)
  void updateRotations(double deltaTime) {
    final dt = deltaTime * _rotationSpeed;

    // Calculate velocity
    _rotationVelocityXW = (_rotationXW - _rotationXW) / deltaTime;
    _rotationVelocityYW = (_rotationYW - _rotationYW) / deltaTime;
    _rotationVelocityZW = (_rotationZW - _rotationZW) / deltaTime;

    // Update angles
    _rotationXW = (_rotationXW + dt * 0.5) % (2.0 * math.pi);
    _rotationYW = (_rotationYW + dt * 0.7) % (2.0 * math.pi);
    _rotationZW = (_rotationZW + dt * 0.3) % (2.0 * math.pi);

    // Update JavaScript
    _updateJavaScriptParameter('rot4dXW', _rotationXW);
    _updateJavaScriptParameter('rot4dYW', _rotationYW);
    _updateJavaScriptParameter('rot4dZW', _rotationZW);

    notifyListeners();
  }

  /// Get rotation angle for specific plane (for visual→audio modulation)
  double getRotationAngle(String plane) {
    switch (plane.toUpperCase()) {
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
  void setMorphParameter(double morph) {
    _morphParameter = morph.clamp(0.0, 1.0);
    _updateJavaScriptParameter('morphParameter', _morphParameter);
    notifyListeners();
  }

  /// Get projection distance (for reverb modulation)
  double getProjectionDistance() {
    return _projectionDistance;
  }

  /// Set projection distance
  void setProjectionDistance(double distance) {
    _projectionDistance = distance.clamp(5.0, 15.0);
    _updateJavaScriptParameter('projectionDistance', _projectionDistance);
    notifyListeners();
  }

  /// Get layer separation (for delay modulation)
  double getLayerSeparation() {
    return _layerSeparation;
  }

  /// Set layer separation
  void setLayerSeparation(double separation) {
    _layerSeparation = separation.clamp(0.0, 5.0);
    _updateJavaScriptParameter('layerSeparation', _layerSeparation);
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

  /// Update JavaScript parameter via WebView
  /// VIB3+ uses window.updateParameter(name, value) API
  Future<void> _updateJavaScriptParameter(String name, dynamic value) async {
    if (_webViewController == null) return;

    try {
      await _webViewController!.runJavaScript(
        'if (window.updateParameter) { window.updateParameter("$name", $value); }'
      );
    } catch (e) {
      debugPrint('⚠️  Error updating JS parameter $name: $e');
    }
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
      'system': _currentSystem,
      'rotationXW': _rotationXW,
      'rotationYW': _rotationYW,
      'rotationZW': _rotationZW,
      'rotationSpeed': _rotationSpeed,
      'tessellationDensity': _tessellationDensity,
      'vertexBrightness': _vertexBrightness,
      'hueShift': _hueShift,
      'glowIntensity': _glowIntensity,
      'rgbSplitAmount': _rgbSplitAmount,
      'activeVertexCount': _activeVertexCount,
      'morphParameter': _morphParameter,
      'projectionDistance': _projectionDistance,
      'layerSeparation': _layerSeparation,
      'isAnimating': _isAnimating,
    };
  }

  // Additional methods for UI component compatibility

  /// Get system colors based on current system
  SystemColors get systemColors {
    return SystemColors.fromName(_currentSystem);
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
    stopAnimation();
    super.dispose();
  }
}
