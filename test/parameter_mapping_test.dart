// Parameter Mapping Tests
//
// Tests for the bidirectional audio-visual parameter mapping system:
// - Mapping curves (linear, exponential, logarithmic, sinusoidal)
// - Parameter range transformations
// - Edge cases and boundary conditions

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/mapping/audio_to_visual.dart';

void main() {
  group('ParameterMapping Basic Operations', () {
    test('linear mapping at boundaries', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 100.0,
        curve: MappingCurve.linear,
      );

      expect(mapping.map(0.0), equals(0.0));
      expect(mapping.map(1.0), equals(100.0));
      expect(mapping.map(0.5), equals(50.0));
    });

    test('linear mapping with offset range', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 50.0,
        maxRange: 150.0,
        curve: MappingCurve.linear,
      );

      expect(mapping.map(0.0), equals(50.0));
      expect(mapping.map(1.0), equals(150.0));
      expect(mapping.map(0.5), equals(100.0));
    });

    test('linear mapping clamps input values', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 100.0,
        curve: MappingCurve.linear,
      );

      // Values outside 0-1 should be clamped
      expect(mapping.map(-0.5), equals(0.0));
      expect(mapping.map(1.5), equals(100.0));
    });
  });

  group('Exponential Curve', () {
    test('exponential mapping emphasizes high values', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 100.0,
        curve: MappingCurve.exponential,
      );

      // Exponential: pow(x, 2)
      expect(mapping.map(0.0), equals(0.0));
      expect(mapping.map(1.0), equals(100.0));

      // 0.5^2 = 0.25, so 25.0
      expect(mapping.map(0.5), closeTo(25.0, 0.1));

      // 0.7^2 = 0.49, so 49.0
      expect(mapping.map(0.7), closeTo(49.0, 0.1));
    });

    test('exponential curve stays below linear', () {
      final linear = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.linear,
      );

      final exponential = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.exponential,
      );

      // For values 0 < x < 1, exponential should be less than linear
      for (double x = 0.1; x < 1.0; x += 0.1) {
        expect(exponential.map(x), lessThan(linear.map(x)),
            reason: 'Exponential at $x should be less than linear');
      }
    });
  });

  group('Logarithmic Curve', () {
    test('logarithmic mapping emphasizes low values', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 100.0,
        curve: MappingCurve.logarithmic,
      );

      expect(mapping.map(0.0), closeTo(0.0, 0.1));
      expect(mapping.map(1.0), closeTo(100.0, 0.1));

      // Logarithmic should be above linear for mid values
      expect(mapping.map(0.5), greaterThan(50.0));
    });

    test('logarithmic curve stays above linear', () {
      final linear = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.linear,
      );

      final logarithmic = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.logarithmic,
      );

      // For values 0 < x < 1, logarithmic should be greater than linear
      for (double x = 0.1; x < 0.9; x += 0.1) {
        expect(logarithmic.map(x), greaterThan(linear.map(x)),
            reason: 'Logarithmic at $x should be greater than linear');
      }
    });
  });

  group('Sinusoidal Curve', () {
    test('sinusoidal mapping is S-shaped', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 100.0,
        curve: MappingCurve.sinusoidal,
      );

      // Boundaries
      expect(mapping.map(0.0), closeTo(0.0, 0.1));
      expect(mapping.map(1.0), closeTo(100.0, 0.1));

      // Midpoint should be at 50
      expect(mapping.map(0.5), closeTo(50.0, 0.1));
    });

    test('sinusoidal has smooth transitions at extremes', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.sinusoidal,
      );

      // Near 0, curve should be gentle
      final slope0 = mapping.map(0.05) - mapping.map(0.0);
      final slope1 = mapping.map(1.0) - mapping.map(0.95);

      // Slope near extremes should be less than slope in middle
      final slopeMid = (mapping.map(0.55) - mapping.map(0.45)) / 0.1;

      expect(slope0, lessThan(slopeMid * 0.1));
      expect(slope1, lessThan(slopeMid * 0.1));
    });
  });

  group('Negative Range Mappings', () {
    test('handles negative target ranges', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: -12.0,
        maxRange: 12.0,
        curve: MappingCurve.linear,
      );

      expect(mapping.map(0.0), equals(-12.0));
      expect(mapping.map(1.0), equals(12.0));
      expect(mapping.map(0.5), equals(0.0));
    });

    test('handles inverted ranges', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 100.0,
        maxRange: 0.0,
        curve: MappingCurve.linear,
      );

      expect(mapping.map(0.0), equals(100.0));
      expect(mapping.map(1.0), equals(0.0));
      expect(mapping.map(0.5), equals(50.0));
    });
  });

  group('Audio-Visual Mapping Presets', () {
    test('rotation to detune mapping uses sinusoidal curve', () {
      // Simulating XY rotation to Osc1 detune
      final mapping = ParameterMapping(
        sourceParam: 'rotationXY',
        targetParam: 'oscillator1Detune',
        minRange: -12.0,
        maxRange: 12.0,
        curve: MappingCurve.sinusoidal,
      );

      // Full rotation (0 -> 1) maps smoothly through detune range
      expect(mapping.map(0.0), closeTo(-12.0, 0.5));
      expect(mapping.map(0.5), closeTo(0.0, 0.5));
      expect(mapping.map(1.0), closeTo(12.0, 0.5));
    });

    test('bass energy to rotation speed uses linear mapping', () {
      final mapping = ParameterMapping(
        sourceParam: 'bassEnergy',
        targetParam: 'rotationSpeed',
        minRange: 0.5,
        maxRange: 2.5,
        curve: MappingCurve.linear,
      );

      expect(mapping.map(0.0), equals(0.5)); // Minimum rotation speed
      expect(mapping.map(1.0), equals(2.5)); // Maximum rotation speed
      expect(mapping.map(0.5), equals(1.5)); // Mid rotation speed
    });

    test('RMS to glow intensity uses exponential mapping', () {
      final mapping = ParameterMapping(
        sourceParam: 'rms',
        targetParam: 'glowIntensity',
        minRange: 0.0,
        maxRange: 3.0,
        curve: MappingCurve.exponential,
      );

      // Quiet audio = minimal glow
      expect(mapping.map(0.0), equals(0.0));

      // Loud audio = maximum glow
      expect(mapping.map(1.0), equals(3.0));

      // Mid volume = less than mid glow (exponential)
      expect(mapping.map(0.5), lessThan(1.5));
    });
  });

  group('Mapping Curve Consistency', () {
    test('all curves are monotonically increasing', () {
      for (final curve in MappingCurve.values) {
        final mapping = ParameterMapping(
          sourceParam: 'test',
          targetParam: 'output',
          minRange: 0.0,
          maxRange: 100.0,
          curve: curve,
        );

        double prev = mapping.map(0.0);
        for (double x = 0.01; x <= 1.0; x += 0.01) {
          final current = mapping.map(x);
          expect(current, greaterThanOrEqualTo(prev),
              reason: '${curve.name} curve should be monotonically increasing at $x');
          prev = current;
        }
      }
    });

    test('all curves start at minRange and end at maxRange', () {
      for (final curve in MappingCurve.values) {
        final mapping = ParameterMapping(
          sourceParam: 'test',
          targetParam: 'output',
          minRange: 10.0,
          maxRange: 90.0,
          curve: curve,
        );

        expect(mapping.map(0.0), closeTo(10.0, 0.5),
            reason: '${curve.name} should start at minRange');
        expect(mapping.map(1.0), closeTo(90.0, 0.5),
            reason: '${curve.name} should end at maxRange');
      }
    });
  });

  group('Edge Cases', () {
    test('handles zero-width range', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 50.0,
        maxRange: 50.0,
        curve: MappingCurve.linear,
      );

      // All inputs should map to 50
      expect(mapping.map(0.0), equals(50.0));
      expect(mapping.map(0.5), equals(50.0));
      expect(mapping.map(1.0), equals(50.0));
    });

    test('handles very small ranges', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 0.001,
        curve: MappingCurve.linear,
      );

      expect(mapping.map(0.0), equals(0.0));
      expect(mapping.map(1.0), equals(0.001));
      expect(mapping.map(0.5), closeTo(0.0005, 0.0001));
    });

    test('handles very large ranges', () {
      final mapping = ParameterMapping(
        sourceParam: 'test',
        targetParam: 'output',
        minRange: 0.0,
        maxRange: 1000000.0,
        curve: MappingCurve.linear,
      );

      expect(mapping.map(0.0), equals(0.0));
      expect(mapping.map(1.0), equals(1000000.0));
      expect(mapping.map(0.5), equals(500000.0));
    });
  });
}
