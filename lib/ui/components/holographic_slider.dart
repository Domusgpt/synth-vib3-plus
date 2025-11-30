// Holographic Slider Component
//
// Custom slider with holographic gradient fill, system-color glow,
// and smooth animations. Features neoskeuomorphic styling and
// responsive touch handling.
//
// Visual feedback:
// - Track: Holographic gradient fill from min to current value
// - Thumb: Glowing circle with system color
// - State: Inactive (60% opacity) → Active (100%) → Engaged (glow + scale)
//
// A Paul Phillips Manifestation
//
import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';

class HolographicSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String unit;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final SystemColors systemColors;
  final IconData? icon;
  final bool showValue;

  const HolographicSlider({
    super.key,
    required this.label,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.unit = '%',
    required this.onChanged,
    this.onChangeEnd,
    required this.systemColors,
    this.icon,
    this.showValue = true,
  });

  @override
  State<HolographicSlider> createState() => _HolographicSliderState();
}

class _HolographicSliderState extends State<HolographicSlider>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: SynthTheme.transitionQuick,
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: SynthTheme.curveStandard),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  String _formatValue() {
    if (widget.unit == 'note') {
      // MIDI note number
      return widget.value.round().toString();
    } else if (widget.unit == '%') {
      // Percentage
      final percentage = ((widget.value - widget.min) / (widget.max - widget.min) * 100);
      return '${percentage.round()}${widget.unit}';
    } else if (widget.unit == 'ms') {
      // Milliseconds
      return '${widget.value.round()}${widget.unit}';
    } else if (widget.unit == 'Hz') {
      // Frequency
      return '${widget.value.round()}${widget.unit}';
    } else if (widget.unit == 'cents') {
      // Cents (musical tuning)
      return '${widget.value.toStringAsFixed(1)}${widget.unit}';
    } else {
      // Default: 2 decimal places
      return widget.value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = SynthTheme(systemColors: widget.systemColors);
    final normalizedValue = (widget.value - widget.min) / (widget.max - widget.min);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SynthTheme.spacingSmall,
        horizontal: SynthTheme.spacingMedium,
      ),
      child: Row(
        children: [
          // Icon (optional)
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: widget.systemColors.primary,
              size: 16,
            ),
            const SizedBox(width: SynthTheme.spacingSmall),
          ],

          // Label
          SizedBox(
            width: 80,
            child: Text(
              widget.label,
              style: SynthTheme.textStyleBody.copyWith(
                color: theme.getTextColor(_isDragging),
              ),
            ),
          ),

          // Slider
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() => _isDragging = true);
                _glowController.forward();
              },
              onHorizontalDragUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final sliderStart = 96.0 + (widget.icon != null ? 24.0 : 0.0);
                final sliderWidth = box.size.width - sliderStart - 50.0;
                final percentage = ((localPosition.dx - sliderStart) / sliderWidth).clamp(0.0, 1.0);
                final newValue = widget.min + (percentage * (widget.max - widget.min));

                widget.onChanged(newValue);
              },
              onHorizontalDragEnd: (_) {
                setState(() => _isDragging = false);
                _glowController.reverse();
                if (widget.onChangeEnd != null) {
                  widget.onChangeEnd!(widget.value);
                }
              },
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isDragging ? _glowAnimation.value : 1.0,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: SynthTheme.cardBackground,
                        boxShadow: _isDragging
                            ? theme.getGlow(GlowIntensity.engaged)
                            : theme.getGlow(GlowIntensity.inactive),
                      ),
                      child: Stack(
                        children: [
                          // Unfilled track (background)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: SynthTheme.borderSubtle,
                                width: 1,
                              ),
                            ),
                          ),

                          // Filled track (holographic gradient)
                          FractionallySizedBox(
                            widthFactor: normalizedValue,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: theme.getHolographicGradient(),
                                boxShadow: _isDragging
                                    ? theme.getGlow(GlowIntensity.active)
                                    : null,
                              ),
                            ),
                          ),

                          // Thumb (position indicator)
                          Positioned(
                            left: normalizedValue * (MediaQuery.of(context).size.width -
                                    96 -
                                    50 -
                                    (widget.icon != null ? 24 : 0)) -
                                8,
                            top: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.systemColors.primary,
                                boxShadow: _isDragging
                                    ? theme.getGlow(GlowIntensity.engaged)
                                    : theme.getGlow(GlowIntensity.active),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Value display
          if (widget.showValue) ...[
            const SizedBox(width: SynthTheme.spacingSmall),
            SizedBox(
              width: 45,
              child: Text(
                _formatValue(),
                style: SynthTheme.textStyleValue(
                  _isDragging
                      ? widget.systemColors.primary
                      : SynthTheme.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact vertical slider (for side bezels/thumb pads)
class VerticalHolographicSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final SystemColors systemColors;
  final double width;
  final double height;

  const VerticalHolographicSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
    required this.systemColors,
    this.width = 32,
    this.height = 200,
  });

  @override
  State<VerticalHolographicSlider> createState() =>
      _VerticalHolographicSliderState();
}

class _VerticalHolographicSliderState extends State<VerticalHolographicSlider> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = SynthTheme(systemColors: widget.systemColors);
    final normalizedValue = (widget.value - widget.min) / (widget.max - widget.min);

    return GestureDetector(
      onVerticalDragStart: (_) {
        setState(() => _isDragging = true);
      },
      onVerticalDragUpdate: (details) {
        final percentage = 1.0 - ((details.localPosition.dy / widget.height).clamp(0.0, 1.0));
        final newValue = widget.min + (percentage * (widget.max - widget.min));
        widget.onChanged(newValue);
      },
      onVerticalDragEnd: (_) {
        setState(() => _isDragging = false);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.width / 2),
          color: SynthTheme.cardBackground,
          border: Border.all(
            color: _isDragging
                ? widget.systemColors.primary
                : SynthTheme.borderSubtle,
            width: 2,
          ),
          boxShadow: _isDragging
              ? theme.getGlow(GlowIntensity.engaged)
              : theme.getGlow(GlowIntensity.inactive),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Filled portion (gradient from bottom)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: normalizedValue,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.width / 2),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        widget.systemColors.primary,
                        widget.systemColors.secondary,
                        widget.systemColors.accent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Value indicator (horizontal line)
            Positioned(
              bottom: (normalizedValue * widget.height) - 2,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: widget.systemColors.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: theme.getGlow(GlowIntensity.active),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
