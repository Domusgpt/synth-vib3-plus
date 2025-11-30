// Synth-VIB3+ Main Application
//
// Professional holographic synthesizer with 4D visualization,
// multi-touch XY pad, orb controller, and collapsible UI.
//
// A Paul Phillips Manifestation
//
import 'package:flutter/material.dart';
import 'ui/screens/synth_main_screen.dart';

void main() {
  runApp(const SynthVIB3App());
}

class SynthVIB3App extends StatelessWidget {
  final bool enableVisualizer;
  final Widget? homeOverride;
  final bool enableTiltSensors;
  final bool applySystemUi;

  const SynthVIB3App({
    super.key,
    this.enableVisualizer = true,
    this.homeOverride,
    this.enableTiltSensors = true,
    this.applySystemUi = true,
  });

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
      home:
          homeOverride ??
          SynthMainScreen(
            enableVisualizer: enableVisualizer,
            enableTiltSensors: enableTiltSensors,
            applySystemUi: applySystemUi,
          ),
    );
  }
}
