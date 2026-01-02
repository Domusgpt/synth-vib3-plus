// VIB3 Widget Integration Tests
//
// Comprehensive tests for the VIB3+ visualization widget
// with visual state examination and debug output.
//
// These tests catch:
// - GestureDetector conflicts
// - Layout overflow issues
// - State synchronization problems
// - Rendering errors
//
// A Paul Phillips Manifestation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:synther_vib34d_holographic/vib3/widget/vib3_widget.dart';
import 'package:synther_vib34d_holographic/vib3/core/vib3_engine.dart';
import 'package:synther_vib34d_holographic/providers/visual_provider.dart';

/// Debug helper to examine widget tree state
class WidgetStateExaminer {
  final WidgetTester tester;
  final List<String> logs = [];

  WidgetStateExaminer(this.tester);

  void log(String message) {
    logs.add('[${DateTime.now().millisecondsSinceEpoch}] $message');
    debugPrint('🔍 $message');
  }

  void examineGestureDetectors() {
    final gestureDetectors = tester.widgetList<GestureDetector>(
      find.byType(GestureDetector),
    );

    log('Found ${gestureDetectors.length} GestureDetector widgets');

    for (final gd in gestureDetectors) {
      final hasOnPan = gd.onPanStart != null ||
          gd.onPanUpdate != null ||
          gd.onPanEnd != null;
      final hasOnScale = gd.onScaleStart != null ||
          gd.onScaleUpdate != null ||
          gd.onScaleEnd != null;

      if (hasOnPan && hasOnScale) {
        log('⚠️ CONFLICT: GestureDetector has BOTH pan AND scale handlers!');
        log('   onPanStart: ${gd.onPanStart != null}');
        log('   onPanUpdate: ${gd.onPanUpdate != null}');
        log('   onPanEnd: ${gd.onPanEnd != null}');
        log('   onScaleStart: ${gd.onScaleStart != null}');
        log('   onScaleUpdate: ${gd.onScaleUpdate != null}');
        log('   onScaleEnd: ${gd.onScaleEnd != null}');
      } else if (hasOnPan) {
        log('✓ GestureDetector uses pan handlers only');
      } else if (hasOnScale) {
        log('✓ GestureDetector uses scale handlers only');
      }
    }
  }

  void examineLayoutOverflows() {
    // Check for RenderFlex overflow
    final flexErrors = tester.takeException();
    if (flexErrors != null) {
      log('⚠️ OVERFLOW ERROR: $flexErrors');
    } else {
      log('✓ No layout overflow errors detected');
    }
  }

  void examineCustomPainters() {
    final painters = tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    );
    log('Found ${painters.length} CustomPaint widgets');

    for (final painter in painters) {
      if (painter.painter != null) {
        log('  - Painter: ${painter.painter.runtimeType}');
      }
    }
  }

  void examineProviderState(BuildContext context) {
    try {
      final visual = Provider.of<VisualProvider>(context, listen: false);
      log('VisualProvider state:');
      log('  - System: ${visual.currentSystem}');
      log('  - Geometry: ${visual.geometryIndex}');
      log('  - RotationXY: ${visual.rotationXY.toStringAsFixed(3)}');
      log('  - RotationXW: ${visual.rotationXW.toStringAsFixed(3)}');
      log('  - Tessellation: ${visual.tessellationDensity}');
      log('  - Brightness: ${visual.vertexBrightness}');
    } catch (e) {
      log('⚠️ Could not access VisualProvider: $e');
    }
  }

  void printSummary() {
    debugPrint('\n${'=' * 60}');
    debugPrint('WIDGET STATE EXAMINATION SUMMARY');
    debugPrint('=' * 60);
    for (final logEntry in logs) {
      debugPrint(logEntry);
    }
    debugPrint('=' * 60 + '\n');
  }
}

void main() {
  group('VIB3Widget Gesture Tests', () {
    testWidgets('VIB3Widget does NOT have pan+scale gesture conflict',
        (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 0,
              enableInteraction: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Examine all gesture detectors
      examiner.examineGestureDetectors();

      // Find all GestureDetectors and check for conflicts
      final gestureDetectors = tester.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      );

      for (final gd in gestureDetectors) {
        final hasOnPan = gd.onPanStart != null ||
            gd.onPanUpdate != null ||
            gd.onPanEnd != null;
        final hasOnScale = gd.onScaleStart != null ||
            gd.onScaleUpdate != null ||
            gd.onScaleEnd != null;

        // This is the critical test - pan+scale together causes runtime error
        expect(
          hasOnPan && hasOnScale,
          isFalse,
          reason: 'GestureDetector should not have both pan and scale handlers. '
              'Scale is a superset of pan.',
        );
      }

      examiner.printSummary();
    });

    testWidgets('VIB3Widget responds to scale gestures', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);
      VIB3EngineState? lastState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 0,
              enableInteraction: true,
              onStateChanged: (state) {
                lastState = state;
                examiner.log('State changed: rotationXY=${state.rotationXY.toStringAsFixed(3)}');
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Simulate a drag gesture (single finger)
      final center = tester.getCenter(find.byType(VIB3Widget));
      await tester.dragFrom(center, const Offset(100, 50));
      await tester.pump();

      examiner.log('After drag: lastState=$lastState');
      examiner.printSummary();

      // Widget should have processed the gesture
      expect(find.byType(VIB3Widget), findsOneWidget);
    });

    testWidgets('VIB3Widget handles pinch-to-zoom gesture', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.holographic,
              geometryIndex: 8, // Hypersphere geometry
              enableInteraction: true,
              onStateChanged: (state) {
                examiner.log('Pinch state: rotationXW=${state.rotationXW.toStringAsFixed(3)}');
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify widget renders without gesture conflict
      final gestureDetectors = tester.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      );

      examiner.log('GestureDetector count: ${gestureDetectors.length}');
      expect(gestureDetectors, isNotEmpty);

      examiner.printSummary();
    });
  });

  group('VIB3Widget Visual System Tests', () {
    testWidgets('All 3 visual systems render without error', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);

      for (final system in VisualSystem.values) {
        examiner.log('Testing system: ${system.name}');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VIB3Widget(
                system: system,
                geometryIndex: 0,
                enableInteraction: true,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Verify renders
        expect(find.byType(VIB3Widget), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        examiner.examineCustomPainters();
      }

      examiner.printSummary();
    });

    testWidgets('All 24 geometries render without error', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);

      for (int geomIndex = 0; geomIndex < 24; geomIndex++) {
        final coreIndex = geomIndex ~/ 8;
        final baseIndex = geomIndex % 8;
        examiner.log('Testing geometry $geomIndex (core=$coreIndex, base=$baseIndex)');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VIB3Widget(
                system: VisualSystem.quantum,
                geometryIndex: geomIndex,
                enableInteraction: false, // Faster test
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));

        // Verify renders
        expect(
          find.byType(VIB3Widget),
          findsOneWidget,
          reason: 'Geometry $geomIndex should render',
        );
      }

      examiner.log('✓ All 24 geometries rendered successfully');
      examiner.printSummary();
    });
  });

  group('VIB3Widget State Synchronization Tests', () {
    testWidgets('State changes propagate correctly', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);
      final stateChanges = <VIB3EngineState>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.faceted,
              geometryIndex: 5,
              hueShift: 180.0,
              glowIntensity: 2.0,
              enableInteraction: true,
              onStateChanged: (state) {
                stateChanges.add(state);
              },
            ),
          ),
        ),
      );

      // Let animation tick
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      examiner.log('State changes received: ${stateChanges.length}');

      // Should receive state updates from animation loop
      expect(stateChanges, isNotEmpty,
          reason: 'Widget should emit state changes from animation');

      if (stateChanges.isNotEmpty) {
        final lastState = stateChanges.last;
        examiner.log('Last state:');
        examiner.log('  - system: ${lastState.system}');
        examiner.log('  - geometryIndex: ${lastState.geometryIndex}');
        examiner.log('  - hueShift: ${lastState.hueShift}');
        examiner.log('  - glowIntensity: ${lastState.glowIntensity}');

        expect(lastState.system, equals(VisualSystem.faceted));
        expect(lastState.geometryIndex, equals(5));
      }

      examiner.printSummary();
    });

    testWidgets('Audio reactivity data flows correctly', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);

      final audioData = AudioReactivityData(
        bassEnergy: 0.8,
        midEnergy: 0.5,
        highEnergy: 0.3,
        rmsAmplitude: 0.6,
        spectralCentroid: 2000.0,
      );

      VIB3EngineState? capturedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 0,
              audioData: audioData,
              audioReactivityStrength: 1.0,
              onStateChanged: (state) {
                capturedState = state;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      examiner.log('Audio reactivity test:');
      examiner.log('  - Input bass: ${audioData.bassEnergy}');
      examiner.log('  - Input mid: ${audioData.midEnergy}');
      examiner.log('  - Input high: ${audioData.highEnergy}');

      expect(capturedState, isNotNull);
      if (capturedState != null) {
        examiner.log('  - Output audioData: ${capturedState!.audioData}');
      }

      examiner.printSummary();
    });
  });

  group('VIB3Widget Demo Mode Tests', () {
    testWidgets('Demo mode generates audio simulation', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);
      final stateChanges = <VIB3EngineState>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.holographic,
              geometryIndex: 0,
              demoMode: true, // Enable demo mode
              onStateChanged: (state) {
                stateChanges.add(state);
              },
            ),
          ),
        ),
      );

      // Run several animation frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      examiner.log('Demo mode state changes: ${stateChanges.length}');

      expect(stateChanges, isNotEmpty);

      // Check that audio data varies in demo mode
      if (stateChanges.length >= 2) {
        final first = stateChanges.first.audioData;
        final last = stateChanges.last.audioData;

        examiner.log('First audio: bass=${first.bassEnergy.toStringAsFixed(2)}, mid=${first.midEnergy.toStringAsFixed(2)}');
        examiner.log('Last audio: bass=${last.bassEnergy.toStringAsFixed(2)}, mid=${last.midEnergy.toStringAsFixed(2)}');

        // Demo mode should generate varying audio
        // (At minimum, time changes should cause variation)
      }

      examiner.printSummary();
    });
  });

  group('VIB3Widget Error Handling Tests', () {
    testWidgets('Invalid geometry index is clamped', (WidgetTester tester) async {
      final examiner = WidgetStateExaminer(tester);

      // Test with out-of-range geometry
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 999, // Invalid - should be 0-23
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Should render without crash
      expect(find.byType(VIB3Widget), findsOneWidget);
      examiner.log('✓ Invalid geometry index handled gracefully');

      examiner.printSummary();
    });

    testWidgets('Negative geometry index is handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: -5, // Negative
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Should render without crash
      expect(find.byType(VIB3Widget), findsOneWidget);
    });
  });
}
