/**
 * Synth-VIB3+ Main Application
 *
 * Professional holographic synthesizer with 4D visualization,
 * multi-touch XY pad, orb controller, and collapsible UI.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'ui/screens/synth_main_screen.dart';

void main() {
  runApp(const SynthVIB3App());
}

class SynthVIB3App extends StatelessWidget {
  const SynthVIB3App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synth-VIB3+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF00FFFF), // Quantum cyan
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFFF),
          secondary: Color(0xFF88CCFF),
          surface: Color(0xFF1A1A2E),
        ),
      ),
      home: const SynthMainScreen(),
    );
  }
}

