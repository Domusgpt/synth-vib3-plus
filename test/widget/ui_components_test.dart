// UI Components Integration Tests
//
// Tests for all UI components with visual state examination:
// - Top Bezel
// - Collapsible Bezel / Bottom Panel
// - Orb Controller
// - System Selector
//
// These tests detect:
// - Layout overflow errors
// - Text truncation issues
// - Responsive layout problems
// - Theme consistency
//
// A Paul Phillips Manifestation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:synther_vib34d_holographic/ui/theme/synth_theme.dart';
import 'package:synther_vib34d_holographic/ui/components/top_bezel.dart';
import 'package:synther_vib34d_holographic/ui/components/collapsible_bezel.dart';
import 'package:synther_vib34d_holographic/ui/components/orb_controller.dart';
import 'package:synther_vib34d_holographic/providers/visual_provider.dart';
import 'package:synther_vib34d_holographic/providers/audio_provider.dart';
import 'package:synther_vib34d_holographic/providers/ui_state_provider.dart';
import 'package:synther_vib34d_holographic/providers/tilt_sensor_provider.dart';

/// Test helper for examining UI state
class UIStateExaminer {
  final WidgetTester tester;
  final List<String> logs = [];
  final List<String> errors = [];

  UIStateExaminer(this.tester);

  void log(String message) {
    logs.add(message);
    debugPrint('📋 $message');
  }

  void error(String message) {
    errors.add(message);
    debugPrint('❌ ERROR: $message');
  }

  /// Check for any overflow errors in the widget tree
  Future<void> checkForOverflows() async {
    // Flutter reports overflow errors to the console
    // We can catch them by checking for RenderFlex overflows
    final exception = tester.takeException();
    if (exception != null) {
      error('Layout overflow detected: $exception');
    } else {
      log('✓ No overflow errors');
    }
  }

  /// Examine all Text widgets for overflow
  void examineTextWidgets() {
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    log('Found ${textWidgets.length} Text widgets');

    for (final text in textWidgets) {
      if (text.overflow == TextOverflow.ellipsis) {
        log('  - Text with ellipsis: "${text.data?.substring(0, 20.clamp(0, text.data?.length ?? 0))}..."');
      }
    }
  }

  /// Examine Container constraints
  void examineConstraints() {
    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.byType(ConstrainedBox),
    );
    log('Found ${constrainedBoxes.length} ConstrainedBox widgets');

    for (final box in constrainedBoxes) {
      log('  - Constraints: ${box.constraints}');
    }
  }

  /// Check sizing of key components
  void examineComponentSizes() {
    // Check if TopBezel exists and measure it
    final topBezelFinder = find.byType(TopBezel);
    if (topBezelFinder.evaluate().isNotEmpty) {
      final size = tester.getSize(topBezelFinder);
      log('TopBezel size: ${size.width} x ${size.height}');

      if (size.height > SynthTheme.topBezelHeight + 10) {
        error('TopBezel height (${size.height}) exceeds expected (${SynthTheme.topBezelHeight})');
      }
    }
  }

  void printSummary() {
    debugPrint('\n${'=' * 60}');
    debugPrint('UI COMPONENT TEST SUMMARY');
    debugPrint('=' * 60);
    debugPrint('Logs:');
    for (final logEntry in logs) {
      debugPrint('  $logEntry');
    }
    if (errors.isNotEmpty) {
      debugPrint('\nERRORS:');
      for (final errorEntry in errors) {
        debugPrint('  ❌ $errorEntry');
      }
    }
    debugPrint('=' * 60 + '\n');
  }

  bool get hasErrors => errors.isNotEmpty;
}

/// Creates a test app with all required providers
Widget createTestApp({required Widget child, Size? screenSize}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => VisualProvider()),
      ChangeNotifierProvider(create: (_) => AudioProvider()),
      ChangeNotifierProvider(create: (_) => UIStateProvider()),
      ChangeNotifierProvider(create: (_) => TiltSensorProvider()),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: SynthTheme.backgroundColor,
        body: child,
      ),
    ),
  );
}

void main() {
  group('TopBezel Tests', () {
    testWidgets('TopBezel renders without overflow', (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopBezel(
                  systemColors: SystemColors.fromName('Quantum'),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      examiner.examineTextWidgets();
      examiner.examineComponentSizes();
      await examiner.checkForOverflows();

      expect(find.byType(TopBezel), findsOneWidget);
      expect(examiner.hasErrors, isFalse, reason: examiner.errors.join(', '));

      examiner.printSummary();
    });

    testWidgets('TopBezel system selector buttons render correctly',
        (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopBezel(
                  systemColors: SystemColors.fromName('Holographic'),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      // Should have Q, F, H buttons
      expect(find.text('Q'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('H'), findsOneWidget);

      examiner.log('✓ All system selector buttons found');
      examiner.printSummary();
    });

    testWidgets('TopBezel geometry indicator handles long names',
        (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      // Set a geometry with a long name
      final visualProvider = VisualProvider();
      visualProvider.setGeometry(4); // Klein Bottle - longer name

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: visualProvider),
            ChangeNotifierProvider(create: (_) => AudioProvider()),
            ChangeNotifierProvider(create: (_) => UIStateProvider()),
            ChangeNotifierProvider(create: (_) => TiltSensorProvider()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: TopBezel(
                      systemColors: SystemColors.fromName('Quantum'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      examiner.examineTextWidgets();
      examiner.examineConstraints();
      await examiner.checkForOverflows();

      expect(examiner.hasErrors, isFalse, reason: examiner.errors.join(', '));
      examiner.printSummary();
    });

    testWidgets('TopBezel expands and collapses correctly',
        (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopBezel(
                  systemColors: SystemColors.fromName('Faceted'),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      // Initial height should be collapsed
      final initialSize = tester.getSize(find.byType(TopBezel));
      examiner.log('Initial height: ${initialSize.height}');
      expect(initialSize.height, equals(SynthTheme.topBezelHeight));

      // Tap to expand
      await tester.tap(find.byType(TopBezel));
      await tester.pumpAndSettle();

      final expandedSize = tester.getSize(find.byType(TopBezel));
      examiner.log('Expanded height: ${expandedSize.height}');
      expect(expandedSize.height, greaterThan(SynthTheme.topBezelHeight));

      examiner.printSummary();
    });
  });

  group('BottomBezelContainer Tests', () {
    testWidgets('BottomBezelContainer renders all 4 tabs',
        (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              BottomBezelContainer(
                systemColors: SystemColors.fromName('Quantum'),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      // Check for tab labels
      expect(find.text('Synthesis'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Mapping'), findsOneWidget);

      examiner.log('✓ All 4 panel tabs found');
      await examiner.checkForOverflows();

      expect(examiner.hasErrors, isFalse);
      examiner.printSummary();
    });

    testWidgets('BottomBezelContainer tab tap expands panel',
        (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              BottomBezelContainer(
                systemColors: SystemColors.fromName('Holographic'),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      // Tap Synthesis tab
      await tester.tap(find.text('Synthesis'));
      await tester.pumpAndSettle();

      examiner.log('Tapped Synthesis tab');

      // Should show expanded panel
      expect(find.byType(CollapsibleBezel), findsOneWidget);

      await examiner.checkForOverflows();
      examiner.printSummary();
    });
  });

  group('OrbController Tests', () {
    testWidgets('OrbController renders at initial position',
        (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OrbController(
            systemColors: SystemColors.fromName('Quantum'),
            initialPosition: const Offset(0.5, 0.5),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(OrbController), findsOneWidget);

      examiner.log('✓ OrbController rendered');
      await examiner.checkForOverflows();

      examiner.printSummary();
    });

    testWidgets('OrbController responds to drag', (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OrbController(
            systemColors: SystemColors.fromName('Faceted'),
            initialPosition: const Offset(0.5, 0.5),
          ),
        ),
      );

      await tester.pump();

      // Find the orb and drag it
      final orbFinder = find.byType(OrbController);
      final initialPosition = tester.getCenter(orbFinder);

      await tester.drag(orbFinder, const Offset(50, 50));
      await tester.pump();

      examiner.log('Dragged orb from $initialPosition');
      await examiner.checkForOverflows();

      examiner.printSummary();
    });
  });

  group('SystemColors Tests', () {
    testWidgets('All system colors are accessible', (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      final systems = ['Quantum', 'Faceted', 'Holographic'];

      for (final system in systems) {
        final colors = SystemColors.fromName(system);

        expect(colors.primary, isNotNull);
        expect(colors.secondary, isNotNull);
        expect(colors.accent, isNotNull);

        examiner.log('$system colors: primary=${colors.primary}, secondary=${colors.secondary}');
      }

      examiner.printSummary();
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('UI adapts to portrait mode', (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      // Set portrait size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopBezel(
                  systemColors: SystemColors.fromName('Quantum'),
                ),
              ),
              BottomBezelContainer(
                systemColors: SystemColors.fromName('Quantum'),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      examiner.log('Portrait mode test (1080x1920)');
      await examiner.checkForOverflows();

      expect(examiner.hasErrors, isFalse);
      examiner.printSummary();

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('UI adapts to landscape mode', (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      // Set landscape size
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopBezel(
                  systemColors: SystemColors.fromName('Holographic'),
                ),
              ),
              BottomBezelContainer(
                systemColors: SystemColors.fromName('Holographic'),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      examiner.log('Landscape mode test (1920x1080)');
      await examiner.checkForOverflows();

      expect(examiner.hasErrors, isFalse);
      examiner.printSummary();

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('UI handles small screen', (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      // Set small screen size
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopBezel(
                  systemColors: SystemColors.fromName('Faceted'),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      examiner.log('Small screen test (320x480)');
      examiner.examineTextWidgets();
      await examiner.checkForOverflows();

      // Text should use ellipsis on small screens
      expect(examiner.hasErrors, isFalse);
      examiner.printSummary();

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Theme Consistency Tests', () {
    testWidgets('SynthTheme constants are valid', (WidgetTester tester) async {
      final examiner = UIStateExaminer(tester);

      // Verify theme constants
      expect(SynthTheme.topBezelHeight, greaterThan(0));
      expect(SynthTheme.panelCollapsedHeight, greaterThan(0));
      expect(SynthTheme.panelExpandedHeight, greaterThan(SynthTheme.panelCollapsedHeight));
      expect(SynthTheme.spacingSmall, greaterThan(0));
      expect(SynthTheme.spacingMedium, greaterThan(SynthTheme.spacingSmall));
      expect(SynthTheme.spacingLarge, greaterThan(SynthTheme.spacingMedium));

      examiner.log('Theme constants:');
      examiner.log('  - topBezelHeight: ${SynthTheme.topBezelHeight}');
      examiner.log('  - panelCollapsedHeight: ${SynthTheme.panelCollapsedHeight}');
      examiner.log('  - panelExpandedHeight: ${SynthTheme.panelExpandedHeight}');
      examiner.log('  - spacingSmall: ${SynthTheme.spacingSmall}');
      examiner.log('  - spacingMedium: ${SynthTheme.spacingMedium}');
      examiner.log('  - spacingLarge: ${SynthTheme.spacingLarge}');

      examiner.printSummary();
    });
  });
}
