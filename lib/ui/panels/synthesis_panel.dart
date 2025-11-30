// Synthesis Panel
//
// Controls for synthesis branch selection, oscillator parameters,
// envelope settings, and voice configuration.
//
// A Paul Phillips Manifestation
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/holographic_slider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/visual_provider.dart';

class SynthesisPanelContent extends StatelessWidget {
  const SynthesisPanelContent({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final visualProvider = Provider.of<VisualProvider>(context);
    final systemColors = visualProvider.systemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Synthesis Branch
        Text(
          'SYNTHESIS BRANCH',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildBranchSelector(audioProvider, systemColors),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Oscillators
        Text(
          'OSCILLATORS',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'OSC 1 Tune',
          value: audioProvider.oscillator1Detune,
          min: -12.0,
          max: 12.0,
          unit: 'cents',
          onChanged: (value) => audioProvider.setOscillator1Detune(value),
          systemColors: systemColors,
          icon: Icons.music_note,
        ),
        HolographicSlider(
          label: 'OSC 2 Tune',
          value: audioProvider.oscillator2Detune,
          min: -12.0,
          max: 12.0,
          unit: 'cents',
          onChanged: (value) => audioProvider.setOscillator2Detune(value),
          systemColors: systemColors,
          icon: Icons.music_note,
        ),
        HolographicSlider(
          label: 'Mix Balance',
          value: audioProvider.mixBalance,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => audioProvider.setMixBalance(value),
          systemColors: systemColors,
          icon: Icons.tune,
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
          min: 0.0,
          max: 2000.0,
          unit: 'ms',
          onChanged: (value) => audioProvider.setEnvelopeAttack(value),
          systemColors: systemColors,
          icon: Icons.trending_up,
        ),
        HolographicSlider(
          label: 'Decay',
          value: audioProvider.envelopeDecay,
          min: 0.0,
          max: 2000.0,
          unit: 'ms',
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
          min: 0.0,
          max: 5000.0,
          unit: 'ms',
          onChanged: (value) => audioProvider.setEnvelopeRelease(value),
          systemColors: systemColors,
          icon: Icons.arrow_downward,
        ),
      ],
    );
  }

  Widget _buildBranchSelector(
    AudioProvider audioProvider,
    SystemColors systemColors,
  ) {
    final theme = SynthTheme(systemColors: systemColors);
    final branches = ['Direct', 'FM', 'Ring Mod'];
    final currentBranch = audioProvider.currentSynthesisBranch;

    return Row(
      children: branches.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isActive = currentBranch == label;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < branches.length - 1
                  ? SynthTheme.spacingSmall
                  : 0,
            ),
            child: GestureDetector(
              onTap: () => audioProvider.setSynthesisBranch(index),
              child: AnimatedContainer(
                duration: SynthTheme.transitionQuick,
                height: SynthTheme.touchTargetMinimum,
                decoration: theme.getNeoskeuButtonDecoration(isActive: isActive),
                child: Center(
                  child: Text(
                    label,
                    style: SynthTheme.textStyleBody.copyWith(
                      color: theme.getTextColor(isActive),
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
