/**
 * Geometry Panel
 *
 * Controls for 4D geometry selection, polytope core, rotation parameters,
 * and projection settings.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/holographic_slider.dart';
import '../../providers/visual_provider.dart';

class GeometryPanelContent extends StatelessWidget {
  const GeometryPanelContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visualProvider = Provider.of<VisualProvider>(context);
    final systemColors = visualProvider.systemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Base Geometry
        Text(
          'BASE GEOMETRY',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildGeometryGrid(visualProvider, systemColors),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Synthesis Modulation (4D Rotation controls sonic parameters)
        Text(
          'SYNTHESIS MODULATION',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'XW: FM Depth / Detune 1',
          value: visualProvider.rotationXW,
          min: 0.0,
          max: 6.28, // 2π
          unit: '',
          onChanged: (value) => visualProvider.setRotationXW(value),
          systemColors: systemColors,
          icon: Icons.tune,
        ),
        HolographicSlider(
          label: 'YW: Ring Mod / Detune 2',
          value: visualProvider.rotationYW,
          min: 0.0,
          max: 6.28,
          unit: '',
          onChanged: (value) => visualProvider.setRotationYW(value),
          systemColors: systemColors,
          icon: Icons.grain,
        ),
        HolographicSlider(
          label: 'ZW: Filter Cutoff',
          value: visualProvider.rotationZW,
          min: 0.0,
          max: 6.28,
          unit: '',
          onChanged: (value) => visualProvider.setRotationZW(value),
          systemColors: systemColors,
          icon: Icons.filter_alt,
        ),
        HolographicSlider(
          label: 'Modulation Rate (LFO)',
          value: visualProvider.rotationSpeed,
          min: 0.0,
          max: 2.0,
          unit: '',
          onChanged: (value) => visualProvider.setRotationSpeed(value),
          systemColors: systemColors,
          icon: Icons.waves,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Spatial Synthesis (Projection controls reverb/delay)
        Text(
          'SPATIAL SYNTHESIS',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Reverb Amount',
          value: visualProvider.projectionDistance,
          min: 5.0,
          max: 15.0,
          unit: '',
          onChanged: (value) => visualProvider.setProjectionDistance(value),
          systemColors: systemColors,
          icon: Icons.surround_sound,
        ),
        HolographicSlider(
          label: 'Delay / Echo Depth',
          value: visualProvider.layerSeparation,
          min: 0.0,
          max: 5.0,
          unit: '',
          onChanged: (value) => visualProvider.setLayerSeparation(value),
          systemColors: systemColors,
          icon: Icons.graphic_eq,
        ),
        HolographicSlider(
          label: 'Waveform Crossfade',
          value: visualProvider.morphParameter,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => visualProvider.setMorphParameter(value),
          systemColors: systemColors,
          icon: Icons.timeline,
        ),
      ],
    );
  }

  Widget _buildGeometryGrid(
    VisualProvider visualProvider,
    SystemColors systemColors,
  ) {
    final theme = SynthTheme(systemColors: systemColors);

    // 24 geometries organized by synthesis branch (3 cores × 8 base geometries)
    // Names reflect SONIC CHARACTER, not visual geometry names
    final geometries = [
      // BASE/DIRECT (0-7): Pure synthesis with filtering
      'Fundamental',    // 0: Tetrahedron
      'Complex',        // 1: Hypercube
      'Smooth',         // 2: Sphere
      'Cyclic',         // 3: Torus
      'Twisted',        // 4: Klein Bottle
      'Recursive',      // 5: Fractal
      'Flowing',        // 6: Wave
      'Crystalline',    // 7: Crystal

      // HYPERSPHERE/FM (8-15): FM synthesis (🌀 prefix)
      '🌀 Fundamental', // 8: FM Tetrahedron
      '🌀 Complex',     // 9: FM Hypercube
      '🌀 Smooth',      // 10: FM Sphere
      '🌀 Cyclic',      // 11: FM Torus
      '🌀 Twisted',     // 12: FM Klein Bottle
      '🌀 Recursive',   // 13: FM Fractal
      '🌀 Flowing',     // 14: FM Wave
      '🌀 Crystalline', // 15: FM Crystal

      // HYPERTETRAHEDRON/RING MOD (16-23): Ring modulation (🔺 prefix)
      '🔺 Fundamental', // 16: Ring Tetrahedron
      '🔺 Complex',     // 17: Ring Hypercube
      '🔺 Smooth',      // 18: Ring Sphere
      '🔺 Cyclic',      // 19: Ring Torus
      '🔺 Twisted',     // 20: Ring Klein Bottle
      '🔺 Recursive',   // 21: Ring Fractal
      '🔺 Flowing',     // 22: Ring Wave
      '🔺 Crystalline', // 23: Ring Crystal
    ];

    return Column(
      children: [
        // Show current synthesis branch
        Padding(
          padding: const EdgeInsets.only(bottom: SynthTheme.spacingSmall),
          child: Text(
            _getSynthesisBranchLabel(visualProvider.currentGeometry),
            style: SynthTheme.textStyleBody.copyWith(
              color: systemColors.accent,
              fontSize: 11,
            ),
          ),
        ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: SynthTheme.spacingSmall,
            mainAxisSpacing: SynthTheme.spacingSmall,
          ),
          itemCount: geometries.length,
          itemBuilder: (context, index) {
            final isActive = visualProvider.currentGeometry == index;
            return GestureDetector(
              onTap: () => visualProvider.setGeometry(index),
              child: AnimatedContainer(
                duration: SynthTheme.transitionQuick,
                decoration: theme.getNeoskeuButtonDecoration(isActive: isActive),
                child: Center(
                  child: Text(
                    geometries[index],
                    style: SynthTheme.textStyleBody.copyWith(
                      color: theme.getTextColor(isActive),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getSynthesisBranchLabel(int geometryIndex) {
    final coreIndex = geometryIndex ~/ 8;
    switch (coreIndex) {
      case 0: return 'DIRECT SYNTHESIS (Base 0-7)';
      case 1: return 'FM SYNTHESIS (Hypersphere 8-15)';
      case 2: return 'RING MODULATION (Hypertetrahedron 16-23)';
      default: return 'SYNTHESIS BRANCH';
    }
  }
}
