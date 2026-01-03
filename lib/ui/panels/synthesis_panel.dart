/**
 * Synthesis Panel
 *
 * Consolidated controls for all audio synthesis parameters:
 * - Oscillators (detune, mix)
 * - Filter (cutoff, resonance)
 * - Effects (reverb, delay)
 * - Envelope (ADSR)
 *
 * Synthesis branch is controlled via Geometry panel (polytope core selection)
 * per the sonic parity architecture.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/holographic_slider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/visual_provider.dart';

class SynthesisPanelContent extends StatelessWidget {
  const SynthesisPanelContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final visualProvider = Provider.of<VisualProvider>(context);
    final systemColors = visualProvider.systemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Oscillators
        Text(
          'OSCILLATORS',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'OSC 1 Tune → XY Rotation',
          value: audioProvider.oscillator1Detune,
          min: -12.0,
          max: 12.0,
          unit: 'cents',
          onChanged: (value) {
            audioProvider.setOscillator1Detune(value);
            // Bidirectional: Also update visual rotation XY
            visualProvider.setRotationXY((value + 12.0) / 24.0);
          },
          systemColors: systemColors,
          icon: Icons.music_note,
        ),
        HolographicSlider(
          label: 'OSC 2 Tune → XZ Rotation',
          value: audioProvider.oscillator2Detune,
          min: -12.0,
          max: 12.0,
          unit: 'cents',
          onChanged: (value) {
            audioProvider.setOscillator2Detune(value);
            // Bidirectional: Also update visual rotation XZ
            visualProvider.setRotationXZ((value + 12.0) / 24.0);
          },
          systemColors: systemColors,
          icon: Icons.music_note,
        ),
        HolographicSlider(
          label: 'Mix Balance → Brightness',
          value: audioProvider.mixBalance,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            audioProvider.setMixBalance(value);
            // Bidirectional: Also update visual brightness
            visualProvider.setVertexBrightness(value);
          },
          systemColors: systemColors,
          icon: Icons.tune,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Filter
        Text(
          'FILTER',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Cutoff → Hue Shift',
          value: audioProvider.filterCutoff,
          min: 20.0,
          max: 20000.0,
          unit: 'Hz',
          onChanged: (value) {
            audioProvider.setFilterCutoff(value);
            // Bidirectional: Map cutoff to hue (spectral → color)
            final normalizedCutoff = (value - 20.0) / 19980.0;
            visualProvider.setHueShift(normalizedCutoff * 360.0);
          },
          systemColors: systemColors,
          icon: Icons.waves,
        ),
        HolographicSlider(
          label: 'Resonance → Saturation',
          value: audioProvider.filterResonance,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            audioProvider.setFilterResonance(value);
            // Bidirectional: Also update visual saturation
            visualProvider.setSaturation(value);
          },
          systemColors: systemColors,
          icon: Icons.graphic_eq,
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
          label: 'Reverb Mix → Glow',
          value: audioProvider.reverbMix,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            audioProvider.setReverbMix(value);
            // Bidirectional: Also update visual glow intensity
            visualProvider.setGlowIntensity(value * 3.0);
          },
          systemColors: systemColors,
          icon: Icons.water_drop,
        ),
        HolographicSlider(
          label: 'Delay Mix → Distance',
          value: audioProvider.delayMix,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) {
            audioProvider.setDelayMix(value);
            // Bidirectional: Also update visual projection distance
            visualProvider.setProjectionDistance(5.0 + value * 10.0);
          },
          systemColors: systemColors,
          icon: Icons.repeat,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Envelope
        Text(
          'ENVELOPE',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Attack',
          value: audioProvider.envelopeAttack,
          min: 0.001,
          max: 2.0,
          unit: 's',
          onChanged: (value) => audioProvider.setEnvelopeAttack(value),
          systemColors: systemColors,
          icon: Icons.trending_up,
        ),
        HolographicSlider(
          label: 'Decay',
          value: audioProvider.envelopeDecay,
          min: 0.001,
          max: 2.0,
          unit: 's',
          onChanged: (value) => audioProvider.setEnvelopeDecay(value),
          systemColors: systemColors,
          icon: Icons.trending_down,
        ),
        HolographicSlider(
          label: 'Sustain',
          value: audioProvider.envelopeSustain,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setEnvelopeSustain(value),
          systemColors: systemColors,
          icon: Icons.horizontal_rule,
        ),
        HolographicSlider(
          label: 'Release',
          value: audioProvider.envelopeRelease,
          min: 0.001,
          max: 5.0,
          unit: 's',
          onChanged: (value) => audioProvider.setEnvelopeRelease(value),
          systemColors: systemColors,
          icon: Icons.arrow_downward,
        ),
      ],
    );
  }
}
