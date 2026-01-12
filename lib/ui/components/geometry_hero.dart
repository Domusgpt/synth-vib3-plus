/**
 * Geometry Hero Widget
 *
 * Fixed "hero" section showing geometry selection with SONIC terminology:
 * - Synthesis Method: DIRECT / FM / RING MOD (was "Polytope Core")
 * - Voice Character: 8 buttons (was "Base Geometry")
 *
 * This section never scrolls and is always visible above the parameter sliders.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../../providers/visual_provider.dart';
import '../../providers/audio_provider.dart';

/// Voice character data for each base geometry
class VoiceCharacter {
  final String label;       // Short button label
  final String fullName;    // Full name for tooltips
  final String description; // Sonic description
  final int geometryBase;   // Base geometry index (0-7)

  const VoiceCharacter({
    required this.label,
    required this.fullName,
    required this.description,
    required this.geometryBase,
  });
}

/// All 8 voice characters with their sonic descriptions
const List<VoiceCharacter> voiceCharacters = [
  VoiceCharacter(
    label: 'FUND',
    fullName: 'Fundamental',
    description: 'Minimal, pure tone',
    geometryBase: 0,
  ),
  VoiceCharacter(
    label: 'CMPLX',
    fullName: 'Complex',
    description: 'Dual oscillators, detuned',
    geometryBase: 1,
  ),
  VoiceCharacter(
    label: 'SMTH',
    fullName: 'Smooth',
    description: 'Filtered harmonics, soft',
    geometryBase: 2,
  ),
  VoiceCharacter(
    label: 'CYCL',
    fullName: 'Cyclic',
    description: 'Rhythmic, LFO modulated',
    geometryBase: 3,
  ),
  VoiceCharacter(
    label: 'ASYM',
    fullName: 'Asymmetric',
    description: 'Stereo phase effects',
    geometryBase: 4,
  ),
  VoiceCharacter(
    label: 'RCRS',
    fullName: 'Recursive',
    description: 'Self-modulating feedback',
    geometryBase: 5,
  ),
  VoiceCharacter(
    label: 'SWEP',
    fullName: 'Sweeping',
    description: 'Filter sweep motion',
    geometryBase: 6,
  ),
  VoiceCharacter(
    label: 'CRSP',
    fullName: 'Crisp',
    description: 'Sharp attack transients',
    geometryBase: 7,
  ),
];

/// Synthesis method data
class SynthesisMethod {
  final String label;
  final String description;
  final int coreIndex; // 0=Direct, 1=FM, 2=Ring Mod

  const SynthesisMethod({
    required this.label,
    required this.description,
    required this.coreIndex,
  });
}

/// All 3 synthesis methods
const List<SynthesisMethod> synthesisMethods = [
  SynthesisMethod(
    label: 'DIRECT',
    description: 'Clean synthesis with filtering',
    coreIndex: 0,
  ),
  SynthesisMethod(
    label: 'FM',
    description: 'Frequency modulation',
    coreIndex: 1,
  ),
  SynthesisMethod(
    label: 'RING',
    description: 'Ring modulation',
    coreIndex: 2,
  ),
];

/// The fixed geometry hero section
class GeometryHeroWidget extends StatelessWidget {
  const GeometryHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final visualProvider = Provider.of<VisualProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final systemColors = visualProvider.systemColors;
    final theme = SynthTheme(systemColors: systemColors);

    final currentGeometry = visualProvider.currentGeometry;
    final currentCore = currentGeometry ~/ 8;
    final currentBase = currentGeometry % 8;

    return Container(
      padding: const EdgeInsets.all(SynthTheme.spacingMedium),
      decoration: BoxDecoration(
        color: systemColors.surface.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: systemColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Synthesis Method
          Text(
            'SYNTHESIS METHOD',
            style: SynthTheme.textStyleCaption.copyWith(
              color: systemColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: SynthTheme.spacingSmall),
          Row(
            children: synthesisMethods.map((method) {
              final isActive = method.coreIndex == currentCore;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: method.coreIndex < 2 ? SynthTheme.spacingSmall : 0,
                  ),
                  child: _SynthesisMethodButton(
                    method: method,
                    isActive: isActive,
                    systemColors: systemColors,
                    onTap: () => _onMethodTap(
                      context,
                      visualProvider,
                      audioProvider,
                      method.coreIndex,
                      currentBase,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: SynthTheme.spacingLarge),

          // Section: Voice Character
          Text(
            'VOICE CHARACTER',
            style: SynthTheme.textStyleCaption.copyWith(
              color: systemColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: SynthTheme.spacingSmall),

          // 4x2 grid of voice character buttons
          Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < 3 ? SynthTheme.spacingXSmall : 0,
                    ),
                    child: _VoiceCharacterButton(
                      character: voiceCharacters[i],
                      isActive: voiceCharacters[i].geometryBase == currentBase,
                      systemColors: systemColors,
                      onTap: () => _onVoiceTap(
                        context,
                        visualProvider,
                        audioProvider,
                        currentCore,
                        voiceCharacters[i].geometryBase,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SynthTheme.spacingXSmall),
          Row(
            children: [
              for (int i = 4; i < 8; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < 7 ? SynthTheme.spacingXSmall : 0,
                    ),
                    child: _VoiceCharacterButton(
                      character: voiceCharacters[i],
                      isActive: voiceCharacters[i].geometryBase == currentBase,
                      systemColors: systemColors,
                      onTap: () => _onVoiceTap(
                        context,
                        visualProvider,
                        audioProvider,
                        currentCore,
                        voiceCharacters[i].geometryBase,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: SynthTheme.spacingSmall),

          // Current selection display
          Center(
            child: Text(
              '${synthesisMethods[currentCore].label} ${voiceCharacters[currentBase].fullName}',
              style: SynthTheme.textStyleBody.copyWith(
                color: systemColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMethodTap(
    BuildContext context,
    VisualProvider visualProvider,
    AudioProvider audioProvider,
    int newCore,
    int currentBase,
  ) {
    final newGeometry = (newCore * 8) + currentBase;
    visualProvider.setGeometry(newGeometry);
    audioProvider.setSynthesisBranch(newGeometry);
  }

  void _onVoiceTap(
    BuildContext context,
    VisualProvider visualProvider,
    AudioProvider audioProvider,
    int currentCore,
    int newBase,
  ) {
    final newGeometry = (currentCore * 8) + newBase;
    visualProvider.setGeometry(newGeometry);
    audioProvider.setSynthesisBranch(newGeometry);
  }
}

/// Button for synthesis method selection
class _SynthesisMethodButton extends StatelessWidget {
  final SynthesisMethod method;
  final bool isActive;
  final SystemColors systemColors;
  final VoidCallback onTap;

  const _SynthesisMethodButton({
    required this.method,
    required this.isActive,
    required this.systemColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showTooltip(context),
      child: AnimatedContainer(
        duration: SynthTheme.transitionQuick,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? systemColors.primary.withOpacity(0.2)
              : systemColors.surface,
          border: Border.all(
            color: isActive
                ? systemColors.primary
                : systemColors.primary.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: systemColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            method.label,
            style: SynthTheme.textStyleBody.copyWith(
              color: isActive ? systemColors.primary : SynthTheme.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${method.label}: ${method.description}',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: systemColors.surface,
      ),
    );
  }
}

/// Button for voice character selection
class _VoiceCharacterButton extends StatelessWidget {
  final VoiceCharacter character;
  final bool isActive;
  final SystemColors systemColors;
  final VoidCallback onTap;

  const _VoiceCharacterButton({
    required this.character,
    required this.isActive,
    required this.systemColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showTooltip(context),
      child: AnimatedContainer(
        duration: SynthTheme.transitionQuick,
        height: 56,
        decoration: BoxDecoration(
          color: isActive
              ? systemColors.primary.withOpacity(0.2)
              : systemColors.surface.withOpacity(0.5),
          border: Border.all(
            color: isActive
                ? systemColors.primary
                : systemColors.primary.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: systemColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            character.label,
            style: SynthTheme.textStyleCaption.copyWith(
              color: isActive ? systemColors.primary : SynthTheme.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${character.fullName}: ${character.description}',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: systemColors.surface,
      ),
    );
  }
}
