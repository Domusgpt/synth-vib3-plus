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
// Note: These tests avoid platform dependencies (audio, sensors)
// to run in CI environment.
//
// A Paul Phillips Manifestation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:synther_vib34d_holographic/vib3/widget/vib3_widget.dart';
import 'package:synther_vib34d_holographic/vib3/core/vib3_engine.dart';

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
      } else if (hasOnPan) {
        log('✓ GestureDetector uses pan handlers only');
      } else if (hasOnScale) {
        log('✓ GestureDetector uses scale handlers only');
      }
    }
  }

  void examineCustomPainters() {
    final painters = tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    );
    log('Found ${painters.length} CustomPaint widgets');
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

    testWidgets('VIB3Widget renders with interaction enabled',
        (WidgetTester tester) async {
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

      // Should have at least one GestureDetector when interaction enabled
      expect(find.byType(GestureDetector), findsWidgets);
      expect(find.byType(VIB3Widget), findsOneWidget);
    });

    testWidgets('VIB3Widget renders without interaction',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 0,
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Widget should render without crash
      expect(find.byType(VIB3Widget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('VIB3Widget Visual System Tests', () {
    testWidgets('Quantum system renders without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 0,
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VIB3Widget), findsOneWidget);
    });

    testWidgets('Holographic system renders without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.holographic,
              geometryIndex: 0,
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VIB3Widget), findsOneWidget);
    });

    testWidgets('Faceted system renders without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.faceted,
              geometryIndex: 0,
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VIB3Widget), findsOneWidget);
    });
  });

  group('VIB3Widget Geometry Tests', () {
    testWidgets('Base core geometries (0-7) render',
        (WidgetTester tester) async {
      for (int geomIndex = 0; geomIndex < 8; geomIndex++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VIB3Widget(
                system: VisualSystem.quantum,
                geometryIndex: geomIndex,
                enableInteraction: false,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(VIB3Widget), findsOneWidget,
            reason: 'Geometry $geomIndex (Base) should render');
      }
    });

    testWidgets('Hypersphere core geometries (8-15) render',
        (WidgetTester tester) async {
      for (int geomIndex = 8; geomIndex < 16; geomIndex++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VIB3Widget(
                system: VisualSystem.quantum,
                geometryIndex: geomIndex,
                enableInteraction: false,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(VIB3Widget), findsOneWidget,
            reason: 'Geometry $geomIndex (Hypersphere) should render');
      }
    });

    testWidgets('Hypertetrahedron core geometries (16-23) render',
        (WidgetTester tester) async {
      for (int geomIndex = 16; geomIndex < 24; geomIndex++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VIB3Widget(
                system: VisualSystem.quantum,
                geometryIndex: geomIndex,
                enableInteraction: false,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(VIB3Widget), findsOneWidget,
            reason: 'Geometry $geomIndex (Hypertetrahedron) should render');
      }
    });
  });

  group('VIB3Widget State Callback Tests', () {
    testWidgets('onStateChanged callback is invoked',
        (WidgetTester tester) async {
      final stateChanges = <VIB3EngineState>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.faceted,
              geometryIndex: 5,
              enableInteraction: false,
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

      // Should receive state updates from animation loop
      expect(stateChanges, isNotEmpty,
          reason: 'Widget should emit state changes from animation');
    });

    testWidgets('State contains correct system and geometry',
        (WidgetTester tester) async {
      VIB3EngineState? capturedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.holographic,
              geometryIndex: 12,
              enableInteraction: false,
              onStateChanged: (state) {
                capturedState = state;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedState, isNotNull);
      expect(capturedState!.system, equals(VisualSystem.holographic));
      expect(capturedState!.geometryIndex, equals(12));
    });
  });

  group('VIB3Widget Audio Reactivity Tests', () {
    testWidgets('Widget accepts audio reactivity data',
        (WidgetTester tester) async {
      final audioData = AudioReactivityData(
        bassEnergy: 0.8,
        midEnergy: 0.5,
        highEnergy: 0.3,
        rmsAmplitude: 0.6,
        spectralCentroid: 2000.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 0,
              audioData: audioData,
              audioReactivityStrength: 1.0,
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VIB3Widget), findsOneWidget);
    });

    testWidgets('Demo mode renders without external audio',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.holographic,
              geometryIndex: 0,
              demoMode: true,
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VIB3Widget), findsOneWidget);
    });
  });

  group('VIB3Widget Edge Case Tests', () {
    testWidgets('Invalid geometry index is handled gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.quantum,
              geometryIndex: 999, // Invalid
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VIB3Widget), findsOneWidget);
    });

    testWidgets('Negative geometry index is handled gracefully',
        (WidgetTester tester) async {
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
      expect(find.byType(VIB3Widget), findsOneWidget);
    });

    testWidgets('Extreme visual parameters are handled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VIB3Widget(
              system: VisualSystem.faceted,
              geometryIndex: 0,
              hueShift: 999.0, // Extreme
              glowIntensity: 100.0, // Extreme
              autoRotateSpeed: 10.0, // High
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VIB3Widget), findsOneWidget);
    });
  });
}
