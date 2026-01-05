/**
 * Effects Panel
 *
 * Controls for reverb, delay, filter refinement, and other audio effects.
 * NOTE: Primary controls (Cutoff→Hue, Resonance→Saturation, Reverb→Glow, Delay→Distance)
 * are in the Synthesis panel as bidirectional mappings. This panel contains
 * ONLY the unique refinement parameters.
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
        // Section: Filter (unique params only)
        Text(
          'FILTER',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        // NOTE: Cutoff and Resonance are in Synthesis panel (bidirectional with Hue/Saturation)
        HolographicSlider(
          label: 'Filter Env',
          value: audioProvider.filterEnvelopeAmount,
          min: -1.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setFilterEnvelopeAmount(value),
          systemColors: systemColors,
          icon: Icons.insights,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Reverb (unique params only)
        Text(
          'REVERB',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        // NOTE: Reverb Mix is in Synthesis panel (bidirectional with Glow)
        HolographicSlider(
          label: 'Room Size',
          value: audioProvider.reverbRoomSize,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setReverbRoomSize(value),
          systemColors: systemColors,
          icon: Icons.format_size,
        ),
        HolographicSlider(
          label: 'Damping',
          value: audioProvider.reverbDamping,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setReverbDamping(value),
          systemColors: systemColors,
          icon: Icons.blur_on,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Delay (unique params only)
        Text(
          'DELAY',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        // NOTE: Delay Mix is in Synthesis panel (bidirectional with Distance)
        HolographicSlider(
          label: 'Time',
          value: audioProvider.delayTime,
          min: 0.0,
          max: 2000.0,
          unit: 'ms',
          onChanged: (value) => audioProvider.setDelayTime(value),
          systemColors: systemColors,
          icon: Icons.access_time,
        ),
        HolographicSlider(
          label: 'Feedback',
          value: audioProvider.delayFeedback,
          min: 0.0,
          max: 0.95,
          unit: '%',
          onChanged: (value) => audioProvider.setDelayFeedback(value),
          systemColors: systemColors,
          icon: Icons.repeat,
        ),
      ],
    );
  }
}
