/**
 * Geometry Panel - UNIFIED CONTROL PANEL
 *
 * Single panel for all bidirectional visual↔audio controls.
 * Every slider affects BOTH visual rendering AND audio synthesis.
 *
 * Sections:
 * - POLYTOPE CORE: Synthesis branch (Direct/FM/RingMod)
 * - BASE GEOMETRY: Voice character (8 shapes)
 * - 4D ROTATION: XW→FM, YW→RingMod, ZW→Filter
 * - 3D ROTATION: XY→OSC1, XZ→OSC2 (detune)
 * - SHAPE: Morph→Waveform, Density→Voices, Chaos→Noise
 * - COLOR: Hue→Cutoff, Saturation→Resonance, Brightness→Mix
 * - EFFECTS: Glow→Reverb, Speed→LFO
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/holographic_slider.dart';
import '../../providers/visual_provider.dart';
import '../../providers/audio_provider.dart';

class GeometryPanelContent extends StatelessWidget {
  const GeometryPanelContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visualProvider = Provider.of<VisualProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    final systemColors = visualProvider.systemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Base Geometry Selection
        Text(
          'GEOMETRY',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildGeometryGrid(visualProvider, systemColors),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: 4D Rotation (Synthesis branch modulation)
        Text(
          '4D ROTATION',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'XW → FM Depth',
          value: visualProvider.rotationXW,
          min: 0.0,
          max: 6.28,
          unit: '',
          onChanged: (value) => visualProvider.setRotationXW(value),
          systemColors: systemColors,
          icon: Icons.tune,
        ),
        HolographicSlider(
          label: 'YW → Ring Mod',
          value: visualProvider.rotationYW,
          min: 0.0,
          max: 6.28,
          unit: '',
          onChanged: (value) => visualProvider.setRotationYW(value),
          systemColors: systemColors,
          icon: Icons.grain,
        ),
        HolographicSlider(
          label: 'ZW → Filter Mod',
          value: visualProvider.rotationZW,
          min: 0.0,
          max: 6.28,
          unit: '',
          onChanged: (value) => visualProvider.setRotationZW(value),
          systemColors: systemColors,
          icon: Icons.filter_alt,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: 3D Rotation (Oscillator detuning)
        Text(
          '3D ROTATION',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'XY → OSC 1 Detune',
          value: visualProvider.rotationXY,
          min: 0.0,
          max: 6.28,
          unit: '',
          onChanged: (value) {
            visualProvider.setRotationXY(value);
            // Bidirectional: Map to oscillator detune (±12 cents)
            final detune = ((value / 6.28) * 24.0) - 12.0;
            audioProvider.setOscillator1Detune(detune);
          },
          systemColors: systemColors,
          icon: Icons.music_note,
        ),
        HolographicSlider(
          label: 'XZ → OSC 2 Detune',
          value: visualProvider.rotationXZ,
          min: 0.0,
          max: 6.28,
          unit: '',
          onChanged: (value) {
            visualProvider.setRotationXZ(value);
            // Bidirectional: Map to oscillator detune (±12 cents)
            final detune = ((value / 6.28) * 24.0) - 12.0;
            audioProvider.setOscillator2Detune(detune);
          },
          systemColors: systemColors,
          icon: Icons.music_note,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Shape Modulation
        Text(
          'SHAPE',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Morph → Waveform',
          value: visualProvider.morphParameter,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            visualProvider.setMorphParameter(value);
            audioProvider.setMixBalance(value);
          },
          systemColors: systemColors,
          icon: Icons.timeline,
        ),
        HolographicSlider(
          label: 'Density → Voices',
          value: visualProvider.baseTessellationDensity,
          min: 3.0,
          max: 15.0,
          unit: '',
          onChanged: (value) {
            visualProvider.setTessellationDensity(value);
            audioProvider.setVoiceCount(value.round().clamp(1, 8));
          },
          systemColors: systemColors,
          icon: Icons.grid_4x4,
        ),
        HolographicSlider(
          label: 'Chaos → Noise',
          value: visualProvider.baseRgbSplitAmount / 10.0,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            visualProvider.setRGBSplitAmount(value * 10.0);
            audioProvider.synthesizerEngine.setNoiseLevel(value * 0.3);
          },
          systemColors: systemColors,
          icon: Icons.scatter_plot,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Color (Filter mapping)
        Text(
          'COLOR',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Hue → Cutoff',
          value: visualProvider.baseHueShift,
          min: 0.0,
          max: 360.0,
          unit: '°',
          onChanged: (value) {
            visualProvider.setHueShift(value);
            // Map hue to filter cutoff (spectral → frequency)
            final cutoff = 200 + (value / 360.0) * 8000;
            audioProvider.setFilterCutoff(cutoff);
          },
          systemColors: systemColors,
          icon: Icons.palette,
        ),
        HolographicSlider(
          label: 'Saturation → Resonance',
          value: visualProvider.baseSaturation,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            visualProvider.setSaturation(value);
            audioProvider.setFilterResonance(value);
          },
          systemColors: systemColors,
          icon: Icons.contrast,
        ),
        HolographicSlider(
          label: 'Brightness → Mix',
          value: visualProvider.baseVertexBrightness,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            visualProvider.setVertexBrightness(value);
            audioProvider.setMixBalance(value);
          },
          systemColors: systemColors,
          icon: Icons.brightness_6,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Effects
        Text(
          'EFFECTS',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Glow → Reverb',
          value: visualProvider.baseGlowIntensity,
          min: 0.0,
          max: 3.0,
          unit: '',
          onChanged: (value) {
            visualProvider.setGlowIntensity(value);
            audioProvider.setReverbMix(value / 3.0);
          },
          systemColors: systemColors,
          icon: Icons.light_mode,
        ),
        HolographicSlider(
          label: 'Speed → LFO Rate',
          value: visualProvider.baseRotationSpeed,
          min: 0.1,
          max: 2.0,
          unit: '',
          onChanged: (value) {
            visualProvider.setRotationSpeed(value);
            audioProvider.synthesizerEngine.setLFORate(value * 5.0);
          },
          systemColors: systemColors,
          icon: Icons.speed,
        ),
      ],
    );
  }

  Widget _buildGeometryGrid(
    VisualProvider visualProvider,
    SystemColors systemColors,
  ) {
    final theme = SynthTheme(systemColors: systemColors);

    // 8 base geometries × 3 polytope cores = 24 combinations
    final baseGeometries = [
      'Tetra',    // 0: Fundamental
      'Hyper',    // 1: Complex
      'Sphere',   // 2: Smooth
      'Torus',    // 3: Cyclic
      'Klein',    // 4: Twisted
      'Fractal',  // 5: Recursive
      'Wave',     // 6: Flowing
      'Crystal',  // 7: Sharp
    ];

    final polytopeCores = [
      {'name': 'Base', 'subtitle': 'Direct', 'offset': 0},
      {'name': 'Hyper', 'subtitle': 'FM', 'offset': 8},
      {'name': 'Tetra', 'subtitle': 'Ring', 'offset': 16},
    ];

    final currentGeometry = visualProvider.currentGeometry;
    final currentCoreIndex = currentGeometry ~/ 8;
    final currentBaseIndex = currentGeometry % 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POLYTOPE CORE SELECTOR
        Text(
          'Core → Synthesis Branch',
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

        // BASE GEOMETRY SELECTOR
        Text(
          'Shape → Voice Character',
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
            childAspectRatio: 2.0,
            crossAxisSpacing: SynthTheme.spacingSmall,
            mainAxisSpacing: SynthTheme.spacingSmall,
          ),
          itemCount: baseGeometries.length,
          itemBuilder: (context, baseIndex) {
            final isActive = currentBaseIndex == baseIndex;
            return GestureDetector(
              onTap: () {
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
                      fontSize: 10,
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
}
