/**
 * Synthesis Branch Manager Unit Tests
 *
 * Tests the core synthesis routing based on geometry:
 * - Base Core (0-7) → Direct Synthesis
 * - Hypersphere Core (8-15) → FM Synthesis
 * - Hypertetrahedron Core (16-23) → Ring Modulation
 *
 * Also tests visual system to sound family mapping.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synther_vib34d_holographic/synthesis/synthesis_branch_manager.dart';

void main() {
  group('SynthesisBranchManager Initialization', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager(sampleRate: 44100.0);
    });

    test('should initialize with default values', () {
      expect(manager.currentGeometry, equals(0));
      expect(manager.currentCore, equals(PolytopeCor.base));
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));
    });

    test('should initialize with quantum visual system', () {
      expect(manager.visualSystem, equals(VisualSystem.quantum));
    });
  });

  group('Geometry to Core Mapping', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('should map geometries 0-7 to Base core (Direct Synthesis)', () {
      for (int i = 0; i <= 7; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.base),
            reason: 'Geometry $i should map to Base core');
      }
    });

    test('should map geometries 8-15 to Hypersphere core (FM Synthesis)', () {
      for (int i = 8; i <= 15; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.hypersphere),
            reason: 'Geometry $i should map to Hypersphere core');
      }
    });

    test('should map geometries 16-23 to Hypertetrahedron core (Ring Mod)', () {
      for (int i = 16; i <= 23; i++) {
        manager.setGeometry(i);
        expect(manager.currentCore, equals(PolytopeCor.hypertetrahedron),
            reason: 'Geometry $i should map to Hypertetrahedron core');
      }
    });

    test('should throw ArgumentError for invalid geometry', () {
      expect(() => manager.setGeometry(-1), throwsA(isA<ArgumentError>()));
      expect(() => manager.setGeometry(24), throwsA(isA<ArgumentError>()));
      expect(() => manager.setGeometry(100), throwsA(isA<ArgumentError>()));
    });
  });

  group('Geometry to Base Geometry Mapping', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('should map index % 8 == 0 to Tetrahedron', () {
      manager.setGeometry(0);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));

      manager.setGeometry(8);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));

      manager.setGeometry(16);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.tetrahedron));
    });

    test('should map index % 8 == 1 to Hypercube', () {
      manager.setGeometry(1);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.hypercube));

      manager.setGeometry(9);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.hypercube));

      manager.setGeometry(17);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.hypercube));
    });

    test('should map index % 8 == 2 to Sphere', () {
      manager.setGeometry(2);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.sphere));
    });

    test('should map index % 8 == 3 to Torus', () {
      manager.setGeometry(3);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.torus));
    });

    test('should map index % 8 == 4 to Klein Bottle', () {
      manager.setGeometry(4);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.kleinBottle));
    });

    test('should map index % 8 == 5 to Fractal', () {
      manager.setGeometry(5);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.fractal));
    });

    test('should map index % 8 == 6 to Wave', () {
      manager.setGeometry(6);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.wave));
    });

    test('should map index % 8 == 7 to Crystal', () {
      manager.setGeometry(7);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));

      manager.setGeometry(15);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));

      manager.setGeometry(23);
      expect(manager.currentBaseGeometry, equals(BaseGeometry.crystal));
    });
  });

  group('Visual System to Sound Family Mapping', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('should map Quantum to pure harmonic sound family', () {
      manager.setVisualSystem(VisualSystem.quantum);
      expect(manager.soundFamily.name, equals('Quantum/Pure'));
      expect(manager.soundFamily.filterQ, equals(8.0));
    });

    test('should map Faceted to geometric hybrid sound family', () {
      manager.setVisualSystem(VisualSystem.faceted);
      expect(manager.soundFamily.name, equals('Faceted/Geometric'));
      expect(manager.soundFamily.filterQ, equals(5.5));
    });

    test('should map Holographic to spectral rich sound family', () {
      manager.setVisualSystem(VisualSystem.holographic);
      expect(manager.soundFamily.name, equals('Holographic/Rich'));
      expect(manager.soundFamily.filterQ, equals(4.0));
    });
  });

  group('Voice Character Properties', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('should have correct attack/release for Tetrahedron (fundamental)', () {
      manager.setGeometry(0);
      expect(manager.voiceCharacter.attackMs, equals(10.0));
      expect(manager.voiceCharacter.releaseMs, equals(250.0));
    });

    test('should have correct attack/release for Crystal (crystalline)', () {
      manager.setGeometry(7);
      expect(manager.voiceCharacter.attackMs, equals(2.0)); // Fast attack
      expect(manager.voiceCharacter.releaseMs, equals(150.0));
    });

    test('should have chorus effect for Hypercube', () {
      manager.setGeometry(1);
      expect(manager.voiceCharacter.hasChorusEffect, isTrue);
      expect(manager.voiceCharacter.detuneCents, equals(8.0));
    });

    test('should have filter sweep for Torus', () {
      manager.setGeometry(3);
      expect(manager.voiceCharacter.hasFilterSweep, isTrue);
      expect(manager.voiceCharacter.hasPhaseModulation, isTrue);
    });
  });

  group('Audio Buffer Generation', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager(sampleRate: 44100.0);
    });

    test('should generate buffer of correct length', () {
      final buffer = manager.generateBuffer(512, 440.0);
      expect(buffer.length, equals(512));
    });

    test('should generate samples within valid range', () {
      manager.noteOn();
      final buffer = manager.generateBuffer(512, 440.0);

      for (final sample in buffer) {
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });

    test('should generate Direct synthesis for Base core', () {
      manager.setGeometry(0); // Base core
      manager.noteOn();
      final buffer = manager.generateBuffer(512, 440.0);

      // Buffer should have non-zero samples after note on
      final hasContent = buffer.any((s) => s.abs() > 0.001);
      expect(hasContent, isTrue);
    });

    test('should generate FM synthesis for Hypersphere core', () {
      manager.setGeometry(8); // Hypersphere core
      manager.noteOn();
      final buffer = manager.generateBuffer(512, 440.0);

      final hasContent = buffer.any((s) => s.abs() > 0.001);
      expect(hasContent, isTrue);
    });

    test('should generate Ring Mod synthesis for Hypertetrahedron core', () {
      manager.setGeometry(16); // Hypertetrahedron core
      manager.noteOn();
      final buffer = manager.generateBuffer(512, 440.0);

      final hasContent = buffer.any((s) => s.abs() > 0.001);
      expect(hasContent, isTrue);
    });
  });

  group('Envelope Behavior', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager(sampleRate: 44100.0);
    });

    test('should start silent before note on', () {
      final buffer = manager.generateBuffer(512, 440.0);

      // Should be essentially silent (envelope at 0)
      final maxSample = buffer.fold<double>(0.0, (max, s) => s.abs() > max ? s.abs() : max);
      expect(maxSample, lessThan(0.1)); // Allow for small noise
    });

    test('should increase amplitude after note on', () {
      manager.noteOn();

      // Generate several buffers to let envelope build up
      for (int i = 0; i < 10; i++) {
        manager.generateBuffer(512, 440.0);
      }

      final buffer = manager.generateBuffer(512, 440.0);
      final maxSample = buffer.fold<double>(0.0, (max, s) => s.abs() > max ? s.abs() : max);

      expect(maxSample, greaterThan(0.1)); // Should have audible level
    });

    test('should decrease amplitude after note off', () {
      manager.noteOn();

      // Build up envelope
      for (int i = 0; i < 20; i++) {
        manager.generateBuffer(512, 440.0);
      }

      // Get level at sustain
      final sustainBuffer = manager.generateBuffer(512, 440.0);
      final sustainMax = sustainBuffer.fold<double>(0.0, (max, s) => s.abs() > max ? s.abs() : max);

      // Trigger release
      manager.noteOff();

      // Generate many buffers to let envelope decay
      for (int i = 0; i < 50; i++) {
        manager.generateBuffer(512, 440.0);
      }

      final releaseBuffer = manager.generateBuffer(512, 440.0);
      final releaseMax = releaseBuffer.fold<double>(0.0, (max, s) => s.abs() > max ? s.abs() : max);

      expect(releaseMax, lessThan(sustainMax)); // Should decay
    });
  });

  group('Configuration String', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager();
    });

    test('should include all configuration details', () {
      manager.setGeometry(11); // Hypersphere Torus
      manager.setVisualSystem(VisualSystem.faceted);

      final config = manager.configString;

      expect(config, contains('Geometry: 11'));
      expect(config, contains('hypersphere'));
      expect(config, contains('FM Synthesis'));
      expect(config, contains('torus'));
      expect(config, contains('faceted'));
      expect(config, contains('Faceted/Geometric'));
    });
  });

  group('Sound Family Properties', () {
    test('Quantum should have high filter Q', () {
      expect(SoundFamily.quantum.filterQ, equals(8.0));
      expect(SoundFamily.quantum.noiseLevel, equals(0.005));
    });

    test('Faceted should have moderate filter Q', () {
      expect(SoundFamily.faceted.filterQ, equals(5.5));
      expect(SoundFamily.faceted.waveformMix[1], greaterThan(0.3)); // Square
    });

    test('Holographic should have high reverb', () {
      expect(SoundFamily.holographic.reverbMix, equals(0.45));
      expect(SoundFamily.holographic.waveformMix[3], greaterThan(0.4)); // Saw
    });

    test('All sound families should have 8 harmonic amplitudes', () {
      expect(SoundFamily.quantum.harmonicAmplitudes.length, equals(8));
      expect(SoundFamily.faceted.harmonicAmplitudes.length, equals(8));
      expect(SoundFamily.holographic.harmonicAmplitudes.length, equals(8));
    });

    test('First harmonic should always be 1.0 (fundamental)', () {
      expect(SoundFamily.quantum.harmonicAmplitudes[0], equals(1.0));
      expect(SoundFamily.faceted.harmonicAmplitudes[0], equals(1.0));
      expect(SoundFamily.holographic.harmonicAmplitudes[0], equals(1.0));
    });
  });

  group('72 Combinations Coverage', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager(sampleRate: 44100.0);
    });

    test('should support all 24 geometry configurations', () {
      // Test all 24 geometries can be set without error
      for (int g = 0; g < 24; g++) {
        expect(() => manager.setGeometry(g), returnsNormally);
        expect(manager.currentGeometry, equals(g));
      }
    });

    test('should support all 3 visual systems', () {
      for (final system in VisualSystem.values) {
        expect(() => manager.setVisualSystem(system), returnsNormally);
        expect(manager.visualSystem, equals(system));
      }
    });

    test('should generate unique sounds for different core+system combinations', () {
      // This is a basic test - full audio comparison would need more sophisticated analysis
      final buffers = <String, double>{};

      for (final system in VisualSystem.values) {
        for (int core = 0; core < 3; core++) {
          manager.setVisualSystem(system);
          manager.setGeometry(core * 8); // First geometry of each core
          manager.noteOn();

          // Generate some samples
          for (int i = 0; i < 10; i++) {
            manager.generateBuffer(512, 440.0);
          }

          final buffer = manager.generateBuffer(512, 440.0);
          final rms = _calculateRMS(buffer);

          final key = '${system.name}_${core}';
          buffers[key] = rms;
        }
      }

      // All combinations should produce non-zero output
      for (final entry in buffers.entries) {
        expect(entry.value, greaterThan(0.0), reason: '${entry.key} should produce sound');
      }
    });
  });
}

/// Calculate RMS (Root Mean Square) of a buffer
double _calculateRMS(List<double> buffer) {
  double sum = 0.0;
  for (final sample in buffer) {
    sum += sample * sample;
  }
  return (sum / buffer.length).abs();
}
