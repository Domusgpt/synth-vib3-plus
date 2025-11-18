/**
 * Mapping Panel
 *
 * Controls for visual-to-audio parameter mappings, XY pad configuration,
 * and modulation settings.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/holographic_slider.dart';
import '../../providers/ui_state_provider.dart';

class MappingPanelContent extends StatelessWidget {
  const MappingPanelContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final systemColors = uiState.currentSystemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: XY Pad Configuration
        Text(
          'XY PAD CONFIGURATION',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildAxisSelector(
          'X-Axis (Horizontal)',
          uiState.xyAxisX,
          (value) => uiState.setXYAxisX(value),
          systemColors,
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildAxisSelector(
          'Y-Axis (Vertical)',
          uiState.xyAxisY,
          (value) => uiState.setXYAxisY(value),
          systemColors,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Pitch Configuration
        Text(
          'PITCH CONFIGURATION',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Range Start',
          value: uiState.pitchRangeStart.toDouble(),
          min: 0.0,
          max: 127.0,
          unit: 'note',
          divisions: 127,
          onChanged: (value) => uiState.setPitchRangeStart(value.round()),
          systemColors: systemColors,
          icon: Icons.arrow_downward,
        ),
        HolographicSlider(
          label: 'Range End',
          value: uiState.pitchRangeEnd.toDouble(),
          min: 0.0,
          max: 127.0,
          unit: 'note',
          divisions: 127,
          onChanged: (value) => uiState.setPitchRangeEnd(value.round()),
          systemColors: systemColors,
          icon: Icons.arrow_upward,
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildScaleSelector(uiState, systemColors),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Orb Controller
        Text(
          'ORB CONTROLLER',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        HolographicSlider(
          label: 'Pitch Bend',
          value: uiState.orbPitchBendRange,
          min: 1.0,
          max: 12.0,
          unit: '',
          divisions: 11,
          onChanged: (value) => uiState.setOrbPitchBendRange(value),
          systemColors: systemColors,
          icon: Icons.swap_horiz,
        ),
        HolographicSlider(
          label: 'Vibrato Depth',
          value: uiState.orbVibratoDepth,
          min: 0.0,
          max: 1.0,
          unit: '%',
          onChanged: (value) => uiState.setOrbVibratoDepth(value),
          systemColors: systemColors,
          icon: Icons.vibration,
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildToggle(
          'Tilt Control',
          uiState.tiltEnabled,
          (value) => uiState.setTiltEnabled(value),
          systemColors,
        ),
        const SizedBox(height: SynthTheme.spacingLarge),

        // Section: Visual → Audio Modulation
        Text(
          'VISUAL → AUDIO MODULATION',
          style: SynthTheme.textStyleHeading.copyWith(
            color: systemColors.primary,
          ),
        ),
        const SizedBox(height: SynthTheme.spacingSmall),
        _buildModulationMatrix(systemColors),
      ],
    );
  }

  Widget _buildAxisSelector(
    String label,
    XYAxisParameter currentValue,
    Function(XYAxisParameter) onChanged,
    SystemColors systemColors,
  ) {
    final theme = SynthTheme(systemColors: systemColors);
    final parameters = XYAxisParameter.values;
    final parameterLabels = {
      XYAxisParameter.pitch: 'Pitch',
      XYAxisParameter.filterCutoff: 'Filter',
      XYAxisParameter.resonance: 'Resonance',
      XYAxisParameter.oscillatorMix: 'OSC Mix',
      XYAxisParameter.morphParameter: 'Morph',
      XYAxisParameter.rotationSpeed: 'Rotation',
      XYAxisParameter.fmDepth: 'FM Depth',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SynthTheme.textStyleBody),
        const SizedBox(height: SynthTheme.spacingXSmall),
        Wrap(
          spacing: SynthTheme.spacingXSmall,
          runSpacing: SynthTheme.spacingXSmall,
          children: parameters.map((param) {
            final isActive = currentValue == param;
            return GestureDetector(
              onTap: () => onChanged(param),
              child: AnimatedContainer(
                duration: SynthTheme.transitionQuick,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isActive
                        ? systemColors.primary
                        : SynthTheme.borderSubtle,
                    width: isActive ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
                  color: isActive
                      ? systemColors.primary.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Text(
                  parameterLabels[param]!,
                  style: SynthTheme.textStyleCaption.copyWith(
                    color: theme.getTextColor(isActive),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScaleSelector(UIStateProvider uiState, SystemColors systemColors) {
    final theme = SynthTheme(systemColors: systemColors);
    final scales = ['Chromatic', 'Major', 'Minor', 'Pentatonic', 'Blues'];
    final currentScale = uiState.pitchScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scale', style: SynthTheme.textStyleBody),
        const SizedBox(height: SynthTheme.spacingXSmall),
        Wrap(
          spacing: SynthTheme.spacingXSmall,
          runSpacing: SynthTheme.spacingXSmall,
          children: scales.map((scale) {
            final isActive = currentScale.toLowerCase() == scale.toLowerCase();
            return GestureDetector(
              onTap: () => uiState.setPitchScale(scale.toLowerCase()),
              child: AnimatedContainer(
                duration: SynthTheme.transitionQuick,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isActive
                        ? systemColors.primary
                        : SynthTheme.borderSubtle,
                    width: isActive ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
                  color: isActive
                      ? systemColors.primary.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Text(
                  scale,
                  style: SynthTheme.textStyleCaption.copyWith(
                    color: theme.getTextColor(isActive),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToggle(
    String label,
    bool value,
    Function(bool) onChanged,
    SystemColors systemColors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SynthTheme.textStyleBody),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: systemColors.primary,
          activeTrackColor: systemColors.primary.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildModulationMatrix(SystemColors systemColors) {
    return Container(
      padding: const EdgeInsets.all(SynthTheme.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: SynthTheme.borderSubtle),
        borderRadius: BorderRadius.circular(SynthTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModulationRow('Rotation XW', '→ OSC 1 Freq'),
          _buildModulationRow('Rotation YW', '→ OSC 2 Freq'),
          _buildModulationRow('Rotation ZW', '→ Filter Cutoff'),
          _buildModulationRow('Morph Param', '→ Wavetable Pos'),
          _buildModulationRow('Projection Dist', '→ Reverb Mix'),
          _buildModulationRow('Layer Depth', '→ Delay Time'),
        ],
      ),
    );
  }

  Widget _buildModulationRow(String source, String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              source,
              style: SynthTheme.textStyleCaption,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              target,
              style: SynthTheme.textStyleCaption.copyWith(
                color: SynthTheme.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
