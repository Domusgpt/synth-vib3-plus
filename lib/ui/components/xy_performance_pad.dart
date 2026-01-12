/**
 * XY Performance Pad
 *
 * Primary interaction surface overlaying the 4D visualization.
 * Features multi-touch support (up to 8 simultaneous notes),
 * scale quantization, holographic touch feedback, and dual-axis
 * parameter control.
 *
 * Visual Feedback:
 * - Touch ripples with system-color glow
 * - Sustaining notes show persistent indicators
 * - Scale-aware grid overlay (optional)
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/synth_theme.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/visual_provider.dart';
import '../../debug/audio_debug_overlay.dart';

class XYPerformancePad extends StatefulWidget {
  final SystemColors systemColors;
  final bool showGrid;
  final Widget? backgroundVisualization;

  const XYPerformancePad({
    Key? key,
    required this.systemColors,
    this.showGrid = false,
    this.backgroundVisualization,
  }) : super(key: key);

  @override
  State<XYPerformancePad> createState() => _XYPerformancePadState();
}

class _XYPerformancePadState extends State<XYPerformancePad>
    with TickerProviderStateMixin {
  // Track active touches (up to 8 simultaneous)
  final Map<int, TouchPoint> _activeTouches = {};

  // Ripple animations for each touch
  final Map<int, AnimationController> _rippleControllers = {};
  final Map<int, Animation<double>> _rippleAnimations = {};

  @override
  void dispose() {
    for (var controller in _rippleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTouchStart(PointerDownEvent event, UIStateProvider uiState, AudioProvider audioProvider) {
    debugPrint('👆 [XYPad] Touch START received! pointer=${event.pointer} pos=${event.localPosition}');

    if (_activeTouches.length >= 8) {
      debugPrint('⚠️ [XYPad] Max 8 touches reached, ignoring');
      return;
    }

    final touchId = event.pointer;
    final position = event.localPosition;
    final size = context.size!;
    debugPrint('👆 [XYPad] Processing touch in area ${size.width.toInt()}x${size.height.toInt()}');

    // Normalize position (0.0 to 1.0)
    final normalizedX = (position.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = 1.0 - (position.dy / size.height).clamp(0.0, 1.0);

    // Calculate MIDI note from X position (respects scale/quantization)
    final midiNote = uiState.xyPositionToMidiNote(normalizedX);

    // Calculate Y-axis parameter value
    final yValue = _calculateYAxisValue(normalizedY, uiState);

    // Trigger note
    audioProvider.noteOn(midiNote);
    _applyYAxisParameter(yValue, uiState, audioProvider);

    // Store touch point
    setState(() {
      _activeTouches[touchId] = TouchPoint(
        id: touchId,
        position: position,
        midiNote: midiNote,
        yValue: yValue,
        startTime: DateTime.now(),
      );
    });

    // Create ripple animation
    _createRippleAnimation(touchId);

    debugPrint('🎹 Touch $touchId: Note $midiNote, Y-Param: ${yValue.toStringAsFixed(2)}');
  }

  void _handleTouchMove(PointerMoveEvent event, UIStateProvider uiState, AudioProvider audioProvider) {
    final touchId = event.pointer;
    if (!_activeTouches.containsKey(touchId)) return;

    final position = event.localPosition;
    final size = context.size!;

    // Normalize position
    final normalizedX = (position.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = 1.0 - (position.dy / size.height).clamp(0.0, 1.0);

    // Calculate new MIDI note
    final newMidiNote = uiState.xyPositionToMidiNote(normalizedX);
    final oldMidiNote = _activeTouches[touchId]!.midiNote;

    // If pitch changed, trigger new note
    if (newMidiNote != oldMidiNote) {
      audioProvider.noteOff(oldMidiNote);
      audioProvider.noteOn(newMidiNote);
    }

    // Update Y-axis parameter (continuous)
    final yValue = _calculateYAxisValue(normalizedY, uiState);
    _applyYAxisParameter(yValue, uiState, audioProvider);

    // Update touch point
    setState(() {
      _activeTouches[touchId] = TouchPoint(
        id: touchId,
        position: position,
        midiNote: newMidiNote,
        yValue: yValue,
        startTime: _activeTouches[touchId]!.startTime,
      );
    });
  }

  void _handleTouchEnd(PointerUpEvent event, UIStateProvider uiState, AudioProvider audioProvider) {
    final touchId = event.pointer;
    if (!_activeTouches.containsKey(touchId)) return;

    final touchPoint = _activeTouches[touchId]!;
    audioProvider.noteOff(touchPoint.midiNote);

    setState(() {
      _activeTouches.remove(touchId);
    });

    // Fade out ripple
    _rippleControllers[touchId]?.reverse();

    debugPrint('🎹 Touch $touchId released: Note ${touchPoint.midiNote}');
  }

  void _createRippleAnimation(int touchId) {
    final controller = AnimationController(
      duration: SynthTheme.rippleDuration,
      vsync: this,
    );
    final animation = Tween<double>(begin: 0.0, end: 80.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    _rippleControllers[touchId] = controller;
    _rippleAnimations[touchId] = animation;

    controller.forward();

    // Clean up after animation completes
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _rippleControllers.remove(touchId);
        _rippleAnimations.remove(touchId);
      }
    });
  }

  double _calculateYAxisValue(double normalizedY, UIStateProvider uiState) {
    // Y-axis always returns 0.0 to 1.0 (normalized)
    return normalizedY;
  }

  void _applyYAxisParameter(double value, UIStateProvider uiState, AudioProvider audioProvider) {
    final yAxis = uiState.xyAxisY;
    final visualProvider = Provider.of<VisualProvider>(context, listen: false);

    switch (yAxis) {
      case XYAxisParameter.pitch:
        // Pitch is handled by X-axis
        break;

      case XYAxisParameter.filterCutoff:
        // Map 0-1 to 20Hz-20kHz logarithmically
        final cutoff = 20.0 * math.pow(1000, value);
        audioProvider.setFilterCutoff(cutoff);
        break;

      case XYAxisParameter.resonance:
        audioProvider.setFilterResonance(value);
        break;

      case XYAxisParameter.fmDepth:
        // FM depth control (for FM synthesis branch)
        audioProvider.setFMDepth(value);
        break;

      case XYAxisParameter.ringModMix:
        // Ring modulation mix (for ring mod synthesis branch)
        audioProvider.setRingModMix(value);
        break;

      case XYAxisParameter.morph:
      case XYAxisParameter.morphParameter:
        visualProvider.setMorphParameter(value);
        break;

      case XYAxisParameter.chaos:
        // Chaos/randomization parameter
        visualProvider.setMorphParameter(value); // Placeholder
        break;

      case XYAxisParameter.brightness:
        visualProvider.setVertexBrightness(value);
        break;

      case XYAxisParameter.reverb:
        visualProvider.setGlowIntensity(value * 3.0);
        break;

      case XYAxisParameter.oscillatorMix:
        audioProvider.setMixBalance(value);
        break;

      case XYAxisParameter.rotationSpeed:
        visualProvider.setRotationSpeed(value * 2.0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    // Use GestureDetector with immediate drag start for synthesizer response
    // dragStartBehavior.down makes pan gestures fire immediately on touch
    return GestureDetector(
      // Capture all touches in this area even if children are transparent
      behavior: HitTestBehavior.opaque,
      // CRITICAL: Start drag immediately on touch, don't wait for movement
      dragStartBehavior: DragStartBehavior.down,
      onPanStart: (details) {
        debugPrint('👆 [XYPad] PAN START at ${details.localPosition}');
        _handleGestureTouchStart(details.localPosition, uiState, audioProvider);
      },
      onPanUpdate: (details) {
        _handleGestureTouchMove(details.localPosition, uiState, audioProvider);
      },
      onPanEnd: (details) {
        debugPrint('👆 [XYPad] PAN END');
        _handleGestureTouchEnd(uiState, audioProvider);
      },
      onPanCancel: () {
        debugPrint('👆 [XYPad] PAN CANCEL');
        _handleGestureTouchEnd(uiState, audioProvider);
      },
      child: Container(
        // Ensure container fills available space and has a color for hit testing
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,  // Force stack to fill available space
          children: [
            // Background visualization (VIB3+ WebGL view)
            if (widget.backgroundVisualization != null)
              Positioned.fill(child: widget.backgroundVisualization!),

            // Grid overlay (optional, scale-aware)
            if (widget.showGrid)
              Positioned.fill(
                child: CustomPaint(
                  painter: XYGridPainter(
                    systemColors: widget.systemColors,
                    pitchRangeStart: uiState.pitchRangeStart,
                    pitchRangeEnd: uiState.pitchRangeEnd,
                    scale: uiState.pitchScale,
                  ),
                ),
              ),

            // Touch ripples and indicators
            Positioned.fill(
              child: CustomPaint(
                painter: TouchIndicatorPainter(
                  touches: _activeTouches.values.toList(),
                  rippleAnimations: _rippleAnimations,
                  systemColors: widget.systemColors,
                ),
              ),
            ),

            // Configuration overlay (top corner)
            Positioned(
              top: SynthTheme.spacingMedium,
              right: SynthTheme.spacingMedium,
              child: _buildConfigOverlay(uiState),
            ),
          ],
        ),
      ),
    );
  }

  // Single-touch gesture handlers (for GestureDetector)
  int _currentGestureId = 0;

  void _handleGestureTouchStart(Offset position, UIStateProvider uiState, AudioProvider audioProvider) {
    // Record touch for debug overlay
    recordDebugTouch();

    final size = context.size!;
    debugPrint('👆 [XYPad] Processing touch in area ${size.width.toInt()}x${size.height.toInt()}');

    // Normalize position (0.0 to 1.0)
    final normalizedX = (position.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = 1.0 - (position.dy / size.height).clamp(0.0, 1.0);

    // Calculate MIDI note from X position
    final midiNote = uiState.xyPositionToMidiNote(normalizedX);
    final yValue = _calculateYAxisValue(normalizedY, uiState);

    // Trigger note
    audioProvider.noteOn(midiNote);
    _applyYAxisParameter(yValue, uiState, audioProvider);

    // Store touch point
    _currentGestureId++;
    setState(() {
      _activeTouches[_currentGestureId] = TouchPoint(
        id: _currentGestureId,
        position: position,
        midiNote: midiNote,
        yValue: yValue,
        startTime: DateTime.now(),
      );
    });

    _createRippleAnimation(_currentGestureId);
    debugPrint('🎹 Touch: Note $midiNote, Y-Param: ${yValue.toStringAsFixed(2)}');
  }

  void _handleGestureTouchMove(Offset position, UIStateProvider uiState, AudioProvider audioProvider) {
    if (_activeTouches.isEmpty) return;

    final size = context.size!;
    final normalizedX = (position.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = 1.0 - (position.dy / size.height).clamp(0.0, 1.0);

    final newMidiNote = uiState.xyPositionToMidiNote(normalizedX);
    final currentTouch = _activeTouches[_currentGestureId];
    if (currentTouch == null) return;

    final oldMidiNote = currentTouch.midiNote;

    if (newMidiNote != oldMidiNote) {
      audioProvider.noteOff(oldMidiNote);
      audioProvider.noteOn(newMidiNote);
    }

    final yValue = _calculateYAxisValue(normalizedY, uiState);
    _applyYAxisParameter(yValue, uiState, audioProvider);

    setState(() {
      _activeTouches[_currentGestureId] = TouchPoint(
        id: _currentGestureId,
        position: position,
        midiNote: newMidiNote,
        yValue: yValue,
        startTime: currentTouch.startTime,
      );
    });
  }

  void _handleGestureTouchEnd(UIStateProvider uiState, AudioProvider audioProvider) {
    final currentTouch = _activeTouches[_currentGestureId];
    if (currentTouch != null) {
      audioProvider.noteOff(currentTouch.midiNote);
      debugPrint('🎹 Touch released: Note ${currentTouch.midiNote}');
    }

    _rippleControllers[_currentGestureId]?.reverse();

    setState(() {
      _activeTouches.remove(_currentGestureId);
    });
  }

  Widget _buildConfigOverlay(UIStateProvider uiState) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SynthTheme.spacingMedium,
        vertical: SynthTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: SynthTheme.panelBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(SynthTheme.radiusMedium),
        border: Border.all(color: SynthTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'X: ${_getAxisLabel(uiState.xyAxisX)}',
            style: SynthTheme.textStyleCaption.copyWith(
              color: widget.systemColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Y: ${_getAxisLabel(uiState.xyAxisY)}',
            style: SynthTheme.textStyleCaption.copyWith(
              color: widget.systemColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_getMidiNoteName(uiState.pitchRangeStart)} - ${_getMidiNoteName(uiState.pitchRangeEnd)}',
            style: SynthTheme.textStyleCaption,
          ),
          const SizedBox(height: 4),
          Text(
            uiState.pitchScale.toUpperCase(),
            style: SynthTheme.textStyleCaption.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getAxisLabel(XYAxisParameter param) {
    switch (param) {
      case XYAxisParameter.pitch:
        return 'Pitch';
      case XYAxisParameter.filterCutoff:
        return 'Filter';
      case XYAxisParameter.resonance:
        return 'Resonance';
      case XYAxisParameter.fmDepth:
        return 'FM Depth';
      case XYAxisParameter.ringModMix:
        return 'Ring Mod';
      case XYAxisParameter.morph:
        return 'Morph';
      case XYAxisParameter.chaos:
        return 'Chaos';
      case XYAxisParameter.brightness:
        return 'Brightness';
      case XYAxisParameter.reverb:
        return 'Reverb';
      case XYAxisParameter.oscillatorMix:
        return 'OSC Mix';
      case XYAxisParameter.morphParameter:
        return 'Morph Param';
      case XYAxisParameter.rotationSpeed:
        return 'Rotation';
    }
  }

  String _getMidiNoteName(int midiNote) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    final noteName = noteNames[midiNote % 12];
    return '$noteName$octave';
  }
}

/// Touch point data structure
class TouchPoint {
  final int id;
  final Offset position;
  final int midiNote;
  final double yValue;
  final DateTime startTime;

  TouchPoint({
    required this.id,
    required this.position,
    required this.midiNote,
    required this.yValue,
    required this.startTime,
  });

  Duration get duration => DateTime.now().difference(startTime);
}

/// Custom painter for touch indicators and ripples
class TouchIndicatorPainter extends CustomPainter {
  final List<TouchPoint> touches;
  final Map<int, Animation<double>> rippleAnimations;
  final SystemColors systemColors;

  TouchIndicatorPainter({
    required this.touches,
    required this.rippleAnimations,
    required this.systemColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var touch in touches) {
      // Ripple effect
      final rippleAnimation = rippleAnimations[touch.id];
      if (rippleAnimation != null) {
        final rippleRadius = rippleAnimation.value;
        final rippleOpacity = (1.0 - rippleAnimation.value / 80.0) * 0.5;

        final ripplePaint = Paint()
          ..color = systemColors.primary.withOpacity(rippleOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(touch.position, rippleRadius, ripplePaint);
      }

      // Touch indicator (sustaining note)
      final indicatorPaint = Paint()
        ..color = systemColors.primary.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = systemColors.primary.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      // Glow
      canvas.drawCircle(touch.position, 24, glowPaint);

      // Center dot
      canvas.drawCircle(touch.position, 12, indicatorPaint);

      // Note label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _getMidiNoteName(touch.midiNote),
          style: SynthTheme.textStyleCaption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          touch.position.dx - textPainter.width / 2,
          touch.position.dy + 20,
        ),
      );
    }
  }

  String _getMidiNoteName(int midiNote) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    final noteName = noteNames[midiNote % 12];
    return '$noteName$octave';
  }

  @override
  bool shouldRepaint(TouchIndicatorPainter oldDelegate) => true;
}

/// Custom painter for grid overlay (scale-aware)
class XYGridPainter extends CustomPainter {
  final SystemColors systemColors;
  final int pitchRangeStart;
  final int pitchRangeEnd;
  final String scale;

  XYGridPainter({
    required this.systemColors,
    required this.pitchRangeStart,
    required this.pitchRangeEnd,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = systemColors.primary.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical lines (pitch divisions)
    final octaves = ((pitchRangeEnd - pitchRangeStart) / 12).ceil();
    for (var i = 0; i <= octaves; i++) {
      final x = size.width * (i / octaves);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal lines (Y parameter divisions)
    for (var i = 0; i <= 8; i++) {
      final y = size.height * (i / 8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Octave markers (thicker lines)
    final octaveMarkerPaint = Paint()
      ..color = systemColors.primary.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i <= octaves; i++) {
      final x = size.width * (i / octaves);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), octaveMarkerPaint);
    }
  }

  @override
  bool shouldRepaint(XYGridPainter oldDelegate) {
    return pitchRangeStart != oldDelegate.pitchRangeStart ||
        pitchRangeEnd != oldDelegate.pitchRangeEnd ||
        scale != oldDelegate.scale;
  }
}
