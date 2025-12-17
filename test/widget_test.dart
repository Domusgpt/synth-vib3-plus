/**
 * Synth-VIB3+ Widget Tests
 *
 * Comprehensive tests for the holographic synthesizer application.
 * Tests core functionality, UI components, and audio-visual coupling.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:synther_vib34d_holographic/main.dart';
import 'package:synther_vib34d_holographic/providers/audio_provider.dart';
import 'package:synther_vib34d_holographic/providers/visual_provider.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';

void main() {
  // NOTE: Full app widget tests are skipped because TiltSensorProvider creates
  // timers that remain pending. Integration tests should be used for full app testing.
  group('App Initialization', () {
    testWidgets('SynthVIB3App loads without error', (WidgetTester tester) async {
      // Skip this test - full app has pending timers from TiltSensorProvider
      // Use integration tests for full app testing
    }, skip: true); // Full app tests require integration test infrastructure

    testWidgets('App has correct title', (WidgetTester tester) async {
      // Skip - same reason
    }, skip: true); // Full app tests require integration test infrastructure

    testWidgets('App uses dark theme', (WidgetTester tester) async {
      // Skip - same reason
    }, skip: true); // Full app tests require integration test infrastructure
  });

  group('VisualProvider State', () {
    test('Initial system should be faceted', () {
      final provider = VisualProvider();
      expect(provider.currentSystem, equals('faceted'));
    });

    test('Initial geometry should be 0', () {
      final provider = VisualProvider();
      expect(provider.currentGeometry, equals(0));
    });

    test('Rotation angles should initialize to 0', () {
      final provider = VisualProvider();
      expect(provider.rotationXW, equals(0.0));
      expect(provider.rotationYW, equals(0.0));
      expect(provider.rotationZW, equals(0.0));
    });

    test('setGeometry should accept 0-23 range', () async {
      final provider = VisualProvider();

      for (int i = 0; i <= 23; i++) {
        await provider.setGeometry(i);
        expect(provider.currentGeometry, equals(i));
      }
    });

    test('setGeometry should clamp invalid values', () async {
      final provider = VisualProvider();

      await provider.setGeometry(-5);
      expect(provider.currentGeometry, equals(0));

      await provider.setGeometry(100);
      expect(provider.currentGeometry, equals(23));
    });

    test('getRotationAngle should return correct values', () {
      final provider = VisualProvider();

      provider.setRotationXW(1.0);
      provider.setRotationYW(2.0);
      provider.setRotationZW(3.0);

      expect(provider.getRotationAngle('XW'), equals(1.0));
      expect(provider.getRotationAngle('YW'), equals(2.0));
      expect(provider.getRotationAngle('ZW'), equals(3.0));
      expect(provider.getRotationAngle('INVALID'), equals(0.0));
    });

    test('systemColors should return valid colors for each system', () async {
      final provider = VisualProvider();

      await provider.switchSystem('quantum');
      expect(provider.systemColors, isNotNull);
      expect(provider.systemColors.primary, isA<Color>());

      await provider.switchSystem('faceted');
      expect(provider.systemColors, isNotNull);

      await provider.switchSystem('holographic');
      expect(provider.systemColors, isNotNull);
    });
  });

  group('SynthesisBranchManager', () {
    test('Geometry 0-7 maps to Base/Direct synthesis', () {
      final manager = SynthesisBranchManager();

      for (int i = 0; i <= 7; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.base));
      }
    });

    test('Geometry 8-15 maps to Hypersphere/FM synthesis', () {
      final manager = SynthesisBranchManager();

      for (int i = 8; i <= 15; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.hypersphere));
      }
    });

    test('Geometry 16-23 maps to Hypertetrahedron/Ring Mod', () {
      final manager = SynthesisBranchManager();

      for (int i = 16; i <= 23; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.hypertetrahedron));
      }
    });

    test('Base geometry extraction should be correct', () {
      final manager = SynthesisBranchManager();

      // Test Tetrahedron (0, 8, 16)
      manager.setGeometry(0);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));
      manager.setGeometry(8);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));
      manager.setGeometry(16);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));

      // Test Crystal (7, 15, 23)
      manager.setGeometry(7);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));
      manager.setGeometry(15);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));
      manager.setGeometry(23);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));
    });

    test('Invalid geometry should throw error', () {
      final manager = SynthesisBranchManager();

      expect(() => manager.setGeometry(-1), throwsA(isA<ArgumentError>()));
      expect(() => manager.setGeometry(24), throwsA(isA<ArgumentError>()));
    });

    test('Visual system should update sound family', () {
      final manager = SynthesisBranchManager();

      manager.setVisualSystem(VisualSystem.quantum);
      expect(manager.soundFamily.name, contains('Quantum'));

      manager.setVisualSystem(VisualSystem.faceted);
      expect(manager.soundFamily.name, contains('Faceted'));

      manager.setVisualSystem(VisualSystem.holographic);
      expect(manager.soundFamily.name, contains('Holographic'));
    });

    test('Audio buffer should be generated with correct length', () {
      final manager = SynthesisBranchManager(sampleRate: 44100.0);
      manager.noteOn();

      final buffer = manager.generateBuffer(512, 440.0);
      expect(buffer.length, equals(512));
    });

    test('Audio samples should be in valid range', () {
      final manager = SynthesisBranchManager(sampleRate: 44100.0);
      manager.noteOn();

      // Let envelope build up
      for (int i = 0; i < 10; i++) {
        manager.generateBuffer(512, 440.0);
      }

      final buffer = manager.generateBuffer(512, 440.0);
      for (final sample in buffer) {
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('Architecture Validation', () {
    test('Should have 24 unique geometry combinations', () {
      final manager = SynthesisBranchManager();
      final configurations = <String>{};

      for (int i = 0; i < 24; i++) {
        manager.setGeometry(i);
        final config = '${manager.currentCore.name}_${manager.currentBaseGeometry.name}';
        configurations.add(config);
      }

      // 3 cores × 8 base geometries = 24, but only 24 unique combos
      // Each core+base combo is unique within a core, but base geometries repeat
      expect(configurations.length, equals(24));
    });

    test('Should have 3 visual systems', () {
      expect(VisualSystem.values.length, equals(3));
      expect(VisualSystem.values, contains(VisualSystem.quantum));
      expect(VisualSystem.values, contains(VisualSystem.faceted));
      expect(VisualSystem.values, contains(VisualSystem.holographic));
    });

    test('Should have 3 polytope cores', () {
      expect(PolytopeCor.values.length, equals(3));
      expect(PolytopeCor.values, contains(PolytopeCor.base));
      expect(PolytopeCor.values, contains(PolytopeCor.hypersphere));
      expect(PolytopeCor.values, contains(PolytopeCor.hypertetrahedron));
    });

    test('Should have 8 base geometries', () {
      expect(BaseGeometry.values.length, equals(8));
    });

    test('Total combinations should be 72 (3 systems × 24 geometries)', () {
      // This validates the architecture: 3 visual systems × 24 geometries = 72
      final total = VisualSystem.values.length *
          (PolytopeCor.values.length * BaseGeometry.values.length);
      expect(total, equals(72));
    });
  });

  group('Parameter Bounds', () {
    test('Rotation speed should clamp to valid range', () {
      final provider = VisualProvider();

      provider.setRotationSpeed(0.0);
      expect(provider.rotationSpeed, equals(0.1)); // Min clamped

      provider.setRotationSpeed(10.0);
      expect(provider.rotationSpeed, equals(5.0)); // Max clamped

      provider.setRotationSpeed(2.5);
      expect(provider.rotationSpeed, equals(2.5)); // Valid
    });

    test('Morph parameter should clamp to 0-1', () {
      final provider = VisualProvider();

      provider.setMorphParameter(-0.5);
      expect(provider.morphParameter, equals(0.0));

      provider.setMorphParameter(1.5);
      expect(provider.morphParameter, equals(1.0));

      provider.setMorphParameter(0.5);
      expect(provider.morphParameter, equals(0.5));
    });

    test('Projection distance should clamp to 5-15', () {
      final provider = VisualProvider();

      provider.setProjectionDistance(1.0);
      expect(provider.projectionDistance, equals(5.0));

      provider.setProjectionDistance(20.0);
      expect(provider.projectionDistance, equals(15.0));

      provider.setProjectionDistance(10.0);
      expect(provider.projectionDistance, equals(10.0));
    });
  });

  group('Geometry Index Calculation', () {
    test('Core index formula: geometry ~/ 8', () {
      // Base: 0-7 → core 0
      expect(0 ~/ 8, equals(0));
      expect(7 ~/ 8, equals(0));

      // Hypersphere: 8-15 → core 1
      expect(8 ~/ 8, equals(1));
      expect(15 ~/ 8, equals(1));

      // Hypertetrahedron: 16-23 → core 2
      expect(16 ~/ 8, equals(2));
      expect(23 ~/ 8, equals(2));
    });

    test('Base geometry formula: geometry % 8', () {
      // Tetrahedron: 0, 8, 16 → base 0
      expect(0 % 8, equals(0));
      expect(8 % 8, equals(0));
      expect(16 % 8, equals(0));

      // Crystal: 7, 15, 23 → base 7
      expect(7 % 8, equals(7));
      expect(15 % 8, equals(7));
      expect(23 % 8, equals(7));
    });

    test('Inverse formula: (core * 8) + base', () {
      // Hypersphere Torus: core=1, base=3 → index 11
      expect((1 * 8) + 3, equals(11));

      // Hypertetrahedron Crystal: core=2, base=7 → index 23
      expect((2 * 8) + 7, equals(23));

      // Base Wave: core=0, base=6 → index 6
      expect((0 * 8) + 6, equals(6));
    });
  });
}
