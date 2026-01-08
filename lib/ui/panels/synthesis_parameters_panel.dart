/**
 * Synthesis Parameters Panel
 *
 * Single scrollable panel containing ALL synthesis parameter sliders
 * grouped by SONIC function:
 *
 * - PITCH/DETUNE: Detune 1, Detune 2, Chorus (3 sliders)
 * - MODULATION DEPTH: FM Depth, Ring Mod, Filter Mod (3 sliders)
 * - TONE SHAPING: Brightness, Resonance, Output (3 sliders)
 * - SPACE & TEXTURE: Reverb, Noise, Waveform (3 sliders)
 * - DENSITY & SPEED: Voices, LFO Rate (2 sliders)
 *
 * Total: 14 sliders with ghost offset showing audio reactivity
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../components/synth_parameter_slider.dart';
import '../../providers/visual_provider.dart';
import '../../providers/audio_provider.dart';

class SynthesisParametersPanel extends StatelessWidget {
  const SynthesisParametersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final visualProvider = Provider.of<VisualProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final systemColors = visualProvider.systemColors;

    // Determine which synthesis modulations are active based on core
    final currentCore = visualProvider.currentGeometry ~/ 8;
    final isFMCore = currentCore == 1;        // Hypersphere
    final isRingCore = currentCore == 2;      // Hypertetrahedron

    return Container(
      color: systemColors.background,
      child: ListView(
        padding: const EdgeInsets.only(bottom: SynthTheme.spacingLarge),
        children: [
          // ========================================
          // PITCH/DETUNE Section
          // ========================================
          SynthParameterSectionHeader(
            title: 'PITCH / DETUNE',
            systemColors: systemColors,
          ),

          // Detune 1 (XY Rotation → ±12 cents)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Detune 1',
              visualLabel: 'XY Rotation',
              sonicLabel: 'OSC 1 pitch offset',
              min: -math.pi,
              max: math.pi,
              unit: 'c',
              isBidirectional: true,
            ),
            value: _rotationToCents(visualProvider.rotationXY, 12.0),
            ghostOffset: 0.0, // TODO: Wire to audio reactivity
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (cents) {
              visualProvider.setRotationXY(_centsToRotation(cents, 12.0));
            },
            onDoubleTap: () => visualProvider.setRotationXY(0.0),
          ),

          // Detune 2 (XZ Rotation → ±12 cents)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Detune 2',
              visualLabel: 'XZ Rotation',
              sonicLabel: 'OSC 2 pitch offset',
              min: -math.pi,
              max: math.pi,
              unit: 'c',
              isBidirectional: true,
            ),
            value: _rotationToCents(visualProvider.rotationXZ, 12.0),
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (cents) {
              visualProvider.setRotationXZ(_centsToRotation(cents, 12.0));
            },
            onDoubleTap: () => visualProvider.setRotationXZ(0.0),
          ),

          // Chorus (YZ Rotation → ±7 cents)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Chorus',
              visualLabel: 'YZ Rotation',
              sonicLabel: 'Combined detune (thickness)',
              min: -math.pi,
              max: math.pi,
              unit: 'c',
              isBidirectional: true,
            ),
            value: _rotationToCents(visualProvider.rotationYZ, 7.0),
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (cents) {
              visualProvider.setRotationYZ(_centsToRotation(cents, 7.0));
            },
            onDoubleTap: () => visualProvider.setRotationYZ(0.0),
          ),

          // ========================================
          // MODULATION DEPTH Section
          // ========================================
          SynthParameterSectionHeader(
            title: 'MODULATION DEPTH',
            systemColors: systemColors,
          ),

          // FM Depth (XW Rotation → 0-2 semitones) - ONLY active for FM core
          SynthParameterSlider(
            config: SynthSliderConfig(
              label: 'FM Depth',
              visualLabel: 'XW Rotation',
              sonicLabel: 'Frequency modulation',
              min: 0.0,
              max: 2.0,
              unit: 'st',
              isEnabled: isFMCore,
            ),
            value: _rotationToSemitones(visualProvider.rotationXW),
            ghostOffset: 0.0,
            activityLevel: isFMCore ? 0.3 : 0.0,
            systemColors: systemColors,
            onChanged: (st) {
              if (isFMCore) {
                visualProvider.setRotationXW(_semitonesToRotation(st));
              }
            },
            onDoubleTap: () => visualProvider.setRotationXW(0.0),
          ),

          // Ring Mod (YW Rotation → 0-100%) - ONLY active for Ring core
          SynthParameterSlider(
            config: SynthSliderConfig(
              label: 'Ring Mod',
              visualLabel: 'YW Rotation',
              sonicLabel: 'Ring modulation depth',
              min: 0.0,
              max: 1.0,
              unit: '%',
              isEnabled: isRingCore,
            ),
            value: _rotationToPercent(visualProvider.rotationYW),
            ghostOffset: 0.0,
            activityLevel: isRingCore ? 0.3 : 0.0,
            systemColors: systemColors,
            onChanged: (percent) {
              if (isRingCore) {
                visualProvider.setRotationYW(_percentToRotation(percent));
              }
            },
            onDoubleTap: () => visualProvider.setRotationYW(0.0),
          ),

          // Filter Mod (ZW Rotation → ±40%)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Filter Mod',
              visualLabel: 'ZW Rotation',
              sonicLabel: 'Cutoff modulation',
              min: -0.4,
              max: 0.4,
              unit: '%',
              isBidirectional: true,
            ),
            value: _rotationToFilterMod(visualProvider.rotationZW),
            ghostOffset: 0.0,
            activityLevel: 0.2,
            systemColors: systemColors,
            onChanged: (mod) {
              visualProvider.setRotationZW(_filterModToRotation(mod));
            },
            onDoubleTap: () => visualProvider.setRotationZW(0.0),
          ),

          // ========================================
          // TONE SHAPING Section
          // ========================================
          SynthParameterSectionHeader(
            title: 'TONE SHAPING',
            systemColors: systemColors,
          ),

          // Brightness (Hue → Spectral tilt)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Brightness',
              visualLabel: 'Hue',
              sonicLabel: 'Spectral tilt EQ',
              min: 0.0,
              max: 360.0,
              unit: '°',
            ),
            value: visualProvider.hueShift,
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (hue) => visualProvider.setHueShift(hue),
            onDoubleTap: () => visualProvider.setHueShift(180.0),
          ),

          // Resonance (Saturation → Filter Q)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Resonance',
              visualLabel: 'Saturation',
              sonicLabel: 'Filter Q boost',
              min: 0.0,
              max: 1.0,
              unit: '%',
            ),
            value: visualProvider.saturation,
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (sat) => visualProvider.setSaturation(sat),
            onDoubleTap: () => visualProvider.setSaturation(0.7),
          ),

          // Output (Brightness → Gain)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Output',
              visualLabel: 'Brightness',
              sonicLabel: 'Output gain',
              min: 0.0,
              max: 1.0,
              unit: '%',
            ),
            value: visualProvider.vertexBrightness,
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (b) => visualProvider.setVertexBrightness(b),
            onDoubleTap: () => visualProvider.setVertexBrightness(0.8),
          ),

          // ========================================
          // SPACE & TEXTURE Section
          // ========================================
          SynthParameterSectionHeader(
            title: 'SPACE & TEXTURE',
            systemColors: systemColors,
          ),

          // Reverb (Glow → Wet mix 5-60%)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Reverb',
              visualLabel: 'Glow',
              sonicLabel: 'Reverb wet mix',
              min: 0.05,
              max: 0.6,
              unit: '%',
            ),
            value: _glowToReverb(visualProvider.glowIntensity),
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (reverb) {
              visualProvider.setGlowIntensity(_reverbToGlow(reverb));
            },
            onDoubleTap: () => visualProvider.setGlowIntensity(1.0),
          ),

          // Noise (Chaos → 0-30%)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Noise',
              visualLabel: 'Chaos',
              sonicLabel: 'Noise injection',
              min: 0.0,
              max: 0.3,
              unit: '%',
            ),
            value: visualProvider.chaosAmount * 0.3,
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (noise) {
              visualProvider.setChaosAmount(noise / 0.3);
            },
            onDoubleTap: () => visualProvider.setChaosAmount(0.0),
          ),

          // Waveform (Morph → Shape crossfade)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Waveform',
              visualLabel: 'Morph',
              sonicLabel: 'Shape crossfade',
              min: 0.0,
              max: 1.0,
              unit: '%',
            ),
            value: visualProvider.morphParameter,
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (morph) => visualProvider.setMorphParameter(morph),
            onDoubleTap: () => visualProvider.setMorphParameter(0.0),
          ),

          // ========================================
          // DENSITY & SPEED Section
          // ========================================
          SynthParameterSectionHeader(
            title: 'DENSITY & SPEED',
            systemColors: systemColors,
          ),

          // Voices (Grid Density → 1-8 voices)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'Voices',
              visualLabel: 'Grid Density',
              sonicLabel: 'Polyphony count',
              min: 1.0,
              max: 8.0,
              unit: 'voices',
            ),
            value: visualProvider.tessellationDensity.toDouble(),
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (voices) {
              visualProvider.setTessellationDensity(voices.round());
            },
            onDoubleTap: () => visualProvider.setTessellationDensity(4),
          ),

          // LFO Rate (Speed → 0.1-10 Hz)
          SynthParameterSlider(
            config: const SynthSliderConfig(
              label: 'LFO Rate',
              visualLabel: 'Speed',
              sonicLabel: 'Modulation speed',
              min: 0.1,
              max: 5.0,
              unit: 'Hz',
            ),
            value: visualProvider.rotationSpeed,
            ghostOffset: 0.0,
            activityLevel: 0.0,
            systemColors: systemColors,
            onChanged: (rate) => visualProvider.setRotationSpeed(rate),
            onDoubleTap: () => visualProvider.setRotationSpeed(1.0),
          ),

          // Bottom padding
          const SizedBox(height: SynthTheme.spacingXLarge),
        ],
      ),
    );
  }

  // ========================================
  // Conversion helpers
  // ========================================

  /// Convert rotation (0-2π) to cents (±maxCents)
  static double _rotationToCents(double rotation, double maxCents) {
    // Rotation 0-π = 0 to +maxCents, π-2π = 0 to -maxCents
    final normalized = (rotation % (2 * math.pi)) / (2 * math.pi);
    return (normalized * 2 - 1) * maxCents;
  }

  /// Convert cents (±maxCents) to rotation (0-2π)
  static double _centsToRotation(double cents, double maxCents) {
    final normalized = (cents / maxCents + 1) / 2;
    return normalized * 2 * math.pi;
  }

  /// Convert rotation (0-2π) to semitones (0-2)
  static double _rotationToSemitones(double rotation) {
    return (rotation / (2 * math.pi)) * 2.0;
  }

  /// Convert semitones (0-2) to rotation (0-2π)
  static double _semitonesToRotation(double st) {
    return (st / 2.0) * 2 * math.pi;
  }

  /// Convert rotation (0-2π) to percent (0-1)
  static double _rotationToPercent(double rotation) {
    return rotation / (2 * math.pi);
  }

  /// Convert percent (0-1) to rotation (0-2π)
  static double _percentToRotation(double percent) {
    return percent * 2 * math.pi;
  }

  /// Convert rotation (0-2π) to filter mod (±0.4)
  static double _rotationToFilterMod(double rotation) {
    final normalized = (rotation % (2 * math.pi)) / (2 * math.pi);
    return (normalized * 2 - 1) * 0.4;
  }

  /// Convert filter mod (±0.4) to rotation (0-2π)
  static double _filterModToRotation(double mod) {
    final normalized = (mod / 0.4 + 1) / 2;
    return normalized * 2 * math.pi;
  }

  /// Convert glow (0-3) to reverb (0.05-0.6)
  static double _glowToReverb(double glow) {
    return 0.05 + (glow / 3.0) * 0.55;
  }

  /// Convert reverb (0.05-0.6) to glow (0-3)
  static double _reverbToGlow(double reverb) {
    return ((reverb - 0.05) / 0.55) * 3.0;
  }
}
