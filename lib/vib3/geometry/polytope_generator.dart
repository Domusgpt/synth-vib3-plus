// 4D Polytope Generator
//
// Generates vertices and edges for all 8 base geometries
// Each geometry has unique 4D structure and connectivity
//
// A Paul Phillips Manifestation
//
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' as vm;

/// Edge definition (pair of vertex indices)
class Edge {
  final int v1;
  final int v2;

  const Edge(this.v1, this.v2);

  @override
  String toString() => 'Edge($v1, $v2)';
}

/// Complete polytope geometry
class Polytope {
  final List<vm.Vector4> vertices;
  final List<Edge> edges;
  final String name;

  const Polytope({
    required this.vertices,
    required this.edges,
    required this.name,
  });

  int get vertexCount => vertices.length;
  int get edgeCount => edges.length;

  @override
  String toString() => 'Polytope($name: $vertexCount vertices, $edgeCount edges)';
}

/// Generates 4D polytope geometries
class PolytopeGenerator {
  /// Generate polytope for base geometry index
  static Polytope generateBase(int baseIndex, {double scale = 1.0}) {
    switch (baseIndex) {
      case 0:
        return _generateTetrahedron(scale);
      case 1:
        return _generateHypercube(scale);
      case 2:
        return _generateSphere(scale);
      case 3:
        return _generateTorus(scale);
      case 4:
        return _generateKleinBottle(scale);
      case 5:
        return _generateFractal(scale);
      case 6:
        return _generateWave(scale);
      case 7:
        return _generateCrystal(scale);
      default:
        return _generateHypercube(scale);
    }
  }

  /// 0: Tetrahedron (5-cell / 4-simplex)
  /// Fundamental 4D polytope with 5 vertices
  static Polytope _generateTetrahedron(double scale) {
    // 5-cell vertices in 4D
    final vertices = [
      vm.Vector4(1, 1, 1, -1 / math.sqrt(5)) * scale,
      vm.Vector4(1, -1, -1, -1 / math.sqrt(5)) * scale,
      vm.Vector4(-1, 1, -1, -1 / math.sqrt(5)) * scale,
      vm.Vector4(-1, -1, 1, -1 / math.sqrt(5)) * scale,
      vm.Vector4(0, 0, 0, math.sqrt(5) - 1 / math.sqrt(5)) * scale,
    ];

    // Connect all vertices (complete graph)
    final edges = <Edge>[];
    for (int i = 0; i < vertices.length; i++) {
      for (int j = i + 1; j < vertices.length; j++) {
        edges.add(Edge(i, j));
      }
    }

    return Polytope(vertices: vertices, edges: edges, name: 'Tetrahedron');
  }

  /// 1: Hypercube (Tesseract / 8-cell)
  /// 4D cube with 16 vertices
  static Polytope _generateHypercube(double scale) {
    final vertices = <vm.Vector4>[];

    // 16 vertices of tesseract
    for (int i = 0; i < 16; i++) {
      final x = (i & 1) * 2.0 - 1.0;
      final y = ((i >> 1) & 1) * 2.0 - 1.0;
      final z = ((i >> 2) & 1) * 2.0 - 1.0;
      final w = ((i >> 3) & 1) * 2.0 - 1.0;
      vertices.add(vm.Vector4(x, y, z, w) * scale);
    }

    // 32 edges (8 per dimension)
    final edges = <Edge>[];
    for (int i = 0; i < 16; i++) {
      // Connect to neighbors in each dimension
      if ((i & 1) == 0) edges.add(Edge(i, i + 1)); // X edges
      if ((i & 2) == 0) edges.add(Edge(i, i + 2)); // Y edges
      if ((i & 4) == 0) edges.add(Edge(i, i + 4)); // Z edges
      if ((i & 8) == 0) edges.add(Edge(i, i + 8)); // W edges
    }

    return Polytope(vertices: vertices, edges: edges, name: 'Hypercube');
  }

  /// 2: Sphere (4D hypersphere approximation)
  /// Fibonacci sphere on 4D hypersurface
  static Polytope _generateSphere(double scale, {int subdivisions = 32}) {
    final vertices = <vm.Vector4>[];
    final goldenRatio = (1.0 + math.sqrt(5.0)) / 2.0;

    // Generate points on 4D hypersphere using Fibonacci lattice
    for (int i = 0; i < subdivisions; i++) {
      final theta = 2.0 * math.pi * i / goldenRatio;
      final phi = math.acos(1.0 - 2.0 * (i + 0.5) / subdivisions);
      final psi = 2.0 * math.pi * i / (subdivisions / 4.0);

      final x = math.sin(phi) * math.cos(theta);
      final y = math.sin(phi) * math.sin(theta);
      final z = math.cos(phi) * math.cos(psi);
      final w = math.cos(phi) * math.sin(psi);

      vertices.add(vm.Vector4(x, y, z, w) * scale);
    }

    // Connect nearby vertices
    final edges = <Edge>[];
    for (int i = 0; i < vertices.length; i++) {
      final next = (i + 1) % vertices.length;
      edges.add(Edge(i, next));

      // Add cross-connections for better structure
      if (i + 4 < vertices.length) {
        edges.add(Edge(i, i + 4));
      }
    }

    return Polytope(vertices: vertices, edges: edges, name: 'Sphere');
  }

  /// 3: Torus (4D hypertorus)
  /// Cyclic structure with double-rotation
  static Polytope _generateTorus(double scale,
      {int majorSubdivisions = 16, int minorSubdivisions = 8}) {
    final vertices = <vm.Vector4>[];
    final majorRadius = 1.0;
    final minorRadius = 0.4;

    // Generate torus vertices
    for (int i = 0; i < majorSubdivisions; i++) {
      final u = 2.0 * math.pi * i / majorSubdivisions;
      for (int j = 0; j < minorSubdivisions; j++) {
        final v = 2.0 * math.pi * j / minorSubdivisions;

        final x = (majorRadius + minorRadius * math.cos(v)) * math.cos(u);
        final y = (majorRadius + minorRadius * math.cos(v)) * math.sin(u);
        final z = minorRadius * math.sin(v) * math.cos(u * 0.5);
        final w = minorRadius * math.sin(v) * math.sin(u * 0.5);

        vertices.add(vm.Vector4(x, y, z, w) * scale);
      }
    }

    // Connect torus loops
    final edges = <Edge>[];
    for (int i = 0; i < majorSubdivisions; i++) {
      for (int j = 0; j < minorSubdivisions; j++) {
        final current = i * minorSubdivisions + j;
        final nextJ = i * minorSubdivisions + ((j + 1) % minorSubdivisions);
        final nextI = ((i + 1) % majorSubdivisions) * minorSubdivisions + j;

        edges.add(Edge(current, nextJ));
        edges.add(Edge(current, nextI));
      }
    }

    return Polytope(vertices: vertices, edges: edges, name: 'Torus');
  }

  /// 4: Klein Bottle (4D non-orientable surface)
  /// Twisted topology in 4D space
  static Polytope _generateKleinBottle(double scale,
      {int uSubdivisions = 16, int vSubdivisions = 8}) {
    final vertices = <vm.Vector4>[];
    final r = 2.0;

    for (int i = 0; i < uSubdivisions; i++) {
      final u = 2.0 * math.pi * i / uSubdivisions;
      for (int j = 0; j < vSubdivisions; j++) {
        final v = 2.0 * math.pi * j / vSubdivisions;

        // Klein bottle parametric equations in 4D
        final x = (r + math.cos(u / 2) * math.sin(v) - math.sin(u / 2) * math.sin(2 * v)) *
            math.cos(u);
        final y = (r + math.cos(u / 2) * math.sin(v) - math.sin(u / 2) * math.sin(2 * v)) *
            math.sin(u);
        final z = math.sin(u / 2) * math.sin(v) + math.cos(u / 2) * math.sin(2 * v);
        final w = math.cos(v) * 0.5;

        vertices.add(vm.Vector4(x, y, z, w) * scale * 0.3);
      }
    }

    // Connect with twisted topology
    final edges = <Edge>[];
    for (int i = 0; i < uSubdivisions; i++) {
      for (int j = 0; j < vSubdivisions; j++) {
        final current = i * vSubdivisions + j;
        final nextJ = i * vSubdivisions + ((j + 1) % vSubdivisions);
        final nextI = ((i + 1) % uSubdivisions) * vSubdivisions + j;

        edges.add(Edge(current, nextJ));
        edges.add(Edge(current, nextI));
      }
    }

    return Polytope(vertices: vertices, edges: edges, name: 'Klein Bottle');
  }

  /// 5: Fractal (4D recursive structure)
  /// Self-similar pattern at multiple scales
  static Polytope _generateFractal(double scale, {int iterations = 3}) {
    final vertices = <vm.Vector4>[];
    final edges = <Edge>[];

    // Start with tetrahedron
    _addFractalIteration(vertices, edges, vm.Vector4(0, 0, 0, 0), scale, iterations);

    return Polytope(vertices: vertices, edges: edges, name: 'Fractal');
  }

  static void _addFractalIteration(
    List<vm.Vector4> vertices,
    List<Edge> edges,
    vm.Vector4 center,
    double scale,
    int depth,
  ) {
    if (depth == 0) {
      // Add single vertex
      vertices.add(center);
      return;
    }

    // Add vertices in 4D cross pattern
    final startIdx = vertices.length;
    final offsets = [
      vm.Vector4(1, 0, 0, 0),
      vm.Vector4(-1, 0, 0, 0),
      vm.Vector4(0, 1, 0, 0),
      vm.Vector4(0, -1, 0, 0),
      vm.Vector4(0, 0, 1, 0),
      vm.Vector4(0, 0, -1, 0),
      vm.Vector4(0, 0, 0, 1),
      vm.Vector4(0, 0, 0, -1),
    ];

    for (final offset in offsets) {
      final newCenter = center + offset * scale;
      vertices.add(newCenter);

      // Recurse with smaller scale
      if (depth > 1) {
        _addFractalIteration(vertices, edges, newCenter, scale * 0.5, depth - 1);
      }
    }

    // Connect center to all branches
    for (int i = 0; i < offsets.length; i++) {
      if (startIdx > 0) {
        edges.add(Edge(startIdx - 1, startIdx + i));
      }
    }
  }

  /// 6: Wave (4D sinusoidal pattern)
  /// Flowing, sweeping structure
  static Polytope _generateWave(double scale, {int subdivisions = 24}) {
    final vertices = <vm.Vector4>[];

    // Generate wave pattern
    for (int i = 0; i < subdivisions; i++) {
      final t = 2.0 * math.pi * i / subdivisions;

      for (int j = 0; j < subdivisions ~/ 2; j++) {
        final s = math.pi * j / (subdivisions ~/ 2);

        final x = math.cos(t) * math.sin(s);
        final y = math.sin(t) * math.sin(s);
        final z = math.cos(s);
        final w = math.sin(2 * t) * 0.5;

        vertices.add(vm.Vector4(x, y, z, w) * scale);
      }
    }

    // Connect in wave pattern
    final edges = <Edge>[];
    final rowSize = subdivisions ~/ 2;
    for (int i = 0; i < subdivisions; i++) {
      for (int j = 0; j < rowSize; j++) {
        final current = i * rowSize + j;
        if (j < rowSize - 1) {
          edges.add(Edge(current, current + 1));
        }
        final nextRow = ((i + 1) % subdivisions) * rowSize + j;
        edges.add(Edge(current, nextRow));
      }
    }

    return Polytope(vertices: vertices, edges: edges, name: 'Wave');
  }

  /// 7: Crystal (4D crystalline structure)
  /// Sharp, geometric lattice
  static Polytope _generateCrystal(double scale) {
    final vertices = <vm.Vector4>[];
    final edges = <Edge>[];

    // 24-cell: unique 4D regular polytope
    // 24 vertices at unit distance from origin

    // Generate vertices (24-cell has octahedral symmetry in each 3D slice)
    // Coordinate permutations: (±1, ±1, 0, 0) and all permutations
    final coords = [
      [1, 1, 0, 0],
      [1, -1, 0, 0],
      [-1, 1, 0, 0],
      [-1, -1, 0, 0],
      [1, 0, 1, 0],
      [1, 0, -1, 0],
      [-1, 0, 1, 0],
      [-1, 0, -1, 0],
      [1, 0, 0, 1],
      [1, 0, 0, -1],
      [-1, 0, 0, 1],
      [-1, 0, 0, -1],
      [0, 1, 1, 0],
      [0, 1, -1, 0],
      [0, -1, 1, 0],
      [0, -1, -1, 0],
      [0, 1, 0, 1],
      [0, 1, 0, -1],
      [0, -1, 0, 1],
      [0, -1, 0, -1],
      [0, 0, 1, 1],
      [0, 0, 1, -1],
      [0, 0, -1, 1],
      [0, 0, -1, -1],
    ];

    for (final coord in coords) {
      vertices.add(vm.Vector4(
        coord[0].toDouble(),
        coord[1].toDouble(),
        coord[2].toDouble(),
        coord[3].toDouble(),
      ) * scale);
    }

    // Connect vertices that are sqrt(2) apart (96 edges in 24-cell)
    for (int i = 0; i < vertices.length; i++) {
      for (int j = i + 1; j < vertices.length; j++) {
        final dist = (vertices[i] - vertices[j]).length;
        if ((dist - math.sqrt(2) * scale).abs() < 0.01) {
          edges.add(Edge(i, j));
        }
      }
    }

    return Polytope(vertices: vertices, edges: edges, name: 'Crystal');
  }
}
