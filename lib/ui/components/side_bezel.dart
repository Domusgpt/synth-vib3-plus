/**
 * Side Bezel - Swipe-to-Reveal Thumb Pads
 *
 * Hidden by default, swipe from edge to reveal:
 * - Left bezel: Harmony intervals (play notes relative to XY pad)
 * - Right bezel: Modulation triggers (effects, percussion)
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/visual_provider.dart';

/// Side bezel position
enum BezelSide { left, right }

/// Harmony intervals for left bezel (semitones from root)
class HarmonyInterval {
  final String name;
  final int semitones;
  final Color? color;

  const HarmonyInterval(this.name, this.semitones, [this.color]);

  static const List<HarmonyInterval> intervals = [
    HarmonyInterval('Oct+', 12),
    HarmonyInterval('5th', 7),
    HarmonyInterval('4th', 5),
    HarmonyInterval('3rd', 4),
    HarmonyInterval('m3', 3),
    HarmonyInterval('Oct-', -12),
  ];
}

/// Modulation triggers for right bezel
class ModTrigger {
  final String name;
  final IconData icon;
  final void Function(AudioProvider, VisualProvider) onTrigger;

  const ModTrigger(this.name, this.icon, this.onTrigger);

  static List<ModTrigger> triggers = [
    ModTrigger('Filter↑', Icons.trending_up, (audio, visual) {
      // Quick filter sweep up
      final current = audio.filterCutoff;
      audio.setFilterCutoff((current * 2.0).clamp(20.0, 20000.0));
      visual.setHueShift((visual.hueShift + 60) % 360);
    }),
    ModTrigger('Filter↓', Icons.trending_down, (audio, visual) {
      // Quick filter sweep down
      final current = audio.filterCutoff;
      audio.setFilterCutoff((current / 2.0).clamp(20.0, 20000.0));
      visual.setHueShift((visual.hueShift - 60) % 360);
    }),
    ModTrigger('Noise', Icons.grain, (audio, visual) {
      // Noise burst + chaos
      audio.synthesizerEngine.setNoiseLevel(0.3);
      visual.setRGBSplitAmount(8.0);
      // Auto-decay after 200ms
      Future.delayed(const Duration(milliseconds: 200), () {
        audio.synthesizerEngine.setNoiseLevel(0.0);
        visual.setRGBSplitAmount(0.0);
      });
    }),
    ModTrigger('Reverb', Icons.waves, (audio, visual) {
      // Reverb spike + glow
      final currentReverb = audio.reverbMix;
      audio.setReverbMix(0.9);
      visual.setGlowIntensity(3.0);
      // Decay back
      Future.delayed(const Duration(milliseconds: 500), () {
        audio.setReverbMix(currentReverb);
        visual.setGlowIntensity(1.0);
      });
    }),
    ModTrigger('Warp', Icons.blur_on, (audio, visual) {
      // FM/Ring mod intensity spike
      audio.setFMDepth(2.0);
      audio.setRingModMix(1.0);
      visual.setRotationXW(5.0);
      // Decay
      Future.delayed(const Duration(milliseconds: 300), () {
        audio.setFMDepth(0.5);
        audio.setRingModMix(0.5);
      });
    }),
    ModTrigger('Glitch', Icons.flash_on, (audio, visual) {
      // Random chaos burst
      visual.setRGBSplitAmount(10.0);
      visual.setRotationSpeed(5.0);
      audio.synthesizerEngine.setNoiseLevel(0.2);
      // Quick decay
      Future.delayed(const Duration(milliseconds: 150), () {
        visual.setRGBSplitAmount(0.0);
        visual.setRotationSpeed(1.0);
        audio.synthesizerEngine.setNoiseLevel(0.0);
      });
    }),
  ];
}

class SideBezel extends StatefulWidget {
  final BezelSide side;
  final SystemColors systemColors;

  const SideBezel({
    Key? key,
    required this.side,
    required this.systemColors,
  }) : super(key: key);

  @override
  State<SideBezel> createState() => _SideBezelState();
}

class _SideBezelState extends State<SideBezel> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  static const double _collapsedWidth = 12.0; // Thin edge indicator
  static const double _expandedWidth = 64.0;  // Full thumb pad width

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _animationController.forward();
  }

  void _collapse() {
    _animationController.reverse().then((_) {
      setState(() => _isExpanded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.side == BezelSide.left;

    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: SynthTheme.topBezelHeight + SynthTheme.spacingMedium,
      bottom: SynthTheme.panelCollapsedHeight + SynthTheme.spacingMedium,
      child: GestureDetector(
        // Swipe to expand/collapse
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (isLeft) {
            if (velocity > 100) _expand();
            if (velocity < -100) _collapse();
          } else {
            if (velocity < -100) _expand();
            if (velocity > 100) _collapse();
          }
        },
        onTap: () {
          if (_isExpanded) {
            _collapse();
          } else {
            _expand();
          }
        },
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            final width = _collapsedWidth +
                (_expandedWidth - _collapsedWidth) * _slideAnimation.value;

            return Container(
              width: width,
              decoration: BoxDecoration(
                color: SynthTheme.panelBackground.withOpacity(0.9),
                borderRadius: BorderRadius.only(
                  topLeft: isLeft ? Radius.zero : const Radius.circular(12),
                  bottomLeft: isLeft ? Radius.zero : const Radius.circular(12),
                  topRight: isLeft ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isLeft ? const Radius.circular(12) : Radius.zero,
                ),
                border: Border.all(
                  color: widget.systemColors.primary.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.systemColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(isLeft ? 2 : -2, 0),
                  ),
                ],
              ),
              child: _slideAnimation.value > 0.5
                  ? _buildExpandedContent()
                  : _buildCollapsedIndicator(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollapsedIndicator() {
    return Center(
      child: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: widget.systemColors.primary.withOpacity(0.6),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    if (widget.side == BezelSide.left) {
      return _buildHarmonyPads();
    } else {
      return _buildModTriggers();
    }
  }

  Widget _buildHarmonyPads() {
    final audioProvider = Provider.of<AudioProvider>(context);
    final uiState = Provider.of<UIStateProvider>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: HarmonyInterval.intervals.map((interval) {
        return _buildThumbPad(
          label: interval.name,
          onTap: () {
            // Play note at interval from current XY pad root
            final rootNote = uiState.pitchRootNote + 60; // Middle C octave
            final harmonyNote = rootNote + interval.semitones;
            audioProvider.noteOn(harmonyNote.clamp(0, 127));
            // Short duration
            Future.delayed(const Duration(milliseconds: 200), () {
              audioProvider.noteOff(harmonyNote.clamp(0, 127));
            });
          },
          onLongPress: () {
            // Sustained harmony note
            final rootNote = uiState.pitchRootNote + 60;
            final harmonyNote = rootNote + interval.semitones;
            audioProvider.noteOn(harmonyNote.clamp(0, 127));
          },
          onLongPressUp: () {
            final rootNote = uiState.pitchRootNote + 60;
            final harmonyNote = rootNote + interval.semitones;
            audioProvider.noteOff(harmonyNote.clamp(0, 127));
          },
        );
      }).toList(),
    );
  }

  Widget _buildModTriggers() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final visualProvider = Provider.of<VisualProvider>(context, listen: false);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ModTrigger.triggers.map((trigger) {
        return _buildThumbPad(
          label: trigger.name,
          icon: trigger.icon,
          onTap: () => trigger.onTrigger(audioProvider, visualProvider),
        );
      }).toList(),
    );
  }

  Widget _buildThumbPad({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    VoidCallback? onLongPressUp,
  }) {
    final theme = SynthTheme(systemColors: widget.systemColors);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressUp: onLongPressUp,
      child: Container(
        width: 52,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: SynthTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.systemColors.primary.withOpacity(0.4),
          ),
          boxShadow: theme.getGlow(GlowIntensity.inactive),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: widget.systemColors.primary),
            Text(
              label,
              style: SynthTheme.textStyleCaption.copyWith(
                color: widget.systemColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
