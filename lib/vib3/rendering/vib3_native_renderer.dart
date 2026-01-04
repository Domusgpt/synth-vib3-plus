/**
 * VIB3+ Native Renderer
 *
 * Production-ready Flutter CustomPainter for VIB3+ visualization
 * Supports all 24 geometries across 3 systems (Quantum, Holographic, Faceted)
 *
 * Features:
 * - Full 6D rotation (XY, XZ, YZ, XW, YW, ZW)
 * - 4D→3D→2D projection pipeline
 * - Audio-reactive modulation
 * - Multi-layer holographic rendering
 * - Post-processing effects (glow, chromatic aberration)
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../math/rotation_4d.dart';
import '../geometry/polytope_generator.dart';
import '../geometry/geometry_library.dart';

/// Rendering configuration
class VIB3RenderConfig {
  final String system; // 'quantum', 'holographic', 'faceted'
  final int geometryIndex; // 0-23

  // Rotation angles (radians)
  final double rotationXY;
  final double rotationXZ;
  final double rotationYZ;
  final double rotationXW;
  final double rotationYW;
  final double rotationZW;

  // Visual parameters
  final double rotationSpeed;
  final int tessellationDensity;
  final double vertexBrightness;
  final double hueShift;
  final double glowIntensity;
  final double rgbSplitAmount;
  final double morphParameter;
  final double projectionDistance;
  final double layerSeparation;

  // Audio reactivity
  final double bassEnergy;
  final double midEnergy;
  final double highEnergy;
  final double rmsAmplitude;

  const VIB3RenderConfig({
    required this.system,
    required this.geometryIndex,
    this.rotationXY = 0.0,
    this.rotationXZ = 0.0,
    this.rotationYZ = 0.0,
    this.rotationXW = 0.0,
    this.rotationYW = 0.0,
    this.rotationZW = 0.0,
    this.rotationSpeed = 1.0,
    this.tessellationDensity = 5,
    this.vertexBrightness = 0.8,
    this.hueShift = 180.0,
    this.glowIntensity = 1.0,
    this.rgbSplitAmount = 0.0,
    this.morphParameter = 0.0,
    this.projectionDistance = 8.0,
    this.layerSeparation = 2.0,
    this.bassEnergy = 0.0,
    this.midEnergy = 0.0,
    this.highEnergy = 0.0,
    this.rmsAmplitude = 0.0,
  });
}

/// Main VIB3+ renderer
class VIB3NativeRenderer extends CustomPainter {
  final VIB3RenderConfig config;
  final double time;

  VIB3NativeRenderer({
    required this.config,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseRadius = math.min(size.width, size.height) * 0.35;

    // Clear background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _getBackgroundColor(),
    );

    // Render based on system type
    switch (config.system) {
      case 'quantum':
        _renderQuantumSystem(canvas, centerX, centerY, baseRadius);
        break;
      case 'holographic':
        _renderHolographicSystem(canvas, centerX, centerY, baseRadius);
        break;
      case 'faceted':
        _renderFacetedSystem(canvas, centerX, centerY, baseRadius);
        break;
      default:
        _renderQuantumSystem(canvas, centerX, centerY, baseRadius);
    }
  }

  /// Get background color based on system and audio
  Color _getBackgroundColor() {
    final baseDarkness = 0.05 + config.bassEnergy * 0.05;
    return HSLColor.fromAHSL(1.0, config.hueShift, 0.1, baseDarkness).toColor();
  }

  /// Render Quantum system - 5 canvas layers per VIB3-CORE QuantumEngine.js
  /// From QuantumEngine.js createVisualizers():
  /// - background: reactivity 0.4, deep purple/black/dark blue
  /// - shadow: reactivity 0.6, toxic greens/yellows (inverted geometry response)
  /// - content: reactivity 1.0, hot red/orange/white-hot
  /// - highlight: reactivity 1.3, electric cyan/blue (cubic peak response)
  /// - accent: reactivity 1.6, magenta/violet/hot pink (chaotic bursts)
  ///
  /// From QuantumVisualizer.js getLayerColorPalette():
  /// - Intensity modulation varies by layer (inverted for shadow, cubic for highlight, etc.)
  /// - RGB separation patterns differ: minimal→vertical→radial→lightning→chaotic
  void _renderQuantumSystem(Canvas canvas, double cx, double cy, double radius) {
    final metadata = GeometryLibrary.getGeometryMetadata(config.geometryIndex);
    final polytope = PolytopeGenerator.generateBase(metadata.baseIndex);

    // 5-layer Quantum system matching VIB3-CORE QuantumEngine.js & QuantumVisualizer.js
    final quantumLayers = [
      {
        'role': 'background',
        'reactivity': 0.4,                    // From QuantumEngine.js
        'hue': 270.0,                         // Deep purple/black/dark blue
        'sat': 0.6, 'light': 0.15,
        'baseIntensity': 0.3,                 // intensity 0.3 + geometry×0.4
        'geometryMod': 0.4,
        'alpha': 0.6,
        'split': 0.02,                        // Minimal separation, smooth
        'strokeWidth': 1.0,
      },
      {
        'role': 'shadow',
        'reactivity': 0.6,
        'hue': 90.0,                          // Toxic greens and yellows
        'sat': 0.85, 'light': 0.35,
        'baseIntensity': 0.1,                 // shadowIntensity×0.8 + 0.1 (inverted)
        'geometryMod': -0.8,                  // NEGATIVE = inverted geometry response
        'alpha': 0.4,
        'split': 0.08,                        // Heavy vertical separation
        'strokeWidth': 1.3,
      },
      {
        'role': 'content',
        'reactivity': 1.0,
        'hue': 15.0,                          // Hot red/orange/white-hot
        'sat': 0.9, 'light': 0.55,
        'baseIntensity': 0.2,                 // geometry×1.2 + 0.2
        'geometryMod': 1.2,
        'alpha': 1.0,
        'split': 0.15,                        // Explosive radial separation
        'strokeWidth': 2.0,
      },
      {
        'role': 'highlight',
        'reactivity': 1.3,
        'hue': 190.0,                         // Electric cyan and blue
        'sat': 0.9, 'light': 0.6,
        'baseIntensity': 0.1,                 // geometry³×1.5 + 0.1 (cubic peak)
        'geometryMod': 1.5,                   // Will apply cubic (³) in code
        'geometryCubic': true,                // Flag for cubic response
        'alpha': 0.8,
        'split': 0.25,                        // Lightning-like separation
        'strokeWidth': 2.5,
      },
      {
        'role': 'accent',
        'reactivity': 1.6,
        'hue': 300.0,                         // Magenta/violet/hot pink
        'sat': 0.85, 'light': 0.5,
        'baseIntensity': 0.05,                // randomBurst×geometry×2.0 + 0.05
        'geometryMod': 2.0,
        'randomBurst': true,                  // Flag for chaotic burst
        'alpha': 0.3,
        'split': 0.30,                        // Chaotic multi-directional
        'strokeWidth': 1.5,
      },
    ];

    // Render all 5 layers back to front
    for (int layer = 0; layer < 5; layer++) {
      final layerDef = quantumLayers[layer];
      final depth = layer / 4.0;
      final reactivity = layerDef['reactivity'] as double;

      // Each layer has different rotation offset for parallax depth
      final layerOffset = (layer - 2) * 0.12;
      final layerSpeed = 0.6 + reactivity * 0.4;

      final rotation = Rotation4D.apply6DRotation(
        xy: config.rotationXY * config.rotationSpeed * layerSpeed + layerOffset * 0.3,
        xz: config.rotationXZ * config.rotationSpeed * layerSpeed + layerOffset * 0.2,
        yz: config.rotationYZ * config.rotationSpeed * layerSpeed + layerOffset * 0.1,
        xw: config.rotationXW * config.rotationSpeed * layerSpeed,
        yw: config.rotationYW * config.rotationSpeed * layerSpeed,
        zw: config.rotationZW * config.rotationSpeed * layerSpeed,
      );

      final rotatedVertices = Rotation4D.rotateVertices(polytope.vertices, rotation);

      // Layer-specific hue with user hue shift applied
      final layerHue = ((layerDef['hue'] as double) + config.hueShift) % 360.0;

      // Calculate geometry-based intensity per VIB3-CORE QuantumVisualizer.js
      double geometryIntensity = config.vertexBrightness; // Use vertexBrightness as geometry value
      final geometryMod = layerDef['geometryMod'] as double;
      final baseIntensity = layerDef['baseIntensity'] as double;

      double layerIntensity;
      if (layerDef['geometryCubic'] == true) {
        // Highlight: cubic peak response (geometry³×1.5 + 0.1)
        layerIntensity = baseIntensity + math.pow(geometryIntensity, 3).toDouble() * geometryMod;
      } else if (layerDef['randomBurst'] == true) {
        // Accent: chaotic burst (randomBurst×geometry×2.0 + 0.05)
        final burst = math.sin(time * 0.05 + layer.toDouble()) * 0.5 + 0.5;
        layerIntensity = baseIntensity + burst * geometryIntensity * geometryMod;
      } else if (geometryMod < 0) {
        // Shadow: inverted geometry response ((1-geometry)²×0.8 + 0.1)
        layerIntensity = baseIntensity + math.pow(1.0 - geometryIntensity, 2).toDouble() * geometryMod.abs();
      } else {
        // Normal: baseIntensity + geometry × geometryMod
        layerIntensity = baseIntensity + geometryIntensity * geometryMod;
      }
      layerIntensity = layerIntensity.clamp(0.1, 1.0);

      // Audio reactivity scaled by layer reactivity
      final audioBoost = (config.bassEnergy + config.midEnergy + config.highEnergy) * 0.1 * reactivity;

      final layerAlpha = ((layerDef['alpha'] as double) + audioBoost).clamp(0.1, 1.0);
      final layerLight = ((layerDef['light'] as double) + layerIntensity * 0.2).clamp(0.1, 0.9);

      final layerColor = HSLColor.fromAHSL(
        layerAlpha,
        layerHue,
        layerDef['sat'] as double,
        layerLight,
      ).toColor();

      // Layer radius varies for depth effect
      final layerRadius = radius * (0.85 + depth * 0.3) * (1.0 + config.bassEnergy * 0.1 * reactivity);

      // RGB split amount for this layer
      final splitAmount = (layerDef['split'] as double) * config.rgbSplitAmount * 10.0;

      // Stroke width from layer definition
      final strokeWidth = layerDef['strokeWidth'] as double;

      // Render with RGB separation if split amount is significant
      if (splitAmount > 0.5) {
        _renderWireframeRGBSplit(
          canvas, cx, cy, layerRadius,
          rotatedVertices, polytope.edges,
          layerColor, splitAmount,
          strokeWidth: strokeWidth,
          glow: config.glowIntensity * (0.3 + reactivity * 0.3),
        );
      } else {
        _renderWireframe(
          canvas, cx, cy, layerRadius,
          rotatedVertices, polytope.edges,
          layerColor,
          strokeWidth: strokeWidth,
          glow: config.glowIntensity * (0.3 + reactivity * 0.3),
        );
      }
    }

    // Add bright vertex particles on content and highlight layers (per VIB3-CORE)
    final mainRotation = Rotation4D.apply6DRotation(
      xy: config.rotationXY * config.rotationSpeed,
      xz: config.rotationXZ * config.rotationSpeed,
      yz: config.rotationYZ * config.rotationSpeed,
      xw: config.rotationXW * config.rotationSpeed,
      yw: config.rotationYW * config.rotationSpeed,
      zw: config.rotationZW * config.rotationSpeed,
    );
    final mainVertices = Rotation4D.rotateVertices(polytope.vertices, mainRotation);

    // Content layer: white-hot particles
    final contentParticleColor = HSLColor.fromAHSL(
      0.9,
      15.0, // Hot red/white
      0.9,
      0.85 + config.highEnergy * 0.1,
    ).toColor();

    _renderVertexParticles(
      canvas, cx, cy,
      radius * (1.0 + config.bassEnergy * 0.15),
      mainVertices,
      contentParticleColor,
      size: 3.0 + config.highEnergy * 3.0,
    );

    // Highlight layer: cyan particles (subtle overlay)
    final highlightParticleColor = HSLColor.fromAHSL(
      0.6,
      190.0, // Electric cyan
      0.9,
      0.7,
    ).toColor();

    _renderVertexParticles(
      canvas, cx, cy,
      radius * 1.02,
      mainVertices,
      highlightParticleColor,
      size: 2.0 + config.midEnergy * 2.0,
    );
  }

  /// Render wireframe with RGB channel separation (chromatic aberration)
  void _renderWireframeRGBSplit(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    List<vm.Vector4> vertices,
    List<Edge> edges,
    Color baseColor,
    double splitAmount,
    {
    required double strokeWidth,
    required double glow,
  }) {
    // Calculate RGB offsets based on split amount
    final offsetR = Offset(splitAmount, -splitAmount * 0.5);
    final offsetG = Offset.zero;
    final offsetB = Offset(-splitAmount, splitAmount * 0.5);

    // Extract RGB from base color
    final r = baseColor.red / 255.0;
    final g = baseColor.green / 255.0;
    final b = baseColor.blue / 255.0;
    final alpha = baseColor.opacity;

    // Render each color channel separately with offset
    final channels = [
      {'offset': offsetR, 'color': Color.fromRGBO((r * 255).round(), 0, 0, alpha * 0.8)},
      {'offset': offsetG, 'color': Color.fromRGBO(0, (g * 255).round(), 0, alpha * 0.9)},
      {'offset': offsetB, 'color': Color.fromRGBO(0, 0, (b * 255).round(), alpha * 0.8)},
    ];

    for (final channel in channels) {
      final offset = channel['offset'] as Offset;
      final color = channel['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus; // Additive blending for RGB

      if (glow > 0.0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, glow * 1.5);
      }

      for (final edge in edges) {
        final v1 = vertices[edge.v1];
        final v2 = vertices[edge.v2];

        final p1 = _projectToScreen(v1, cx, cy, radius);
        final p2 = _projectToScreen(v2, cx, cy, radius);

        // Apply channel offset
        final p1Offset = p1 + offset;
        final p2Offset = p2 + offset;

        // Depth-based alpha
        final depth1 = 1.0 / (config.projectionDistance - v1.w);
        final depth2 = 1.0 / (config.projectionDistance - v2.w);
        final avgDepth = (depth1 + depth2) / 2.0;
        final depthAlpha = (avgDepth * 0.5 + 0.5).clamp(0.2, 1.0);

        paint.color = color.withOpacity(color.opacity * depthAlpha);
        canvas.drawLine(p1Offset, p2Offset, paint);
      }
    }
  }

  /// Render Holographic system - 5 canvas layers per VIB3-CORE spec
  /// Uses generateRoleParams() layer configs from HolographicVisualizer.js:
  /// - background: densityMult 0.4, speedMult 0.2, colorShift 0°, intensity 0.2, reactivity 0.5
  /// - shadow: densityMult 0.8, speedMult 0.3, colorShift +180°, intensity 0.4, reactivity 0.7
  /// - content: densityMult 1.0, speedMult 1.0, colorShift hue, intensity 0.5, reactivity 0.9
  /// - highlight: densityMult 1.5+, speedMult 0.8+, colorShift hue+60°, intensity 0.6+, reactivity 1.1
  /// - accent: densityMult 2.5+, speedMult 0.4+, colorShift hue+300°, intensity 0.3+, reactivity 1.5
  void _renderHolographicSystem(Canvas canvas, double cx, double cy, double radius) {
    final metadata = GeometryLibrary.getGeometryMetadata(config.geometryIndex);
    final polytope = PolytopeGenerator.generateBase(metadata.baseIndex);

    // 5-layer holographic system matching VIB3-CORE HolographicVisualizer.js generateRoleParams()
    final holographicLayers = [
      {
        'role': 'background',
        'densityMult': 0.4,
        'speedMult': 0.2,
        'colorShift': 0.0,
        'intensity': 0.2,
        'reactivity': 0.5,
        'strokeWidth': 1.0,
      },
      {
        'role': 'shadow',
        'densityMult': 0.8,
        'speedMult': 0.3,
        'colorShift': 180.0,
        'intensity': 0.4,
        'reactivity': 0.7,
        'strokeWidth': 1.5,
      },
      {
        'role': 'content',
        'densityMult': 1.0,
        'speedMult': 1.0,
        'colorShift': config.hueShift,
        'intensity': 0.5,
        'reactivity': 0.9,
        'strokeWidth': 2.0,
      },
      {
        'role': 'highlight',
        'densityMult': 1.5 + config.tessellationDensity * 0.03,
        'speedMult': 0.8 + config.rotationSpeed * 0.2,
        'colorShift': config.hueShift + 60.0,
        'intensity': 0.6 + config.vertexBrightness * 0.2,
        'reactivity': 1.1,
        'strokeWidth': 2.5,
      },
      {
        'role': 'accent',
        'densityMult': 2.5 + config.tessellationDensity * 0.05,
        'speedMult': 0.4 + config.rotationSpeed * 0.1,
        'colorShift': config.hueShift + 300.0,
        'intensity': 0.3 + config.vertexBrightness * 0.1,
        'reactivity': 1.5,
        'strokeWidth': 1.5,
      },
    ];

    // Render all 5 layers back to front
    for (int layer = 0; layer < 5; layer++) {
      final layerDef = holographicLayers[layer];
      final depth = layer / 4.0;

      // Layer-specific rotation speed from roleParams
      final layerSpeedMult = layerDef['speedMult'] as double;
      final reactivity = layerDef['reactivity'] as double;

      final rotation = Rotation4D.apply6DRotation(
        xy: config.rotationXY * config.rotationSpeed * layerSpeedMult,
        xz: config.rotationXZ * config.rotationSpeed * layerSpeedMult,
        yz: config.rotationYZ * config.rotationSpeed * layerSpeedMult,
        xw: config.rotationXW * config.rotationSpeed * layerSpeedMult,
        yw: config.rotationYW * config.rotationSpeed * layerSpeedMult,
        zw: config.rotationZW * config.rotationSpeed * layerSpeedMult,
      );

      final rotatedVertices = Rotation4D.rotateVertices(polytope.vertices, rotation);

      // Layer color from roleParams colorShift
      final layerHue = (layerDef['colorShift'] as double) % 360.0;
      final layerIntensity = layerDef['intensity'] as double;

      // Audio reactivity scales with layer reactivity
      final audioBoost = (config.bassEnergy * 0.15 + config.midEnergy * 0.1 + config.highEnergy * 0.1) * reactivity;

      final layerAlpha = (layerIntensity + audioBoost).clamp(0.1, 0.95);
      final layerColor = HSLColor.fromAHSL(
        layerAlpha,
        layerHue,
        0.7,
        0.4 + config.vertexBrightness * 0.3,
      ).toColor();

      // Layer radius varies by density multiplier
      final densityMult = layerDef['densityMult'] as double;
      final layerRadius = radius * (0.7 + depth * 0.5) * (0.8 + densityMult * 0.2);

      // RGB glitch effect for holographic (from rgbGlitch() in HolographicVisualizer.js)
      // Controlled by chaos parameter
      final glitchAmount = config.morphParameter * reactivity * 5.0;

      if (glitchAmount > 1.0) {
        _renderWireframeRGBGlitch(
          canvas, cx, cy, layerRadius,
          rotatedVertices, polytope.edges,
          layerColor, glitchAmount,
          strokeWidth: layerDef['strokeWidth'] as double,
          glow: config.glowIntensity * (0.6 + layerIntensity * 0.4),
        );
      } else {
        _renderWireframe(
          canvas, cx, cy, layerRadius,
          rotatedVertices, polytope.edges,
          layerColor,
          strokeWidth: layerDef['strokeWidth'] as double,
          glow: config.glowIntensity * (0.6 + layerIntensity * 0.4),
        );
      }
    }

    // Add holographic particles on content layer (layer 2)
    final mainRotation = Rotation4D.apply6DRotation(
      xy: config.rotationXY * config.rotationSpeed,
      xz: config.rotationXZ * config.rotationSpeed,
      yz: config.rotationYZ * config.rotationSpeed,
      xw: config.rotationXW * config.rotationSpeed,
      yw: config.rotationYW * config.rotationSpeed,
      zw: config.rotationZW * config.rotationSpeed,
    );
    final mainVertices = Rotation4D.rotateVertices(polytope.vertices, mainRotation);

    final particleColor = HSLColor.fromAHSL(
      0.8,
      config.hueShift,
      0.9,
      0.7,
    ).toColor();

    _renderVertexParticles(
      canvas, cx, cy, radius,
      mainVertices, particleColor,
      size: 2.0 + config.highEnergy * 3.0,
    );
  }

  /// Render wireframe with RGB glitch effect (holographic scanline distortion)
  /// Based on rgbGlitch() from HolographicVisualizer.js
  void _renderWireframeRGBGlitch(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    List<vm.Vector4> vertices,
    List<Edge> edges,
    Color baseColor,
    double glitchAmount,
    {
    required double strokeWidth,
    required double glow,
  }) {
    // RGB glitch offsets based on scanline pattern (like original)
    final scanlinePhase = time * 0.001;
    final glitchR = math.sin(scanlinePhase * 30.0) * glitchAmount * 0.06;
    final glitchG = math.sin(scanlinePhase * 28.0 + 0.5) * glitchAmount * 0.06;
    final glitchB = math.sin(scanlinePhase * 32.0 + 1.0) * glitchAmount * 0.06;

    // Offset each channel
    final offsetR = Offset(glitchR * 3.0, 0);
    final offsetG = Offset.zero;
    final offsetB = Offset(-glitchB * 3.0, 0);

    final r = baseColor.red / 255.0;
    final g = baseColor.green / 255.0;
    final b = baseColor.blue / 255.0;
    final alpha = baseColor.opacity;

    final channels = [
      {'offset': offsetR, 'color': Color.fromRGBO((r * 255).round(), 0, 0, alpha * 0.7)},
      {'offset': offsetG, 'color': Color.fromRGBO(0, (g * 255).round(), 0, alpha * 0.8)},
      {'offset': offsetB, 'color': Color.fromRGBO(0, 0, (b * 255).round(), alpha * 0.7)},
    ];

    for (final channel in channels) {
      final offset = channel['offset'] as Offset;
      final color = channel['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus;

      if (glow > 0.0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, glow * 1.5);
      }

      for (final edge in edges) {
        final v1 = vertices[edge.v1];
        final v2 = vertices[edge.v2];

        final p1 = _projectToScreen(v1, cx, cy, radius);
        final p2 = _projectToScreen(v2, cx, cy, radius);

        // Apply channel offset
        final p1Offset = p1 + offset;
        final p2Offset = p2 + offset;

        final depth1 = 1.0 / (config.projectionDistance - v1.w);
        final depth2 = 1.0 / (config.projectionDistance - v2.w);
        final avgDepth = (depth1 + depth2) / 2.0;
        final depthAlpha = (avgDepth * 0.5 + 0.5).clamp(0.2, 1.0);

        paint.color = color.withOpacity(color.opacity * depthAlpha);
        canvas.drawLine(p1Offset, p2Offset, paint);
      }
    }
  }

  /// Render Faceted system - 5 canvas layers per VIB3-CORE spec
  /// Faceted uses the same 5-layer role structure but with geometric aesthetic:
  /// - Clean 2D geometric patterns with 4D rotation
  /// - Sharp edges and faceted rendering
  /// - No RGB glitch effects (pure geometric)
  ///
  /// Role intensities from VIB3-CORE Visualizer.js:
  /// - background: 0.3, shadow: 0.5, content: 0.8, highlight: 1.0, accent: 1.2
  void _renderFacetedSystem(Canvas canvas, double cx, double cy, double radius) {
    final metadata = GeometryLibrary.getGeometryMetadata(config.geometryIndex);
    final polytope = PolytopeGenerator.generateBase(metadata.baseIndex);

    // 5-layer faceted system using VIB3-CORE roleIntensities
    // Faceted aesthetic: geometric, clean, sharp-edged (no RGB glitch)
    final facetedLayers = [
      {
        'role': 'background',
        'roleIntensity': 0.3,
        'speedMult': 0.3,
        'hueOffset': -60.0,    // Subtle background hue
        'saturation': 0.4,
        'lightness': 0.2,
        'strokeWidth': 0.8,
        'radiusMult': 0.85,
      },
      {
        'role': 'shadow',
        'roleIntensity': 0.5,
        'speedMult': 0.5,
        'hueOffset': -30.0,    // Shadow slightly darker/cooler
        'saturation': 0.5,
        'lightness': 0.3,
        'strokeWidth': 1.2,
        'radiusMult': 0.90,
      },
      {
        'role': 'content',
        'roleIntensity': 0.8,
        'speedMult': 1.0,
        'hueOffset': 0.0,      // Main content at base hue
        'saturation': 0.7,
        'lightness': 0.5,
        'strokeWidth': 2.0,
        'radiusMult': 1.0,
      },
      {
        'role': 'highlight',
        'roleIntensity': 1.0,
        'speedMult': 1.2,
        'hueOffset': 30.0,     // Highlight warmer/brighter
        'saturation': 0.8,
        'lightness': 0.65,
        'strokeWidth': 2.5,
        'radiusMult': 1.02,
      },
      {
        'role': 'accent',
        'roleIntensity': 1.2,
        'speedMult': 0.8,
        'hueOffset': 180.0,    // Accent is complementary color
        'saturation': 0.9,
        'lightness': 0.6,
        'strokeWidth': 1.5,
        'radiusMult': 1.05,
      },
    ];

    // Render all 5 layers back to front
    for (int layer = 0; layer < 5; layer++) {
      final layerDef = facetedLayers[layer];
      final depth = layer / 4.0;

      // Layer-specific rotation speed
      final layerSpeedMult = layerDef['speedMult'] as double;
      final roleIntensity = layerDef['roleIntensity'] as double;

      // Slight rotation offset per layer for parallax
      final layerOffset = (layer - 2) * 0.08;

      final rotation = Rotation4D.apply6DRotation(
        xy: config.rotationXY * config.rotationSpeed * layerSpeedMult + layerOffset,
        xz: config.rotationXZ * config.rotationSpeed * layerSpeedMult + layerOffset * 0.7,
        yz: config.rotationYZ * config.rotationSpeed * layerSpeedMult + layerOffset * 0.5,
        xw: config.rotationXW * config.rotationSpeed * layerSpeedMult,
        yw: config.rotationYW * config.rotationSpeed * layerSpeedMult,
        zw: config.rotationZW * config.rotationSpeed * layerSpeedMult,
      );

      final rotatedVertices = Rotation4D.rotateVertices(polytope.vertices, rotation);

      // Layer color with hue offset and saturation from role
      final layerHue = (config.hueShift + (layerDef['hueOffset'] as double)) % 360.0;
      final layerSat = layerDef['saturation'] as double;
      final layerLight = layerDef['lightness'] as double;

      // Audio reactivity scaled by roleIntensity
      final audioBoost = (config.bassEnergy * 0.1 + config.midEnergy * 0.1) * roleIntensity;
      final layerAlpha = (roleIntensity * 0.4 + audioBoost).clamp(0.1, 0.95);

      final layerColor = HSLColor.fromAHSL(
        layerAlpha,
        layerHue,
        layerSat,
        (layerLight + config.vertexBrightness * 0.15).clamp(0.1, 0.9),
      ).toColor();

      // Layer radius varies by role
      final radiusMult = layerDef['radiusMult'] as double;
      final layerRadius = radius * radiusMult * (1.0 + config.bassEnergy * 0.1);

      // Faceted: clean geometric rendering (no RGB effects)
      _renderWireframe(
        canvas, cx, cy, layerRadius,
        rotatedVertices, polytope.edges,
        layerColor,
        strokeWidth: layerDef['strokeWidth'] as double,
        glow: config.glowIntensity * (0.3 + roleIntensity * 0.4),
      );
    }

    // Add sharp vertex points on content/highlight layers
    final mainRotation = Rotation4D.apply6DRotation(
      xy: config.rotationXY * config.rotationSpeed,
      xz: config.rotationXZ * config.rotationSpeed,
      yz: config.rotationYZ * config.rotationSpeed,
      xw: config.rotationXW * config.rotationSpeed,
      yw: config.rotationYW * config.rotationSpeed,
      zw: config.rotationZW * config.rotationSpeed,
    );
    final mainVertices = Rotation4D.rotateVertices(polytope.vertices, mainRotation);

    // Faceted uses white vertex points for crisp geometric look
    _renderVertexParticles(
      canvas, cx, cy, radius,
      mainVertices, Colors.white,
      size: 2.5 + config.highEnergy * 2.5,
    );
  }

  /// Render wireframe from edges
  void _renderWireframe(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    List<vm.Vector4> vertices,
    List<Edge> edges,
    Color color,
    {
    required double strokeWidth,
    required double glow,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Add glow effect
    if (glow > 0.0) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        glow * 2.0,
      );
    }

    // Project and draw edges
    for (final edge in edges) {
      final v1 = vertices[edge.v1];
      final v2 = vertices[edge.v2];

      final p1 = _projectToScreen(v1, cx, cy, radius);
      final p2 = _projectToScreen(v2, cx, cy, radius);

      // Depth-based alpha (vertices closer to camera are brighter)
      final depth1 = 1.0 / (config.projectionDistance - v1.w);
      final depth2 = 1.0 / (config.projectionDistance - v2.w);
      final avgDepth = (depth1 + depth2) / 2.0;
      final depthAlpha = (avgDepth * 0.5 + 0.5).clamp(0.2, 1.0);

      final depthColor = color.withOpacity(color.opacity * depthAlpha);
      paint.color = depthColor;

      canvas.drawLine(p1, p2, paint);
    }
  }

  /// Render vertex particles
  void _renderVertexParticles(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    List<vm.Vector4> vertices,
    Color color,
    {
    required double size,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final vertex in vertices) {
      final p = _projectToScreen(vertex, cx, cy, radius);

      // Depth-based size and brightness
      final depth = 1.0 / (config.projectionDistance - vertex.w);
      final depthScale = (depth * 0.5 + 0.5).clamp(0.3, 1.2);
      final depthAlpha = depthScale.clamp(0.3, 1.0);

      paint.color = color.withOpacity(color.opacity * depthAlpha);

      canvas.drawCircle(p, size * depthScale, paint);
    }
  }

  /// Project 4D vertex to screen coordinates
  Offset _projectToScreen(vm.Vector4 v, double cx, double cy, double radius) {
    final projected = Rotation4D.project4Dto2D(
      v,
      distance: config.projectionDistance,
    );

    return Offset(
      cx + projected.x * radius,
      cy + projected.y * radius,
    );
  }

  @override
  bool shouldRepaint(VIB3NativeRenderer oldDelegate) {
    return time != oldDelegate.time ||
        config.system != oldDelegate.config.system ||
        config.geometryIndex != oldDelegate.config.geometryIndex ||
        config.rotationSpeed != oldDelegate.config.rotationSpeed ||
        config.bassEnergy != oldDelegate.config.bassEnergy ||
        config.midEnergy != oldDelegate.config.midEnergy ||
        config.highEnergy != oldDelegate.config.highEnergy ||
        config.rmsAmplitude != oldDelegate.config.rmsAmplitude;
  }
}
