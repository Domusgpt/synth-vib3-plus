/**
 * Native Flutter VIB34D Quantum Holographic Visualizer
 *
 * Pure Dart/Flutter implementation using CustomPainter
 * No WebView, no JavaScript - just native Canvas rendering
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Native VIB34D visualizer using Flutter's Canvas API
class NativeVIB34DPainter extends CustomPainter {
  final double time;
  final double bass;
  final double mid;
  final double high;
  final double energy;

  NativeVIB34DPainter({
    required this.time,
    this.bass = 0.0,
    this.mid = 0.0,
    this.high = 0.0,
    this.energy = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.3;

    // Clear background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // Draw 5 holographic layers
    _drawBackgroundLayer(canvas, centerX, centerY, radius);
    _drawShadowLayer(canvas, centerX, centerY, radius);
    _drawContentLayer(canvas, centerX, centerY, radius);
    _drawHighlightLayer(canvas, centerX, centerY, radius);
    _drawAccentLayer(canvas, centerX, centerY, radius);
  }

  /// Layer 1: Background geometric structure
  void _drawBackgroundLayer(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1 + bass * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Rotating octahedron wireframe
    final vertices = _generate4DPolytopeVertices(8, time * 0.5);
    _drawWireframe(canvas, cx, cy, radius * 0.8, vertices, paint);
  }

  /// Layer 2: Shadow depth field
  void _drawShadowLayer(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.15 + mid * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Pulsing icosahedron
    final vertices = _generate4DPolytopeVertices(12, time * 0.7 + 0.5);
    _drawWireframe(canvas, cx, cy, radius * 0.9, vertices, paint);
  }

  /// Layer 3: Main content (tesseract/hypercube)
  void _drawContentLayer(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.4 + energy * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 4D hypercube projection
    final vertices = _generateHypercubeVertices(time);
    _drawHypercubeEdges(canvas, cx, cy, radius, vertices, paint);
  }

  /// Layer 4: Highlight particles
  void _drawHighlightLayer(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6 + high * 0.3)
      ..style = PaintingStyle.fill;

    // Rotating particles around vertices
    final vertices = _generate4DPolytopeVertices(20, time * 1.2);
    for (var vertex in vertices) {
      final projected = _project4Dto2D(vertex);
      final x = cx + projected.x * radius;
      final y = cy + projected.y * radius;
      canvas.drawCircle(
        Offset(x, y),
        2.0 + bass * 3.0,
        paint,
      );
    }
  }

  /// Layer 5: Accent glitch effects
  void _drawAccentLayer(Canvas canvas, double cx, double cy, double radius) {
    // RGB chromatic aberration effect
    final colors = [
      Colors.red.withOpacity(0.3),
      Colors.green.withOpacity(0.3),
      Colors.blue.withOpacity(0.3),
    ];

    for (int i = 0; i < 3; i++) {
      final offset = (i - 1) * 2.0 * (1.0 + energy * 2.0);
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final vertices = _generate4DPolytopeVertices(16, time * 1.5);
      _drawWireframe(canvas, cx + offset, cy, radius * 1.1, vertices, paint);
    }
  }

  /// Generate 4D polytope vertices
  List<vm.Vector4> _generate4DPolytopeVertices(int count, double angle) {
    final vertices = <vm.Vector4>[];
    for (int i = 0; i < count; i++) {
      final theta = (i / count) * math.pi * 2;
      final phi = math.sin(angle + theta * 2) * 0.5;

      vertices.add(vm.Vector4(
        math.cos(theta) * math.cos(phi),
        math.sin(theta) * math.cos(phi),
        math.sin(phi),
        math.cos(angle + theta),
      ));
    }
    return vertices;
  }

  /// Generate 4D hypercube vertices
  List<vm.Vector4> _generateHypercubeVertices(double angle) {
    final vertices = <vm.Vector4>[];

    // 16 vertices of a tesseract
    for (int i = 0; i < 16; i++) {
      final x = (i & 1) * 2.0 - 1.0;
      final y = ((i >> 1) & 1) * 2.0 - 1.0;
      final z = ((i >> 2) & 1) * 2.0 - 1.0;
      final w = ((i >> 3) & 1) * 2.0 - 1.0;

      vertices.add(vm.Vector4(x, y, z, w));
    }

    // Rotate in 4D
    return vertices.map((v) => _rotate4D(v, angle)).toList();
  }

  /// Rotate 4D vector
  vm.Vector4 _rotate4D(vm.Vector4 v, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    return vm.Vector4(
      v.x * c - v.w * s,
      v.y,
      v.z,
      v.x * s + v.w * c,
    );
  }

  /// Project 4D to 2D
  vm.Vector2 _project4Dto2D(vm.Vector4 v) {
    final distance = 2.0;
    final w = 1.0 / (distance - v.w);

    return vm.Vector2(v.x * w, v.y * w);
  }

  /// Draw wireframe from vertices
  void _drawWireframe(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    List<vm.Vector4> vertices,
    Paint paint,
  ) {
    // Connect adjacent vertices
    for (int i = 0; i < vertices.length; i++) {
      final next = (i + 1) % vertices.length;

      final p1 = _project4Dto2D(vertices[i]);
      final p2 = _project4Dto2D(vertices[next]);

      canvas.drawLine(
        Offset(cx + p1.x * radius, cy + p1.y * radius),
        Offset(cx + p2.x * radius, cy + p2.y * radius),
        paint,
      );
    }
  }

  /// Draw hypercube edges
  void _drawHypercubeEdges(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    List<vm.Vector4> vertices,
    Paint paint,
  ) {
    // Connect hypercube edges (32 edges in tesseract)
    final edges = [
      // Inner cube
      [0, 1], [1, 3], [3, 2], [2, 0],
      [4, 5], [5, 7], [7, 6], [6, 4],
      [0, 4], [1, 5], [2, 6], [3, 7],
      // Outer cube
      [8, 9], [9, 11], [11, 10], [10, 8],
      [12, 13], [13, 15], [15, 14], [14, 12],
      [8, 12], [9, 13], [10, 14], [11, 15],
      // Connections between cubes
      [0, 8], [1, 9], [2, 10], [3, 11],
      [4, 12], [5, 13], [6, 14], [7, 15],
    ];

    for (final edge in edges) {
      final p1 = _project4Dto2D(vertices[edge[0]]);
      final p2 = _project4Dto2D(vertices[edge[1]]);

      canvas.drawLine(
        Offset(cx + p1.x * radius, cy + p1.y * radius),
        Offset(cx + p2.x * radius, cy + p2.y * radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(NativeVIB34DPainter oldDelegate) {
    return time != oldDelegate.time ||
        bass != oldDelegate.bass ||
        mid != oldDelegate.mid ||
        high != oldDelegate.high ||
        energy != oldDelegate.energy;
  }
}

/// Widget that displays native VIB34D visualization
class NativeVIB34DWidget extends StatefulWidget {
  const NativeVIB34DWidget({Key? key}) : super(key: key);

  @override
  State<NativeVIB34DWidget> createState() => _NativeVIB34DWidgetState();
}

class _NativeVIB34DWidgetState extends State<NativeVIB34DWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double bass = 0.5;
  double mid = 0.5;
  double high = 0.5;
  double energy = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1), // Continuous animation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: NativeVIB34DPainter(
            time: _controller.value * math.pi * 2,
            bass: bass,
            mid: mid,
            high: high,
            energy: energy,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
