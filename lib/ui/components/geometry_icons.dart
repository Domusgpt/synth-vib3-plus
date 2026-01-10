/**
 * Geometry Icons
 *
 * CustomPainter-based icons for the 8 base geometries.
 * No emojis - pure vector graphics that scale and color properly.
 *
 * 0: Tetrahedron (Fundamental) - Simple triangle
 * 1: Hypercube (Complex) - Nested squares
 * 2: Sphere (Smooth) - Circle with gradient suggestion
 * 3: Torus (Cyclic) - Ring/donut shape
 * 4: Klein Bottle (Twisted) - Figure-8/infinity
 * 5: Fractal (Recursive) - Nested triangles
 * 6: Wave (Flowing) - Sine wave
 * 7: Crystal (Sharp) - Diamond/star burst
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Icon widget that renders a geometry type
class GeometryIcon extends StatelessWidget {
  final int geometryIndex; // 0-7 base geometry
  final Color color;
  final double size;
  final bool isActive;

  const GeometryIcon({
    super.key,
    required this.geometryIndex,
    required this.color,
    this.size = 24.0,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GeometryIconPainter(
          geometryIndex: geometryIndex % 8,
          color: color,
          isActive: isActive,
        ),
      ),
    );
  }
}

class _GeometryIconPainter extends CustomPainter {
  final int geometryIndex;
  final Color color;
  final bool isActive;

  _GeometryIconPainter({
    required this.geometryIndex,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = isActive ? 1.5 : 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    switch (geometryIndex) {
      case 0:
        _drawTetrahedron(canvas, center, radius, paint);
        break;
      case 1:
        _drawHypercube(canvas, center, radius, paint);
        break;
      case 2:
        _drawSphere(canvas, center, radius, paint);
        break;
      case 3:
        _drawTorus(canvas, center, radius, paint);
        break;
      case 4:
        _drawKleinBottle(canvas, center, radius, paint);
        break;
      case 5:
        _drawFractal(canvas, center, radius, paint);
        break;
      case 6:
        _drawWave(canvas, center, radius, paint);
        break;
      case 7:
        _drawCrystal(canvas, center, radius, paint);
        break;
    }
  }

  /// 0: Tetrahedron - Simple equilateral triangle
  void _drawTetrahedron(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 1: Hypercube - Two nested squares with connecting lines
  void _drawHypercube(Canvas canvas, Offset center, double radius, Paint paint) {
    final outer = radius;
    final inner = radius * 0.5;

    // Outer square (rotated 45deg)
    final outerPath = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + math.pi / 4;
      final point = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );
      if (i == 0) {
        outerPath.moveTo(point.dx, point.dy);
      } else {
        outerPath.lineTo(point.dx, point.dy);
      }
    }
    outerPath.close();

    // Inner square (aligned)
    final innerPath = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final point = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );
      if (i == 0) {
        innerPath.moveTo(point.dx, point.dy);
      } else {
        innerPath.lineTo(point.dx, point.dy);
      }
    }
    innerPath.close();

    canvas.drawPath(outerPath, paint);
    canvas.drawPath(innerPath, paint);

    // Connecting lines (only in stroke mode for clarity)
    if (!isActive) {
      final thinPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      for (int i = 0; i < 4; i++) {
        final outerAngle = (i * math.pi / 2) + math.pi / 4;
        final innerAngle = (i * math.pi / 2);
        final outerPoint = Offset(
          center.dx + outer * math.cos(outerAngle),
          center.dy + outer * math.sin(outerAngle),
        );
        final innerPoint = Offset(
          center.dx + inner * math.cos(innerAngle),
          center.dy + inner * math.sin(innerAngle),
        );
        canvas.drawLine(outerPoint, innerPoint, thinPaint);
      }
    }
  }

  /// 2: Sphere - Circle with inner arcs suggesting 3D
  void _drawSphere(Canvas canvas, Offset center, double radius, Paint paint) {
    // Main circle
    canvas.drawCircle(center, radius, paint);

    // Inner ellipse arcs (suggesting 3D sphere)
    if (!isActive) {
      final arcPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      // Horizontal ellipse
      canvas.drawArc(
        Rect.fromCenter(center: center, width: radius * 1.6, height: radius * 0.6),
        0, math.pi, false, arcPaint,
      );

      // Vertical ellipse
      canvas.drawArc(
        Rect.fromCenter(center: center, width: radius * 0.6, height: radius * 1.6),
        math.pi / 2, math.pi, false, arcPaint,
      );
    }
  }

  /// 3: Torus - Donut/ring shape
  void _drawTorus(Canvas canvas, Offset center, double radius, Paint paint) {
    final outer = radius;
    final inner = radius * 0.45;

    // Outer circle
    canvas.drawCircle(center, outer, paint);

    // Inner circle (hole) - always stroke to show the hole
    final holePaint = Paint()
      ..color = isActive ? color.withOpacity(0.3) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth;
    canvas.drawCircle(center, inner, holePaint);

    // If filled, draw the hole as background color
    if (isActive) {
      final cutoutPaint = Paint()
        ..color = Colors.black.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, inner - 1, cutoutPaint);
    }
  }

  /// 4: Klein Bottle - Figure-8 / infinity symbol
  void _drawKleinBottle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    // Figure-8 using bezier curves
    final w = radius * 1.2;
    final h = radius * 0.7;

    // Left loop
    path.moveTo(center.dx, center.dy);
    path.cubicTo(
      center.dx - w, center.dy - h,
      center.dx - w, center.dy + h,
      center.dx, center.dy,
    );

    // Right loop (crossed)
    path.cubicTo(
      center.dx + w, center.dy + h,
      center.dx + w, center.dy - h,
      center.dx, center.dy,
    );

    canvas.drawPath(path, paint);
  }

  /// 5: Fractal - Sierpinski-style nested triangles
  void _drawFractal(Canvas canvas, Offset center, double radius, Paint paint) {
    void drawTriangle(Offset c, double r, int depth) {
      if (depth <= 0 || r < 3) return;

      final path = Path();
      for (int i = 0; i < 3; i++) {
        final angle = (i * 2 * math.pi / 3) - math.pi / 2;
        final point = Offset(
          c.dx + r * math.cos(angle),
          c.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);

      // Recurse for smaller triangles
      if (depth > 1) {
        for (int i = 0; i < 3; i++) {
          final angle = (i * 2 * math.pi / 3) - math.pi / 2;
          final newCenter = Offset(
            c.dx + r * 0.5 * math.cos(angle),
            c.dy + r * 0.5 * math.sin(angle),
          );
          drawTriangle(newCenter, r * 0.4, depth - 1);
        }
      }
    }

    drawTriangle(center, radius, isActive ? 2 : 3);
  }

  /// 6: Wave - Sine wave
  void _drawWave(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final amplitude = radius * 0.6;
    final wavelength = radius * 2;

    path.moveTo(center.dx - radius, center.dy);

    for (double x = -radius; x <= radius; x += 1) {
      final y = amplitude * math.sin((x / wavelength) * 2 * math.pi * 1.5);
      if (x == -radius) {
        path.moveTo(center.dx + x, center.dy + y);
      } else {
        path.lineTo(center.dx + x, center.dy + y);
      }
    }

    canvas.drawPath(path, paint);
  }

  /// 7: Crystal - Diamond/star burst
  void _drawCrystal(Canvas canvas, Offset center, double radius, Paint paint) {
    // 8-pointed star
    final path = Path();
    final outerRadius = radius;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < 8; i++) {
      final isOuter = i % 2 == 0;
      final r = isOuter ? outerRadius : innerRadius;
      final angle = (i * math.pi / 4) - math.pi / 2;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GeometryIconPainter oldDelegate) {
    return geometryIndex != oldDelegate.geometryIndex ||
           color != oldDelegate.color ||
           isActive != oldDelegate.isActive;
  }
}

/// Synthesis method icons (DIRECT, FM, RING)
class SynthesisMethodIcon extends StatelessWidget {
  final int methodIndex; // 0=Direct, 1=FM, 2=Ring
  final Color color;
  final double size;
  final bool isActive;

  const SynthesisMethodIcon({
    super.key,
    required this.methodIndex,
    required this.color,
    this.size = 24.0,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SynthesisMethodPainter(
          methodIndex: methodIndex,
          color: color,
          isActive: isActive,
        ),
      ),
    );
  }
}

class _SynthesisMethodPainter extends CustomPainter {
  final int methodIndex;
  final Color color;
  final bool isActive;

  _SynthesisMethodPainter({
    required this.methodIndex,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    switch (methodIndex) {
      case 0:
        _drawDirect(canvas, center, radius, paint);
        break;
      case 1:
        _drawFM(canvas, center, radius, paint);
        break;
      case 2:
        _drawRing(canvas, center, radius, paint);
        break;
    }
  }

  /// Direct synthesis - Simple sine wave
  void _drawDirect(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    for (double x = -radius; x <= radius; x += 1) {
      final y = radius * 0.7 * math.sin((x / radius) * math.pi);
      if (x == -radius) {
        path.moveTo(center.dx + x, center.dy - y);
      } else {
        path.lineTo(center.dx + x, center.dy - y);
      }
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 2.5 : 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  /// FM synthesis - Carrier + modulator waves
  void _drawFM(Canvas canvas, Offset center, double radius, Paint paint) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 2.0 : 1.2
      ..strokeCap = StrokeCap.round;

    // Modulated wave (FM result)
    final path = Path();
    for (double x = -radius; x <= radius; x += 0.5) {
      final modulator = math.sin((x / radius) * math.pi * 3) * 0.3;
      final carrier = math.sin((x / radius) * math.pi * 1.5 + modulator * 2);
      final y = radius * 0.6 * carrier;
      if (x == -radius) {
        path.moveTo(center.dx + x, center.dy - y);
      } else {
        path.lineTo(center.dx + x, center.dy - y);
      }
    }
    canvas.drawPath(path, strokePaint);
  }

  /// Ring modulation - Two overlapping circles
  void _drawRing(Canvas canvas, Offset center, double radius, Paint paint) {
    final offset = radius * 0.4;

    // Left circle
    canvas.drawCircle(
      Offset(center.dx - offset, center.dy),
      radius * 0.7,
      paint,
    );

    // Right circle
    canvas.drawCircle(
      Offset(center.dx + offset, center.dy),
      radius * 0.7,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SynthesisMethodPainter oldDelegate) {
    return methodIndex != oldDelegate.methodIndex ||
           color != oldDelegate.color ||
           isActive != oldDelegate.isActive;
  }
}

/// Visual system icons (Quantum, Faceted, Holographic)
class SystemIcon extends StatelessWidget {
  final String systemName; // quantum, faceted, holographic
  final Color color;
  final double size;
  final bool isActive;

  const SystemIcon({
    super.key,
    required this.systemName,
    required this.color,
    this.size = 24.0,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SystemIconPainter(
          systemName: systemName,
          color: color,
          isActive: isActive,
        ),
      ),
    );
  }
}

class _SystemIconPainter extends CustomPainter {
  final String systemName;
  final Color color;
  final bool isActive;

  _SystemIconPainter({
    required this.systemName,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    switch (systemName.toLowerCase()) {
      case 'quantum':
        _drawQuantum(canvas, center, radius, paint);
        break;
      case 'faceted':
        _drawFaceted(canvas, center, radius, paint);
        break;
      case 'holographic':
        _drawHolographic(canvas, center, radius, paint);
        break;
    }
  }

  /// Quantum - Electron orbits / atom style
  void _drawQuantum(Canvas canvas, Offset center, double radius, Paint paint) {
    // Central dot
    canvas.drawCircle(center, radius * 0.2, paint);

    // Orbital ellipses
    final orbitPaint = Paint()
      ..color = color.withOpacity(isActive ? 0.8 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal orbit
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.6),
      orbitPaint,
    );

    // Tilted orbit
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.6),
      orbitPaint,
    );
    canvas.restore();

    // Another tilted orbit
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.6),
      orbitPaint,
    );
    canvas.restore();
  }

  /// Faceted - Geometric crystal/gem shape
  void _drawFaceted(Canvas canvas, Offset center, double radius, Paint paint) {
    // Hexagon with internal facets
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Internal facet lines
    if (!isActive) {
      final facetPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      for (int i = 0; i < 3; i++) {
        final angle1 = (i * math.pi / 3) - math.pi / 2;
        final angle2 = angle1 + math.pi;
        canvas.drawLine(
          Offset(center.dx + radius * math.cos(angle1), center.dy + radius * math.sin(angle1)),
          Offset(center.dx + radius * math.cos(angle2), center.dy + radius * math.sin(angle2)),
          facetPaint,
        );
      }
    }
  }

  /// Holographic - Layered/prismatic effect
  void _drawHolographic(Canvas canvas, Offset center, double radius, Paint paint) {
    // Multiple offset circles suggesting depth/layers
    for (int i = 2; i >= 0; i--) {
      final offset = i * 3.0;
      final layerPaint = Paint()
        ..color = color.withOpacity(isActive ? (1.0 - i * 0.25) : (0.8 - i * 0.2))
        ..style = i == 0 && isActive ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(
        Offset(center.dx - offset, center.dy - offset),
        radius * (1.0 - i * 0.15),
        layerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SystemIconPainter oldDelegate) {
    return systemName != oldDelegate.systemName ||
           color != oldDelegate.color ||
           isActive != oldDelegate.isActive;
  }
}
