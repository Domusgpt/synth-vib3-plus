/**
 * Synth-VIB3+ Main Application
 *
 * Professional holographic synthesizer with 4D visualization,
 * multi-touch XY pad, orb controller, and collapsible UI.
 *
 * ARCHITECTURE:
 * - Providers initialized at app level for global access
 * - ParameterBridge orchestrates bidirectional audio-visual coupling
 * - 60 FPS parameter update loop started automatically
 * - Firebase initialized for cloud preset sync
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Providers
import 'providers/audio_provider.dart';
import 'providers/visual_provider.dart';
import 'providers/ui_state_provider.dart';
import 'providers/tilt_sensor_provider.dart';

// Mapping
import 'mapping/parameter_bridge.dart';

// UI
import 'ui/screens/synth_main_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for cloud preset sync
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️  Firebase initialization failed: $e');
    debugPrint('📝 Cloud preset sync will be unavailable');
    // Continue without Firebase - offline mode
  }

  // Lock orientation and system UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SynthVIB3App());
}

class SynthVIB3App extends StatefulWidget {
  const SynthVIB3App({Key? key}) : super(key: key);

  @override
  State<SynthVIB3App> createState() => _SynthVIB3AppState();
}

class _SynthVIB3AppState extends State<SynthVIB3App> {
  // Core providers
  late final AudioProvider audioProvider;
  late final VisualProvider visualProvider;
  late final UIStateProvider uiStateProvider;
  late final TiltSensorProvider tiltSensorProvider;

  // Bidirectional parameter bridge
  late final ParameterBridge parameterBridge;

  @override
  void initState() {
    super.initState();

    // Initialize providers
    audioProvider = AudioProvider();
    visualProvider = VisualProvider();
    uiStateProvider = UIStateProvider();
    tiltSensorProvider = TiltSensorProvider();

    // Create parameter bridge (connects audio ↔ visual)
    parameterBridge = ParameterBridge(
      audioProvider: audioProvider,
      visualProvider: visualProvider,
    );

    // Start the 60 FPS bidirectional coupling loop
    parameterBridge.start();
    debugPrint('✅ Parameter bridge started at 60 FPS');

    // Start visual animation
    visualProvider.startAnimation();
    debugPrint('✅ Visual animation started');
  }

  @override
  void dispose() {
    // Clean shutdown
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

