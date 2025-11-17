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
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum VisualizerLifecyclePhase {
  booting,
  waitingForViewer,
  syncingState,
  switching,
  ready,
  faulted,
}

class VisualProvider with ChangeNotifier {
  // Current VIB34D system
  String _currentSystem = 'quantum'; // 'quantum', 'holographic', 'faceted'
  String? _viewerActiveSystem;

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
  bool _visualizerReady = false;
  VisualizerLifecyclePhase _lifecyclePhase = VisualizerLifecyclePhase.booting;
  String? _lifecycleNote;
  String? _viewerLabel;
  String? _lastVisualizerError;
  Completer<void>? _pendingSwitchCompleter;
  Timer? _switchTimeoutTimer;
  final Duration _switchAcknowledgementTimeout = const Duration(seconds: 6);

  // Batched parameter transmission
  final Map<String, dynamic> _pendingParameterUpdates = {};
  Timer? _parameterFlushTimer;
  final Duration _parameterFlushInterval = const Duration(milliseconds: 16);

  // Audio reactive cache (forwarded to WebView when ready)
  Map<String, double>? _lastAudioReactive;

  // Animation state
  bool _isAnimating = false;
  DateTime _lastUpdateTime = DateTime.now();
  double _currentFPS = 60.0; // Track actual FPS

  VisualProvider() {
    debugPrint('✅ VisualProvider initialized');
  }

  void _setLifecyclePhase(VisualizerLifecyclePhase phase, {String? note}) {
    _lifecyclePhase = phase;
    _lifecycleNote = note;
  }

  VisualizerLifecyclePhase _phaseFromString(String? rawPhase) {
    switch (rawPhase) {
      case 'booting':
        return VisualizerLifecyclePhase.booting;
      case 'initializing':
      case 'switching':
        return VisualizerLifecyclePhase.switching;
      case 'tearing-down':
        return VisualizerLifecyclePhase.switching;
      case 'ready':
        return VisualizerLifecyclePhase.ready;
      case 'faulted':
        return VisualizerLifecyclePhase.faulted;
      default:
        return _lifecyclePhase;
    }
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
  VisualizerLifecyclePhase get lifecyclePhase => _lifecyclePhase;
  String? get lifecycleNote => _lifecycleNote;
  String? get viewerLabel => _viewerLabel;
  String? get lastVisualizerError => _lastVisualizerError;

  /// Initialize WebView controller for VIB34D systems
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
    _visualizerReady = false;
    _pendingParameterUpdates.clear();
    _parameterFlushTimer?.cancel();
    _parameterFlushTimer = null;
    _setLifecyclePhase(
      VisualizerLifecyclePhase.waitingForViewer,
      note: 'Awaiting viewer bootstrap',
    );
    debugPrint('✅ WebView controller attached to VisualProvider');
    notifyListeners();
  }

  /// Viewer handshake completion handler from WebView widget
  Future<void> handleViewerReady({String? reportedSystem}) async {
    if (_visualizerReady) return;
    _visualizerReady = true;
    _viewerActiveSystem = reportedSystem;
    _setLifecyclePhase(
      VisualizerLifecyclePhase.syncingState,
      note: 'Synchronizing VIB34D parameters',
    );
    debugPrint('🛰️  Visualizer reported ready – syncing state');
    await _flushFullStateToVisualizer();
    await switchSystem(_currentSystem);
    if (_lastAudioReactive != null) {
      await _sendAudioReactive(_lastAudioReactive!);
    }
    notifyListeners();
  }

  Future<void> handleViewerEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    switch (event) {
      case 'viewer-ready':
        _viewerLabel = payload['label'] as String? ?? _viewerLabel;
        await handleViewerReady(reportedSystem: payload['system'] as String?);
        return;
      case 'viewer-lifecycle':
        final lifecycle = payload['lifecycle'] as String?;
        final label = payload['label'] as String?;
        if (label != null) {
          _viewerLabel = label;
        }
        _setLifecyclePhase(
          _phaseFromString(lifecycle),
          note: payload['message'] as String? ?? _lifecycleNote,
        );
        break;
      case 'system-initializing':
        _setLifecyclePhase(
          VisualizerLifecyclePhase.switching,
          note: 'Initializing ${payload['system'] ?? 'visualizer'}',
        );
        break;
      case 'system-ready':
        _viewerLabel = payload['label'] as String? ?? _viewerLabel;
        _resolvePendingSwitch(payload['system'] as String?);
        _setLifecyclePhase(
          VisualizerLifecyclePhase.ready,
          note: 'Running ${payload['system'] ?? _currentSystem}',
        );
        break;
      case 'system-destroyed':
        _viewerActiveSystem = null;
        _setLifecyclePhase(
          VisualizerLifecyclePhase.switching,
          note: 'Visualizer stack cleared',
        );
        break;
      case 'system-error':
      case 'viewer-error':
        _lastVisualizerError = payload['message'] as String? ?? 'Visualizer error';
        _setLifecyclePhase(
          VisualizerLifecyclePhase.faulted,
          note: _lastVisualizerError,
        );
        _failPendingSwitch(_lastVisualizerError ?? 'Visualizer error');
        break;
    }

    notifyListeners();
  }

  /// Switch between VIB34D systems
  Future<void> switchSystem(String systemName, {bool force = false}) async {
    final bool alreadyViewerTarget = _viewerActiveSystem == systemName;
    _currentSystem = systemName;

    if (_webViewController != null && _visualizerReady) {
      if (!alreadyViewerTarget || force) {
        _setLifecyclePhase(
          VisualizerLifecyclePhase.switching,
          note: 'Switching to $systemName stack',
        );
        final encoded = jsonEncode(systemName);
        final script = force
            ? 'window.vib34d?.switchSystem($encoded, {force:true});'
            : 'window.vib34d?.switchSystem($encoded);';
        await _runJavaScript(script);
        await _awaitSystemReady(systemName);
      }
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

  /// Set current geometry
  void setGeometry(int geometryIndex) {
    _currentGeometry = geometryIndex.clamp(0, 7);
    _updateJavaScriptParameter('geometry', _currentGeometry);

    // Update vertex count based on geometry
    _activeVertexCount = _getVertexCountForGeometry(_currentGeometry);

    notifyListeners();
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

  /// Queue a parameter update to be sent to WebView in a single batch
  void _updateJavaScriptParameter(String name, dynamic value) {
    _pendingParameterUpdates[name] = value;
    _scheduleParameterFlush();
  }

  void _scheduleParameterFlush() {
    if (!_visualizerReady || _webViewController == null) return;
    _parameterFlushTimer ??= Timer(_parameterFlushInterval, () {
      _flushParameterBatch();
    });
  }

  Future<void> _flushParameterBatch() async {
    if (_pendingParameterUpdates.isEmpty || _webViewController == null) {
      _parameterFlushTimer?.cancel();
      _parameterFlushTimer = null;
      return;
    }

    final payload = jsonEncode(_pendingParameterUpdates);
    _pendingParameterUpdates.clear();
    _parameterFlushTimer?.cancel();
    _parameterFlushTimer = null;

    await _runJavaScript('window.vib34d?.updateParameters($payload);');
  }

  Future<void> _flushFullStateToVisualizer() async {
    if (_webViewController == null) return;
    final payload = jsonEncode({
      'rotationSpeed': _rotationSpeed,
      'tessellationDensity': _tessellationDensity,
      'vertexBrightness': _vertexBrightness,
      'hueShift': _hueShift,
      'glowIntensity': _glowIntensity,
      'rgbSplitAmount': _rgbSplitAmount,
      'rot4dXW': _rotationXW,
      'rot4dYW': _rotationYW,
      'rot4dZW': _rotationZW,
      'morphParameter': _morphParameter,
      'geometry': _currentGeometry,
      'projectionDistance': _projectionDistance,
      'layerSeparation': _layerSeparation,
    });

    await _runJavaScript('window.vib34d?.updateParameters($payload);');
  }

  Future<void> _runJavaScript(String script) async {
    if (_webViewController == null) return;
    try {
      await _webViewController!.runJavaScript(script);
    } catch (e) {
      debugPrint('⚠️  WebView JS error: $e');
    }
  }

  /// Forward real-time audio reactivity data to the visualizer
  void updateAudioReactive(Map<String, double> data) {
    _lastAudioReactive = Map<String, double>.from(data);
    if (!_visualizerReady || _webViewController == null) return;
    unawaited(_sendAudioReactive(_lastAudioReactive!));
  }

  Future<void> _sendAudioReactive(Map<String, double> data) async {
    final payload = jsonEncode(data);
    await _runJavaScript('window.vib34d?.updateAudio($payload);');
  }

  Future<void> _awaitSystemReady(String targetSystem) async {
    _pendingSwitchCompleter?.complete();
    final completer = Completer<void>();
    _pendingSwitchCompleter = completer;

    _switchTimeoutTimer?.cancel();
    _switchTimeoutTimer = Timer(_switchAcknowledgementTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Visualizer did not acknowledge $targetSystem in time'),
        );
        _setLifecyclePhase(
          VisualizerLifecyclePhase.faulted,
          note: 'Visualizer timed out while switching to $targetSystem',
        );
        notifyListeners();
      }
    });

    try {
      await completer.future;
    } finally {
      _switchTimeoutTimer?.cancel();
      _switchTimeoutTimer = null;
      _pendingSwitchCompleter = null;
    }
  }

  void _resolvePendingSwitch(String? reportedSystem) {
    if (reportedSystem != null) {
      _viewerActiveSystem = reportedSystem;
    }
    if (_pendingSwitchCompleter != null && !_pendingSwitchCompleter!.isCompleted) {
      _pendingSwitchCompleter!.complete();
    }
    _switchTimeoutTimer?.cancel();
    _switchTimeoutTimer = null;
  }

  void _failPendingSwitch(String message) {
    if (_pendingSwitchCompleter != null && !_pendingSwitchCompleter!.isCompleted) {
      _pendingSwitchCompleter!.completeError(StateError(message));
    }
    _switchTimeoutTimer?.cancel();
    _switchTimeoutTimer = null;
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

  /// Get system colors (placeholder - returns color scheme based on system)
  dynamic get systemColors {
    // This should return SystemColors from SynthTheme
    // For now, return null and let UI components handle it
    return null;
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

  /// Handle WebView unload/reset
  void markVisualizerNotReady() {
    _visualizerReady = false;
    _viewerActiveSystem = null;
    _lastVisualizerError = null;
    _pendingParameterUpdates.clear();
    _parameterFlushTimer?.cancel();
    _parameterFlushTimer = null;
    _setLifecyclePhase(
      VisualizerLifecyclePhase.waitingForViewer,
      note: 'Awaiting viewer reload',
    );
    debugPrint('🛑 Visualizer reset – awaiting readiness');
    notifyListeners();
  }

  @override
  void dispose() {
    stopAnimation();
    super.dispose();
  }
}
