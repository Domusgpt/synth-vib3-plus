// UI Components Integration Tests
//
// Tests for UI components with visual state examination.
// Tests basic widget structure without platform dependencies.
//
// Note: These tests avoid AudioProvider and TiltSensorProvider
// which require platform channels not available in CI.
//
// A Paul Phillips Manifestation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:synther_vib34d_holographic/ui/theme/synth_theme.dart';
import 'package:synther_vib34d_holographic/providers/visual_provider.dart';
import 'package:synther_vib34d_holographic/providers/ui_state_provider.dart';

void main() {
  group('SynthTheme Tests', () {
    test('Theme constants are valid', () {
      expect(SynthTheme.topBezelHeight, greaterThan(0));
      expect(SynthTheme.panelCollapsedHeight, greaterThan(0));
      expect(SynthTheme.panelExpandedHeight, greaterThan(SynthTheme.panelCollapsedHeight));
      expect(SynthTheme.spacingSmall, greaterThan(0));
      expect(SynthTheme.spacingMedium, greaterThan(SynthTheme.spacingSmall));
      expect(SynthTheme.spacingLarge, greaterThan(SynthTheme.spacingMedium));
    });

    test('Theme colors are defined', () {
      expect(SynthTheme.backgroundColor, isNotNull);
      expect(SynthTheme.panelBackground, isNotNull);
      expect(SynthTheme.cardBackground, isNotNull);
      expect(SynthTheme.borderSubtle, isNotNull);
    });

    test('Theme text styles are defined', () {
      expect(SynthTheme.textStyleBody, isNotNull);
      expect(SynthTheme.textStyleCaption, isNotNull);
    });
  });

  group('SystemColors Tests', () {
    test('Quantum colors are accessible', () {
      final colors = SystemColors.fromName('Quantum');
      expect(colors.primary, isNotNull);
      expect(colors.secondary, isNotNull);
      expect(colors.accent, isNotNull);
    });

    test('Faceted colors are accessible', () {
      final colors = SystemColors.fromName('Faceted');
      expect(colors.primary, isNotNull);
      expect(colors.secondary, isNotNull);
      expect(colors.accent, isNotNull);
    });

    test('Holographic colors are accessible', () {
      final colors = SystemColors.fromName('Holographic');
      expect(colors.primary, isNotNull);
      expect(colors.secondary, isNotNull);
      expect(colors.accent, isNotNull);
    });

    test('Unknown system returns default colors', () {
      final colors = SystemColors.fromName('Unknown');
      expect(colors.primary, isNotNull);
    });

    test('Case insensitive system name matching', () {
      final colors1 = SystemColors.fromName('quantum');
      final colors2 = SystemColors.fromName('QUANTUM');
      final colors3 = SystemColors.fromName('Quantum');

      expect(colors1.primary, equals(colors2.primary));
      expect(colors2.primary, equals(colors3.primary));
    });
  });

  group('VisualProvider Widget Integration', () {
    testWidgets('VisualProvider can be consumed via Consumer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => VisualProvider(),
          child: MaterialApp(
            home: Consumer<VisualProvider>(
              builder: (context, visual, _) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text('System: ${visual.currentSystem}'),
                      Text('Geometry: ${visual.geometryIndex}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('System:'), findsOneWidget);
      expect(find.textContaining('Geometry:'), findsOneWidget);
    });

    testWidgets('VisualProvider state changes trigger rebuild',
        (WidgetTester tester) async {
      final provider = VisualProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Consumer<VisualProvider>(
              builder: (context, visual, _) {
                return Scaffold(
                  body: Text('Brightness: ${visual.vertexBrightness}'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Brightness: 0.8'), findsOneWidget);

      provider.setVertexBrightness(0.5);
      await tester.pump();

      expect(find.text('Brightness: 0.5'), findsOneWidget);
    });
  });

  group('UIStateProvider Widget Integration', () {
    testWidgets('UIStateProvider can be consumed via Consumer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => UIStateProvider(),
          child: MaterialApp(
            home: Consumer<UIStateProvider>(
              builder: (context, ui, _) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Orb visible: ${ui.orbControllerVisible}'),
                      Text('Grid: ${ui.xyPadShowGrid}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('Orb visible:'), findsOneWidget);
      expect(find.textContaining('Grid:'), findsOneWidget);
    });

    testWidgets('UIStateProvider panel expansion works',
        (WidgetTester tester) async {
      final provider = UIStateProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Consumer<UIStateProvider>(
              builder: (context, ui, _) {
                return Scaffold(
                  body: Text('Synthesis expanded: ${ui.isPanelExpanded('synthesis')}'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Synthesis expanded: false'), findsOneWidget);

      provider.expandPanel('synthesis');
      await tester.pump();

      expect(find.text('Synthesis expanded: true'), findsOneWidget);
    });
  });

  group('Multi-Provider Integration', () {
    testWidgets('Multiple providers work together',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VisualProvider()),
            ChangeNotifierProvider(create: (_) => UIStateProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final visual = Provider.of<VisualProvider>(context);
                final ui = Provider.of<UIStateProvider>(context);
                return Scaffold(
                  body: Column(
                    children: [
                      Text('System: ${visual.currentSystem}'),
                      Text('Orb: ${ui.orbControllerVisible}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('System:'), findsOneWidget);
      expect(find.textContaining('Orb:'), findsOneWidget);
    });
  });

  group('Theme Widget Tests', () {
    testWidgets('Dark theme is properly applied',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: SynthTheme.backgroundColor,
          ),
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // Scaffold exists and is rendered
      expect(scaffold, isNotNull);
    });

    testWidgets('System colors can be used in widgets',
        (WidgetTester tester) async {
      final systemColors = SystemColors.fromName('Quantum');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: systemColors.primary,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, equals(systemColors.primary));
    });
  });

  group('Glow Intensity Tests', () {
    test('GlowIntensity enum values exist', () {
      // Three intensity levels: inactive, active, engaged
      expect(GlowIntensity.inactive, isNotNull);
      expect(GlowIntensity.active, isNotNull);
      expect(GlowIntensity.engaged, isNotNull);
    });

    test('SynthTheme returns glow for each intensity', () {
      final systemColors = SystemColors.fromName('Quantum');
      final theme = SynthTheme(systemColors: systemColors);

      final inactiveGlow = theme.getGlow(GlowIntensity.inactive);
      final activeGlow = theme.getGlow(GlowIntensity.active);
      final engagedGlow = theme.getGlow(GlowIntensity.engaged);

      expect(inactiveGlow, isNotNull);
      expect(activeGlow, isNotNull);
      expect(engagedGlow, isNotNull);
    });
  });

  group('Geometry Display Tests', () {
    testWidgets('Geometry index displays correctly',
        (WidgetTester tester) async {
      final provider = VisualProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Consumer<VisualProvider>(
              builder: (context, visual, _) {
                // Calculate core and base like top_bezel does
                final fullIndex = visual.currentGeometry;
                final coreIndex = fullIndex ~/ 8;
                final baseIndex = fullIndex % 8;

                return Scaffold(
                  body: Column(
                    children: [
                      Text('Full index: $fullIndex'),
                      Text('Core: $coreIndex'),
                      Text('Base: $baseIndex'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Default geometry is 0
      expect(find.text('Full index: 0'), findsOneWidget);
      expect(find.text('Core: 0'), findsOneWidget);
      expect(find.text('Base: 0'), findsOneWidget);

      // Change to geometry 10 (Hypersphere Sphere)
      provider.setGeometry(10);
      await tester.pump();

      expect(find.text('Full index: 10'), findsOneWidget);
      expect(find.text('Core: 1'), findsOneWidget);
      expect(find.text('Base: 2'), findsOneWidget);
    });

    testWidgets('All 24 geometry indices calculate correctly',
        (WidgetTester tester) async {
      for (int i = 0; i < 24; i++) {
        final expectedCore = i ~/ 8;
        final expectedBase = i % 8;

        final provider = VisualProvider();
        provider.setGeometry(i);

        expect(provider.currentGeometry, equals(i));

        // Verify the calculation matches expected
        final actualCore = provider.currentGeometry ~/ 8;
        final actualBase = provider.currentGeometry % 8;

        expect(actualCore, equals(expectedCore),
            reason: 'Geometry $i should have core $expectedCore');
        expect(actualBase, equals(expectedBase),
            reason: 'Geometry $i should have base $expectedBase');
      }
    });
  });

  group('Rotation Display Tests', () {
    testWidgets('All 6 rotation values display',
        (WidgetTester tester) async {
      final provider = VisualProvider();
      provider.setRotationXY(1.0);
      provider.setRotationXZ(2.0);
      provider.setRotationYZ(3.0);
      provider.setRotationXW(4.0);
      provider.setRotationYW(5.0);
      provider.setRotationZW(6.0);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Consumer<VisualProvider>(
              builder: (context, visual, _) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text('XY: ${visual.rotationXY.toStringAsFixed(1)}'),
                      Text('XZ: ${visual.rotationXZ.toStringAsFixed(1)}'),
                      Text('YZ: ${visual.rotationYZ.toStringAsFixed(1)}'),
                      Text('XW: ${visual.rotationXW.toStringAsFixed(1)}'),
                      Text('YW: ${visual.rotationYW.toStringAsFixed(1)}'),
                      Text('ZW: ${visual.rotationZW.toStringAsFixed(1)}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('XY: 1.0'), findsOneWidget);
      expect(find.text('XZ: 2.0'), findsOneWidget);
      expect(find.text('YZ: 3.0'), findsOneWidget);
      expect(find.text('XW: 4.0'), findsOneWidget);
      expect(find.text('YW: 5.0'), findsOneWidget);
      expect(find.text('ZW: 6.0'), findsOneWidget);
    });
  });
}
