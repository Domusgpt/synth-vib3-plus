/**
 * Synth Main Screen
 *
 * Master UI scaffold that assembles all components:
 * - Top bezel (system selector, stats)
 * - XY performance pad (with VIB3+ visualization background)
 * - Orb controller (floating pitch modulation)
 * - Bottom bezel (collapsible panels)
 *
 * Layout Philosophy:
 * - Visualization-first: 75-90% screen real estate for visuals
 * - Collapsible everything: Maximize visual space when not needed
 * - Multi-touch optimized: Up to 8 simultaneous touch points
 * - Responsive: Adapts to portrait/landscape/tablet
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/top_bezel.dart';
import '../components/xy_performance_pad.dart';
import '../components/orb_controller.dart';
import '../components/collapsible_bezel.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/visual_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/tilt_sensor_provider.dart';
import '../../mapping/parameter_bridge.dart';

class SynthMainScreen extends StatefulWidget {
  const SynthMainScreen({Key? key}) : super(key: key);

  @override
  State<SynthMainScreen> createState() => _SynthMainScreenState();
}

class _SynthMainScreenState extends State<SynthMainScreen> {
  @override
  void initState() {
    super.initState();
    // Lock to fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Lock to landscape (can be made configurable later)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core state providers
        ChangeNotifierProvider(create: (_) => UIStateProvider()),
        ChangeNotifierProvider(create: (_) => VisualProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => TiltSensorProvider()),

        // Parameter bridge depends on Audio and Visual providers
        ChangeNotifierProxyProvider2<AudioProvider, VisualProvider, ParameterBridge>(
          create: (context) => ParameterBridge(
            audioProvider: Provider.of<AudioProvider>(context, listen: false),
            visualProvider: Provider.of<VisualProvider>(context, listen: false),
          ),
          update: (context, audio, visual, previous) => previous ?? ParameterBridge(
            audioProvider: audio,
            visualProvider: visual,
          ),
        ),
      ],
      child: const _SynthMainContent(),
    );
  }
}

class _SynthMainContent extends StatefulWidget {
  const _SynthMainContent({Key? key}) : super(key: key);

  @override
  State<_SynthMainContent> createState() => _SynthMainContentState();
}

class _SynthMainContentState extends State<_SynthMainContent> {
  @override
  void initState() {
    super.initState();

    // Initialize the sonic+visual coupling after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAudioVisualCoupling();
    });
  }

  /// Initialize and start the bidirectional audio-visual coupling
  void _initializeAudioVisualCoupling() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final visualProvider = Provider.of<VisualProvider>(context, listen: false);
    final parameterBridge = Provider.of<ParameterBridge>(context, listen: false);

    // Set initial visual system and geometry
    visualProvider.switchSystem('quantum'); // Start with Quantum system
    visualProvider.setGeometry(0); // Start with Tetrahedron (geometry 0)
    debugPrint('🎨 Initial state: Quantum Base Tetrahedron (Geometry 0)');

    // Sync initial state to audio (geometry 0 = Direct synthesis, Quantum = Pure timbre)
    audioProvider.setVisualSystem('quantum');
    audioProvider.setGeometry(0);
    debugPrint('🎵 Audio synced: Direct synthesis with Pure/Harmonic timbre');

    // Start audio generation
    audioProvider.startAudio();
    debugPrint('🎵 Audio generation started');

    // Start visual animation
    visualProvider.startAnimation();
    debugPrint('🎨 Visual animation started');

    // Start 60 FPS parameter bridge (THE MAGIC!)
    parameterBridge.start();
    debugPrint('🔄 Parameter bridge started at 60 FPS');
    debugPrint('✨ Bidirectional audio-visual coupling ACTIVE');
    debugPrint('💎 All 72 combinations available (3 systems × 24 geometries)');
  }

  @override
  void dispose() {
    // Clean shutdown
    try {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final visualProvider = Provider.of<VisualProvider>(context, listen: false);
      final parameterBridge = Provider.of<ParameterBridge>(context, listen: false);

      parameterBridge.stop();
      visualProvider.stopAnimation();
      audioProvider.stopAudio();
      debugPrint('🛑 Audio-visual coupling stopped');
    } catch (e) {
      debugPrint('⚠️ Error during dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final visualProvider = Provider.of<VisualProvider>(context);
    final systemColors = visualProvider.systemColors;

    return Scaffold(
      backgroundColor: SynthTheme.backgroundColor,
      body: Stack(
        children: [
          // Layer 1: Background visualization (VIB3+ WebGL)
          _buildVisualizationLayer(context),

          // Layer 2: XY Performance Pad (touch overlay)
          Positioned.fill(
            child: XYPerformancePad(
              systemColors: systemColors,
              showGrid: uiState.xyPadShowGrid,
              backgroundVisualization: null, // Visualization rendered separately
            ),
          ),

          // Layer 3: Top Bezel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBezel(systemColors: systemColors),
          ),

          // Layer 4: Bottom Bezel (collapsible panels)
          BottomBezelContainer(systemColors: systemColors),

          // Layer 5: Orb Controller (floating)
          if (uiState.orbControllerVisible)
            Positioned.fill(
              child: OrbController(
                systemColors: systemColors,
                initialPosition: _getOrbInitialPosition(context, uiState),
              ),
            ),

          // Layer 6: Side bezels (portrait mode only)
          if (_isPortrait(context)) ...[
            _buildLeftBezel(context, systemColors),
            _buildRightBezel(context, systemColors),
          ],

          // Layer 7: Debug overlay (development only)
          if (_shouldShowDebugOverlay(context))
            _buildDebugOverlay(context, uiState, visualProvider),
        ],
      ),
    );
  }

  Widget _buildVisualizationLayer(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: SynthTheme.backgroundColor,
        child: Center(
          child: Text(
            'VIB3+ Visualization\n(WebGL View)',
            textAlign: TextAlign.center,
            style: SynthTheme.textStyleBody.copyWith(
              color: SynthTheme.textDim,
            ),
          ),
        ),
      ),
    );
  }

  Offset _getOrbInitialPosition(BuildContext context, UIStateProvider uiState) {
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      // Landscape: Bottom-left corner
      return const Offset(0.15, 0.75);
    } else {
      // Portrait: Bottom-center
      return const Offset(0.5, 0.8);
    }
  }

  bool _isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  Widget _buildLeftBezel(BuildContext context, SystemColors systemColors) {
    final uiState = Provider.of<UIStateProvider>(context);

    return Positioned(
      left: 0,
      top: SynthTheme.topBezelHeight + SynthTheme.spacingLarge,
      bottom: SynthTheme.panelCollapsedHeight + SynthTheme.spacingLarge,
      child: Container(
        width: SynthTheme.sideBezelWidth,
        decoration: BoxDecoration(
          color: SynthTheme.panelBackground.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(SynthTheme.radiusLarge),
            bottomRight: Radius.circular(SynthTheme.radiusLarge),
          ),
          border: Border.all(color: SynthTheme.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildThumbPad('Octave -', systemColors, () {
              final current = uiState.pitchRangeStart;
              uiState.setPitchRangeStart((current - 12).clamp(0, 127));
              uiState.setPitchRangeEnd((uiState.pitchRangeEnd - 12).clamp(0, 127));
            }),
            _buildThumbPad('Octave +', systemColors, () {
              final current = uiState.pitchRangeStart;
              uiState.setPitchRangeStart((current + 12).clamp(0, 127));
              uiState.setPitchRangeEnd((uiState.pitchRangeEnd + 12).clamp(0, 127));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRightBezel(BuildContext context, SystemColors systemColors) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Positioned(
      right: 0,
      top: SynthTheme.topBezelHeight + SynthTheme.spacingLarge,
      bottom: SynthTheme.panelCollapsedHeight + SynthTheme.spacingLarge,
      child: Container(
        width: SynthTheme.sideBezelWidth,
        decoration: BoxDecoration(
          color: SynthTheme.panelBackground.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(SynthTheme.radiusLarge),
            bottomLeft: Radius.circular(SynthTheme.radiusLarge),
          ),
          border: Border.all(color: SynthTheme.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildThumbPad('Filter+', systemColors, () {
              final current = audioProvider.filterCutoff;
              audioProvider.setFilterCutoff((current * 1.2).clamp(20.0, 20000.0));
            }),
            _buildThumbPad('Filter-', systemColors, () {
              final current = audioProvider.filterCutoff;
              audioProvider.setFilterCutoff((current / 1.2).clamp(20.0, 20000.0));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbPad(String label, SystemColors systemColors, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 60,
        decoration: BoxDecoration(
          color: SynthTheme.cardBackground,
          borderRadius: BorderRadius.circular(SynthTheme.radiusMedium),
          border: Border.all(color: systemColors.primary.withOpacity(0.5)),
          boxShadow: SynthTheme(systemColors: systemColors).getGlow(GlowIntensity.inactive),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: SynthTheme.textStyleCaption.copyWith(
              color: systemColors.primary,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowDebugOverlay(BuildContext context) {
    // Show debug overlay in debug mode only
    return false; // Set to true for debugging
  }

  Widget _buildDebugOverlay(
    BuildContext context,
    UIStateProvider uiState,
    VisualProvider visualProvider,
  ) {
    return Positioned(
      bottom: SynthTheme.panelCollapsedHeight + SynthTheme.spacingMedium,
      right: SynthTheme.spacingMedium,
      child: Container(
        padding: const EdgeInsets.all(SynthTheme.spacingSmall),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG',
              style: SynthTheme.textStyleCaption.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'FPS: ${visualProvider.currentFPS.round()}',
              style: SynthTheme.textStyleCaption.copyWith(color: Colors.white),
            ),
            Text(
              'System: ${visualProvider.currentSystem}',
              style: SynthTheme.textStyleCaption.copyWith(color: Colors.white),
            ),
            Text(
              'Geometry: ${visualProvider.currentGeometry}',
              style: SynthTheme.textStyleCaption.copyWith(color: Colors.white),
            ),
            Text(
              'Orb: ${uiState.orbControllerPosition.dx.toStringAsFixed(2)}, ${uiState.orbControllerPosition.dy.toStringAsFixed(2)}',
              style: SynthTheme.textStyleCaption.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
