/**
 * VIB3+ Visual System Renderers
 *
 * Complete rendering systems for all three visual modes:
 *
 * QUANTUM: Pure harmonic synthesis aesthetic
 * - High resonance, bright wireframes
 * - Single-layer with particle vertices
 * - Clean glow effects
 * - High contrast, minimal noise
 *
 * HOLOGRAPHIC: Spectral rich multi-layer depth field
 * - 5-7 depth layers with parallax
 * - Heavy chromatic aberration
 * - Scanline overlay
 * - Motion trails and ethereal glow
 *
 * FACETED: Geometric hybrid dual-layer structure
 * - Background structure + bright highlights
 * - Sharp vertices with moderate glow
 * - Balanced contrast
 * - Subtle depth fog
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/vib3_engine.dart';
import '../geometry/polytope_generator.dart';
import '../geometry/geometry_library.dart';
import '../geometry/polychora_4d.dart';
import '../math/rotation_4d.dart';
import '../effects/post_processing.dart';

/// Projected vertex with depth and color information
class ProjectedVertex {
  final Offset position;
  final double depth;       // W coordinate for 4D depth
  final double brightness;  // Computed brightness
  final Color color;

  const ProjectedVertex({
    required this.position,
    required this.depth,
    required this.brightness,
    required this.color,
  });
}

/// Edge with projected endpoints
class ProjectedEdge {
  final ProjectedVertex v1;
  final ProjectedVertex v2;
  final double averageDepth;

  const ProjectedEdge({
    required this.v1,
    required this.v2,
    required this.averageDepth,
  });
}

/// Base class for visual system renderers
abstract class VisualSystemRenderer {
  final VIB3EngineState state;
  final Size canvasSize;
  final double time;
  final PostProcessingPipeline effects;

  VisualSystemRenderer({
    required this.state,
    required this.canvasSize,
    required this.time,
    required this.effects,
  });

  /// Render the visual system
  void render(Canvas canvas);

  /// Get the base hue for this system
  double get baseHue;

  /// Get polygon generator for current geometry
  Polytope getPolytope() {
    final metadata = GeometryLibrary.getGeometryMetadata(state.geometryIndex);
    return PolytopeGenerator.generateBase(metadata.baseIndex);
  }

  /// Get 6D rotation matrix
  vm.Matrix4 getRotationMatrix() {
    // Base rotation from state
    var rotation = Rotation4D.apply6DRotation(
      xy: state.rotationXY,
      xz: state.rotationXZ,
      yz: state.rotationYZ,
      xw: state.rotationXW,
      yw: state.rotationYW,
      zw: state.rotationZW,
    );

    // Add time-based animation
    final animTime = time * state.animationSpeed;
    final animRotation = Rotation4D.apply6DRotation(
      xy: animTime * 0.3,
      xz: animTime * 0.2,
      xw: animTime * 0.15,
      yw: animTime * 0.1,
    );

    return animRotation * rotation;
  }

  /// Project vertices to screen space
  List<ProjectedVertex> projectVertices(
    List<vm.Vector4> vertices,
    vm.Matrix4 rotation,
  ) {
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;
    final baseRadius = math.min(canvasSize.width, canvasSize.height) * 0.35;

    // Audio-reactive radius
    final audioRadius = baseRadius * (1.0 + state.audioData.bassEnergy *
        state.audioReactivityStrength * 0.2);

    final projected = <ProjectedVertex>[];

    for (final vertex in vertices) {
      // Apply rotation
      final rotated = rotation.transform(vertex);

      // Stereographic projection 4D -> 2D
      final projDist = state.projectionDistance;
      final w = 1.0 / (projDist - rotated.w);
      final screenX = centerX + rotated.x * w * audioRadius;
      final screenY = centerY + rotated.y * w * audioRadius;

      // Calculate depth-based brightness
      final depth = rotated.w;
      final normalizedDepth = (depth + 2) / 4; // Normalize to 0-1 range
      final brightness = (0.3 + normalizedDepth * 0.7).clamp(0.0, 1.0);

      // Calculate vertex color with audio modulation
      final hue = (baseHue +
          state.hueShift +
          state.audioData.spectralCentroid / 50 * state.audioReactivityStrength
      ) % 360;

      final color = HSLColor.fromAHSL(
        1.0,
        hue,
        state.saturation,
        brightness * state.vertexBrightness,
      ).toColor();

      projected.add(ProjectedVertex(
        position: Offset(screenX, screenY),
        depth: depth,
        brightness: brightness,
        color: color,
      ));
    }

    return projected;
  }

  /// Project edges with depth sorting
  List<ProjectedEdge> projectEdges(
    List<ProjectedVertex> vertices,
    List<Edge> edges,
  ) {
    final projected = <ProjectedEdge>[];

    for (final edge in edges) {
      if (edge.v1 >= vertices.length || edge.v2 >= vertices.length) continue;

      final v1 = vertices[edge.v1];
      final v2 = vertices[edge.v2];
      final avgDepth = (v1.depth + v2.depth) / 2;

      projected.add(ProjectedEdge(
        v1: v1,
        v2: v2,
        averageDepth: avgDepth,
      ));
    }

    // Sort back-to-front for proper rendering
    projected.sort((a, b) => a.averageDepth.compareTo(b.averageDepth));

    return projected;
  }

  /// Draw background gradient
  void drawBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);

    // Audio-reactive background brightness
    final baseBrightness = 0.03 + state.audioData.bassEnergy *
        state.audioReactivityStrength * 0.02;

    final gradient = ui.Gradient.radial(
      Offset(canvasSize.width / 2, canvasSize.height / 2),
      math.max(canvasSize.width, canvasSize.height) * 0.8,
      [
        HSLColor.fromAHSL(1, baseHue, 0.3, baseBrightness + 0.02).toColor(),
        HSLColor.fromAHSL(1, baseHue, 0.2, baseBrightness).toColor(),
      ],
    );

    canvas.drawRect(rect, Paint()..shader = gradient);
  }
}

/// Quantum Visual System Renderer
/// Pure harmonic synthesis aesthetic with high resonance
class QuantumRenderer extends VisualSystemRenderer {
  QuantumRenderer({
    required super.state,
    required super.canvasSize,
    required super.time,
    required super.effects,
  });

  @override
  double get baseHue => 200.0; // Cyan/blue base

  @override
  void render(Canvas canvas) {
    drawBackground(canvas);

    final polytope = getPolytope();
    final rotation = getRotationMatrix();
    final vertices = Rotation4D.rotateVertices(polytope.vertices, rotation);
    final projected = projectVertices(vertices, rotation);
    final edges = projectEdges(projected, polytope.edges);

    // Record motion trails
    effects.trails.recordFrame(projected.map((v) => v.position).toList());

    // Draw motion trails (subtle for quantum)
    if (state.audioData.rmsAmplitude > 0.1) {
      effects.trails.drawTrails(
        canvas,
        HSLColor.fromAHSL(0.3, baseHue, 0.5, 0.5).toColor(),
        strokeWidth: 1.0,
      );
    }

    // Quantum uses high-contrast single layer
    final edgeColor = HSLColor.fromAHSL(
      1.0,
      (baseHue + state.hueShift) % 360,
      0.85 + state.audioData.midEnergy * 0.1,
      0.6 + state.vertexBrightness * 0.3,
    ).toColor();

    // Draw edges with glow
    for (final edge in edges) {
      final depthAlpha = (0.4 + edge.averageDepth * 0.3).clamp(0.3, 1.0);
      final lineColor = edgeColor.withOpacity(depthAlpha);

      // Audio-reactive stroke width
      final strokeWidth = 2.0 + state.audioData.midEnergy * 2.0;

      effects.glow.drawGlowLine(
        canvas,
        edge.v1.position,
        edge.v2.position,
        lineColor,
        strokeWidth: strokeWidth,
        customIntensity: state.glowIntensity,
      );
    }

    // Draw vertex particles
    final particleColor = HSLColor.fromAHSL(
      1.0,
      (baseHue + state.hueShift + 30) % 360,
      0.9,
      0.8,
    ).toColor();

    for (final vertex in projected) {
      final size = 3.0 + vertex.brightness * 2.0 +
          state.audioData.highEnergy * 3.0;

      effects.glow.drawGlowPoint(
        canvas,
        vertex.position,
        size,
        particleColor.withOpacity(vertex.brightness),
        customIntensity: state.glowIntensity * 0.8,
      );
    }

    // Draw center core
    _drawQuantumCore(canvas);

    // Overlay effects
    effects.update(time);
    effects.drawOverlays(canvas, canvasSize, time);
  }

  void _drawQuantumCore(Canvas canvas) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final coreRadius = 20.0 + state.audioData.bassEnergy * 15.0;

    // Pulsing core with audio reactivity
    final pulseFactor = 1.0 + math.sin(time * 4) * 0.1 * state.audioData.rmsAmplitude;

    final coreColor = HSLColor.fromAHSL(
      0.8,
      (baseHue + state.hueShift) % 360,
      0.9,
      0.7,
    ).toColor();

    // Outer glow
    final outerGlow = Paint()
      ..color = coreColor.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreRadius * 2);
    canvas.drawCircle(center, coreRadius * 2 * pulseFactor, outerGlow);

    // Inner core
    effects.glow.drawGlowPoint(
      canvas,
      center,
      coreRadius * pulseFactor,
      coreColor,
      customIntensity: state.glowIntensity * 1.5,
    );
  }
}

/// Holographic Visual System Renderer
/// Multi-layer depth field with ethereal effects
class HolographicRenderer extends VisualSystemRenderer {
  static const int layerCount = 5;

  HolographicRenderer({
    required super.state,
    required super.canvasSize,
    required super.time,
    required super.effects,
  });

  @override
  double get baseHue => 280.0; // Purple/violet base

  @override
  void render(Canvas canvas) {
    drawBackground(canvas);

    final polytope = getPolytope();

    // Render multiple depth layers
    for (int layer = 0; layer < layerCount; layer++) {
      _renderLayer(canvas, polytope, layer);
    }

    // Draw holographic particles floating between layers
    _drawHolographicParticles(canvas);

    // Overlay effects (scanlines, noise, vignette)
    effects.update(time);
    effects.drawOverlays(canvas, canvasSize, time);
  }

  void _renderLayer(Canvas canvas, Polytope polytope, int layer) {
    final depth = layer / (layerCount - 1);
    final layerOffset = (layer - layerCount / 2) * state.layerSeparation * 0.1;

    // Each layer rotates at different speed for parallax
    final layerSpeed = 1.0 + (layer - layerCount / 2) * 0.2;
    final animTime = time * state.animationSpeed * layerSpeed;

    final rotation = Rotation4D.apply6DRotation(
      xy: state.rotationXY + animTime * 0.3,
      xz: state.rotationXZ + animTime * 0.2,
      yz: state.rotationYZ + animTime * 0.1,
      xw: state.rotationXW + layerOffset + animTime * 0.15,
      yw: state.rotationYW + layerOffset + animTime * 0.08,
      zw: state.rotationZW + layerOffset,
    );

    final vertices = Rotation4D.rotateVertices(polytope.vertices, rotation);
    final projected = projectVertices(vertices, rotation);

    // Scale layer radius for depth effect
    final layerScale = 0.7 + depth * 0.6;

    // Layer-specific hue shift across spectrum
    final layerHue = (baseHue + state.hueShift + layer * 25.0) % 360.0;

    // Layer alpha based on depth and audio
    final baseAlpha = 0.15 + depth * 0.25;
    final audioAlpha = state.audioData.rmsAmplitude * state.audioReactivityStrength * 0.15;
    final layerAlpha = (baseAlpha + audioAlpha).clamp(0.1, 0.7);

    final layerColor = HSLColor.fromAHSL(
      layerAlpha,
      layerHue,
      0.7 + state.saturation * 0.2,
      0.5 + depth * 0.2,
    ).toColor();

    // Calculate layer-specific radius
    final baseRadius = math.min(canvasSize.width, canvasSize.height) * 0.35;
    final layerRadius = baseRadius * layerScale * (1.0 + state.audioData.bassEnergy * 0.1);

    // Draw edges with chromatic aberration for deeper layers
    for (final edge in polytope.edges) {
      if (edge.v1 >= projected.length || edge.v2 >= projected.length) continue;

      final v1 = projected[edge.v1];
      final v2 = projected[edge.v2];

      // Scale positions for this layer
      final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
      final p1 = center + (v1.position - center) * layerScale;
      final p2 = center + (v2.position - center) * layerScale;

      final strokeWidth = 1.5 + layer * 0.3 + state.audioData.midEnergy;

      // Use chromatic aberration for outer layers
      if (layer > 1 && state.rgbSplitAmount > 0) {
        effects.chromatic.drawAberratedLine(
          canvas,
          p1,
          p2,
          layerColor,
          strokeWidth: strokeWidth,
          opacity: layerAlpha * 0.6,
        );
      } else {
        effects.glow.drawGlowLine(
          canvas,
          p1,
          p2,
          layerColor,
          strokeWidth: strokeWidth,
          customIntensity: state.glowIntensity * (1.0 - depth * 0.3),
        );
      }
    }
  }

  void _drawHolographicParticles(Canvas canvas) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final maxRadius = math.min(canvasSize.width, canvasSize.height) * 0.4;

    final particleCount = 20 + (state.audioData.highEnergy * 30).round();
    final rng = math.Random((time * 100).floor());

    final particleColor = HSLColor.fromAHSL(
      0.6,
      (baseHue + state.hueShift) % 360,
      0.9,
      0.7,
    ).toColor();

    for (int i = 0; i < particleCount; i++) {
      final angle = rng.nextDouble() * math.pi * 2 + time * 0.5;
      final distance = rng.nextDouble() * maxRadius;
      final z = rng.nextDouble() * 2 - 1; // Simulated depth

      final x = center.dx + math.cos(angle) * distance * (1 + z * 0.3);
      final y = center.dy + math.sin(angle) * distance * (1 + z * 0.3);

      final size = 1.0 + rng.nextDouble() * 2.0;
      final alpha = (0.3 + z * 0.3).clamp(0.1, 0.7);

      canvas.drawCircle(
        Offset(x, y),
        size,
        Paint()..color = particleColor.withOpacity(alpha),
      );
    }
  }
}

/// Faceted Visual System Renderer
/// Geometric hybrid with dual-layer structure
class FacetedRenderer extends VisualSystemRenderer {
  FacetedRenderer({
    required super.state,
    required super.canvasSize,
    required super.time,
    required super.effects,
  });

  @override
  double get baseHue => 160.0; // Green/teal base

  @override
  void render(Canvas canvas) {
    drawBackground(canvas);

    final polytope = getPolytope();
    final rotation = getRotationMatrix();
    final vertices = Rotation4D.rotateVertices(polytope.vertices, rotation);
    final projected = projectVertices(vertices, rotation);
    final edges = projectEdges(projected, polytope.edges);

    // Faceted uses dual layers: background structure + foreground highlights

    // Layer 1: Background structure (darker, thinner)
    _renderStructureLayer(canvas, edges);

    // Layer 2: Bright faceted edges (highlights)
    _renderHighlightLayer(canvas, edges);

    // Sharp vertex points
    _renderVertexPoints(canvas, projected);

    // Subtle depth fog overlay
    if (state.audioData.bassEnergy > 0.3) {
      _drawDepthFog(canvas);
    }

    // Overlay effects
    effects.update(time);
    effects.drawOverlays(canvas, canvasSize, time);
  }

  void _renderStructureLayer(Canvas canvas, List<ProjectedEdge> edges) {
    final structureHue = (baseHue + state.hueShift - 30) % 360;
    final baseAlpha = 0.3 + state.audioData.bassEnergy * 0.15;

    final structureColor = HSLColor.fromAHSL(
      baseAlpha,
      structureHue,
      0.5,
      0.25,
    ).toColor();

    for (final edge in edges) {
      final depthFactor = (0.5 + edge.averageDepth * 0.25).clamp(0.3, 0.8);
      final lineColor = structureColor.withOpacity(depthFactor * baseAlpha);

      effects.glow.drawGlowLine(
        canvas,
        edge.v1.position * 0.95 + Offset(canvasSize.width * 0.025, canvasSize.height * 0.025),
        edge.v2.position * 0.95 + Offset(canvasSize.width * 0.025, canvasSize.height * 0.025),
        lineColor,
        strokeWidth: 1.5,
        customIntensity: state.glowIntensity * 0.4,
      );
    }
  }

  void _renderHighlightLayer(Canvas canvas, List<ProjectedEdge> edges) {
    final highlightHue = (baseHue + state.hueShift + 30) % 360;

    for (final edge in edges) {
      final depthAlpha = (0.5 + edge.averageDepth * 0.3).clamp(0.4, 1.0);

      final highlightColor = HSLColor.fromAHSL(
        depthAlpha,
        highlightHue,
        0.8 + state.saturation * 0.1,
        0.55 + state.vertexBrightness * 0.25,
      ).toColor();

      // Audio-reactive stroke width
      final strokeWidth = 2.5 + state.audioData.midEnergy * 2.0;

      effects.glow.drawGlowLine(
        canvas,
        edge.v1.position,
        edge.v2.position,
        highlightColor,
        strokeWidth: strokeWidth,
        customIntensity: state.glowIntensity,
      );
    }
  }

  void _renderVertexPoints(Canvas canvas, List<ProjectedVertex> vertices) {
    // Sharp, bright vertex points characteristic of faceted style
    for (final vertex in vertices) {
      final size = 2.5 + vertex.brightness * 1.5 +
          state.audioData.highEnergy * 2.0;

      // White core with colored glow
      effects.glow.drawGlowPoint(
        canvas,
        vertex.position,
        size,
        Colors.white.withOpacity(vertex.brightness * 0.9),
        customIntensity: state.glowIntensity * 0.6,
      );

      // Colored outer ring
      final ringColor = HSLColor.fromAHSL(
        0.6,
        (baseHue + state.hueShift) % 360,
        0.9,
        0.6,
      ).toColor();

      canvas.drawCircle(
        vertex.position,
        size * 1.5,
        Paint()
          ..color = ringColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawDepthFog(Canvas canvas) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final fogRadius = math.min(canvasSize.width, canvasSize.height) * 0.6;

    final fogColor = HSLColor.fromAHSL(
      1.0,
      baseHue,
      0.3,
      0.05,
    ).toColor();

    final fogPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        fogRadius,
        [
          Colors.transparent,
          fogColor.withOpacity(0.1),
          fogColor.withOpacity(0.3),
        ],
        [0.0, 0.7, 1.0],
      )
      ..blendMode = BlendMode.multiply;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      fogPaint,
    );
  }
}

/// Factory for creating appropriate renderer based on visual system
class VisualSystemRendererFactory {
  static VisualSystemRenderer create({
    required VIB3EngineState state,
    required Size canvasSize,
    required double time,
    PostProcessingConfig? effectsConfig,
  }) {
    // Get effects config based on system type
    final config = effectsConfig ?? _getDefaultEffectsConfig(state.system);
    final effects = PostProcessingPipeline(config);

    switch (state.system) {
      case VisualSystem.quantum:
        return QuantumRenderer(
          state: state,
          canvasSize: canvasSize,
          time: time,
          effects: effects,
        );
      case VisualSystem.holographic:
        return HolographicRenderer(
          state: state,
          canvasSize: canvasSize,
          time: time,
          effects: effects,
        );
      case VisualSystem.faceted:
        return FacetedRenderer(
          state: state,
          canvasSize: canvasSize,
          time: time,
          effects: effects,
        );
    }
  }

  static PostProcessingConfig _getDefaultEffectsConfig(VisualSystem system) {
    switch (system) {
      case VisualSystem.quantum:
        return PostProcessingConfig.quantum();
      case VisualSystem.holographic:
        return PostProcessingConfig.holographic();
      case VisualSystem.faceted:
        return PostProcessingConfig.faceted();
    }
  }
}
