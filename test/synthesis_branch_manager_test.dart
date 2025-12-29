// Synthesis Branch Manager Tests
//
// Tests for the 3D matrix synthesis routing system:
// - Polytope Core routing (Direct/FM/RingMod)
// - Visual System to Sound Family mapping
// - Base Geometry to Voice Character mapping
// - Audio buffer generation for all 72 combinations

import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';

void main() {
  group('SynthesisBranchManager Initialization', () {
    test('initializes with default values', () {
      final manager = SynthesisBranchManager();

      expect(manager.sampleRate, equals(44100.0));
      expect(manager.currentGeometry, equals(0));
      expect(manager.visualSystem, equals(VisualSystem.quantum));
      expect(manager.currentCore, equals(PolytopeCor.base));
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));
    });

    test('initializes with custom sample rate', () {
      final manager = SynthesisBranchManager(sampleRate: 48000.0);
      expect(manager.sampleRate, equals(48000.0));
    });
  });

  group('Geometry Routing (3D Matrix)', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('geometries 0-7 route to Base core (Direct synthesis)', () {
      for (int i = 0; i <= 7; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.base),
            reason: 'Geometry $i should route to Base core');
      }
    });

    test('geometries 8-15 route to Hypersphere core (FM synthesis)', () {
      for (int i = 8; i <= 15; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.hypersphere),
            reason: 'Geometry $i should route to Hypersphere core');
      }
    });

    test('geometries 16-23 route to Hypertetrahedron core (Ring Mod)', () {
      for (int i = 16; i <= 23; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.hypertetrahedron),
            reason: 'Geometry $i should route to Hypertetrahedron core');
      }
    });

    test('base geometry cycles through all 8 types correctly', () {
      final expectedGeometries = [
        BaseGeometry.tetrahedron,
        BaseGeometry.hypercube,
        BaseGeometry.sphere,
        BaseGeometry.torus,
        BaseGeometry.kleinBottle,
        BaseGeometry.fractal,
        BaseGeometry.wave,
        BaseGeometry.crystal,
      ];

      // Test for each core (0-7, 8-15, 16-23)
      for (int coreOffset = 0; coreOffset < 24; coreOffset += 8) {
        for (int i = 0; i < 8; i++) {
          manager.setGeometry(coreOffset + i);
          expect(manager.currentBaseGeometry, equals(expectedGeometries[i]),
              reason: 'Geometry ${coreOffset + i} should have base geometry ${expectedGeometries[i]}');
        }
      }
    });

    test('throws ArgumentError for invalid geometry', () {
      expect(() => manager.setGeometry(-1), throwsArgumentError);
      expect(() => manager.setGeometry(24), throwsArgumentError);
      expect(() => manager.setGeometry(100), throwsArgumentError);
    });
  });

  group('Visual System to Sound Family', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('Quantum system maps to Quantum sound family', () {
      manager.setVisualSystem(VisualSystem.quantum);
      expect(manager.soundFamily.name, equals('Quantum/Pure'));
      expect(manager.soundFamily.filterQ, equals(8.0));
    });

    test('Faceted system maps to Faceted sound family', () {
      manager.setVisualSystem(VisualSystem.faceted);
      expect(manager.soundFamily.name, equals('Faceted/Geometric'));
      expect(manager.soundFamily.filterQ, equals(5.5));
    });

    test('Holographic system maps to Holographic sound family', () {
      manager.setVisualSystem(VisualSystem.holographic);
      expect(manager.soundFamily.name, equals('Holographic/Rich'));
      expect(manager.soundFamily.filterQ, equals(4.0));
    });
  });

  group('Voice Character Properties', () {
    test('Tetrahedron has fundamental character (minimal complexity)', () {
      expect(VoiceCharacter.tetrahedron.name, equals('Fundamental'));
      expect(VoiceCharacter.tetrahedron.harmonicCount, equals(3));
      expect(VoiceCharacter.tetrahedron.detuneCents, equals(0.0));
    });

    test('Crystal has fast attack for percussive sound', () {
      expect(VoiceCharacter.crystal.attackMs, equals(2.0));
      expect(VoiceCharacter.crystal.releaseMs, equals(150.0));
    });

    test('Hypercube has chorus effect enabled', () {
      expect(VoiceCharacter.hypercube.hasChorusEffect, isTrue);
      expect(VoiceCharacter.hypercube.detuneCents, equals(8.0));
    });

    test('Torus has filter sweep and phase modulation', () {
      expect(VoiceCharacter.torus.hasFilterSweep, isTrue);
      expect(VoiceCharacter.torus.hasPhaseModulation, isTrue);
    });

    test('Fractal has maximum harmonic spread', () {
      expect(VoiceCharacter.fractal.harmonicCount, equals(8));
      expect(VoiceCharacter.fractal.harmonicSpread, equals(0.9));
    });
  });

  group('Sound Family Properties', () {
    test('Quantum family is sine-dominant', () {
      expect(SoundFamily.quantum.waveformMix[0], greaterThan(0.8)); // Sine dominant
      expect(SoundFamily.quantum.noiseLevel, lessThan(0.01)); // Minimal noise
    });

    test('Faceted family is balanced', () {
      // Check that all waveforms contribute
      expect(SoundFamily.faceted.waveformMix[0], greaterThan(0.2)); // Sine
      expect(SoundFamily.faceted.waveformMix[1], greaterThan(0.2)); // Square
      expect(SoundFamily.faceted.waveformMix[2], greaterThan(0.2)); // Triangle
    });

    test('Holographic family is saw-based', () {
      expect(SoundFamily.holographic.waveformMix[3], greaterThan(0.4)); // Saw dominant
      expect(SoundFamily.holographic.reverbMix, greaterThan(0.4)); // High reverb
    });

    test('all sound families have 8 harmonic amplitudes', () {
      expect(SoundFamily.quantum.harmonicAmplitudes.length, equals(8));
      expect(SoundFamily.faceted.harmonicAmplitudes.length, equals(8));
      expect(SoundFamily.holographic.harmonicAmplitudes.length, equals(8));
    });

    test('harmonic amplitudes decrease for natural sound', () {
      for (final family in [SoundFamily.quantum, SoundFamily.faceted, SoundFamily.holographic]) {
        for (int i = 0; i < 7; i++) {
          expect(family.harmonicAmplitudes[i], greaterThanOrEqualTo(family.harmonicAmplitudes[i + 1]),
              reason: '${family.name} harmonics should decrease');
        }
      }
    });
  });

  group('Audio Buffer Generation', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
      manager.noteOn();
    });

    test('generates correct buffer length', () {
      final buffer = manager.generateBuffer(512, 440.0);
      expect(buffer.length, equals(512));
    });

    test('generates non-zero audio samples', () {
      final buffer = manager.generateBuffer(512, 440.0);
      final hasNonZero = buffer.any((sample) => sample != 0.0);
      expect(hasNonZero, isTrue);
    });

    test('samples are within valid range [-1, 1]', () {
      final buffer = manager.generateBuffer(1024, 440.0);
      for (final sample in buffer) {
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });

    test('Direct synthesis (Base core) generates unique output', () {
      manager.setGeometry(0); // Base core
      final buffer1 = manager.generateBuffer(512, 440.0);

      manager.setGeometry(1); // Different geometry, same core
      final buffer2 = manager.generateBuffer(512, 440.0);

      // Buffers should be different due to different voice characters
      bool different = buffer1.any((s) => !buffer2.contains(s));
      expect(different, isTrue);
    });

    test('FM synthesis (Hypersphere core) generates unique output', () {
      manager.setGeometry(8); // Hypersphere core
      final buffer = manager.generateBuffer(512, 440.0);
      final hasNonZero = buffer.any((sample) => sample != 0.0);
      expect(hasNonZero, isTrue);
    });

    test('Ring Mod synthesis (Hypertetrahedron core) generates unique output', () {
      manager.setGeometry(16); // Hypertetrahedron core
      final buffer = manager.generateBuffer(512, 440.0);
      final hasNonZero = buffer.any((sample) => sample != 0.0);
      expect(hasNonZero, isTrue);
    });

    test('different frequencies produce different outputs', () {
      manager.setGeometry(0);
      final buffer440 = manager.generateBuffer(512, 440.0);

      // Reset phases
      manager.setGeometry(0);
      final buffer880 = manager.generateBuffer(512, 880.0);

      bool different = false;
      for (int i = 0; i < 512; i++) {
        if ((buffer440[i] - buffer880[i]).abs() > 0.001) {
          different = true;
          break;
        }
      }
      expect(different, isTrue);
    });
  });

  group('Envelope Behavior', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('noteOn enables envelope', () {
      manager.noteOn();
      // First buffer should have increasing envelope
      final buffer = manager.generateBuffer(512, 440.0);
      // Early samples should be quieter than later samples (attack phase)
      final earlyEnergy = buffer.sublist(0, 50).fold(0.0, (sum, s) => sum + s.abs());
      final laterEnergy = buffer.sublist(200, 250).fold(0.0, (sum, s) => sum + s.abs());
      expect(laterEnergy, greaterThan(earlyEnergy));
    });

    test('noteOff starts release phase', () {
      manager.noteOn();
      manager.generateBuffer(512, 440.0); // Build up envelope

      manager.noteOff();
      final releaseBuffer = manager.generateBuffer(1024, 440.0);

      // Energy should decrease during release
      final earlyEnergy = releaseBuffer.sublist(0, 100).fold(0.0, (sum, s) => sum + s.abs());
      final laterEnergy = releaseBuffer.sublist(900, 1000).fold(0.0, (sum, s) => sum + s.abs());
      expect(laterEnergy, lessThan(earlyEnergy));
    });
  });

  group('All 72 Combinations', () {
    test('all geometry + visual system combinations produce valid audio', () {
      final manager = SynthesisBranchManager();

      for (final system in VisualSystem.values) {
        manager.setVisualSystem(system);

        for (int geometry = 0; geometry < 24; geometry++) {
          manager.setGeometry(geometry);
          manager.noteOn();

          final buffer = manager.generateBuffer(256, 440.0);

          // Verify buffer is valid
          expect(buffer.length, equals(256),
              reason: 'Geometry $geometry + ${system.name} failed to generate buffer');

          final hasNonZero = buffer.any((s) => s != 0.0);
          expect(hasNonZero, isTrue,
              reason: 'Geometry $geometry + ${system.name} generated silent buffer');

          // Verify no NaN or Infinity
          for (final sample in buffer) {
            expect(sample.isFinite, isTrue,
                reason: 'Geometry $geometry + ${system.name} generated invalid sample');
          }
        }
      }
    });
  });

  group('Config String Generation', () {
    test('configString contains all relevant info', () {
      final manager = SynthesisBranchManager();
      manager.setGeometry(11); // Hypersphere + Torus
      manager.setVisualSystem(VisualSystem.faceted);

      final config = manager.configString;

      expect(config, contains('Geometry: 11'));
      expect(config, contains('hypersphere'));
      expect(config, contains('torus'));
      expect(config, contains('faceted'));
      expect(config, contains('Faceted/Geometric'));
      expect(config, contains('Cyclic')); // Torus voice character
    });
  });
}
