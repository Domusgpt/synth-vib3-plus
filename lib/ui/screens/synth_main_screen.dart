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
import '../components/geometry_icons.dart';
// orb_controller.dart removed - using inline _MinimalOrbController instead
// geometry_hero.dart removed - using inline _FixedGeometryHero
import '../panels/synthesis_parameters_panel.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/visual_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/tilt_sensor_provider.dart';
import '../../vib3/rendering/vib3_shader_renderer.dart';
import '../../vib3/core/vib3_engine.dart';
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
        ChangeNotifierProvider(create: (_) => UIStateProvider()),
        ChangeNotifierProvider(create: (_) => VisualProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => TiltSensorProvider()),
        // ParameterBridge connects audio ↔ visual with proxy providers
        ProxyProvider2<AudioProvider, VisualProvider, ParameterBridge>(
          update: (_, audio, visual, previous) {
            final bridge = previous ?? ParameterBridge(
              audioProvider: audio,
              visualProvider: visual,
            );
            // Start the bridge if not already running
            if (!bridge.isRunning) {
              bridge.start();
            }
            return bridge;
          },
          dispose: (_, bridge) => bridge.dispose(),
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
    // DON'T auto-start audio - let user trigger via XY pad touch
    // Audio will start when they touch the performance pad
  }

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final visualProvider = Provider.of<VisualProvider>(context);
    final systemColors = visualProvider.systemColors;

    return Scaffold(
      backgroundColor: systemColors.background,
      body: Stack(
        children: [
          // Layer 1: Background visualization (VIB3+ Shader)
          _buildVisualizationLayer(context),

          // Layer 2: Main content column
          Column(
            children: [
              // Top Bezel (system selector)
              TopBezel(systemColors: systemColors),

              // XY Performance Pad (touch for notes) - takes available space
              Expanded(
                flex: 3,
                child: XYPerformancePad(
                  systemColors: systemColors,
                  showGrid: uiState.xyPadShowGrid,
                  backgroundVisualization: null,
                ),
              ),

              // Bottom panel section (Geometry Hero + Scrollable Parameters)
              _buildBottomPanelSection(context, systemColors),
            ],
          ),

          // Layer 3: Orb Controller (minimized in corner, expands when active)
          // Positioned in bottom-left, above the panel
          if (uiState.orbControllerVisible)
            Positioned(
              left: 16,
              // Panel heights: collapsed ~154px, expanded ~55% screen
              bottom: uiState.isAnyPanelExpanded()
                  ? (MediaQuery.of(context).size.height * 0.55).clamp(320.0, 520.0) + 16
                  : 170,
              child: _MinimalOrbController(
                systemColors: systemColors,
                isActive: uiState.orbControllerActive,
              ),
            ),

          // Layer 4: Side bezels (portrait mode only)
          if (_isPortrait(context)) ...[
            _buildLeftBezel(context, systemColors),
            _buildRightBezel(context, systemColors),
          ],

          // Layer 5: Debug overlay (development only)
          if (_shouldShowDebugOverlay(context))
            _buildDebugOverlay(context, uiState, visualProvider),
        ],
      ),
    );
  }

  /// Build the bottom panel section - portrait phone optimized
  /// Structure: FIXED HERO (always visible) + SCROLLABLE SLIDERS (when expanded)
  Widget _buildBottomPanelSection(BuildContext context, SystemColors systemColors) {
    final uiState = Provider.of<UIStateProvider>(context);
    final isPanelExpanded = uiState.isAnyPanelExpanded();
    final screenHeight = MediaQuery.of(context).size.height;

    // Hero height: ~120px (System/Method row + Voice row + Config display)
    // Collapsed: just hero + expand bar = ~168px
    // Expanded: hero + scrollable sliders up to 55% screen
    const heroHeight = 120.0;
    const expandBarHeight = 48.0; // Larger touch target
    final collapsedHeight = heroHeight + expandBarHeight;
    final expandedHeight = (screenHeight * 0.55).clamp(320.0, 520.0);

    return AnimatedContainer(
      duration: SynthTheme.transitionStandard,
      height: isPanelExpanded ? expandedHeight : collapsedHeight,
      decoration: BoxDecoration(
        color: systemColors.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: systemColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // FIXED HERO - Always visible (synthesis method + voice character)
          SizedBox(
            height: heroHeight,
            child: _FixedGeometryHero(systemColors: systemColors),
          ),

          // Expand/collapse bar - larger touch target (48px)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              debugPrint('Panel tap: isPanelExpanded=$isPanelExpanded');
              if (isPanelExpanded) {
                uiState.collapseAllPanels();
              } else {
                uiState.expandPanel('synthesis');
              }
            },
            child: Container(
              height: 48, // Increased from 24px for better touch
              color: systemColors.background.withOpacity(0.6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: systemColors.primary.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPanelExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: systemColors.primary.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPanelExpanded ? 'COLLAPSE' : 'MORE CONTROLS',
                        style: SynthTheme.textStyleCaption.copyWith(
                          color: systemColors.primary.withOpacity(0.7),
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // SCROLLABLE SLIDERS - Only when expanded
          if (isPanelExpanded)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: const SynthesisParametersPanel(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVisualizationLayer(BuildContext context) {
    // Use GPU shader-based renderer for proper VIB3+ rendering
    return Positioned.fill(
      child: Consumer2<VisualProvider, AudioProvider>(
        builder: (context, visualProvider, audioProvider, child) {
          // Map string system to enum (case-insensitive)
          VisualSystem system;
          switch (visualProvider.currentSystem.toLowerCase()) {
            case 'quantum':
              system = VisualSystem.quantum;
              break;
            case 'holographic':
              system = VisualSystem.holographic;
              break;
            case 'faceted':
            default:
              system = VisualSystem.faceted;
          }

          // Get audio features for reactivity
          final features = audioProvider.currentFeatures;
          AudioReactivityData? audioData;
          if (features != null && audioProvider.isPlaying) {
            audioData = AudioReactivityData(
              bassEnergy: features.bassEnergy.clamp(0.0, 1.0),
              midEnergy: features.midEnergy.clamp(0.0, 1.0),
              highEnergy: features.highEnergy.clamp(0.0, 1.0),
              rmsAmplitude: features.rms.clamp(0.0, 1.0),
            );
          }

          return VIB3AnimatedShaderWidget(
            system: system,
            geometryIndex: visualProvider.currentGeometry,
            audioData: audioData,
            audioReactivityStrength: 0.5,
            hueShift: visualProvider.hueShift,
            glowIntensity: visualProvider.glowIntensity,
            autoRotateSpeed: visualProvider.rotationSpeed * 0.3,
            enableInteraction: false,  // DISABLED: Let XY pad handle all touches for audio
          );
        },
      ),
    );
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
          color: systemColors.surface.withOpacity(0.8),
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
          color: systemColors.surface.withOpacity(0.8),
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
          color: systemColors.surface,
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

/// Fixed Geometry Hero - Always visible at top of bottom panel
/// Shows: System selector + Synthesis Method + Voice Character
/// Uses proper geometric icons (no emojis) with 40px+ touch targets
class _FixedGeometryHero extends StatelessWidget {
  final SystemColors systemColors;

  const _FixedGeometryHero({required this.systemColors});

  // Voice character names for tooltips
  static const _voiceNames = [
    'Fundamental', 'Complex', 'Smooth', 'Cyclic',
    'Twisted', 'Recursive', 'Flowing', 'Crystal',
  ];

  @override
  Widget build(BuildContext context) {
    final visualProvider = Provider.of<VisualProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final currentGeometry = visualProvider.currentGeometry;
    final currentCore = currentGeometry ~/ 8;
    final currentBase = currentGeometry % 8;
    final currentSystem = visualProvider.currentSystem.toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // Row 1: System selector (Q/F/H) + Method selector (DIRECT/FM/RING)
          SizedBox(
            height: 38,
            child: Row(
              children: [
                // System buttons (3)
                for (final system in ['quantum', 'faceted', 'holographic'])
                  _SystemIconButton(
                    systemName: system,
                    isActive: currentSystem == system,
                    onTap: () {
                      visualProvider.setSystem(system);
                      audioProvider.setVisualSystem(system);
                    },
                  ),

                const SizedBox(width: 12),

                // Method buttons (3) - takes remaining space
                Expanded(
                  child: Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Expanded(
                          child: _MethodIconButton(
                            methodIndex: i,
                            isActive: currentCore == i,
                            systemColors: systemColors,
                            onTap: () {
                              final newGeometry = (i * 8) + currentBase;
                              visualProvider.setGeometry(newGeometry);
                              audioProvider.setSynthesisBranch(newGeometry);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Row 2: Voice Character (8 geometry icons)
          SizedBox(
            height: 48,
            child: Row(
              children: [
                // Label
                SizedBox(
                  width: 40,
                  child: Text(
                    'VOICE',
                    style: SynthTheme.textStyleCaption.copyWith(
                      color: SynthTheme.textDim,
                      fontSize: 9,
                    ),
                  ),
                ),

                // 8 geometry buttons
                Expanded(
                  child: Row(
                    children: [
                      for (int i = 0; i < 8; i++)
                        Expanded(
                          child: _VoiceIconButton(
                            geometryIndex: i,
                            isActive: currentBase == i,
                            systemColors: systemColors,
                            tooltip: _voiceNames[i],
                            onTap: () {
                              final newGeometry = (currentCore * 8) + i;
                              visualProvider.setGeometry(newGeometry);
                              audioProvider.setSynthesisBranch(newGeometry);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Row 3: Current config display
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${['DIRECT', 'FM', 'RING'][currentCore]}: ${_voiceNames[currentBase]}',
                  style: SynthTheme.textStyleCaption.copyWith(
                    color: systemColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// System icon button (Q/F/H)
class _SystemIconButton extends StatelessWidget {
  final String systemName;
  final bool isActive;
  final VoidCallback onTap;

  const _SystemIconButton({
    required this.systemName,
    required this.isActive,
    required this.onTap,
  });

  Color get _systemColor {
    switch (systemName) {
      case 'quantum':
        return const Color(0xFF00FFFF);
      case 'faceted':
        return const Color(0xFF4488FF);
      case 'holographic':
        return const Color(0xFFFFAA00);
      default:
        return Colors.white;
    }
  }

  String get _label {
    switch (systemName) {
      case 'quantum':
        return 'Q';
      case 'faceted':
        return 'F';
      case 'holographic':
        return 'H';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? _systemColor.withOpacity(0.25) : Colors.transparent,
          border: Border.all(
            color: isActive ? _systemColor : _systemColor.withOpacity(0.4),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            _label,
            style: TextStyle(
              color: isActive ? _systemColor : _systemColor.withOpacity(0.7),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

/// Method icon button (DIRECT/FM/RING)
class _MethodIconButton extends StatelessWidget {
  final int methodIndex;
  final bool isActive;
  final SystemColors systemColors;
  final VoidCallback onTap;

  const _MethodIconButton({
    required this.methodIndex,
    required this.isActive,
    required this.systemColors,
    required this.onTap,
  });

  static const _labels = ['DIRECT', 'FM', 'RING'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? systemColors.primary.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? systemColors.primary
                : systemColors.primary.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SynthesisMethodIcon(
              methodIndex: methodIndex,
              color: isActive ? systemColors.primary : systemColors.primary.withOpacity(0.6),
              size: 18,
              isActive: isActive,
            ),
            const SizedBox(width: 4),
            Text(
              _labels[methodIndex],
              style: SynthTheme.textStyleCaption.copyWith(
                color: isActive ? systemColors.primary : SynthTheme.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Voice icon button (8 geometry types)
class _VoiceIconButton extends StatelessWidget {
  final int geometryIndex;
  final bool isActive;
  final SystemColors systemColors;
  final String tooltip;
  final VoidCallback onTap;

  const _VoiceIconButton({
    required this.geometryIndex,
    required this.isActive,
    required this.systemColors,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive
              ? systemColors.primary.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? systemColors.primary
                : systemColors.primary.withOpacity(0.25),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: GeometryIcon(
            geometryIndex: geometryIndex,
            color: isActive ? systemColors.primary : systemColors.primary.withOpacity(0.5),
            size: 24,
            isActive: isActive,
          ),
        ),
      ),
    );
  }
}

/// Minimal orb controller - small circle that expands when touched
class _MinimalOrbController extends StatefulWidget {
  final SystemColors systemColors;
  final bool isActive;

  const _MinimalOrbController({
    required this.systemColors,
    required this.isActive,
  });

  @override
  State<_MinimalOrbController> createState() => _MinimalOrbControllerState();
}

class _MinimalOrbControllerState extends State<_MinimalOrbController>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    // Collapsed: 44px, Expanded when dragging: 80px
    final size = _isDragging ? 80.0 : 44.0;

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
          _dragOffset = Offset.zero;
        });
        uiState.setOrbControllerActive(true);
      },
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta / 40; // Scale down for sensitivity
          _dragOffset = Offset(
            _dragOffset.dx.clamp(-1.0, 1.0),
            _dragOffset.dy.clamp(-1.0, 1.0),
          );
        });

        // Apply pitch bend (X) and vibrato (Y)
        final pitchBend = _dragOffset.dx * uiState.orbPitchBendRange;
        audioProvider.setPitchBend(pitchBend);
        audioProvider.setVibratoDepth((1.0 - _dragOffset.dy) / 2.0);
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging = false;
          _dragOffset = Offset.zero;
        });
        uiState.setOrbControllerActive(false);
        audioProvider.setPitchBend(0);
        audioProvider.setVibratoDepth(0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.systemColors.primary,
              widget.systemColors.accent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.systemColors.primary.withOpacity(_isDragging ? 0.6 : 0.3),
              blurRadius: _isDragging ? 20 : 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Icon(
                _isDragging ? Icons.control_camera : Icons.touch_app,
                color: Colors.white.withOpacity(0.8),
                size: _isDragging ? 32 : 20,
              );
            },
          ),
        ),
      ),
    );
  }
}
