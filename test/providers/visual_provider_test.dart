// Visual Provider Unit Tests
//
// Tests for visual parameter state management:
// - 6D rotation angles (XY, XZ, YZ, XW, YW, ZW)
// - Visual parameter ranges (density, brightness, hue, etc.)
// - Visual system switching (Quantum, Faceted, Holographic)
// - Geometry index calculations
// - State change notifications
//
// A Paul Phillips Manifestation

import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

import 'package:synther_vib34d_holographic/providers/visual_provider.dart';
import 'package:synther_vib34d_holographic/vib3/core/vib3_engine.dart';

void main() {
  group('Visual Provider Initialization', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial system is Faceted', () {
      expect(provider.currentSystemEnum, equals(VisualSystem.faceted));
      expect(provider.currentSystem, equals('faceted'));
    });

    test('Initial rotations are zero', () {
      expect(provider.rotationXY, equals(0.0));
      expect(provider.rotationXZ, equals(0.0));
      expect(provider.rotationYZ, equals(0.0));
      expect(provider.rotationXW, equals(0.0));
      expect(provider.rotationYW, equals(0.0));
      expect(provider.rotationZW, equals(0.0));
    });

    test('Initial visual parameters have valid defaults', () {
      expect(provider.rotationSpeed, equals(1.0));
      expect(provider.tessellationDensity, equals(8.0));
      expect(provider.vertexBrightness, equals(0.8));
      expect(provider.hueShift, equals(180.0));
      expect(provider.glowIntensity, equals(1.0));
      expect(provider.rgbSplitAmount, equals(0.0));
      expect(provider.saturation, equals(0.7));
    });

    test('Initial geometry state is valid', () {
      expect(provider.currentGeometry, equals(0));
      expect(provider.geometryIndex, equals(0));
      expect(provider.morphParameter, equals(0.0));
      expect(provider.activeVertexCount, greaterThan(0));
    });
  });

  group('6D Rotation Tests', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('setRotationXY updates correctly and wraps at 2π', () {
      provider.setRotationXY(1.5);
      expect(provider.rotationXY, closeTo(1.5, 0.001));

      // Test wrapping
      provider.setRotationXY(2 * math.pi + 0.5);
      expect(provider.rotationXY, closeTo(0.5, 0.001));
    });

    test('setRotationXZ updates correctly', () {
      provider.setRotationXZ(2.0);
      expect(provider.rotationXZ, closeTo(2.0, 0.001));
    });

    test('setRotationYZ updates correctly', () {
      provider.setRotationYZ(0.7);
      expect(provider.rotationYZ, closeTo(0.7, 0.001));
    });

    test('setRotationXW updates correctly', () {
      provider.setRotationXW(1.2);
      expect(provider.rotationXW, closeTo(1.2, 0.001));
    });

    test('setRotationYW updates correctly', () {
      provider.setRotationYW(0.9);
      expect(provider.rotationYW, closeTo(0.9, 0.001));
    });

    test('setRotationZW updates correctly', () {
      provider.setRotationZW(2.5);
      expect(provider.rotationZW, closeTo(2.5, 0.001));
    });

    test('getRotationAngle returns correct values for all planes', () {
      provider.setRotationXY(0.1);
      provider.setRotationXZ(0.2);
      provider.setRotationYZ(0.3);
      provider.setRotationXW(0.4);
      provider.setRotationYW(0.5);
      provider.setRotationZW(0.6);

      expect(provider.getRotationAngle('XY'), closeTo(0.1, 0.001));
      expect(provider.getRotationAngle('XZ'), closeTo(0.2, 0.001));
      expect(provider.getRotationAngle('YZ'), closeTo(0.3, 0.001));
      expect(provider.getRotationAngle('XW'), closeTo(0.4, 0.001));
      expect(provider.getRotationAngle('YW'), closeTo(0.5, 0.001));
      expect(provider.getRotationAngle('ZW'), closeTo(0.6, 0.001));
    });

    test('getRotationAngle is case insensitive', () {
      provider.setRotationXY(1.0);
      expect(provider.getRotationAngle('xy'), closeTo(1.0, 0.001));
      expect(provider.getRotationAngle('Xy'), closeTo(1.0, 0.001));
      expect(provider.getRotationAngle('XY'), closeTo(1.0, 0.001));
    });

    test('getRotationAngle returns 0 for unknown plane', () {
      expect(provider.getRotationAngle('INVALID'), equals(0.0));
    });

    test('updateRotations advances all 4D angles', () {
      provider.updateRotations(0.1);

      // After update, XW/YW/ZW should have changed
      expect(provider.rotationXW, greaterThan(0.0));
      expect(provider.rotationYW, greaterThan(0.0));
      expect(provider.rotationZW, greaterThan(0.0));
    });

    test('rotation speed affects updateRotations rate', () {
      provider.setRotationSpeed(2.0);
      provider.updateRotations(0.1);
      final fast = provider.rotationXW;

      // Reset and try slow
      provider.setRotationXW(0.0);
      provider.setRotationSpeed(0.5);
      provider.updateRotations(0.1);
      final slow = provider.rotationXW;

      expect(fast, greaterThan(slow * 2),
          reason: '2x speed should produce ~2x rotation');
    });
  });

  group('Visual Parameter Range Tests', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('setRotationSpeed clamps to valid range', () {
      provider.setRotationSpeed(0.05);
      expect(provider.rotationSpeed, equals(0.1)); // Clamped to min

      provider.setRotationSpeed(10.0);
      expect(provider.rotationSpeed, equals(5.0)); // Clamped to max

      provider.setRotationSpeed(2.5);
      expect(provider.rotationSpeed, equals(2.5)); // In range
    });

    test('setTessellationDensity clamps to 2-30 range', () {
      provider.setTessellationDensity(1.0);
      expect(provider.tessellationDensity, equals(2.0)); // Clamped to min

      provider.setTessellationDensity(50.0);
      expect(provider.tessellationDensity, equals(30.0)); // Clamped to max

      provider.setTessellationDensity(15.0);
      expect(provider.tessellationDensity, equals(15.0)); // In range
    });

    test('setVertexBrightness clamps to 0-1', () {
      provider.setVertexBrightness(-0.5);
      expect(provider.vertexBrightness, equals(0.0));

      provider.setVertexBrightness(1.5);
      expect(provider.vertexBrightness, equals(1.0));

      provider.setVertexBrightness(0.5);
      expect(provider.vertexBrightness, equals(0.5));
    });

    test('setHueShift wraps at 360 degrees', () {
      provider.setHueShift(90.0);
      expect(provider.hueShift, equals(90.0));

      provider.setHueShift(450.0);
      expect(provider.hueShift, equals(90.0)); // 450 % 360 = 90
    });

    test('setGlowIntensity clamps to 0-3', () {
      provider.setGlowIntensity(-1.0);
      expect(provider.glowIntensity, equals(0.0));

      provider.setGlowIntensity(5.0);
      expect(provider.glowIntensity, equals(3.0));
    });

    test('setRGBSplitAmount clamps to 0-10', () {
      provider.setRGBSplitAmount(-1.0);
      expect(provider.rgbSplitAmount, equals(0.0));

      provider.setRGBSplitAmount(15.0);
      expect(provider.rgbSplitAmount, equals(10.0));
    });

    test('setSaturation clamps to 0-1', () {
      provider.setSaturation(-0.5);
      expect(provider.saturation, equals(0.0));

      provider.setSaturation(1.5);
      expect(provider.saturation, equals(1.0));

      provider.setSaturation(0.7);
      expect(provider.saturation, equals(0.7));
    });

    test('setMorphParameter clamps to 0-1', () {
      provider.setMorphParameter(-0.5);
      expect(provider.morphParameter, equals(0.0));

      provider.setMorphParameter(1.5);
      expect(provider.morphParameter, equals(1.0));
    });

    test('setProjectionDistance clamps to 5-15', () {
      provider.setProjectionDistance(3.0);
      expect(provider.projectionDistance, equals(5.0));

      provider.setProjectionDistance(20.0);
      expect(provider.projectionDistance, equals(15.0));
    });

    test('setLayerSeparation clamps to 0-5', () {
      provider.setLayerSeparation(-1.0);
      expect(provider.layerSeparation, equals(0.0));

      provider.setLayerSeparation(10.0);
      expect(provider.layerSeparation, equals(5.0));
    });
  });

  group('Visual System Switching', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('switchSystem changes to Quantum', () async {
      await provider.switchSystem(VisualSystem.quantum);
      expect(provider.currentSystemEnum, equals(VisualSystem.quantum));
    });

    test('switchSystem changes to Holographic', () async {
      await provider.switchSystem(VisualSystem.holographic);
      expect(provider.currentSystemEnum, equals(VisualSystem.holographic));
    });

    test('switchSystem accepts string input', () async {
      await provider.switchSystem('quantum');
      expect(provider.currentSystemEnum, equals(VisualSystem.quantum));

      await provider.switchSystem('HOLOGRAPHIC');
      expect(provider.currentSystemEnum, equals(VisualSystem.holographic));
    });

    test('switchSystem updates vertex count per system', () async {
      await provider.switchSystem(VisualSystem.quantum);
      final quantumVertices = provider.activeVertexCount;

      await provider.switchSystem(VisualSystem.holographic);
      final holoVertices = provider.activeVertexCount;

      await provider.switchSystem(VisualSystem.faceted);
      final facetedVertices = provider.activeVertexCount;

      // Each system should have different vertex counts
      expect(quantumVertices, equals(120)); // Tesseract
      expect(holoVertices, equals(500)); // 5 layers × 100
      expect(facetedVertices, equals(50)); // Simpler
    });

    test('setSystem is alias for switchSystem', () async {
      await provider.setSystem('quantum');
      expect(provider.currentSystemEnum, equals(VisualSystem.quantum));
    });
  });

  group('Geometry Selection', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('setGeometry updates currentGeometry', () async {
      await provider.setGeometry(5);
      expect(provider.currentGeometry, equals(5));
      expect(provider.geometryIndex, equals(5));
    });

    test('setGeometry clamps to valid range 0-23', () async {
      await provider.setGeometry(-5);
      expect(provider.currentGeometry, equals(0));

      await provider.setGeometry(30);
      expect(provider.currentGeometry, equals(23));
    });

    test('All 24 geometries can be selected', () async {
      for (int i = 0; i < 24; i++) {
        await provider.setGeometry(i);
        expect(provider.currentGeometry, equals(i));
      }
    });
  });

  group('State Notifications', () {
    late VisualProvider provider;
    int notifyCount = 0;

    setUp(() {
      provider = VisualProvider();
      notifyCount = 0;
      provider.addListener(() => notifyCount++);
    });

    tearDown(() {
      provider.dispose();
    });

    test('Rotation changes trigger notification', () {
      provider.setRotationXY(1.0);
      expect(notifyCount, equals(1));

      provider.setRotationXZ(1.0);
      expect(notifyCount, equals(2));
    });

    test('Visual parameter changes trigger notification', () {
      provider.setVertexBrightness(0.5);
      expect(notifyCount, equals(1));

      provider.setHueShift(90.0);
      expect(notifyCount, equals(2));
    });

    test('updateRotations triggers notification', () {
      provider.updateRotations(0.1);
      expect(notifyCount, equals(1));
    });
  });

  group('Visual State Serialization', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('getVisualState returns complete state', () {
      provider.setRotationXY(0.1);
      provider.setRotationXZ(0.2);
      provider.setHueShift(90.0);
      provider.setVertexBrightness(0.5);

      final state = provider.getVisualState();

      expect(state['rotationXY'], closeTo(0.1, 0.001));
      expect(state['rotationXZ'], closeTo(0.2, 0.001));
      expect(state['hueShift'], equals(90.0));
      expect(state['vertexBrightness'], equals(0.5));
      expect(state['system'], equals('faceted'));
      expect(state['saturation'], equals(0.7));
    });

    test('getVisualState includes all required keys', () {
      final state = provider.getVisualState();

      final requiredKeys = [
        'system', 'rotationXY', 'rotationXZ', 'rotationYZ',
        'rotationXW', 'rotationYW', 'rotationZW',
        'rotationSpeed', 'tessellationDensity', 'vertexBrightness',
        'hueShift', 'glowIntensity', 'rgbSplitAmount', 'saturation',
        'activeVertexCount', 'morphParameter',
        'projectionDistance', 'layerSeparation', 'isAnimating',
      ];

      for (final key in requiredKeys) {
        expect(state.containsKey(key), isTrue,
            reason: 'State should contain key: $key');
      }
    });
  });

  group('Animation State', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial animation state is false', () {
      expect(provider.isAnimating, isFalse);
    });

    test('startAnimation sets isAnimating to true', () {
      provider.startAnimation();
      expect(provider.isAnimating, isTrue);
    });

    test('stopAnimation sets isAnimating to false', () {
      provider.startAnimation();
      provider.stopAnimation();
      expect(provider.isAnimating, isFalse);
    });
  });

  group('Rotation Velocity', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('getRotationVelocity returns combined velocity', () {
      provider.updateRotations(0.1);

      final velocity = provider.getRotationVelocity();
      expect(velocity, greaterThan(0.0));
    });
  });
}
