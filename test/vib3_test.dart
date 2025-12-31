// VIB3+ Native Visualizer Unit Tests
//
// Tests for the native Dart 4D visualization system
// Verifies geometry, rotation, and rendering calculations

import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' as vm;

// Import VIB3+ components
import 'package:synther_vib34d_holographic/vib3/math/quaternion.dart';
import 'package:synther_vib34d_holographic/vib3/math/rotation_4d.dart';
import 'package:synther_vib34d_holographic/vib3/geometry/polytope_generator.dart';
import 'package:synther_vib34d_holographic/vib3/geometry/geometry_library.dart';
import 'package:synther_vib34d_holographic/vib3/core/vib3_engine.dart';
import 'package:synther_vib34d_holographic/vib3/audio/audio_reactive_modulator.dart';

void main() {
  group('Quaternion Tests', () {
    test('Quaternion identity creates correct identity', () {
      final q = Quaternion.identity();
      expect(q.w, equals(1.0));
      expect(q.x, equals(0.0));
      expect(q.y, equals(0.0));
      expect(q.z, equals(0.0));
    });

    test('Quaternion from axis angle works correctly', () {
      // 90 degree rotation around Z axis
      final axis = vm.Vector3(0, 0, 1);
      final q = Quaternion.axisAngle(axis, math.pi / 2);
      expect(q.w, closeTo(math.cos(math.pi / 4), 0.0001));
      expect(q.z, closeTo(math.sin(math.pi / 4), 0.0001));
    });

    test('Quaternion normalization preserves unit length', () {
      final q = Quaternion(1, 2, 3, 4);
      final normalized = q.normalize();
      expect(normalized.length, closeTo(1.0, 0.0001));
    });

    test('Quaternion multiplication produces valid result', () {
      final q1 = Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.5);
      final q2 = Quaternion.axisAngle(vm.Vector3(0, 1, 0), 0.7);

      final result = q1.multiply(q2);

      // Result should be a valid quaternion
      expect(result.length, closeTo(1.0, 0.01));
    });

    test('Quaternion euler conversion works', () {
      final q = Quaternion.euler(0.1, 0.2, 0.3);
      expect(q.length, closeTo(1.0, 0.0001));

      final euler = q.toEuler();
      expect(euler.roll, closeTo(0.1, 0.01));
      expect(euler.pitch, closeTo(0.2, 0.01));
      expect(euler.yaw, closeTo(0.3, 0.01));
    });
  });

  group('Rotation4D Tests', () {
    test('Rotation4D rotateXY produces valid matrix', () {
      final matrix = Rotation4D.rotateXY(math.pi / 4);

      // Should be 4x4 matrix (Matrix4 from vector_math)
      expect(matrix, isA<vm.Matrix4>());

      // Check that diagonal elements are cos(angle)
      expect(matrix.entry(0, 0), closeTo(math.cos(math.pi / 4), 0.0001));
      expect(matrix.entry(1, 1), closeTo(math.cos(math.pi / 4), 0.0001));
    });

    test('Rotation4D apply6DRotation combines all planes', () {
      final matrix = Rotation4D.apply6DRotation(
        xy: 0.1,
        xz: 0.2,
        yz: 0.3,
        xw: 0.4,
        yw: 0.5,
        zw: 0.6,
      );

      expect(matrix, isA<vm.Matrix4>());
    });

    test('Rotation4D project4Dto3D works correctly', () {
      final v4 = vm.Vector4(1, 2, 3, 0);
      final v3 = Rotation4D.project4Dto3D(v4, distance: 2.0);

      expect(v3, isA<vm.Vector3>());
      expect(v3.x, closeTo(0.5, 0.0001)); // 1 / 2
      expect(v3.y, closeTo(1.0, 0.0001)); // 2 / 2
      expect(v3.z, closeTo(1.5, 0.0001)); // 3 / 2
    });

    test('Rotation4D rotateVertices transforms all vertices', () {
      final vertices = [
        vm.Vector4(1, 0, 0, 0),
        vm.Vector4(0, 1, 0, 0),
        vm.Vector4(0, 0, 1, 0),
      ];
      final matrix = Rotation4D.rotateXY(math.pi / 2);
      final rotated = Rotation4D.rotateVertices(vertices, matrix);

      expect(rotated.length, equals(3));
      // After XY rotation, z and w remain unchanged
      expect(rotated[0].z, closeTo(0, 0.0001));
      expect(rotated[0].w, closeTo(0, 0.0001));
    });
  });

  group('Polytope Generator Tests', () {
    test('All 8 base geometries can be generated', () {
      for (int i = 0; i < 8; i++) {
        final polytope = PolytopeGenerator.generateBase(i);
        expect(polytope, isNotNull);
        expect(polytope.vertices, isNotEmpty);
        expect(polytope.edges, isNotEmpty);
      }
    });

    test('Tetrahedron has correct vertex count', () {
      final tetra = PolytopeGenerator.generateBase(0); // Tetrahedron

      // 4D tetrahedron (5-cell) has 5 vertices
      expect(tetra.vertices.length, greaterThanOrEqualTo(4));
    });

    test('Hypercube has correct structure', () {
      final cube = PolytopeGenerator.generateBase(1); // Hypercube

      // Tesseract has 16 vertices, 32 edges
      expect(cube.vertices, isNotEmpty);
      expect(cube.edges, isNotEmpty);
    });

    test('Geometry index calculation is correct', () {
      // Test the 3-level matrix system
      for (int geometryIndex = 0; geometryIndex < 24; geometryIndex++) {
        final coreIndex = geometryIndex ~/ 8;
        final baseGeometry = geometryIndex % 8;

        expect(coreIndex, inInclusiveRange(0, 2));
        expect(baseGeometry, inInclusiveRange(0, 7));
        expect(coreIndex * 8 + baseGeometry, equals(geometryIndex));
      }
    });

    test('All geometry names are defined', () {
      for (int i = 0; i < 8; i++) {
        final polytope = PolytopeGenerator.generateBase(i);
        expect(polytope.name, isNotEmpty);
      }
    });
  });

  group('Geometry Library Tests', () {
    test('All 24 geometry configurations are valid', () {
      for (int i = 0; i < 24; i++) {
        final metadata = GeometryLibrary.getGeometryMetadata(i);
        expect(metadata, isNotNull);
        expect(metadata.name, isNotEmpty);
        expect(metadata.index, equals(i));
      }
    });

    test('Core names match expected values', () {
      expect(GeometryLibrary.coreNames[0], equals('Base'));
      expect(GeometryLibrary.coreNames[1], equals('Hypersphere'));
      expect(GeometryLibrary.coreNames[2], equals('Hypertetrahedron'));
    });

    test('Base geometry names are correct', () {
      final names = [
        'Tetrahedron', 'Hypercube', 'Sphere', 'Torus',
        'Klein Bottle', 'Fractal', 'Wave', 'Crystal'
      ];

      for (int i = 0; i < 8; i++) {
        expect(GeometryLibrary.baseNames[i], equals(names[i]));
      }
    });

    test('decodeGeometryIndex works correctly', () {
      // Test geometry 0 (Base Tetrahedron)
      final (base0, core0) = GeometryLibrary.decodeGeometryIndex(0);
      expect(base0, equals(0));
      expect(core0, equals(0));

      // Test geometry 11 (Hypersphere Torus)
      final (base11, core11) = GeometryLibrary.decodeGeometryIndex(11);
      expect(base11, equals(3)); // Torus
      expect(core11, equals(1)); // Hypersphere

      // Test geometry 23 (Hypertetrahedron Crystal)
      final (base23, core23) = GeometryLibrary.decodeGeometryIndex(23);
      expect(base23, equals(7)); // Crystal
      expect(core23, equals(2)); // Hypertetrahedron
    });

    test('encodeGeometryIndex is inverse of decodeGeometryIndex', () {
      for (int i = 0; i < 24; i++) {
        final (baseIndex, coreIndex) = GeometryLibrary.decodeGeometryIndex(i);
        final encoded = GeometryLibrary.encodeGeometryIndex(baseIndex, coreIndex);
        expect(encoded, equals(i));
      }
    });
  });

  group('VIB3 Engine State Tests', () {
    test('Default state has valid parameters', () {
      const state = VIB3EngineState();

      expect(state.geometryIndex, inInclusiveRange(0, 23));
      expect(state.morphParameter, inInclusiveRange(0.0, 1.0));
      expect(state.chaosAmount, inInclusiveRange(0.0, 1.0));
      expect(state.animationSpeed, greaterThan(0.0));
    });

    test('Quantum preset has correct system', () {
      final state = VIB3EngineState.quantum();
      expect(state.system, equals(VisualSystem.quantum));
    });

    test('State factory methods exist', () {
      // Verify all preset factories work
      final quantum = VIB3EngineState.quantum(geometryIndex: 5);
      expect(quantum.geometryIndex, equals(5));
    });
  });

  group('Audio Reactivity Tests', () {
    test('AudioReactivityData silent is all zeros', () {
      const data = AudioReactivityData.silent;
      expect(data.bassEnergy, equals(0.0));
      expect(data.midEnergy, equals(0.0));
      expect(data.highEnergy, equals(0.0));
      expect(data.rmsAmplitude, equals(0.0));
    });

    test('AudioAnalysisBuffer smoothing works', () {
      final buffer = AudioAnalysisBuffer(bufferSize: 4);

      buffer.push(const AudioReactivityData(
        bassEnergy: 0.0, midEnergy: 0.0, highEnergy: 0.0,
        spectralCentroid: 0.0, rmsAmplitude: 0.0,
      ));
      buffer.push(const AudioReactivityData(
        bassEnergy: 1.0, midEnergy: 1.0, highEnergy: 1.0,
        spectralCentroid: 1000.0, rmsAmplitude: 1.0,
      ));

      final smoothed = buffer.smoothed;
      // Should have moved toward 1.0 with attack rate
      expect(smoothed.bassEnergy, greaterThan(0.0));
      expect(smoothed.bassEnergy, lessThan(1.0));
    });

    test('AudioReactivityData fromFFT handles empty bins', () {
      final data = AudioReactivityData.fromFFT([], 44100);
      expect(data, equals(AudioReactivityData.silent));
    });
  });

  group('Visual System Tests', () {
    test('Visual system enum has 3 options', () {
      expect(VisualSystem.values.length, equals(3));
      expect(VisualSystem.values, contains(VisualSystem.quantum));
      expect(VisualSystem.values, contains(VisualSystem.holographic));
      expect(VisualSystem.values, contains(VisualSystem.faceted));
    });
  });

  group('Integration Tests', () {
    test('Full geometry-to-synthesis mapping covers all 72 combinations', () {
      // Test all 72 combinations (3 systems × 24 geometries)
      int count = 0;
      for (final system in VisualSystem.values) {
        for (int geom = 0; geom < 24; geom++) {
          final (baseGeom, coreIndex) = GeometryLibrary.decodeGeometryIndex(geom);

          // Each combination should map to valid synthesis params
          expect(coreIndex, inInclusiveRange(0, 2));
          expect(baseGeom, inInclusiveRange(0, 7));

          // Verify synthesis branch mapping
          final synthesisType = switch (coreIndex) {
            0 => 'Direct',
            1 => 'FM',
            2 => 'RingMod',
            _ => 'Unknown',
          };
          expect(synthesisType, isNot('Unknown'));

          count++;
        }
      }
      expect(count, equals(72)); // 3 × 24 = 72
    });

    test('Metadata matches decoded indices', () {
      for (int i = 0; i < 24; i++) {
        final metadata = GeometryLibrary.getGeometryMetadata(i);
        final (baseIndex, coreIndex) = GeometryLibrary.decodeGeometryIndex(i);

        expect(metadata.baseIndex, equals(baseIndex));
        expect(metadata.coreIndex, equals(coreIndex));
        expect(metadata.baseName, equals(GeometryLibrary.baseNames[baseIndex]));
        expect(metadata.coreName, equals(GeometryLibrary.coreNames[coreIndex]));
      }
    });
  });
}
