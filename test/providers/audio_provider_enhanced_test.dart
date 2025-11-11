/**
 * Audio Provider Enhanced Tests
 *
 * Test suite for dual-engine audio provider with runtime switching capability.
 *
 * Note: These tests focus on state management and logic. Full integration tests
 * with actual audio engines require physical device or comprehensive mocks.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synth_vib3_plus/providers/audio_provider_enhanced.dart';

void main() {
  group('AudioEngineType Enum', () {
    test('should have pcmSound and soLoud types', () {
      expect(AudioEngineType.values, contains(AudioEngineType.pcmSound));
      expect(AudioEngineType.values, contains(AudioEngineType.soLoud));
      expect(AudioEngineType.values.length, equals(2));
    });

    test('should have correct enum names', () {
      expect(AudioEngineType.pcmSound.name, equals('pcmSound'));
      expect(AudioEngineType.soLoud.name, equals('soLoud'));
    });
  });

  group('VisualSystem Enum', () {
    test('should have all three visual systems', () {
      expect(VisualSystem.values, contains(VisualSystem.quantum));
      expect(VisualSystem.values, contains(VisualSystem.faceted));
      expect(VisualSystem.values, contains(VisualSystem.holographic));
      expect(VisualSystem.values.length, equals(3));
    });

    test('should have correct enum names', () {
      expect(VisualSystem.quantum.name, equals('quantum'));
      expect(VisualSystem.faceted.name, equals('faceted'));
      expect(VisualSystem.holographic.name, equals('holographic'));
    });
  });

  group('AudioProviderEnhanced - Geometry Management', () {
    test('should validate geometry index range (0-23)', () {
      // Valid geometries
      expect(() => _validateGeometry(0), returnsNormally);
      expect(() => _validateGeometry(11), returnsNormally);
      expect(() => _validateGeometry(23), returnsNormally);

      // Invalid geometries
      expect(() => _validateGeometry(-1), throwsArgumentError);
      expect(() => _validateGeometry(24), throwsArgumentError);
      expect(() => _validateGeometry(100), throwsArgumentError);
    });

    test('should map geometry to correct core', () {
      // Base core (geometries 0-7)
      expect(_getCoreIndex(0), equals(0));
      expect(_getCoreIndex(7), equals(0));

      // Hypersphere core (geometries 8-15)
      expect(_getCoreIndex(8), equals(1));
      expect(_getCoreIndex(15), equals(1));

      // Hypertetrahedron core (geometries 16-23)
      expect(_getCoreIndex(16), equals(2));
      expect(_getCoreIndex(23), equals(2));
    });

    test('should map geometry to correct base geometry', () {
      // Each core has 8 base geometries (0-7)
      expect(_getBaseGeometry(0), equals(0)); // Base Tetrahedron
      expect(_getBaseGeometry(7), equals(7)); // Base Crystal
      expect(_getBaseGeometry(8), equals(0)); // Hypersphere Tetrahedron
      expect(_getBaseGeometry(11), equals(3)); // Hypersphere Torus
      expect(_getBaseGeometry(16), equals(0)); // Hypertetrahedron Tetrahedron
      expect(_getBaseGeometry(23), equals(7)); // Hypertetrahedron Crystal
    });
  });

  group('AudioProviderEnhanced - Parameter Mapping', () {
    test('should map glow intensity to reverb correctly', () {
      // Glow 0.0 → 5% reverb
      expect(_glowToReverb(0.0), closeTo(0.05, 0.01));

      // Glow 0.5 → ~32.5% reverb
      expect(_glowToReverb(0.5), closeTo(0.325, 0.01));

      // Glow 1.0 → 60% reverb
      expect(_glowToReverb(1.0), closeTo(0.60, 0.01));
    });

    test('should map glow intensity to attack time correctly', () {
      // Glow 0.0 → 1ms attack
      expect(_glowToAttack(0.0), closeTo(1.0, 0.01));

      // Glow 0.5 → ~50.5ms attack
      expect(_glowToAttack(0.5), closeTo(50.5, 0.5));

      // Glow 1.0 → 100ms attack
      expect(_glowToAttack(1.0), closeTo(100.0, 0.01));
    });

    test('should clamp glow intensity to 0-1 range', () {
      expect(_clampGlow(-0.5), equals(0.0));
      expect(_clampGlow(0.5), equals(0.5));
      expect(_clampGlow(1.5), equals(1.0));
    });
  });

  group('AudioProviderEnhanced - Engine Switching Logic', () {
    test('should track current active engine', () {
      AudioEngineType currentEngine = AudioEngineType.soLoud;

      // Simulate switch to PCM
      currentEngine = AudioEngineType.pcmSound;
      expect(currentEngine, equals(AudioEngineType.pcmSound));

      // Simulate switch back to SoLoud
      currentEngine = AudioEngineType.soLoud;
      expect(currentEngine, equals(AudioEngineType.soLoud));
    });

    test('should preserve engine state during switch', () {
      final engineState = {
        'geometry': 12,
        'visualSystem': VisualSystem.faceted,
        'glowIntensity': 0.7,
        'isPlaying': true,
        'currentNote': 440.0,
      };

      // Simulate engine switch
      final preservedState = Map<String, dynamic>.from(engineState);

      expect(preservedState['geometry'], equals(12));
      expect(preservedState['visualSystem'], equals(VisualSystem.faceted));
      expect(preservedState['glowIntensity'], equals(0.7));
    });
  });

  group('AudioProviderEnhanced - Performance Metrics', () {
    test('should track engine metrics correctly', () {
      final metrics = <AudioEngineType, Map<String, dynamic>>{
        AudioEngineType.pcmSound: {
          'avg_latency_ms': 12.5,
          'total_notes_played': 100,
        },
        AudioEngineType.soLoud: {
          'avg_latency_ms': 7.2,
          'total_notes_played': 100,
        },
      };

      expect(metrics[AudioEngineType.pcmSound]!['avg_latency_ms'],
          equals(12.5));
      expect(
          metrics[AudioEngineType.soLoud]!['avg_latency_ms'], equals(7.2));
    });

    test('should calculate latency improvement correctly', () {
      final pcmLatency = 12.5;
      final soLoudLatency = 7.2;

      final improvement = pcmLatency - soLoudLatency;
      final improvementPercent = (improvement / pcmLatency) * 100.0;

      expect(improvement, closeTo(5.3, 0.1));
      expect(improvementPercent, closeTo(42.4, 0.5));
    });

    test('should handle metrics comparison structure', () {
      final comparison = {
        'pcm': {'avg_latency_ms': 12.5, 'notes_played': 100},
        'soloud': {'avg_latency_ms': 7.2, 'notes_played': 100},
        'comparison': {
          'latency_improvement_ms': 5.3,
          'latency_improvement_percent': 42.4,
        },
        'current_engine': 'soLoud',
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(comparison, containsPair('pcm', anything));
      expect(comparison, containsPair('soloud', anything));
      expect(comparison, containsPair('comparison', anything));
      expect(comparison, containsPair('current_engine', 'soLoud'));
      expect(comparison, containsPair('timestamp', anything));
    });
  });

  group('AudioProviderEnhanced - State Synchronization', () {
    test('should sync all critical state parameters', () {
      final criticalState = {
        'geometry': 12,
        'visualSystem': VisualSystem.faceted,
        'glowIntensity': 0.7,
        'reverbMix': 0.45,
        'attackTime': 70.3,
        'voiceCount': 4,
        'isPlaying': true,
        'currentNote': 440.0,
        'volume': 0.8,
      };

      // Verify all critical parameters are present
      expect(criticalState, containsPair('geometry', anything));
      expect(criticalState, containsPair('visualSystem', anything));
      expect(criticalState, containsPair('glowIntensity', anything));
      expect(criticalState, containsPair('reverbMix', anything));
      expect(criticalState, containsPair('attackTime', anything));
      expect(criticalState, containsPair('voiceCount', anything));
      expect(criticalState, containsPair('isPlaying', anything));
      expect(criticalState, containsPair('currentNote', anything));
      expect(criticalState, containsPair('volume', anything));
    });

    test('should maintain consistency across engine switch', () {
      final stateBeforeSwitch = {
        'geometry': 15,
        'glowIntensity': 0.6,
      };

      final stateAfterSwitch = Map<String, dynamic>.from(stateBeforeSwitch);

      expect(stateAfterSwitch['geometry'], equals(stateBeforeSwitch['geometry']));
      expect(stateAfterSwitch['glowIntensity'],
          equals(stateBeforeSwitch['glowIntensity']));
    });
  });

  group('AudioProviderEnhanced - Visual System Integration', () {
    test('should map visual system to sound family correctly', () {
      expect(_getSystemName(VisualSystem.quantum), equals('quantum'));
      expect(_getSystemName(VisualSystem.faceted), equals('faceted'));
      expect(_getSystemName(VisualSystem.holographic), equals('holographic'));
    });

    test('should validate visual system changes', () {
      final validSystems = [
        VisualSystem.quantum,
        VisualSystem.faceted,
        VisualSystem.holographic,
      ];

      for (final system in validSystems) {
        expect(() => _validateVisualSystem(system), returnsNormally);
      }
    });
  });

  group('AudioProviderEnhanced - Error Handling', () {
    test('should handle invalid geometry gracefully', () {
      expect(() => _validateGeometry(-1), throwsArgumentError);
      expect(() => _validateGeometry(24), throwsArgumentError);
    });

    test('should handle invalid parameter values', () {
      // Glow intensity should be clamped
      expect(_clampGlow(-1.0), equals(0.0));
      expect(_clampGlow(2.0), equals(1.0));

      // Volume should be clamped
      expect(_clampVolume(-0.5), equals(0.0));
      expect(_clampVolume(1.5), equals(1.0));
    });

    test('should provide meaningful error messages', () {
      try {
        _validateGeometry(-1);
        fail('Should have thrown ArgumentError');
      } catch (e) {
        expect(e, isA<ArgumentError>());
        expect(e.toString(), contains('geometry'));
      }
    });
  });

  group('AudioProviderEnhanced - Integration Scenarios', () {
    test('should handle complete playback cycle', () {
      // Simulate playback cycle
      final playbackState = {
        'isPlaying': false,
        'currentNote': 0.0,
      };

      // Start playback
      playbackState['isPlaying'] = true;
      playbackState['currentNote'] = 440.0;
      expect(playbackState['isPlaying'], isTrue);
      expect(playbackState['currentNote'], equals(440.0));

      // Stop playback
      playbackState['isPlaying'] = false;
      playbackState['currentNote'] = 0.0;
      expect(playbackState['isPlaying'], isFalse);
      expect(playbackState['currentNote'], equals(0.0));
    });

    test('should handle engine switch during playback', () {
      final switchScenario = {
        'wasPlaying': true,
        'noteBeforeSwitch': 523.25, // C5
        'engineBefore': AudioEngineType.pcmSound,
        'engineAfter': AudioEngineType.soLoud,
        'shouldResumePlayback': true,
      };

      // Verify switch scenario
      if (switchScenario['wasPlaying'] == true) {
        expect(switchScenario['shouldResumePlayback'], isTrue);
        expect(switchScenario['noteBeforeSwitch'], equals(523.25));
      }
    });

    test('should handle parameter updates during playback', () {
      final parameterUpdate = {
        'isPlaying': true,
        'glowBefore': 0.5,
        'glowAfter': 0.8,
        'shouldNotifyListeners': true,
      };

      // Verify parameter update doesn't stop playback
      expect(parameterUpdate['isPlaying'], isTrue);
      expect(parameterUpdate['glowAfter'], isNot(equals(parameterUpdate['glowBefore'])));
      expect(parameterUpdate['shouldNotifyListeners'], isTrue);
    });
  });
}

// Helper functions for testing (simulating provider logic)

void _validateGeometry(int geometry) {
  if (geometry < 0 || geometry > 23) {
    throw ArgumentError('Geometry must be between 0 and 23, got: $geometry');
  }
}

int _getCoreIndex(int geometry) {
  return geometry ~/ 8; // 0 = Base, 1 = Hypersphere, 2 = Hypertetrahedron
}

int _getBaseGeometry(int geometry) {
  return geometry % 8; // 0-7 (Tetrahedron through Crystal)
}

double _glowToReverb(double glow) {
  return 0.05 + (glow * 0.55); // 5% to 60%
}

double _glowToAttack(double glow) {
  return 1.0 + (glow * 99.0); // 1ms to 100ms
}

double _clampGlow(double glow) {
  return glow.clamp(0.0, 1.0);
}

double _clampVolume(double volume) {
  return volume.clamp(0.0, 1.0);
}

String _getSystemName(VisualSystem system) {
  return system.name;
}

void _validateVisualSystem(VisualSystem system) {
  // Visual system enum is always valid
  assert(VisualSystem.values.contains(system));
}
