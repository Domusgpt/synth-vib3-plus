/**
 * Synth Parameter Slider
 *
 * Unified slider component for all synthesis parameters with:
 * - Base value thumb (solid) - User's manual setting
 * - Ghost offset thumb (40% opacity) - Shows audio reactivity effect
 * - Activity meter - Shows current parameter activity level
 * - Dual readout - Shows both visual value AND sonic value
 * - Disabled state styling (30% opacity)
 * - Bidirectional mode for ± range parameters (detune)
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';

/// Configuration for a synthesis parameter slider
class SynthSliderConfig {
  final String label;          // Primary label (sonic function)
  final String visualLabel;    // Optional visual source label
  final String sonicLabel;     // Sonic effect description
  final double min;
  final double max;
  final String unit;           // Display unit (%, Hz, cents, etc.)
  final bool isBidirectional;  // True for ± ranges (detune)
  final bool isEnabled;        // False to dim/disable slider

  const SynthSliderConfig({
    required this.label,
    this.visualLabel = '',
    this.sonicLabel = '',
    required this.min,
    required this.max,
    required this.unit,
    this.isBidirectional = false,
    this.isEnabled = true,
  });
}

/// The unified parameter slider widget
class SynthParameterSlider extends StatefulWidget {
  final SynthSliderConfig config;
  final double value;               // Current base value
  final double ghostOffset;         // Audio reactivity offset (0 = no offset)
  final double activityLevel;       // 0-1 activity meter level
  final SystemColors systemColors;
  final ValueChanged<double> onChanged;
  final VoidCallback? onDoubleTap;  // Reset to default

  const SynthParameterSlider({
    super.key,
    required this.config,
    required this.value,
    this.ghostOffset = 0.0,
    this.activityLevel = 0.0,
    required this.systemColors,
    required this.onChanged,
    this.onDoubleTap,
  });

  @override
  State<SynthParameterSlider> createState() => _SynthParameterSliderState();
}

class _SynthParameterSliderState extends State<SynthParameterSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _activityController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _activityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void didUpdateWidget(SynthParameterSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate activity level changes
    _activityController.animateTo(
      widget.activityLevel,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final isEnabled = config.isEnabled;
    final opacity = isEnabled ? 1.0 : 0.3;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onDoubleTap: isEnabled ? widget.onDoubleTap : null,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(
            horizontal: SynthTheme.spacingMedium,
            vertical: SynthTheme.spacingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Primary label
                  Expanded(
                    child: Text(
                      config.label,
                      style: SynthTheme.textStyleBody.copyWith(
                        color: isEnabled
                            ? SynthTheme.textPrimary
                            : SynthTheme.textDim,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Value display
                  Text(
                    _formatValue(widget.value),
                    style: SynthTheme.textStyleValue(
                      isEnabled
                          ? widget.systemColors.primary
                          : widget.systemColors.disabledColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SynthTheme.spacingXSmall),

              // Slider track
              Expanded(
                child: IgnorePointer(
                  ignoring: !isEnabled,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildCustomSlider(constraints.maxWidth);
                    },
                  ),
                ),
              ),

              // Activity meter bar
              const SizedBox(height: 2),
              _buildActivityMeter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSlider(double width) {
    final config = widget.config;
    final range = config.max - config.min;

    // Calculate positions
    final basePosition = ((widget.value - config.min) / range) * width;
    final ghostValue = (widget.value + widget.ghostOffset).clamp(config.min, config.max);
    final ghostPosition = ((ghostValue - config.min) / range) * width;

    // Center position for bidirectional sliders
    final centerPosition = config.isBidirectional ? width / 2 : 0.0;

    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isDragging = true),
      onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
      onHorizontalDragUpdate: (details) {
        final newPosition = (details.localPosition.dx / width).clamp(0.0, 1.0);
        final newValue = config.min + (newPosition * range);
        widget.onChanged(newValue);
      },
      onTapDown: (details) {
        final newPosition = (details.localPosition.dx / width).clamp(0.0, 1.0);
        final newValue = config.min + (newPosition * range);
        widget.onChanged(newValue);
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: widget.systemColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(SynthTheme.radiusSmall),
          border: Border.all(
            color: widget.systemColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Track fill (from start/center to base position)
            if (config.isBidirectional)
              _buildBidirectionalTrackFill(width, basePosition, centerPosition)
            else
              _buildUnidirectionalTrackFill(width, basePosition),

            // Ghost thumb (audio reactivity offset)
            if (widget.ghostOffset != 0)
              Positioned(
                left: ghostPosition - 10,
                top: 6,
                child: _buildThumb(isGhost: true),
              ),

            // Base thumb (user value)
            Positioned(
              left: basePosition - 10,
              top: 6,
              child: _buildThumb(isGhost: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnidirectionalTrackFill(double width, double basePosition) {
    return Positioned(
      left: 0,
      top: 8,
      child: Container(
        width: basePosition.clamp(0.0, width),
        height: 16,
        decoration: BoxDecoration(
          gradient: widget.systemColors.sliderGradient,
          borderRadius: BorderRadius.circular(SynthTheme.radiusSmall - 2),
        ),
      ),
    );
  }

  Widget _buildBidirectionalTrackFill(
    double width,
    double basePosition,
    double centerPosition,
  ) {
    final left = basePosition < centerPosition ? basePosition : centerPosition;
    final fillWidth = (basePosition - centerPosition).abs();

    return Positioned(
      left: left,
      top: 8,
      child: Container(
        width: fillWidth.clamp(0.0, width),
        height: 16,
        decoration: BoxDecoration(
          gradient: widget.systemColors.sliderGradient,
          borderRadius: BorderRadius.circular(SynthTheme.radiusSmall - 2),
        ),
      ),
    );
  }

  Widget _buildThumb({required bool isGhost}) {
    final size = isGhost ? 16.0 : 20.0;
    final color = isGhost
        ? widget.systemColors.ghostColor
        : widget.systemColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isGhost ? Colors.transparent : SynthTheme.textPrimary,
          width: isGhost ? 0 : 2,
        ),
        boxShadow: isGhost
            ? null
            : [
                BoxShadow(
                  color: widget.systemColors.primary.withOpacity(0.5),
                  blurRadius: _isDragging ? 12 : 6,
                  spreadRadius: 0,
                ),
              ],
      ),
    );
  }

  Widget _buildActivityMeter() {
    return AnimatedBuilder(
      animation: _activityController,
      builder: (context, child) {
        return Container(
          height: 3,
          decoration: BoxDecoration(
            color: widget.systemColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _activityController.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.systemColors.sliderGradient,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatValue(double value) {
    final config = widget.config;

    // Format based on unit type
    String formatted;
    if (config.unit == 'cents' || config.unit == 'c') {
      // Show sign for bidirectional
      final sign = value >= 0 ? '+' : '';
      formatted = '$sign${value.toStringAsFixed(1)}${config.unit}';
    } else if (config.unit == '%') {
      formatted = '${(value * 100).toStringAsFixed(0)}%';
    } else if (config.unit == 'Hz') {
      if (value >= 1000) {
        formatted = '${(value / 1000).toStringAsFixed(1)}kHz';
      } else {
        formatted = '${value.toStringAsFixed(0)}Hz';
      }
    } else if (config.unit == 'st') {
      final sign = value >= 0 ? '+' : '';
      formatted = '$sign${value.toStringAsFixed(1)}st';
    } else if (config.unit == 'voices') {
      formatted = '${value.toInt()} voices';
    } else if (config.unit.isEmpty) {
      formatted = value.toStringAsFixed(2);
    } else {
      formatted = '${value.toStringAsFixed(1)}${config.unit}';
    }

    return formatted;
  }
}

/// A section header for grouping sliders
class SynthParameterSectionHeader extends StatelessWidget {
  final String title;
  final SystemColors systemColors;

  const SynthParameterSectionHeader({
    super.key,
    required this.title,
    required this.systemColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SynthTheme.spacingMedium,
        vertical: SynthTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: systemColors.surface.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: systemColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: SynthTheme.textStyleCaption.copyWith(
          color: systemColors.primary,
          letterSpacing: 2.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
