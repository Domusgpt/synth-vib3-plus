/**
 * VIB34D Native Bridge
 *
 * Loads and controls the EXACT THREE JavaScript visualization systems:
 * - Quantum System (QuantumVisualizer.js)
 * - Holographic System (HolographicSystem.js)
 * - Faceted System (FacetedVisualizer.js)
 *
 * The JavaScript runs NATIVELY via WebView - we don't rewrite it!
 * We just pass parameters and get state back.
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VIB34DNativeBridge {
  late WebViewController _webViewController;

  // Current visualization system (quantum, holographic, or faceted)
  String _currentSystem = 'quantum';

  // Parameter state
  Map<String, dynamic> _parameters = {
    // Quantum/Holographic parameters
    'geometry': 0,
    'gridDensity': 15.0,
    'morphFactor': 1.0,
    'chaos': 0.2,
    'speed': 1.0,
    'hue': 200.0,
    'intensity': 0.5,
    'saturation': 0.8,
    'dimension': 3.5,

    // 4D Rotation parameters (controlled by audio)
    'rot4dXW': 0.0,
    'rot4dYW': 0.0,
    'rot4dZW': 0.0,

    // Audio reactivity data
    'audioReactive': {
      'bass': 0.0,
      'mid': 0.0,
      'high': 0.0,
      'energy': 0.0,
    },
  };

  /// Initialize the bridge and load the visualization HTML
  Future<void> initialize(WebViewController controller) async {
    _webViewController = controller;

    // Load the HTML wrapper that imports and runs the THREE systems
    final html = await _buildVisualizationHTML();
    await _webViewController.loadHtmlString(html);

    print('✅ VIB34D Native Bridge initialized with $_currentSystem system');
  }

  /// Build the HTML that loads and runs the THREE JavaScript systems
  Future<String> _buildVisualizationHTML() async {
    // Load the JavaScript files
    final quantumJS = await rootBundle.loadString('assets/QuantumVisualizer.js');
    final holographicJS = await rootBundle.loadString('assets/HolographicSystem.js');
    final facetedJS = await rootBundle.loadString('assets/FacetedVisualizer.js');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #000;
      overflow: hidden;
      width: 100vw;
      height: 100vh;
      font-family: 'Orbitron', monospace;
    }
    #visualizer-container {
      position: relative;
      width: 100%;
      height: 100%;
    }
    canvas {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <div id="visualizer-container">
    <!-- The THREE systems will create canvases here -->
    <canvas id="quantum-canvas"></canvas>
    <canvas id="holographic-canvas"></canvas>
    <canvas id="faceted-canvas"></canvas>
  </div>

  <script type="module">
    // === QUANTUM SYSTEM ===
    $quantumJS

    // === HOLOGRAPHIC SYSTEM ===
    $holographicJS

    // === FACETED SYSTEM ===
    $facetedJS

    // === FLUTTER BRIDGE ===
    let currentSystem = 'quantum';
    let quantumVisualizer = null;
    let holographicSystem = null;
    let facetedVisualizer = null;

    // Initialize default system (Quantum)
    window.addEventListener('load', () => {
      initializeQuantumSystem();
    });

    function initializeQuantumSystem() {
      quantumVisualizer = new QuantumHolographicVisualizer(
        'quantum-canvas',
        'content',
        0.9,
        0
      );
      startRenderLoop();
      console.log('✅ Quantum system initialized');
    }

    function initializeHolographicSystem() {
      holographicSystem = new HolographicSystem();
      console.log('✅ Holographic system initialized');
    }

    function initializeFacetedSystem() {
      facetedVisualizer = new IntegratedHolographicVisualizer(
        'faceted-canvas',
        'content',
        0.9,
        0
      );
      console.log('✅ Faceted system initialized');
    }

    // Switch between systems
    function switchSystem(systemName) {
      currentSystem = systemName;

      // Hide all canvases
      document.getElementById('quantum-canvas').style.display = 'none';
      document.getElementById('holographic-canvas').style.display = 'none';
      document.getElementById('faceted-canvas').style.display = 'none';

      // Show and initialize the selected system
      switch(systemName) {
        case 'quantum':
          document.getElementById('quantum-canvas').style.display = 'block';
          if (!quantumVisualizer) initializeQuantumSystem();
          break;
        case 'holographic':
          document.getElementById('holographic-canvas').style.display = 'block';
          if (!holographicSystem) initializeHolographicSystem();
          break;
        case 'faceted':
          document.getElementById('faceted-canvas').style.display = 'block';
          if (!facetedVisualizer) initializeFacetedSystem();
          break;
      }

      console.log(\`🔄 Switched to \${systemName} system\`);
    }

    // Update parameters from Flutter
    function updateParameters(params) {
      const p = typeof params === 'string' ? JSON.parse(params) : params;

      switch(currentSystem) {
        case 'quantum':
          if (quantumVisualizer) {
            quantumVisualizer.updateParameters({
              geometry: p.geometry || 0,
              gridDensity: p.gridDensity || 15,
              morphFactor: p.morphFactor || 1.0,
              chaos: p.chaos || 0.2,
              speed: p.speed || 1.0,
              hue: p.hue || 200,
              intensity: p.intensity || 0.5,
              saturation: p.saturation || 0.8,
              rot4dXW: p.rot4dXW || 0.0,
              rot4dYW: p.rot4dYW || 0.0,
              rot4dZW: p.rot4dZW || 0.0
            });
          }
          break;
        case 'holographic':
          if (holographicSystem) {
            holographicSystem.visualizers.forEach(viz => {
              viz.updateParameters(p);
            });
          }
          break;
        case 'faceted':
          if (facetedVisualizer) {
            facetedVisualizer.updateParameters(p);
          }
          break;
      }
    }

    // Update audio reactivity (THIS IS THE KEY!)
    function updateAudio(audioData) {
      const data = typeof audioData === 'string' ? JSON.parse(audioData) : audioData;

      // Set global audio reactivity for Quantum system
      window.audioEnabled = true;
      window.audioReactive = {
        bass: data.bass || 0.0,
        mid: data.mid || 0.0,
        high: data.high || 0.0,
        energy: data.energy || 0.0
      };

      // Quantum system uses window.audioReactive automatically!

      // For Holographic system
      if (currentSystem === 'holographic' && holographicSystem) {
        holographicSystem.audioData = window.audioReactive;
      }
    }

    // Render loop
    function startRenderLoop() {
      function render() {
        switch(currentSystem) {
          case 'quantum':
            if (quantumVisualizer) quantumVisualizer.render();
            break;
          case 'holographic':
            if (holographicSystem) {
              holographicSystem.visualizers.forEach(viz => viz.render());
            }
            break;
          case 'faceted':
            if (facetedVisualizer) facetedVisualizer.render();
            break;
        }

        requestAnimationFrame(render);
      }
      render();
    }

    // Expose functions to Flutter
    window.vib34d = {
      switchSystem,
      updateParameters,
      updateAudio,
      getCurrentSystem: () => currentSystem
    };

    console.log('✅ VIB34D Native Bridge ready');
  </script>
</body>
</html>
    ''';
  }

  /// Switch between the THREE systems
  Future<void> switchSystem(String systemName) async {
    if (!['quantum', 'holographic', 'faceted'].contains(systemName)) {
      print('❌ Invalid system name: $systemName');
      return;
    }

    _currentSystem = systemName;
    await _webViewController.runJavaScript('window.vib34d.switchSystem("$systemName")');
    print('🔄 Switched to $systemName system');
  }

  /// Update visual parameters
  Future<void> updateParameters(Map<String, dynamic> params) async {
    _parameters.addAll(params);
    final jsonParams = jsonEncode(_parameters);
    await _webViewController.runJavaScript('window.vib34d.updateParameters(\'$jsonParams\')');
  }

  /// Update audio reactivity data (THIS IS THE CORE!)
  Future<void> updateAudio({
    required double bass,
    required double mid,
    required double high,
    required double energy,
  }) async {
    final audioData = jsonEncode({
      'bass': bass,
      'mid': mid,
      'high': high,
      'energy': energy,
    });

    await _webViewController.runJavaScript('window.vib34d.updateAudio(\'$audioData\')');
  }

  /// Get current system name
  String get currentSystem => _currentSystem;

  /// Get current parameters
  Map<String, dynamic> get parameters => Map.from(_parameters);
}
