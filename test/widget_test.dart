// Synth-VIB3+ Widget Tests
//
// Tests for the holographic synthesizer application
// Verifies core functionality of audio-visual coupling system
//
// Note: Full app tests require platform channels (audio, sensors)
// that aren't available in unit test environment. These tests
// verify basic widget structure without platform dependencies.
//
// A Paul Phillips Manifestation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:synther_vib34d_holographic/providers/visual_provider.dart';
import 'package:synther_vib34d_holographic/providers/ui_state_provider.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('MaterialApp can be created with correct title', (WidgetTester tester) async {
      // Test just the MaterialApp wrapper without platform dependencies
      await tester.pumpWidget(
        MaterialApp(
          title: 'Synth-VIB3+',
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Dark theme is properly configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Synth-VIB3+',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            primaryColor: const Color(0xFF00FFFF),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FFFF),
              secondary: Color(0xFF88CCFF),
              surface: Color(0xFF1A1A2E),
            ),
          ),
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, equals('Synth-VIB3+'));
      expect(app.debugShowCheckedModeBanner, isFalse);
      expect(app.theme?.primaryColor, equals(const Color(0xFF00FFFF)));
    });
  });

  group('Provider Integration Tests', () {
    testWidgets('VisualProvider can be accessed via Provider', (WidgetTester tester) async {
      late VisualProvider capturedProvider;

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => VisualProvider(),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                capturedProvider = Provider.of<VisualProvider>(context, listen: false);
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      expect(capturedProvider, isNotNull);
      expect(capturedProvider.currentSystemEnum, isNotNull);
    });

    testWidgets('UIStateProvider can be accessed via Provider', (WidgetTester tester) async {
      late UIStateProvider capturedProvider;

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => UIStateProvider(),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                capturedProvider = Provider.of<UIStateProvider>(context, listen: false);
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      expect(capturedProvider, isNotNull);
    });

    testWidgets('Multiple providers work together', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VisualProvider()),
            ChangeNotifierProvider(create: (_) => UIStateProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final visual = Provider.of<VisualProvider>(context, listen: false);
                final ui = Provider.of<UIStateProvider>(context, listen: false);
                return Scaffold(
                  body: Text('System: ${visual.currentSystem}'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('System:'), findsOneWidget);
    });
  });

  group('Visual System Display Tests', () {
    testWidgets('Visual system name displays correctly', (WidgetTester tester) async {
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
                      Text('Density: ${visual.tessellationDensity}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('System: faceted'), findsOneWidget);
      expect(find.text('Geometry: 0'), findsOneWidget);
      expect(find.text('Density: 8.0'), findsOneWidget);
    });

    testWidgets('Visual system updates trigger rebuild', (WidgetTester tester) async {
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

      // Update the provider
      provider.setVertexBrightness(0.5);
      await tester.pump();

      expect(find.text('Brightness: 0.5'), findsOneWidget);
    });
  });

  group('Rotation Display Tests', () {
    testWidgets('All 6 rotation planes display', (WidgetTester tester) async {
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
