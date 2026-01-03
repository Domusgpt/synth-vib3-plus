/**
 * XY Pad Settings Overlay
 *
 * Floating settings panel for configuring:
 * - Musical key (C through B)
 * - Scale (chromatic, major, minor, pentatonic, blues)
 * - Y-axis parameter assignment
 *
 * Appears when settings icon is tapped on XY pad.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../../providers/ui_state_provider.dart';

class XYPadSettings extends StatelessWidget {
  final SystemColors systemColors;
  final VoidCallback onClose;

  const XYPadSettings({
    Key? key,
    required this.systemColors,
    required this.onClose,
  }) : super(key: key);

  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const List<String> _scaleNames = [
    'chromatic', 'major', 'minor', 'pentatonic', 'blues'
  ];

  static const Map<String, String> _scaleDisplayNames = {
    'chromatic': 'Chromatic',
    'major': 'Major',
    'minor': 'Minor',
    'pentatonic': 'Pentatonic',
    'blues': 'Blues',
  };

  static const Map<XYAxisParameter, String> _yAxisDisplayNames = {
    XYAxisParameter.filterCutoff: 'Filter Cutoff',
    XYAxisParameter.resonance: 'Resonance',
    XYAxisParameter.fmDepth: 'FM Depth',
    XYAxisParameter.ringModMix: 'Ring Mod',
    XYAxisParameter.morph: 'Morph',
    XYAxisParameter.chaos: 'Chaos',
    XYAxisParameter.brightness: 'Brightness',
    XYAxisParameter.reverb: 'Reverb',
    XYAxisParameter.oscillatorMix: 'OSC Mix',
    XYAxisParameter.rotationSpeed: 'Rotation',
  };

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final theme = SynthTheme(systemColors: systemColors);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SynthTheme.panelBackground.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: systemColors.primary.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: theme.getGlow(GlowIntensity.active),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XY Pad Settings',
                style: SynthTheme.textStyleBody.copyWith(
                  color: systemColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: systemColors.secondary),
                onPressed: onClose,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // X-AXIS: Key & Scale
          Text(
            'X-AXIS: Pitch',
            style: SynthTheme.textStyleCaption.copyWith(
              color: systemColors.secondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Key selector
              Expanded(
                child: _buildDropdown<int>(
                  label: 'Key',
                  value: uiState.pitchRootNote,
                  items: List.generate(12, (i) => i),
                  itemBuilder: (i) => _noteNames[i],
                  onChanged: (value) => uiState.setPitchRootNote(value!),
                ),
              ),
              const SizedBox(width: 12),
              // Scale selector
              Expanded(
                flex: 2,
                child: _buildDropdown<String>(
                  label: 'Scale',
                  value: uiState.pitchScale,
                  items: _scaleNames,
                  itemBuilder: (s) => _scaleDisplayNames[s] ?? s,
                  onChanged: (value) => uiState.setPitchScale(value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Y-AXIS: Modulation
          Text(
            'Y-AXIS: Modulation',
            style: SynthTheme.textStyleCaption.copyWith(
              color: systemColors.secondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdown<XYAxisParameter>(
            label: 'Parameter',
            value: uiState.xyAxisY,
            items: _yAxisDisplayNames.keys.toList(),
            itemBuilder: (p) => _yAxisDisplayNames[p] ?? p.name,
            onChanged: (value) => uiState.setXYAxisY(value!),
          ),
          const SizedBox(height: 16),

          // Pitch range
          Text(
            'PITCH RANGE',
            style: SynthTheme.textStyleCaption.copyWith(
              color: systemColors.secondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<int>(
                  label: 'Low',
                  value: uiState.pitchRangeStart,
                  items: List.generate(8, (i) => 24 + i * 12), // C1 to C8
                  itemBuilder: (n) => _midiNoteToName(n),
                  onChanged: (value) => uiState.setPitchRange(value!, uiState.pitchRangeEnd),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown<int>(
                  label: 'High',
                  value: uiState.pitchRangeEnd,
                  items: List.generate(8, (i) => 36 + i * 12), // C2 to C9
                  itemBuilder: (n) => _midiNoteToName(n),
                  onChanged: (value) => uiState.setPitchRange(uiState.pitchRangeStart, value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SynthTheme.textStyleCaption.copyWith(
            color: SynthTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: SynthTheme.cardBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: systemColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox(),
            dropdownColor: SynthTheme.cardBackground,
            style: SynthTheme.textStyleBody.copyWith(
              color: systemColors.primary,
              fontSize: 14,
            ),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemBuilder(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _midiNoteToName(int midiNote) {
    final octave = (midiNote ~/ 12) - 1;
    final noteIndex = midiNote % 12;
    return '${_noteNames[noteIndex]}$octave';
  }
}
