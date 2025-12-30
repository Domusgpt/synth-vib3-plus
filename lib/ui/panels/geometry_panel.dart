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

        // Section: 3D Rotation (XY, XZ, YZ planes)
        Text(
          '3D ROTATION',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'XY Rotation',
          value: visualProvider.rotationXY,
          min: 0.0,
          max: 6.28,
          unit: 'rad',
          onChanged: (value) => visualProvider.setRotationXY(value),
          systemColors: systemColors,
          icon: Icons.rotate_left,
        ),
        HolographicSlider(
          label: 'XZ Rotation',
          value: visualProvider.rotationXZ,
          min: 0.0,
          max: 6.28,
          unit: 'rad',
          onChanged: (value) => visualProvider.setRotationXZ(value),
          systemColors: systemColors,
          icon: Icons.rotate_right,
        ),
        HolographicSlider(
          label: 'YZ Rotation',
          value: visualProvider.rotationYZ,
          min: 0.0,
          max: 6.28,
          unit: 'rad',
          onChanged: (value) => visualProvider.setRotationYZ(value),
          systemColors: systemColors,
          icon: Icons.threesixty,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: 4D Rotation (XW, YW, ZW) - Synthesis Modulation
        Text(
          '4D ROTATION (SYNTHESIS)',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'XW: FM Depth / Detune 1',
          value: visualProvider.rotationXW,
          min: 0.0,
          max: 6.28,
          unit: 'rad',
          onChanged: (value) => visualProvider.setRotationXW(value),
          systemColors: systemColors,
          icon: Icons.tune,
        ),
        HolographicSlider(
          label: 'YW: Ring Mod / Detune 2',
          value: visualProvider.rotationYW,
          min: 0.0,
          max: 6.28,
          unit: 'rad',
          onChanged: (value) => visualProvider.setRotationYW(value),
          systemColors: systemColors,
          icon: Icons.grain,
        ),
        HolographicSlider(
          label: 'ZW: Filter Cutoff',
          value: visualProvider.rotationZW,
          min: 0.0,
          max: 6.28,
          unit: 'rad',
          onChanged: (value) => visualProvider.setRotationZW(value),
          systemColors: systemColors,
          icon: Icons.filter_alt,
        ),
        HolographicSlider(
          label: 'Speed (LFO Rate)',
          value: visualProvider.rotationSpeed,
          min: 0.1,
          max: 3.0,
          unit: 'x',
          onChanged: (value) => visualProvider.setRotationSpeed(value),
          systemColors: systemColors,
          icon: Icons.speed,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Visual Appearance
        Text(
          'VISUAL APPEARANCE',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Hue',
          value: visualProvider.hueShift,
          min: 0.0,
          max: 360.0,
          unit: '°',
          onChanged: (value) => visualProvider.setHueShift(value),
          systemColors: systemColors,
          icon: Icons.palette,
        ),
        HolographicSlider(
          label: 'Brightness',
          value: visualProvider.vertexBrightness,
          min: 0.0,
          max: 1.0,
          unit: '',
          onChanged: (value) => visualProvider.setVertexBrightness(value),
          systemColors: systemColors,
          icon: Icons.brightness_6,
        ),
        HolographicSlider(
          label: 'Glow Intensity',
          value: visualProvider.glowIntensity,
          min: 0.0,
          max: 3.0,
          unit: '',
          onChanged: (value) => visualProvider.setGlowIntensity(value),
          systemColors: systemColors,
          icon: Icons.flare,
        ),
        HolographicSlider(
          label: 'Chaos',
          value: visualProvider.rgbSplitAmount,
          min: 0.0,
          max: 10.0,
          unit: '',
          onChanged: (value) => visualProvider.setRGBSplitAmount(value),
          systemColors: systemColors,
          icon: Icons.blur_on,
        ),
        HolographicSlider(
          label: 'Grid Density',
          value: visualProvider.tessellationDensity.toDouble(),
          min: 3.0,
          max: 10.0,
          unit: '',
          onChanged: (value) => visualProvider.setTessellationDensity(value.round()),
          systemColors: systemColors,
          icon: Icons.grid_on,
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
          label: 'Morph Factor',
          value: visualProvider.morphParameter,
          min: 0.0,
          max: 1.0,
          unit: '',
          onChanged: (value) => visualProvider.setMorphParameter(value),
          systemColors: systemColors,
          icon: Icons.timeline,
        ),
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
          label: 'Delay / Echo',
          value: visualProvider.layerSeparation,
          min: 0.0,
          max: 5.0,
          unit: '',
          onChanged: (value) => visualProvider.setLayerSeparation(value),
          systemColors: systemColors,
          icon: Icons.graphic_eq,
        ),
      ],
    );
  }

  Widget _buildGeometryGrid(
    VisualProvider visualProvider,
    SystemColors systemColors,
  ) {
    final theme = SynthTheme(systemColors: systemColors);

    // Architecture: 8 base geometries × 3 polytope cores = 24 combinations
    // geometryIndex = (coreIndex * 8) + baseIndex

    // 8 base geometry types (determines voice character)
    final baseGeometries = [
      'Tetrahedron',   // 0: Fundamental, minimal filtering
      'Hypercube',     // 1: Complex, dual oscillators with detune
      'Sphere',        // 2: Smooth, filtered harmonics
      'Torus',         // 3: Cyclic, rhythmic phase modulation
      'Klein Bottle',  // 4: Twisted, asymmetric stereo
      'Fractal',       // 5: Recursive, self-modulating
      'Wave',          // 6: Flowing, sweeping filters
      'Crystal',       // 7: Crystalline, sharp attack transients
    ];

    // 3 polytope cores (determines synthesis branch)
    final polytopeCores = [
      {'name': 'Base', 'subtitle': 'Direct Synthesis', 'offset': 0},
      {'name': 'Hypersphere', 'subtitle': 'FM Synthesis', 'offset': 8},
      {'name': 'Hypertetra', 'subtitle': 'Ring Modulation', 'offset': 16},
    ];

    // Calculate current core and base from full geometry index
    final currentGeometry = visualProvider.currentGeometry;
    final currentCoreIndex = currentGeometry ~/ 8;
    final currentBaseIndex = currentGeometry % 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POLYTOPE CORE SELECTOR (3 buttons in a row)
        Text(
          'POLYTOPE CORE (Synthesis Branch)',
          style: SynthTheme.textStyleCaption.copyWith(
            color: systemColors.accent,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        Row(
          children: polytopeCores.asMap().entries.map((entry) {
            final index = entry.key;
            final core = entry.value;
            final isActive = currentCoreIndex == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < polytopeCores.length - 1 ? SynthTheme.spacingSmall : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    // Change core but keep current base geometry
                    final newIndex = (index * 8) + currentBaseIndex;
                    visualProvider.setGeometry(newIndex);
                  },
                  child: AnimatedContainer(
                    duration: SynthTheme.transitionQuick,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: theme.getNeoskeuButtonDecoration(isActive: isActive),
                    child: Column(
                      children: [
                        Text(
                          core['name'] as String,
                          style: SynthTheme.textStyleBody.copyWith(
                            color: theme.getTextColor(isActive),
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          core['subtitle'] as String,
                          style: SynthTheme.textStyleCaption.copyWith(
                            color: theme.getTextColor(isActive).withOpacity(0.7),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: SynthTheme.spacingMedium),

        // BASE GEOMETRY SELECTOR (8 buttons in 2x4 grid)
        Text(
          'BASE GEOMETRY (Voice Character)',
          style: SynthTheme.textStyleCaption.copyWith(
            color: systemColors.accent,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.8,
            crossAxisSpacing: SynthTheme.spacingSmall,
            mainAxisSpacing: SynthTheme.spacingSmall,
          ),
          itemCount: baseGeometries.length,
          itemBuilder: (context, baseIndex) {
            final isActive = currentBaseIndex == baseIndex;
            return GestureDetector(
              onTap: () {
                // Change base geometry but keep current core
                final newIndex = (currentCoreIndex * 8) + baseIndex;
                visualProvider.setGeometry(newIndex);
              },
              child: AnimatedContainer(
                duration: SynthTheme.transitionQuick,
                decoration: theme.getNeoskeuButtonDecoration(isActive: isActive),
                child: Center(
                  child: Text(
                    baseGeometries[baseIndex],
                    textAlign: TextAlign.center,
                    style: SynthTheme.textStyleBody.copyWith(
                      color: theme.getTextColor(isActive),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: SynthTheme.spacingSmall),

        // Show current configuration
        Container(
          padding: const EdgeInsets.all(SynthTheme.spacingSmall),
          decoration: BoxDecoration(
            color: SynthTheme.cardBackground,
            borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
            border: Border.all(color: systemColors.primary.withOpacity(0.3)),
          ),
          child: Text(
            'Current: ${polytopeCores[currentCoreIndex]['name']} ${baseGeometries[currentBaseIndex]} (Index: $currentGeometry)',
            style: SynthTheme.textStyleCaption.copyWith(
              color: systemColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
