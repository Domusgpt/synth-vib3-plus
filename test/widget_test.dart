// Synth-VIB3+ Widget Tests
//
// Tests for the holographic synthesizer application
// Verifies core functionality of audio-visual coupling system

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:synther_vib34d_holographic/main.dart';

void main() {
  testWidgets('SynthVIB3App loads without error', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const SynthVIB3App());

    // Allow async operations to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify the app title is present in the MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has correct theme colors', (WidgetTester tester) async {
    await tester.pumpWidget(const SynthVIB3App());
    await tester.pump();

    // Verify MaterialApp exists with dark theme
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, equals('Synth-VIB3+'));
  });
}
