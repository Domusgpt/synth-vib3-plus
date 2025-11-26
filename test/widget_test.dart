// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:synther_vib34d_holographic/main.dart';
import 'package:synther_vib34d_holographic/ui/screens/synth_main_screen.dart';

void main() {
  testWidgets('Synth app boots with main screen', (WidgetTester tester) async {
    // Build the production app shell without heavy visualizer dependencies for tests.
    await tester.pumpWidget(
      const SynthVIB3App(
        enableVisualizer: false,
        enableTiltSensors: false,
        homeOverride: SynthMainScreen(
          enableVisualizer: false,
          enableTiltSensors: false,
          applySystemUi: false,
        ),
        applySystemUi: false,
      ),
    );

    // Expect the main screen to be present and the banner disabled.
    expect(find.byType(SynthMainScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);
  });
}
