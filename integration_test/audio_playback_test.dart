/**
 * Audio Playback Integration Test
 *
 * Tests the audio pipeline from touch input to PCM output.
 * Designed to run on Firebase Test Lab to diagnose audio issues.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:synth_vib3_plus/main.dart';
import 'package:synth_vib3_plus/providers/audio_provider.dart';
import 'package:synth_vib3_plus/providers/visual_provider.dart';
import 'package:synth_vib3_plus/providers/ui_state_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Playback Tests', () {
    testWidgets('AudioProvider initializes correctly', (tester) async {
      // Create providers
      final audioProvider = AudioProvider();

      // Wait for async initialization
      await audioProvider.ensureInitialized();

      // Verify initialization
      expect(audioProvider.isInitialized, isTrue,
          reason: 'AudioProvider should be initialized');

      print('✅ AudioProvider initialized');
      print('   PCM available: ${audioProvider.isPcmAvailable}');
      print('   Voice count: ${audioProvider.voiceCount}');
    });

    testWidgets('Note on triggers audio generation', (tester) async {
      // Create providers
      final audioProvider = AudioProvider();
      await audioProvider.ensureInitialized();

      // Initial state
      expect(audioProvider.isPlaying, isFalse,
          reason: 'Should not be playing initially');

      // Trigger note on
      final testNote = 60; // Middle C
      audioProvider.noteOn(testNote);

      // Verify audio started
      expect(audioProvider.isPlaying, isTrue,
          reason: 'Should be playing after noteOn');
      expect(audioProvider.currentNote, equals(testNote),
          reason: 'Current note should be set');

      print('✅ noteOn triggered audio generation');
      print('   Playing: ${audioProvider.isPlaying}');
      print('   Current note: ${audioProvider.currentNote}');

      // Wait for some buffers to be generated
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if buffers are being generated
      final metrics = audioProvider.getMetrics();
      print('   Buffers/sec: ${metrics['buffersPerSecond']}');

      // Stop audio
      audioProvider.noteOff(testNote);
    });

    testWidgets('Buffer generation produces non-zero samples', (tester) async {
      // Create providers
      final audioProvider = AudioProvider();
      await audioProvider.ensureInitialized();

      // Set geometry and trigger note
      audioProvider.setGeometry(0); // Direct synthesis, Tetrahedron
      audioProvider.noteOn(60);

      // Wait for buffer generation
      await Future.delayed(const Duration(milliseconds: 200));

      // Check buffer content
      final buffer = audioProvider.getCurrentBuffer();
      expect(buffer, isNotNull, reason: 'Buffer should not be null');

      if (buffer != null) {
        // Find max amplitude
        double maxAmp = 0;
        for (int i = 0; i < buffer.length; i++) {
          if (buffer[i].abs() > maxAmp) {
            maxAmp = buffer[i].abs();
          }
        }

        print('✅ Buffer generated');
        print('   Buffer length: ${buffer.length}');
        print('   Max amplitude: ${maxAmp.toStringAsFixed(4)}');

        expect(maxAmp, greaterThan(0),
            reason: 'Buffer should contain non-zero samples');
      }

      audioProvider.noteOff(60);
    });

    testWidgets('All synthesis branches produce audio', (tester) async {
      final audioProvider = AudioProvider();
      await audioProvider.ensureInitialized();

      // Test each synthesis branch
      final branches = [
        (0, 'Direct'),   // Geometry 0-7
        (8, 'FM'),       // Geometry 8-15
        (16, 'Ring'),    // Geometry 16-23
      ];

      for (final (geometry, name) in branches) {
        audioProvider.setGeometry(geometry);
        audioProvider.noteOn(60);

        await Future.delayed(const Duration(milliseconds: 200));

        final buffer = audioProvider.getCurrentBuffer();
        double maxAmp = 0;
        if (buffer != null) {
          for (int i = 0; i < buffer.length; i++) {
            if (buffer[i].abs() > maxAmp) {
              maxAmp = buffer[i].abs();
            }
          }
        }

        print('$name synthesis (geometry $geometry): maxAmp=${maxAmp.toStringAsFixed(4)}');

        expect(maxAmp, greaterThan(0),
            reason: '$name synthesis should produce audio');

        audioProvider.noteOff(60);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('✅ All synthesis branches produce audio');
    });

    testWidgets('Full app integration test', (tester) async {
      // Pump the full app
      await tester.pumpWidget(const SynthVib3PlusApp());
      await tester.pumpAndSettle();

      print('✅ App launched successfully');

      // Find and tap on the XY pad area (center of screen)
      final center = tester.getCenter(find.byType(Scaffold));
      await tester.tapAt(center);
      await tester.pump();

      print('✅ Tapped center of screen');

      // Wait for audio to start
      await Future.delayed(const Duration(milliseconds: 500));

      // Get audio provider from context
      // Note: This requires the app to expose the provider

      print('✅ Full integration test completed');
    });
  });
}
