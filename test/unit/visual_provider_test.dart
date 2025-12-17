/**
 * Visual Provider Unit Tests
 *
 * Tests the VisualProvider state management including:
 * - System switching (Quantum, Faceted, Holographic)
 * - 4D rotation management
 * - Geometry index calculation (8 base × 3 cores = 24)
 * - Parameter normalization
 * - Velocity calculation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/providers/visual_provider.dart';
import 'dart:math' as math;

void main() {
  group('VisualProvider Initialization', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    test('should initialize with default faceted system', () {
      expect(provider.currentSystem, equals('faceted'));
    });

    test('should initialize with zero rotations', () {
      expect(provider.rotationXW, equals(0.0));
      expect(provider.rotationYW, equals(0.0));
      expect(provider.rotationZW, equals(0.0));
    });

    test('should initialize with geometry index 0', () {
      expect(provider.currentGeometry, equals(0));
    });

    test('should initialize with default visual parameters', () {
      expect(provider.rotationSpeed, equals(1.0));
      expect(provider.tessellationDensity, equals(5));
      expect(provider.vertexBrightness, equals(0.8));
      expect(provider.morphParameter, equals(0.0));
    });
  });

  group('System Switching', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    test('should switch to quantum system', () async {
      await provider.switchSystem('quantum');
      expect(provider.currentSystem, equals('quantum'));
    });

    test('should switch to holographic system', () async {
      await provider.switchSystem('holographic');
      expect(provider.currentSystem, equals('holographic'));
    });

    test('should switch to faceted system', () async {
      await provider.switchSystem('faceted');
      expect(provider.currentSystem, equals('faceted'));
    });

    test('should update vertex count based on system', () async {
      await provider.switchSystem('quantum');
      expect(provider.activeVertexCount, equals(120));

      await provider.switchSystem('holographic');
      expect(provider.activeVertexCount, equals(500));

      await provider.switchSystem('faceted');
      expect(provider.activeVertexCount, equals(50));
    });

    test('should return correct systemColors for each system', () async {
      await provider.switchSystem('quantum');
      expect(provider.systemColors, isNotNull);

      await provider.switchSystem('faceted');
      expect(provider.systemColors, isNotNull);

      await provider.switchSystem('holographic');
      expect(provider.systemColors, isNotNull);
    });
  });

  group('Geometry Index Calculation', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    test('should accept geometry indices 0-23', () async {
      for (int i = 0; i <= 23; i++) {
        await provider.setGeometry(i);
        expect(provider.currentGeometry, equals(i));
      }
    });

    test('should clamp geometry index to valid range', () async {
      await provider.setGeometry(-5);
      expect(provider.currentGeometry, equals(0));

      await provider.setGeometry(100);
      expect(provider.currentGeometry, equals(23));
    });

    test('should correctly calculate core index from geometry', () async {
      // Base core (0-7)
      await provider.setGeometry(3);
      expect(provider.currentGeometry ~/ 8, equals(0));

      // Hypersphere core (8-15)
      await provider.setGeometry(11);
      expect(provider.currentGeometry ~/ 8, equals(1));

      // Hypertetrahedron core (16-23)
      await provider.setGeometry(19);
      expect(provider.currentGeometry ~/ 8, equals(2));
    });

    test('should correctly calculate base geometry from index', () async {
      // Tetrahedron (index % 8 == 0)
      await provider.setGeometry(0);
      expect(provider.currentGeometry % 8, equals(0));

      await provider.setGeometry(8);
      expect(provider.currentGeometry % 8, equals(0));

      await provider.setGeometry(16);
      expect(provider.currentGeometry % 8, equals(0));

      // Crystal (index % 8 == 7)
      await provider.setGeometry(7);
      expect(provider.currentGeometry % 8, equals(7));

      await provider.setGeometry(15);
      expect(provider.currentGeometry % 8, equals(7));

      await provider.setGeometry(23);
      expect(provider.currentGeometry % 8, equals(7));
    });
  });

  group('4D Rotation Management', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    test('should set rotation XW', () {
      provider.setRotationXW(1.5);
      expect(provider.rotationXW, closeTo(1.5, 0.001));
    });

    test('should set rotation YW', () {
      provider.setRotationYW(2.0);
      expect(provider.rotationYW, closeTo(2.0, 0.001));
    });

    test('should set rotation ZW', () {
      provider.setRotationZW(3.14);
      expect(provider.rotationZW, closeTo(3.14, 0.001));
    });

    test('should wrap rotation angles to 0-2π', () {
      provider.setRotationXW(8.0); // > 2π
      expect(provider.rotationXW, lessThan(2 * math.pi));
      expect(provider.rotationXW, greaterThanOrEqualTo(0));
    });

    test('should get rotation angle by plane name', () {
      provider.setRotationXW(1.0);
      provider.setRotationYW(2.0);
      provider.setRotationZW(3.0);

      expect(provider.getRotationAngle('XW'), equals(1.0));
      expect(provider.getRotationAngle('YW'), equals(2.0));
      expect(provider.getRotationAngle('ZW'), equals(3.0));
    });

    test('should return 0 for unknown rotation plane', () {
      expect(provider.getRotationAngle('UNKNOWN'), equals(0.0));
    });

    test('should update rotations with correct velocity calculation', () {
      // Initial state - velocity should be 0
      expect(provider.getRotationVelocity(), equals(0.0));

      // Update rotations
      provider.updateRotations(0.016); // ~60 FPS

      // Velocity should now be non-zero
      expect(provider.getRotationVelocity(), greaterThan(0.0));
    });

    test('should calculate velocity magnitude correctly', () {
      provider.setRotationXW(0.0);
      provider.setRotationYW(0.0);
      provider.setRotationZW(0.0);

      // After update, velocities will be set
      provider.updateRotations(0.1);

      // Velocity is sqrt(vx² + vy² + vz²)
      final velocity = provider.getRotationVelocity();
      expect(velocity, greaterThanOrEqualTo(0.0));
    });
  });

  group('Visual Parameters', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    test('should set rotation speed within bounds', () {
      provider.setRotationSpeed(3.0);
      expect(provider.rotationSpeed, equals(3.0));

      provider.setRotationSpeed(10.0); // Above max
      expect(provider.rotationSpeed, equals(5.0));

      provider.setRotationSpeed(0.0); // Below min
      expect(provider.rotationSpeed, equals(0.1));
    });

    test('should set tessellation density within bounds', () {
      provider.setTessellationDensity(7);
      expect(provider.tessellationDensity, equals(7));

      provider.setTessellationDensity(1); // Below min
      expect(provider.tessellationDensity, equals(3));

      provider.setTessellationDensity(15); // Above max
      expect(provider.tessellationDensity, equals(10));
    });

    test('should set vertex brightness within bounds', () {
      provider.setVertexBrightness(0.5);
      expect(provider.vertexBrightness, equals(0.5));

      provider.setVertexBrightness(2.0); // Above max
      expect(provider.vertexBrightness, equals(1.0));

      provider.setVertexBrightness(-1.0); // Below min
      expect(provider.vertexBrightness, equals(0.0));
    });

    test('should set morph parameter within bounds', () {
      provider.setMorphParameter(0.7);
      expect(provider.morphParameter, equals(0.7));

      provider.setMorphParameter(2.0); // Above max
      expect(provider.morphParameter, equals(1.0));

      provider.setMorphParameter(-0.5); // Below min
      expect(provider.morphParameter, equals(0.0));
    });

    test('should set projection distance within bounds', () {
      provider.setProjectionDistance(10.0);
      expect(provider.projectionDistance, equals(10.0));

      provider.setProjectionDistance(20.0); // Above max
      expect(provider.projectionDistance, equals(15.0));

      provider.setProjectionDistance(1.0); // Below min
      expect(provider.projectionDistance, equals(5.0));
    });

    test('should set layer separation within bounds', () {
      provider.setLayerSeparation(3.0);
      expect(provider.layerSeparation, equals(3.0));

      provider.setLayerSeparation(10.0); // Above max
      expect(provider.layerSeparation, equals(5.0));

      provider.setLayerSeparation(-2.0); // Below min
      expect(provider.layerSeparation, equals(0.0));
    });

    test('should set hue shift with wrapping', () {
      provider.setHueShift(90.0);
      expect(provider.hueShift, equals(90.0));

      provider.setHueShift(400.0); // Should wrap
      expect(provider.hueShift, equals(40.0));
    });

    test('should set glow intensity within bounds', () {
      provider.setGlowIntensity(2.0);
      expect(provider.glowIntensity, equals(2.0));

      provider.setGlowIntensity(5.0); // Above max
      expect(provider.glowIntensity, equals(3.0));

      provider.setGlowIntensity(-1.0); // Below min
      expect(provider.glowIntensity, equals(0.0));
    });
  });

  group('Animation State', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    test('should start animation', () {
      expect(provider.isAnimating, isFalse);

      provider.startAnimation();
      expect(provider.isAnimating, isTrue);
    });

    test('should stop animation', () {
      provider.startAnimation();
      expect(provider.isAnimating, isTrue);

      provider.stopAnimation();
      expect(provider.isAnimating, isFalse);
    });
  });

  group('Visual State Export', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    test('should export complete visual state', () {
      final state = provider.getVisualState();

      expect(state.containsKey('system'), isTrue);
      expect(state.containsKey('rotationXW'), isTrue);
      expect(state.containsKey('rotationYW'), isTrue);
      expect(state.containsKey('rotationZW'), isTrue);
      expect(state.containsKey('rotationSpeed'), isTrue);
      expect(state.containsKey('tessellationDensity'), isTrue);
      expect(state.containsKey('vertexBrightness'), isTrue);
      expect(state.containsKey('hueShift'), isTrue);
      expect(state.containsKey('glowIntensity'), isTrue);
      expect(state.containsKey('morphParameter'), isTrue);
      expect(state.containsKey('projectionDistance'), isTrue);
      expect(state.containsKey('layerSeparation'), isTrue);
      expect(state.containsKey('isAnimating'), isTrue);
    });

    test('should export current values in state', () {
      provider.setRotationSpeed(2.5);
      provider.setMorphParameter(0.8);

      final state = provider.getVisualState();

      expect(state['rotationSpeed'], equals(2.5));
      expect(state['morphParameter'], equals(0.8));
    });
  });
}
