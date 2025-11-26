/**
 * Top Bezel
 *
 * Slim status bar showing visual system selector, FPS counter,
 * geometry display, and settings access. Collapsible to maximize
 * screen real estate.
 *
 * Visual States:
 * - Collapsed: 44px height, essential info only
 * - Expanded: 120px height, detailed controls
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/visual_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/tilt_sensor_provider.dart';

class TopBezel extends StatefulWidget {
  final SystemColors systemColors;

  const TopBezel({
    Key? key,
    required this.systemColors,
  }) : super(key: key);

  @override
  State<TopBezel> createState() => _TopBezelState();
}

class _TopBezelState extends State<TopBezel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SynthTheme.transitionStandard,
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: SynthTheme.topBezelHeight,
      end: 120.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: SynthTheme.curveStandard,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final visualProvider = Provider.of<VisualProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value + SynthTheme.spacingXSmall,
          decoration: BoxDecoration(
            color: SynthTheme.panelBackground.withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: widget.systemColors.primary.withOpacity(0.5),
                width: 2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Collapsed view (always visible)
              _buildCollapsedContent(uiState, visualProvider, audioProvider),

              // Expanded content (only when expanded)
              if (_isExpanded)
                Expanded(
                  child: _buildExpandedContent(
                      uiState, visualProvider, audioProvider),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsedContent(
    UIStateProvider uiState,
    VisualProvider visualProvider,
    AudioProvider audioProvider,
  ) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        height: SynthTheme.topBezelHeight,
        padding:
            const EdgeInsets.symmetric(horizontal: SynthTheme.spacingMedium),
        child: Row(
          children: [
            // Visual system selector
            _buildSystemSelector(visualProvider, audioProvider),

            const Spacer(),

            // FPS counter
            _buildFPSCounter(visualProvider),

            const SizedBox(width: SynthTheme.spacingMedium),

            // Current geometry
            _buildGeometryIndicator(visualProvider),

            const SizedBox(width: SynthTheme.spacingMedium),

            // Expand/collapse indicator
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: widget.systemColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSelector(
    VisualProvider visualProvider,
    AudioProvider audioProvider,
  ) {
    final systems = ['Quantum', 'Faceted', 'Holographic'];
    final currentSystem = visualProvider.currentSystem;

    return Row(
      children: systems.map((system) {
        final isActive = currentSystem.toLowerCase() == system.toLowerCase();
        final systemColors = SystemColors.fromName(system);

        return Padding(
          padding: const EdgeInsets.only(right: SynthTheme.spacingSmall),
          child: GestureDetector(
            onTap: () {
              visualProvider.setSystem(system);
              audioProvider.setVisualSystem(system);
            },
            child: AnimatedContainer(
              duration: SynthTheme.transitionQuick,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? systemColors.primary.withOpacity(0.3)
                    : Colors.transparent,
                border: Border.all(
                  color:
                      isActive ? systemColors.primary : SynthTheme.borderSubtle,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
                boxShadow: isActive
                    ? SynthTheme(systemColors: systemColors)
                        .getGlow(GlowIntensity.active)
                    : null,
              ),
              child: Text(
                system[0], // Single letter (Q, F, H)
                style: SynthTheme.textStyleBody.copyWith(
                  color: isActive
                      ? systemColors.primary
                      : SynthTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFPSCounter(VisualProvider visualProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: SynthTheme.cardBackground,
        borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
        border: Border.all(color: SynthTheme.borderSubtle),
      ),
      child: Text(
        '${visualProvider.currentFPS.round()} FPS',
        style: SynthTheme.textStyleCaption.copyWith(
          color: visualProvider.currentFPS >= 55
              ? Colors.green
              : visualProvider.currentFPS >= 40
                  ? Colors.yellow
                  : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGeometryIndicator(VisualProvider visualProvider) {
    final geometries = [
      'Hypercube',
      'Tesseract',
      'Hypersphere',
      'Torus',
      '24-Cell',
      '120-Cell',
      'Klein Bottle',
      'Fractal',
    ];

    final currentGeometry = geometries[visualProvider.currentGeometry];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: SynthTheme.cardBackground,
        borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
        border: Border.all(
          color: widget.systemColors.primary.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category,
            color: widget.systemColors.primary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            currentGeometry,
            style: SynthTheme.textStyleCaption.copyWith(
              color: widget.systemColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    UIStateProvider uiState,
    VisualProvider visualProvider,
    AudioProvider audioProvider,
  ) {
    final tiltSensor = Provider.of<TiltSensorProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(SynthTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick settings row
          Row(
            children: [
              _buildQuickToggle(
                'Grid',
                uiState.xyPadShowGrid,
                (value) => uiState.setXYPadShowGrid(value),
                Icons.grid_on,
              ),
              const SizedBox(width: SynthTheme.spacingSmall),
              _buildQuickToggle(
                'Tilt',
                uiState.tiltEnabled,
                (value) {
                  uiState.setTiltEnabled(value);
                  if (value) {
                    tiltSensor.enable();
                  } else {
                    tiltSensor.disable();
                  }
                },
                Icons.screen_rotation,
              ),
              const SizedBox(width: SynthTheme.spacingSmall),
              _buildQuickToggle(
                'Orb',
                uiState.orbControllerVisible,
                (value) => uiState.setOrbControllerVisible(value),
                Icons.control_camera,
              ),
            ],
          ),

          const SizedBox(height: SynthTheme.spacingMedium),

          // Stats display
          _buildStatsDisplay(visualProvider, audioProvider),
        ],
      ),
    );
  }

  Widget _buildQuickToggle(
    String label,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: SynthTheme.transitionQuick,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: value
                ? widget.systemColors.primary.withOpacity(0.2)
                : SynthTheme.cardBackground,
            border: Border.all(
              color:
                  value ? widget.systemColors.primary : SynthTheme.borderSubtle,
              width: value ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: value
                    ? widget.systemColors.primary
                    : SynthTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: SynthTheme.textStyleCaption.copyWith(
                  color: value
                      ? widget.systemColors.primary
                      : SynthTheme.textSecondary,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDisplay(
    VisualProvider visualProvider,
    AudioProvider audioProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(SynthTheme.spacingSmall),
      decoration: BoxDecoration(
        color: SynthTheme.cardBackground,
        borderRadius: BorderRadius.circular(SynthTheme.radiusMedium),
        border: Border.all(color: SynthTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Vertices', visualProvider.getActiveVertexCount().toString()),
          _buildStatItem('Voices', audioProvider.getVoiceCount().toString()),
          _buildStatItem(
              'Polyphony', audioProvider.activeNotes.length.toString() + '/8'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: SynthTheme.textStyleBody.copyWith(
            color: widget.systemColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: SynthTheme.textStyleCaption,
        ),
      ],
    );
  }
}
