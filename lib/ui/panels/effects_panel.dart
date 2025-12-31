/**
 * Effects Panel
 *
 * Advanced audio+visual effects controls.
 * Note: Reverb and Delay are in Geometry panel (with visual parity).
 * This panel handles filter and master controls.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/holographic_slider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/visual_provider.dart';

class EffectsPanelContent extends StatelessWidget {
  const EffectsPanelContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final visualProvider = Provider.of<VisualProvider>(context);
    final systemColors = visualProvider.systemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Filter (Audio: filter, Visual: brightness/spectral)
        Text(
          'FILTER (SPECTRAL)',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        Text(
          'Audio: filter cutoff • Visual: brightness tint',
          style: SynthTheme.textStyleCaption.copyWith(
            color: systemColors.accent,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Cutoff / Brightness',
          value: audioProvider.filterCutoff,
          min: 20.0,
          max: 20000.0,
          unit: 'Hz',
          onChanged: (value) {
            audioProvider.setFilterCutoff(value);
            // Map filter cutoff to vertex brightness (higher cutoff = brighter)
            final brightness = ((value - 20.0) / 20000.0).clamp(0.3, 1.0);
            visualProvider.setVertexBrightness(brightness);
          },
          systemColors: systemColors,
          icon: Icons.waves,
        ),
        HolographicSlider(
          label: 'Resonance / Glow',
          value: audioProvider.filterResonance,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            audioProvider.setFilterResonance(value);
            // Map resonance to glow intensity (higher resonance = more glow)
            visualProvider.setGlowIntensity(0.5 + value * 2.5);
          },
          systemColors: systemColors,
          icon: Icons.graphic_eq,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Master Controls
        Text(
          'MASTER',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Volume',
          value: audioProvider.masterVolume,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setMasterVolume(value),
          systemColors: systemColors,
          icon: Icons.volume_up,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Info section about visual parity
        Container(
          padding: const EdgeInsets.all(SynthTheme.spacingSmall),
          decoration: BoxDecoration(
            color: SynthTheme.cardBackground,
            borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
            border: Border.all(color: systemColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visual Parity',
                style: SynthTheme.textStyleCaption.copyWith(
                  color: systemColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Reverb → Geometry > Reverb Amount\n'
                '• Delay → Geometry > Delay/Echo\n'
                '• See Geometry panel for spatial effects',
                style: SynthTheme.textStyleCaption.copyWith(
                  color: systemColors.accent,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
