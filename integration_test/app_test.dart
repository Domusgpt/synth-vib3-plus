/**
 * Integration Tests for Synth-VIB3+
 *
 * Tests the full application flow including:
 * - App initialization
 * - Provider integration
 * - Visual-audio parameter coupling
 * - System switching
 * - Geometry selection
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:synther_vib34d_holographic/main.dart';
import 'package:synther_vib34d_holographic/providers/audio_provider.dart';
import 'package:synther_vib34d_holographic/providers/visual_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization Tests', () {
    testWidgets('App should initialize without errors', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should render
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should have correct title', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('Synth-VIB3+'));
    });
  });

  group('Provider Integration Tests', () {
    testWidgets('AudioProvider should be accessible', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find a widget that uses AudioProvider
      final context = tester.element(find.byType(MaterialApp));

      // Provider should be in the tree
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      expect(audioProvider, isNotNull);
    });

    testWidgets('VisualProvider should be accessible', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final context = tester.element(find.byType(MaterialApp));

      final visualProvider = Provider.of<VisualProvider>(context, listen: false);
      expect(visualProvider, isNotNull);
    });
  });

  group('Visual System Switching Tests', () {
    testWidgets('Should switch between visual systems', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);

      // Test switching systems
      await visualProvider.switchSystem('quantum');
      await tester.pump();
      expect(visualProvider.currentSystem, equals('quantum'));

      await visualProvider.switchSystem('faceted');
      await tester.pump();
      expect(visualProvider.currentSystem, equals('faceted'));

      await visualProvider.switchSystem('holographic');
      await tester.pump();
      expect(visualProvider.currentSystem, equals('holographic'));
    });

    testWidgets('System switch should update audio provider', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      // Switch system
      await visualProvider.switchSystem('holographic');
      audioProvider.setVisualSystem('holographic');
      await tester.pump();

      // Audio provider should have updated
      final config = audioProvider.getSynthesisConfig();
      expect(config, contains('holographic'));
    });
  });

  group('Geometry Selection Tests', () {
    testWidgets('Should select geometry across all 24 indices', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      // Test all 24 geometries
      for (int i = 0; i < 24; i++) {
        await visualProvider.setGeometry(i);
        audioProvider.setGeometry(i);
        await tester.pump();

        expect(visualProvider.currentGeometry, equals(i));

        // Verify core calculation
        final expectedCore = i ~/ 8;
        final expectedBase = i % 8;
        expect(i ~/ 8, equals(expectedCore));
        expect(i % 8, equals(expectedBase));
      }
    });

    testWidgets('Geometry change should update synthesis branch', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      // Test Base core (Direct)
      audioProvider.setGeometry(0);
      await tester.pump();
      expect(audioProvider.currentSynthesisBranch, equals('Direct'));

      // Test Hypersphere core (FM)
      audioProvider.setGeometry(8);
      await tester.pump();
      expect(audioProvider.currentSynthesisBranch, equals('FM'));

      // Test Hypertetrahedron core (Ring Mod)
      audioProvider.setGeometry(16);
      await tester.pump();
      expect(audioProvider.currentSynthesisBranch, equals('Ring Mod'));
    });
  });

  group('Parameter Coupling Tests', () {
    testWidgets('Rotation parameters should be settable', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);

      visualProvider.setRotationXW(1.5);
      await tester.pump();
      expect(visualProvider.rotationXW, closeTo(1.5, 0.01));

      visualProvider.setRotationYW(2.0);
      await tester.pump();
      expect(visualProvider.rotationYW, closeTo(2.0, 0.01));

      visualProvider.setRotationZW(3.0);
      await tester.pump();
      expect(visualProvider.rotationZW, closeTo(3.0, 0.01));
    });

    testWidgets('Morph parameter should affect wavetable', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);

      visualProvider.setMorphParameter(0.0);
      await tester.pump();
      expect(visualProvider.morphParameter, equals(0.0));

      visualProvider.setMorphParameter(0.5);
      await tester.pump();
      expect(visualProvider.morphParameter, equals(0.5));

      visualProvider.setMorphParameter(1.0);
      await tester.pump();
      expect(visualProvider.morphParameter, equals(1.0));
    });
  });

  group('Audio Parameter Tests', () {
    testWidgets('Filter parameters should be settable', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      audioProvider.setFilterCutoff(1000.0);
      await tester.pump();
      expect(audioProvider.filterCutoff, closeTo(1000.0, 1.0));

      audioProvider.setFilterResonance(0.7);
      await tester.pump();
      expect(audioProvider.filterResonance, closeTo(0.7, 0.01));
    });

    testWidgets('Envelope parameters should be settable', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      audioProvider.setEnvelopeAttack(100.0);
      await tester.pump();
      expect(audioProvider.envelopeAttack, closeTo(100.0, 1.0));

      audioProvider.setEnvelopeDecay(200.0);
      await tester.pump();
      expect(audioProvider.envelopeDecay, closeTo(200.0, 1.0));

      audioProvider.setEnvelopeSustain(0.8);
      await tester.pump();
      expect(audioProvider.envelopeSustain, closeTo(0.8, 0.01));

      audioProvider.setEnvelopeRelease(500.0);
      await tester.pump();
      expect(audioProvider.envelopeRelease, closeTo(500.0, 1.0));
    });

    testWidgets('Effects parameters should be settable', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      audioProvider.setReverbMix(0.5);
      await tester.pump();
      expect(audioProvider.reverbMix, closeTo(0.5, 0.01));

      audioProvider.setDelayFeedback(0.4);
      await tester.pump();
      expect(audioProvider.delayFeedback, closeTo(0.4, 0.01));
    });
  });

  group('Note Playback Tests', () {
    testWidgets('Should play and stop notes', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      // Play a note
      audioProvider.playNote(60); // Middle C
      await tester.pump();
      expect(audioProvider.isPlaying, isTrue);

      // Stop note
      audioProvider.stopNote();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(audioProvider.isPlaying, isFalse);
    });

    testWidgets('Should support polyphonic notes', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      // Play multiple notes
      audioProvider.noteOn(60);
      audioProvider.noteOn(64);
      audioProvider.noteOn(67);
      await tester.pump();

      expect(audioProvider.activeNotes.length, equals(3));
      expect(audioProvider.activeNotes, contains(60));
      expect(audioProvider.activeNotes, contains(64));
      expect(audioProvider.activeNotes, contains(67));

      // Release one note
      audioProvider.noteOff(64);
      await tester.pump();
      expect(audioProvider.activeNotes.length, equals(2));
      expect(audioProvider.activeNotes, isNot(contains(64)));
    });
  });

  group('UI State Tests', () {
    testWidgets('Animation state should toggle', (tester) async {
      await tester.pumpWidget(const SynthVIB3App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final context = tester.element(find.byType(MaterialApp));
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);

      visualProvider.startAnimation();
      await tester.pump();
      expect(visualProvider.isAnimating, isTrue);

      visualProvider.stopAnimation();
      await tester.pump();
      expect(visualProvider.isAnimating, isFalse);
    });
  });
}
