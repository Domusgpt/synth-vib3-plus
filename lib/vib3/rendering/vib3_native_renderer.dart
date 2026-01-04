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

  /// Render Quantum system - 5 canvas layers with extreme RGB separation
  /// Layer 0: Background (deep purple/black) - 0.02 separation
  /// Layer 1: Shadow (toxic green) - 0.08 separation
  /// Layer 2: Content (red/orange/white-hot) - 0.15 separation
  /// Layer 3: Highlight (electric cyan) - 0.25 separation
  /// Layer 4: Accent (magenta/violet) - 0.30 separation
  void _renderQuantumSystem(Canvas canvas, double cx, double cy, double radius) {
    final metadata = GeometryLibrary.getGeometryMetadata(config.geometryIndex);
    final polytope = PolytopeGenerator.generateBase(metadata.baseIndex);

    // Quantum layer definitions: [hue, saturation, lightness, alpha, rgbSplit]
    final quantumLayers = [
      {'hue': 270.0, 'sat': 0.6, 'light': 0.15, 'alpha': 0.4, 'split': 0.02, 'name': 'background'},   // Deep purple/black
      {'hue': 90.0,  'sat': 0.8, 'light': 0.35, 'alpha': 0.5, 'split': 0.08, 'name': 'shadow'},       // Toxic green
      {'hue': 15.0,  'sat': 0.9, 'light': 0.55, 'alpha': 0.7, 'split': 0.15, 'name': 'content'},      // Red/orange/white-hot
      {'hue': 190.0, 'sat': 0.9, 'light': 0.6,  'alpha': 0.8, 'split': 0.25, 'name': 'highlight'},    // Electric cyan
      {'hue': 300.0, 'sat': 0.85,'light': 0.5,  'alpha': 0.9, 'split': 0.30, 'name': 'accent'},       // Magenta/violet
    ];

    // Render all 5 layers back to front
    for (int layer = 0; layer < 5; layer++) {
      final layerDef = quantumLayers[layer];
      final depth = layer / 4.0;

      // Each layer has different rotation offset for parallax depth
      final layerOffset = (layer - 2) * 0.15;
      final layerSpeed = 1.0 + (layer - 2) * 0.15;

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

      // Audio reactivity affects different layers differently
      final audioBoost = layer == 2 ? config.bassEnergy * 0.3 :    // Content responds to bass
                         layer == 3 ? config.midEnergy * 0.3 :     // Highlight responds to mid
                         layer == 4 ? config.highEnergy * 0.3 : 0.0; // Accent responds to high

      final layerAlpha = ((layerDef['alpha'] as double) + audioBoost).clamp(0.1, 1.0);
      final layerLight = ((layerDef['light'] as double) + config.vertexBrightness * 0.2).clamp(0.1, 0.9);

      final layerColor = HSLColor.fromAHSL(
        layerAlpha,
        layerHue,
        layerDef['sat'] as double,
        layerLight,
      ).toColor();

      // Layer radius varies for depth effect
      final layerRadius = radius * (0.85 + depth * 0.3) * (1.0 + config.bassEnergy * 0.15);

      // RGB split amount for this layer
      final splitAmount = (layerDef['split'] as double) * config.rgbSplitAmount * 10.0;

      // Stroke width varies by layer (content/highlight/accent are thicker)
      final strokeWidth = layer < 2 ? 1.0 + layer * 0.5 : 2.0 + (layer - 2) * 0.8;

      // Render with RGB separation if split amount is significant
      if (splitAmount > 0.5) {
        _renderWireframeRGBSplit(
          canvas, cx, cy, layerRadius,
          rotatedVertices, polytope.edges,
          layerColor, splitAmount,
          strokeWidth: strokeWidth,
          glow: config.glowIntensity * (0.5 + depth * 0.5),
        );
      } else {
        _renderWireframe(
          canvas, cx, cy, layerRadius,
          rotatedVertices, polytope.edges,
          layerColor,
          strokeWidth: strokeWidth,
          glow: config.glowIntensity * (0.5 + depth * 0.5),
        );
      }
    }

    // Add bright vertex particles on topmost layer
    final mainRotation = Rotation4D.apply6DRotation(
      xy: config.rotationXY * config.rotationSpeed,
      xz: config.rotationXZ * config.rotationSpeed,
      yz: config.rotationYZ * config.rotationSpeed,
      xw: config.rotationXW * config.rotationSpeed,
      yw: config.rotationYW * config.rotationSpeed,
      zw: config.rotationZW * config.rotationSpeed,
    );
    final mainVertices = Rotation4D.rotateVertices(polytope.vertices, mainRotation);

    // Particle color cycles through quantum palette
    final particleHue = (config.hueShift + time * 30.0) % 360.0;
    final particleColor = HSLColor.fromAHSL(
      0.9,
      particleHue,
      0.9,
      0.7 + config.highEnergy * 0.2,
    ).toColor();

    _renderVertexParticles(
      canvas, cx, cy,
      radius * (1.0 + config.bassEnergy * 0.2),
      mainVertices,
      particleColor,
      size: 3.0 + config.highEnergy * 4.0,
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

  /// Render Holographic system (multi-layer depth field)
  void _renderHolographicSystem(Canvas canvas, double cx, double cy, double radius) {
    final metadata = GeometryLibrary.getGeometryMetadata(config.geometryIndex);
    final polytope = PolytopeGenerator.generateBase(metadata.baseIndex);

    // Render 5 holographic layers at different depths
    const layerCount = 5;
    for (int layer = 0; layer < layerCount; layer++) {
      final depth = layer / (layerCount - 1);
      final layerOffset = (layer - layerCount / 2) * config.layerSeparation * 0.1;

      // Each layer rotates at different speed
      final layerSpeed = 1.0 + (layer - layerCount / 2) * 0.2;
      final rotation = Rotation4D.apply6DRotation(
        xy: config.rotationXY * config.rotationSpeed * layerSpeed,
        xz: config.rotationXZ * config.rotationSpeed * layerSpeed,
        yz: config.rotationYZ * config.rotationSpeed * layerSpeed,
        xw: config.rotationXW * config.rotationSpeed * layerSpeed + layerOffset,
        yw: config.rotationYW * config.rotationSpeed * layerSpeed + layerOffset,
        zw: config.rotationZW * config.rotationSpeed * layerSpeed + layerOffset,
      );

      final rotatedVertices = Rotation4D.rotateVertices(polytope.vertices, rotation);

      // Layer color shifts across spectrum
      final layerHue = (config.hueShift + layer * 30.0) % 360.0;
      final layerAlpha = 0.15 + depth * 0.3 + config.rmsAmplitude * 0.2;
      final layerColor = HSLColor.fromAHSL(
        layerAlpha,
        layerHue,
        0.7,
        0.5,
      ).toColor();

      final layerRadius = radius * (0.7 + depth * 0.6);

      _renderWireframe(
        canvas,
        cx,
        cy,
        layerRadius,
        rotatedVertices,
        polytope.edges,
        layerColor,
        strokeWidth: 1.5 + layer * 0.5,
        glow: config.glowIntensity * (1.0 - depth * 0.3),
      );
    }

    // Add holographic particles on outermost layer
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
      canvas,
      cx,
      cy,
      radius,
      mainVertices,
      particleColor,
      size: 2.0 + config.highEnergy * 3.0,
    );
  }

  /// Render Faceted system (geometric hybrid aesthetic)
  void _renderFacetedSystem(Canvas canvas, double cx, double cy, double radius) {
    final metadata = GeometryLibrary.getGeometryMetadata(config.geometryIndex);
    final polytope = PolytopeGenerator.generateBase(metadata.baseIndex);

    // Apply rotation
    final rotation = Rotation4D.apply6DRotation(
      xy: config.rotationXY * config.rotationSpeed,
      xz: config.rotationXZ * config.rotationSpeed,
      yz: config.rotationYZ * config.rotationSpeed,
      xw: config.rotationXW * config.rotationSpeed,
      yw: config.rotationYW * config.rotationSpeed,
      zw: config.rotationZW * config.rotationSpeed,
    );

    final rotatedVertices = Rotation4D.rotateVertices(polytope.vertices, rotation);

    // Faceted uses dual layers: structure + highlights
    // Layer 1: Background structure
    final structureColor = HSLColor.fromAHSL(
      0.3 + config.bassEnergy * 0.2,
      config.hueShift - 30,
      0.6,
      0.3,
    ).toColor();

    _renderWireframe(
      canvas,
      cx,
      cy,
      radius * 0.95,
      rotatedVertices,
      polytope.edges,
      structureColor,
      strokeWidth: 1.5,
      glow: config.glowIntensity * 0.5,
    );

    // Layer 2: Bright faceted edges
    final facetColor = HSLColor.fromAHSL(
      0.7 + config.midEnergy * 0.2,
      config.hueShift + 30,
      0.8,
      0.6,
    ).toColor();

    _renderWireframe(
      canvas,
      cx,
      cy,
      radius,
      rotatedVertices,
      polytope.edges,
      facetColor,
      strokeWidth: 2.5 + config.midEnergy * 2.0,
      glow: config.glowIntensity,
    );

    // Add sharp vertex points
    _renderVertexParticles(
      canvas,
      cx,
      cy,
      radius,
      rotatedVertices,
      Colors.white,
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
