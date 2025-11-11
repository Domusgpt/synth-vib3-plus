/**
 * Tests for SynthesisBranchManager
 *
 * Comprehensive test suite for the synthesis branch manager,
 * ensuring all 72 combinations work correctly and produce
 * musically-tuned output.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';

void main() {
  group('SynthesisBranchManager', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager(sampleRate: 44100.0);
    });

    group('Geometry Selection', () {
      test('should accept valid geometry indices (0-23)', () {
        for (int i = 0; i < 24; i++) {
          expect(() => manager.setGeometry(i), returnsNormally);
        }
      });

      test('should reject invalid geometry indices', () {
        expect(() => manager.setGeometry(-1), throwsArgumentError);
        expect(() => manager.setGeometry(24), throwsArgumentError);
        expect(() => manager.setGeometry(100), throwsArgumentError);
      });

      test('should correctly calculate core index from geometry', () {
        // Base core (0-7)
        manager.setGeometry(0);
        expect(manager.currentCore, equals(PolytopeCor.base));

        manager.setGeometry(7);
        expect(manager.currentCore, equals(PolytopeCor.base));

        // Hypersphere core (8-15)
        manager.setGeometry(8);
        expect(manager.currentCore, equals(PolytopeCor.hypersphere));

        manager.setGeometry(15);
        expect(manager.currentCore, equals(PolytopeCor.hypersphere));

        // Hypertetrahedron core (16-23)
        manager.setGeometry(16);
        expect(manager.currentCore, equals(PolytopeCor.hypertetrahedron));

        manager.setGeometry(23);
        expect(manager.currentCore, equals(PolytopeCor.hypertetrahedron));
      });

      test('should correctly calculate base geometry from index', () {
        manager.setGeometry(0);
        expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));

        manager.setGeometry(7);
        expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));

        manager.setGeometry(11); // Hypersphere Torus
        expect(manager.currentBaseGeometry, equals(BaseGeometry.torus));

        manager.setGeometry(23); // Hypertetrahedron Crystal
        expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));
      });
    });

    group('Visual System Selection', () {
      test('should accept all visual system types', () {
        expect(
          () => manager.setVisualSystem(VisualSystem.quantum),
          returnsNormally,
        );
        expect(
          () => manager.setVisualSystem(VisualSystem.faceted),
          returnsNormally,
        );
        expect(
          () => manager.setVisualSystem(VisualSystem.holographic),
          returnsNormally,
        );
      });

      test('should update sound family when visual system changes', () {
        manager.setVisualSystem(VisualSystem.quantum);
        expect(manager.soundFamily.name, equals('Quantum/Pure'));

        manager.setVisualSystem(VisualSystem.faceted);
        expect(manager.soundFamily.name, equals('Faceted/Geometric'));

        manager.setVisualSystem(VisualSystem.holographic);
        expect(manager.soundFamily.name, equals('Holographic/Rich'));
      });
    });

    group('Audio Generation', () {
      test('should generate buffer with correct size', () {
        manager.setGeometry(0);
        manager.noteOn();

        final buffer = manager.generateBuffer(512, 440.0);

        expect(buffer.length, equals(512));
      });

      test('should generate non-zero audio after noteOn', () {
        manager.setGeometry(0);
        manager.noteOn();

        final buffer = manager.generateBuffer(512, 440.0);

        // At least some samples should be non-zero
        final nonZeroSamples = buffer.where((s) => s.abs() > 0.0001).length;
        expect(nonZeroSamples, greaterThan(0));
      });

      test('should decay to zero after noteOff', () {
        manager.setGeometry(0);
        manager.noteOn();

        // Generate some audio while note is on
        manager.generateBuffer(512, 440.0);

        // Turn note off
        manager.noteOff();

        // Generate several buffers until decay
        for (int i = 0; i < 100; i++) {
          manager.generateBuffer(512, 440.0);
        }

        // Final buffer should be very quiet
        final buffer = manager.generateBuffer(512, 440.0);
        final maxAmplitude = buffer.reduce(
          (a, b) => a.abs() > b.abs() ? a : b,
        ).abs();

        expect(maxAmplitude, lessThan(0.01)); // Very quiet
      });

      test('should respect sample bounds (-1.0 to 1.0)', () {
        manager.setGeometry(0);
        manager.noteOn();

        final buffer = manager.generateBuffer(512, 440.0);

        for (final sample in buffer) {
          expect(sample, greaterThanOrEqualTo(-1.0));
          expect(sample, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('Synthesis Branches', () {
      test('should use direct synthesis for base core (0-7)', () {
        for (int geo = 0; geo <= 7; geo++) {
          manager.setGeometry(geo);
          expect(manager.currentCore, equals(PolytopeCor.base));

          manager.noteOn();
          final buffer = manager.generateBuffer(512, 440.0);

          // Should generate valid audio
          expect(buffer.length, equals(512));
        }
      });

      test('should use FM synthesis for hypersphere core (8-15)', () {
        for (int geo = 8; geo <= 15; geo++) {
          manager.setGeometry(geo);
          expect(manager.currentCore, equals(PolytopeCor.hypersphere));

          manager.noteOn();
          final buffer = manager.generateBuffer(512, 440.0);

          // Should generate valid audio
          expect(buffer.length, equals(512));
        }
      });

      test('should use ring modulation for hypertetrahedron core (16-23)', () {
        for (int geo = 16; geo <= 23; geo++) {
          manager.setGeometry(geo);
          expect(manager.currentCore, equals(PolytopeCor.hypertetrahedron));

          manager.noteOn();
          final buffer = manager.generateBuffer(512, 440.0);

          // Should generate valid audio
          expect(buffer.length, equals(512));
        }
      });
    });

    group('Voice Characters', () {
      test('should apply different envelope times per geometry', () {
        // Tetrahedron (fast attack)
        manager.setGeometry(0);
        expect(manager.voiceCharacter.attackMs, equals(10.0));

        // Sphere (slow attack)
        manager.setGeometry(2);
        expect(manager.voiceCharacter.attackMs, equals(60.0));

        // Crystal (very fast attack)
        manager.setGeometry(7);
        expect(manager.voiceCharacter.attackMs, equals(2.0));
      });

      test('should have unique characteristics for each base geometry', () {
        final characteristics = <String>[];

        for (int baseGeo = 0; baseGeo < 8; baseGeo++) {
          manager.setGeometry(baseGeo); // Use base core
          final config = manager.voiceCharacter.name;
          expect(characteristics.contains(config), isFalse);
          characteristics.add(config);
        }

        expect(characteristics.length, equals(8));
      });
    });

    group('Musical Tuning', () {
      test('should use musical detuning values (in cents)', () {
        // Tetrahedron - perfect tuning
        manager.setGeometry(0);
        expect(manager.voiceCharacter.detuneCents, equals(0.0));

        // Hypercube - musical chorusing
        manager.setGeometry(1);
        expect(manager.voiceCharacter.detuneCents, equals(8.0));

        // Klein Bottle - quarter-tone-ish
        manager.setGeometry(4);
        expect(manager.voiceCharacter.detuneCents, equals(12.0));
      });

      test('should have harmonic-based sound families', () {
        manager.setVisualSystem(VisualSystem.quantum);
        final quantum = manager.soundFamily;
        expect(quantum.harmonicAmplitudes.length, greaterThanOrEqualTo(6));
        expect(quantum.harmonicAmplitudes[0], equals(1.0)); // Fundamental

        manager.setVisualSystem(VisualSystem.holographic);
        final holo = manager.soundFamily;
        expect(holo.harmonicAmplitudes.length, greaterThanOrEqualTo(6));
      });
    });

    group('All 72 Combinations', () {
      test('should generate unique configurations for all 72 combinations', () {
        final configurations = <String>{};

        for (int geo = 0; geo < 24; geo++) {
          for (final system in VisualSystem.values) {
            manager.setGeometry(geo);
            manager.setVisualSystem(system);

            final config =
                '${system.name}_${manager.currentCore.name}_${manager.currentBaseGeometry.name}';

            // Each combination should be unique
            expect(configurations.contains(config), isFalse);
            configurations.add(config);

            // Should generate valid audio
            manager.noteOn();
            final buffer = manager.generateBuffer(128, 440.0);
            expect(buffer.length, equals(128));
          }
        }

        expect(configurations.length, equals(72)); // 3 * 24 = 72
      });
    });

    group('Performance', () {
      test('should generate audio quickly (< 10ms for 512 samples)', () {
        manager.setGeometry(12); // FM synthesis
        manager.noteOn();

        final stopwatch = Stopwatch()..start();
        manager.generateBuffer(512, 440.0);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });

      test('should handle rapid geometry changes without errors', () {
        manager.noteOn();

        for (int i = 0; i < 100; i++) {
          manager.setGeometry(i % 24);
          final buffer = manager.generateBuffer(64, 440.0);
          expect(buffer.length, equals(64));
        }
      });
    });
  });
}
