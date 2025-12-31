/**
 * VIB3+ Post-Processing Effects Pipeline
 *
 * Advanced visual effects rendered in Dart/Flutter:
 * - Glow/Bloom: Multi-layer blur-based bloom
 * - Chromatic Aberration: RGB channel separation
 * - Depth Fog: Distance-based atmospheric effect
 * - Scanlines: CRT/holographic line effect
 * - Noise/Grain: Film grain simulation
 * - Vignette: Edge darkening
 * - Motion Trails: Vertex motion persistence
 * - Glitch: Random displacement effects
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Post-processing effect configuration
class PostProcessingConfig {
  // Glow/Bloom
  final double glowIntensity;      // 0-3
  final double glowRadius;         // 1-20
  final int glowPasses;            // 1-5

  // Chromatic Aberration
  final double rgbSplitAmount;     // 0-10
  final double rgbSplitAngle;      // 0-360°

  // Depth Fog
  final double fogDensity;         // 0-1
  final Color fogColor;
  final double fogStart;           // Near distance
  final double fogEnd;             // Far distance

  // Scanlines
  final bool scanlinesEnabled;
  final double scanlineIntensity;  // 0-1
  final double scanlineFrequency;  // Lines per 100 pixels
  final double scanlineSpeed;      // Animation speed

  // Noise/Grain
  final double noiseIntensity;     // 0-1
  final double noiseScale;         // Grain size
  final bool animatedNoise;

  // Vignette
  final double vignetteIntensity;  // 0-1
  final double vignetteRadius;     // 0-1

  // Motion Trails
  final double trailIntensity;     // 0-1
  final int trailLength;           // Number of ghost frames

  // Glitch
  final double glitchIntensity;    // 0-1
  final double glitchFrequency;    // How often glitches occur

  const PostProcessingConfig({
    this.glowIntensity = 1.0,
    this.glowRadius = 8.0,
    this.glowPasses = 2,
    this.rgbSplitAmount = 0.0,
    this.rgbSplitAngle = 0.0,
    this.fogDensity = 0.0,
    this.fogColor = const Color(0xFF0A0A1A),
    this.fogStart = 5.0,
    this.fogEnd = 20.0,
    this.scanlinesEnabled = false,
    this.scanlineIntensity = 0.3,
    this.scanlineFrequency = 2.0,
    this.scanlineSpeed = 1.0,
    this.noiseIntensity = 0.0,
    this.noiseScale = 1.0,
    this.animatedNoise = true,
    this.vignetteIntensity = 0.2,
    this.vignetteRadius = 0.8,
    this.trailIntensity = 0.0,
    this.trailLength = 5,
    this.glitchIntensity = 0.0,
    this.glitchFrequency = 0.1,
  });

  /// Quantum system preset (clean, bright)
  factory PostProcessingConfig.quantum() {
    return const PostProcessingConfig(
      glowIntensity: 1.2,
      glowRadius: 10.0,
      glowPasses: 2,
      rgbSplitAmount: 0.5,
      scanlinesEnabled: false,
      noiseIntensity: 0.02,
      vignetteIntensity: 0.15,
    );
  }

  /// Holographic system preset (layered, ethereal)
  factory PostProcessingConfig.holographic() {
    return const PostProcessingConfig(
      glowIntensity: 2.0,
      glowRadius: 15.0,
      glowPasses: 3,
      rgbSplitAmount: 3.0,
      rgbSplitAngle: 45.0,
      scanlinesEnabled: true,
      scanlineIntensity: 0.2,
      scanlineFrequency: 3.0,
      noiseIntensity: 0.05,
      vignetteIntensity: 0.25,
      trailIntensity: 0.3,
    );
  }

  /// Faceted system preset (sharp, geometric)
  factory PostProcessingConfig.faceted() {
    return const PostProcessingConfig(
      glowIntensity: 0.8,
      glowRadius: 6.0,
      glowPasses: 1,
      rgbSplitAmount: 1.0,
      scanlinesEnabled: false,
      noiseIntensity: 0.03,
      vignetteIntensity: 0.2,
    );
  }

  PostProcessingConfig copyWith({
    double? glowIntensity,
    double? glowRadius,
    int? glowPasses,
    double? rgbSplitAmount,
    double? rgbSplitAngle,
    double? fogDensity,
    Color? fogColor,
    double? fogStart,
    double? fogEnd,
    bool? scanlinesEnabled,
    double? scanlineIntensity,
    double? scanlineFrequency,
    double? scanlineSpeed,
    double? noiseIntensity,
    double? noiseScale,
    bool? animatedNoise,
    double? vignetteIntensity,
    double? vignetteRadius,
    double? trailIntensity,
    int? trailLength,
    double? glitchIntensity,
    double? glitchFrequency,
  }) {
    return PostProcessingConfig(
      glowIntensity: glowIntensity ?? this.glowIntensity,
      glowRadius: glowRadius ?? this.glowRadius,
      glowPasses: glowPasses ?? this.glowPasses,
      rgbSplitAmount: rgbSplitAmount ?? this.rgbSplitAmount,
      rgbSplitAngle: rgbSplitAngle ?? this.rgbSplitAngle,
      fogDensity: fogDensity ?? this.fogDensity,
      fogColor: fogColor ?? this.fogColor,
      fogStart: fogStart ?? this.fogStart,
      fogEnd: fogEnd ?? this.fogEnd,
      scanlinesEnabled: scanlinesEnabled ?? this.scanlinesEnabled,
      scanlineIntensity: scanlineIntensity ?? this.scanlineIntensity,
      scanlineFrequency: scanlineFrequency ?? this.scanlineFrequency,
      scanlineSpeed: scanlineSpeed ?? this.scanlineSpeed,
      noiseIntensity: noiseIntensity ?? this.noiseIntensity,
      noiseScale: noiseScale ?? this.noiseScale,
      animatedNoise: animatedNoise ?? this.animatedNoise,
      vignetteIntensity: vignetteIntensity ?? this.vignetteIntensity,
      vignetteRadius: vignetteRadius ?? this.vignetteRadius,
      trailIntensity: trailIntensity ?? this.trailIntensity,
      trailLength: trailLength ?? this.trailLength,
      glitchIntensity: glitchIntensity ?? this.glitchIntensity,
      glitchFrequency: glitchFrequency ?? this.glitchFrequency,
    );
  }
}

/// Glow effect painter
class GlowEffectPainter {
  final double intensity;
  final double radius;
  final int passes;

  const GlowEffectPainter({
    this.intensity = 1.0,
    this.radius = 8.0,
    this.passes = 2,
  });

  /// Apply glow to a paint object
  Paint applyGlow(Paint basePaint, {double? customIntensity}) {
    final effectiveIntensity = customIntensity ?? intensity;
    if (effectiveIntensity <= 0) return basePaint;

    return basePaint
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        radius * effectiveIntensity,
      );
  }

  /// Draw glowing line with multiple passes
  void drawGlowLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Color color, {
    double strokeWidth = 2.0,
    double? customIntensity,
  }) {
    final effectiveIntensity = customIntensity ?? intensity;
    if (effectiveIntensity <= 0) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
      return;
    }

    // Draw glow passes (larger, more transparent)
    for (int i = passes; i >= 1; i--) {
      final passRatio = i / passes;
      final glowRadius = radius * effectiveIntensity * passRatio * 2;
      final alpha = (color.alpha * (0.3 / i)).round().clamp(0, 255);

      final glowPaint = Paint()
        ..color = color.withAlpha(alpha)
        ..strokeWidth = strokeWidth + glowRadius
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

      canvas.drawLine(p1, p2, glowPaint);
    }

    // Draw core line
    final corePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, corePaint);
  }

  /// Draw glowing circle/point
  void drawGlowPoint(
    Canvas canvas,
    Offset center,
    double pointRadius,
    Color color, {
    double? customIntensity,
  }) {
    final effectiveIntensity = customIntensity ?? intensity;

    // Draw glow passes
    for (int i = passes; i >= 1; i--) {
      final passRatio = i / passes;
      final glowRadius = radius * effectiveIntensity * passRatio;
      final alpha = (color.alpha * (0.4 / i)).round().clamp(0, 255);

      final glowPaint = Paint()
        ..color = color.withAlpha(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

      canvas.drawCircle(center, pointRadius + glowRadius, glowPaint);
    }

    // Draw core point
    final corePaint = Paint()..color = color;
    canvas.drawCircle(center, pointRadius, corePaint);
  }
}

/// Chromatic aberration effect
class ChromaticAberrationEffect {
  final double amount;
  final double angle;

  const ChromaticAberrationEffect({
    this.amount = 2.0,
    this.angle = 0.0,
  });

  /// Get RGB offsets from center
  (Offset red, Offset green, Offset blue) getOffsets(Offset center) {
    if (amount <= 0) {
      return (Offset.zero, Offset.zero, Offset.zero);
    }

    final angleRad = angle * math.pi / 180;
    final dx = math.cos(angleRad) * amount;
    final dy = math.sin(angleRad) * amount;

    return (
      Offset(-dx, -dy),    // Red shifts one way
      Offset.zero,          // Green stays centered
      Offset(dx, dy),       // Blue shifts opposite
    );
  }

  /// Draw line with chromatic aberration
  void drawAberratedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Color color, {
    double strokeWidth = 2.0,
    double opacity = 0.4,
  }) {
    if (amount <= 0) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
      return;
    }

    final (redOffset, greenOffset, blueOffset) = getOffsets(Offset.zero);

    // Red channel
    final redPaint = Paint()
      ..color = Color.fromRGBO(255, 0, 0, opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;
    canvas.drawLine(p1 + redOffset, p2 + redOffset, redPaint);

    // Green channel (main color)
    final greenPaint = Paint()
      ..color = color.withOpacity(opacity * 2)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1 + greenOffset, p2 + greenOffset, greenPaint);

    // Blue channel
    final bluePaint = Paint()
      ..color = Color.fromRGBO(0, 0, 255, opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;
    canvas.drawLine(p1 + blueOffset, p2 + blueOffset, bluePaint);

    // Core line
    final corePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * 0.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, corePaint);
  }
}

/// Scanline overlay effect
class ScanlineEffect {
  final double intensity;
  final double frequency;
  final double speed;

  const ScanlineEffect({
    this.intensity = 0.3,
    this.frequency = 2.0,
    this.speed = 1.0,
  });

  /// Draw scanline overlay
  void draw(Canvas canvas, Size size, double time) {
    if (intensity <= 0) return;

    final paint = Paint()
      ..color = Colors.black.withOpacity(intensity)
      ..strokeWidth = 1.0;

    final lineSpacing = 100.0 / frequency;
    final offset = (time * speed * 50) % lineSpacing;

    for (double y = offset; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
}

/// Noise/grain overlay effect
class NoiseEffect {
  final double intensity;
  final double scale;

  NoiseEffect({
    this.intensity = 0.1,
    this.scale = 1.0,
  });

  /// Draw noise overlay
  void draw(Canvas canvas, Size size, double time) {
    if (intensity <= 0) return;

    // Seed based on time for animation
    final seed = (time * 10).floor();
    final rng = math.Random(seed);

    final paint = Paint()..style = PaintingStyle.fill;
    final dotSize = 2.0 * scale;
    final spacing = 4.0 * scale;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if (rng.nextDouble() < intensity) {
          final brightness = rng.nextDouble();
          paint.color = Colors.white.withOpacity(brightness * intensity * 0.5);
          canvas.drawRect(
            Rect.fromLTWH(x, y, dotSize, dotSize),
            paint,
          );
        }
      }
    }
  }
}

/// Vignette overlay effect
class VignetteEffect {
  final double intensity;
  final double radius;

  const VignetteEffect({
    this.intensity = 0.3,
    this.radius = 0.8,
  });

  /// Draw vignette overlay
  void draw(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(center.dx * center.dx + center.dy * center.dy);

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        maxRadius,
        [
          Colors.transparent,
          Colors.transparent,
          Colors.black.withOpacity(intensity),
        ],
        [0.0, radius, 1.0],
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }
}

/// Depth fog calculator
class DepthFogEffect {
  final double density;
  final Color fogColor;
  final double nearPlane;
  final double farPlane;

  const DepthFogEffect({
    this.density = 0.5,
    this.fogColor = const Color(0xFF0A0A1A),
    this.nearPlane = 5.0,
    this.farPlane = 20.0,
  });

  /// Calculate fog factor for a given depth (0 = no fog, 1 = full fog)
  double getFogFactor(double depth) {
    if (density <= 0) return 0.0;

    final normalizedDepth = ((depth - nearPlane) / (farPlane - nearPlane))
        .clamp(0.0, 1.0);

    // Exponential fog
    return (1.0 - math.exp(-density * normalizedDepth * 3)).clamp(0.0, 1.0);
  }

  /// Apply fog to a color based on depth
  Color applyFog(Color color, double depth) {
    final fogFactor = getFogFactor(depth);
    if (fogFactor <= 0) return color;

    return Color.lerp(color, fogColor, fogFactor)!;
  }
}

/// Glitch effect generator
class GlitchEffect {
  final double intensity;
  final double frequency;
  final math.Random _random = math.Random();

  double _lastGlitchTime = 0;
  double _glitchDuration = 0;
  List<GlitchSlice>? _currentGlitch;

  GlitchEffect({
    this.intensity = 0.1,
    this.frequency = 0.1,
  });

  /// Update glitch state
  void update(double time) {
    if (intensity <= 0) return;

    // Check if we should start a new glitch
    if (_currentGlitch == null) {
      if (_random.nextDouble() < frequency * 0.016) {
        // Roughly 60fps check
        _startGlitch(time);
      }
    } else {
      // Check if glitch should end
      if (time - _lastGlitchTime > _glitchDuration) {
        _currentGlitch = null;
      }
    }
  }

  void _startGlitch(double time) {
    _lastGlitchTime = time;
    _glitchDuration = 0.05 + _random.nextDouble() * 0.15;

    final sliceCount = 3 + _random.nextInt(5);
    _currentGlitch = List.generate(sliceCount, (i) {
      return GlitchSlice(
        yStart: _random.nextDouble(),
        height: 0.02 + _random.nextDouble() * 0.1,
        xOffset: (_random.nextDouble() - 0.5) * intensity * 50,
        colorShift: _random.nextDouble() * intensity,
      );
    });
  }

  /// Get current glitch slices (null if no active glitch)
  List<GlitchSlice>? get currentGlitch => _currentGlitch;
}

/// A horizontal slice affected by glitch
class GlitchSlice {
  final double yStart;    // 0-1 normalized y position
  final double height;    // 0-1 normalized height
  final double xOffset;   // Pixel offset
  final double colorShift; // Color aberration amount

  const GlitchSlice({
    required this.yStart,
    required this.height,
    required this.xOffset,
    required this.colorShift,
  });
}

/// Motion trail system for vertex persistence
class MotionTrailSystem {
  final int maxTrailLength;
  final double fadeRate;

  final List<List<(Offset, double)>> _trails = [];

  MotionTrailSystem({
    this.maxTrailLength = 5,
    this.fadeRate = 0.7,
  });

  /// Record current vertex positions
  void recordFrame(List<Offset> vertices) {
    if (_trails.length < vertices.length) {
      _trails.addAll(
        List.generate(
          vertices.length - _trails.length,
          (_) => <(Offset, double)>[],
        ),
      );
    }

    for (int i = 0; i < vertices.length && i < _trails.length; i++) {
      _trails[i].add((vertices[i], 1.0));

      // Fade and trim old positions
      _trails[i] = _trails[i]
          .map((e) => (e.$1, e.$2 * fadeRate))
          .where((e) => e.$2 > 0.1)
          .toList();

      // Limit trail length
      while (_trails[i].length > maxTrailLength) {
        _trails[i].removeAt(0);
      }
    }
  }

  /// Get trail for a vertex
  List<(Offset, double)> getTrail(int vertexIndex) {
    if (vertexIndex >= _trails.length) return const [];
    return _trails[vertexIndex];
  }

  /// Draw all trails
  void drawTrails(Canvas canvas, Color color, {double strokeWidth = 1.0}) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final trail in _trails) {
      if (trail.length < 2) continue;

      for (int i = 1; i < trail.length; i++) {
        final (p1, alpha1) = trail[i - 1];
        final (p2, alpha2) = trail[i];
        final avgAlpha = (alpha1 + alpha2) / 2;

        paint.color = color.withOpacity(avgAlpha * 0.5);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  /// Clear all trails
  void clear() {
    for (final trail in _trails) {
      trail.clear();
    }
  }
}

/// Complete post-processing pipeline
class PostProcessingPipeline {
  final PostProcessingConfig config;

  late final GlowEffectPainter _glowPainter;
  late final ChromaticAberrationEffect _chromaticAberration;
  late final ScanlineEffect _scanlines;
  late final NoiseEffect _noise;
  late final VignetteEffect _vignette;
  late final DepthFogEffect _depthFog;
  late final GlitchEffect _glitch;
  late final MotionTrailSystem _motionTrails;

  PostProcessingPipeline(this.config) {
    _glowPainter = GlowEffectPainter(
      intensity: config.glowIntensity,
      radius: config.glowRadius,
      passes: config.glowPasses,
    );
    _chromaticAberration = ChromaticAberrationEffect(
      amount: config.rgbSplitAmount,
      angle: config.rgbSplitAngle,
    );
    _scanlines = ScanlineEffect(
      intensity: config.scanlinesEnabled ? config.scanlineIntensity : 0,
      frequency: config.scanlineFrequency,
      speed: config.scanlineSpeed,
    );
    _noise = NoiseEffect(
      intensity: config.noiseIntensity,
      scale: config.noiseScale,
    );
    _vignette = VignetteEffect(
      intensity: config.vignetteIntensity,
      radius: config.vignetteRadius,
    );
    _depthFog = DepthFogEffect(
      density: config.fogDensity,
      fogColor: config.fogColor,
      nearPlane: config.fogStart,
      farPlane: config.fogEnd,
    );
    _glitch = GlitchEffect(
      intensity: config.glitchIntensity,
      frequency: config.glitchFrequency,
    );
    _motionTrails = MotionTrailSystem(
      maxTrailLength: config.trailLength,
      fadeRate: 1.0 - config.trailIntensity,
    );
  }

  // Expose effects
  GlowEffectPainter get glow => _glowPainter;
  ChromaticAberrationEffect get chromatic => _chromaticAberration;
  DepthFogEffect get fog => _depthFog;
  MotionTrailSystem get trails => _motionTrails;
  GlitchEffect get glitch => _glitch;

  /// Update time-based effects
  void update(double time) {
    _glitch.update(time);
  }

  /// Draw overlay effects (call after main render)
  void drawOverlays(Canvas canvas, Size size, double time) {
    if (config.scanlinesEnabled) {
      _scanlines.draw(canvas, size, time);
    }
    if (config.noiseIntensity > 0) {
      _noise.draw(canvas, size, config.animatedNoise ? time : 0);
    }
    if (config.vignetteIntensity > 0) {
      _vignette.draw(canvas, size);
    }
  }

  /// Apply depth fog to a color
  Color applyDepthFog(Color color, double depth) {
    return _depthFog.applyFog(color, depth);
  }
}
