/**
 * Synth-VIB3+ Main Application
 *
 * Professional holographic synthesizer with 4D visualization,
 * multi-touch XY pad, orb controller, and collapsible UI.
 *
 * ARCHITECTURE:
 * - Providers: AudioProvider, VisualProvider, UIStateProvider, TiltSensorProvider
 * - ParameterBridge: 60 FPS bidirectional coupling between audio and visual
 * - 72 Geometry Combinations: 3 systems × 3 cores × 8 base geometries
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'providers/visual_provider.dart';
import 'providers/ui_state_provider.dart';
import 'providers/tilt_sensor_provider.dart';
import 'mapping/parameter_bridge.dart';
import 'ui/screens/synth_main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation for optimal experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const SynthVIB3App());
}

class SynthVIB3App extends StatefulWidget {
  const SynthVIB3App({Key? key}) : super(key: key);

  @override
  State<SynthVIB3App> createState() => _SynthVIB3AppState();
}

class _SynthVIB3AppState extends State<SynthVIB3App> {
  late final AudioProvider audioProvider;
  late final VisualProvider visualProvider;
  late final UIStateProvider uiStateProvider;
  late final TiltSensorProvider tiltSensorProvider;
  late final ParameterBridge parameterBridge;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    // Create providers
    audioProvider = AudioProvider();
    visualProvider = VisualProvider();
    uiStateProvider = UIStateProvider();
    tiltSensorProvider = TiltSensorProvider();

    // Create parameter bridge (connects audio ↔ visual)
    parameterBridge = ParameterBridge(
      audioProvider: audioProvider,
      visualProvider: visualProvider,
    );

    // Start parameter bridge (60 FPS update loop)
    parameterBridge.start();

    // Start visual animation
    visualProvider.startAnimation();

    debugPrint('✅ Synth-VIB3+ initialized with ParameterBridge');
    debugPrint('🎵 Ready for 72 geometry combinations');
  }

  @override
  void dispose() {
    parameterBridge.stop();
    audioProvider.dispose();
    visualProvider.dispose();
    uiStateProvider.dispose();
    tiltSensorProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
        ChangeNotifierProvider<VisualProvider>.value(value: visualProvider),
        ChangeNotifierProvider<UIStateProvider>.value(value: uiStateProvider),
        ChangeNotifierProvider<TiltSensorProvider>.value(value: tiltSensorProvider),
        ChangeNotifierProvider<ParameterBridge>.value(value: parameterBridge),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}

