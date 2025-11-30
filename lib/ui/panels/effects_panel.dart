// Effects Panel
//
// Controls for reverb, delay, filter, and other audio effects.
//
// A Paul Phillips Manifestation
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/holographic_slider.dart';
import '../../providers/audio_provider.dart';

class EffectsPanelContent extends StatelessWidget {
  const EffectsPanelContent({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final systemColors = audioProvider.systemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Filter
        Text(
          'FILTER',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Cutoff',
          value: audioProvider.filterCutoff,
          min: 20.0,
          max: 20000.0,
          unit: 'Hz',
          onChanged: (value) => audioProvider.setFilterCutoff(value),
          systemColors: systemColors,
          icon: Icons.waves,
        ),
        HolographicSlider(
          label: 'Resonance',
          value: audioProvider.filterResonance,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setFilterResonance(value),
          systemColors: systemColors,
          icon: Icons.graphic_eq,
        ),
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

        // Section: Reverb
        Text(
          'REVERB',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Mix',
          value: audioProvider.reverbMix,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setReverbMix(value),
          systemColors: systemColors,
          icon: Icons.water_drop,
        ),
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

        // Section: Delay
        Text(
          'DELAY',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
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
        HolographicSlider(
          label: 'Mix',
          value: audioProvider.delayMix,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setDelayMix(value),
          systemColors: systemColors,
          icon: Icons.volume_up,
        ),
      ],
    );
  }
}
