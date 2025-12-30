/**
 * Orb Controller
 *
 * Floating, draggable trackball-style pitch modulation controller.
 * Features pitch bend (±1 to ±12 semitones) and vibrato control.
 * Integrates with device tilt for hands-free modulation.
 *
 * Visual States:
 * - Inactive: Subtle glow at origin
 * - Active (dragging): Intense glow + trail effect
 * - Tilt mode: Pulsing indicator + auto-movement
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/synth_theme.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/tilt_sensor_provider.dart';

class OrbController extends StatefulWidget {
  final SystemColors systemColors;
  final Offset initialPosition;

  const OrbController({
    Key? key,
    required this.systemColors,
    this.initialPosition = const Offset(0.5, 0.5), // Normalized (0-1)
  }) : super(key: key);

  @override
  State<OrbController> createState() => _OrbControllerState();
}

class _OrbControllerState extends State<OrbController>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero; // Relative to origin (-1 to 1)
  bool _isDragging = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: SynthTheme.pulseDuration,
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details, UIStateProvider uiState) {
    setState(() => _isDragging = true);
    uiState.setOrbControllerActive(true);
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    UIStateProvider uiState,
    AudioProvider audioProvider,
    Size orbSize,
  ) {
    // Convert drag delta to orb space
    final deltaX = details.delta.dx / (orbSize.width / 2);
    final deltaY = details.delta.dy / (orbSize.height / 2);

    setState(() {
      _position = Offset(
        (_position.dx + deltaX).clamp(-1.0, 1.0),
        (_position.dy + deltaY).clamp(-1.0, 1.0),
      );
    });

    // Update orb controller position in state
    uiState.setOrbControllerPosition(_position);

    // Apply modulation
    _applyModulation(_position, uiState, audioProvider);
  }

  void _handleDragEnd(DragEndDetails details, UIStateProvider uiState) {
    setState(() => _isDragging = false);
    uiState.setOrbControllerActive(false);

    // Return to center with spring animation
    _returnToCenter();
  }

  void _returnToCenter() {
    setState(() {
      _position = Offset.zero;
    });
  }

  void _applyModulation(
    Offset position,
    UIStateProvider uiState,
    AudioProvider audioProvider,
  ) {
    // X-axis: Pitch bend (±semitones based on range setting)
    final pitchBendRange = uiState.orbPitchBendRange;
    final pitchBendSemitones = position.dx * pitchBendRange;
    audioProvider.setPitchBend(pitchBendSemitones);

    // Y-axis: Vibrato depth (0-1)
    final vibratoDepth = (1.0 - position.dy) / 2.0; // Map -1..1 to 0..1
    audioProvider.setVibratoDepth(vibratoDepth);

    debugPrint('🎛️ Orb: Pitch ${pitchBendSemitones.toStringAsFixed(2)}st, Vibrato ${vibratoDepth.toStringAsFixed(2)}');
  }

  // Update orb position from tilt sensor
  void _updateFromTilt(Offset tiltPosition, UIStateProvider uiState, AudioProvider audioProvider) {
    if (!uiState.tiltEnabled) return;

    setState(() {
      _position = tiltPosition;
    });

    _applyModulation(_position, uiState, audioProvider);
  }

  @override
  Widget build(BuildContext context) {
    final uiState = Provider.of<UIStateProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    final tiltSensor = Provider.of<TiltSensorProvider>(context);

    // Sync with tilt if enabled
    if (uiState.tiltEnabled && tiltSensor.isEnabled) {
      final orientation = MediaQuery.of(context).orientation;
      _updateFromTilt(tiltSensor.getTiltPositionForOrientation(orientation), uiState, audioProvider);
    }

    final screenSize = MediaQuery.of(context).size;
    final orbSize = Size(120, 120);

    // Calculate center position on screen
    final centerX = widget.initialPosition.dx * screenSize.width;
    final centerY = widget.initialPosition.dy * screenSize.height;

    // Calculate current orb position
    final orbX = centerX + (_position.dx * orbSize.width / 2);
    final orbY = centerY + (_position.dy * orbSize.height / 2);

    return Stack(
      children: [
        // Origin marker (crosshairs)
        Positioned(
          left: centerX - 20,
          top: centerY - 20,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: CrosshairPainter(
              color: widget.systemColors.primary.withOpacity(0.3),
            ),
          ),
        ),

        // Connection line (from origin to orb)
        if (_position != Offset.zero)
          CustomPaint(
            size: screenSize,
            painter: ConnectionLinePainter(
              start: Offset(centerX, centerY),
              end: Offset(orbX, orbY),
              color: widget.systemColors.primary,
            ),
          ),

        // Orb
        Positioned(
          left: orbX - orbSize.width / 2,
          top: orbY - orbSize.height / 2,
          child: GestureDetector(
            onPanStart: (details) => _handleDragStart(details, uiState),
            onPanUpdate: (details) => _handleDragUpdate(details, uiState, audioProvider, orbSize),
            onPanEnd: (details) => _handleDragEnd(details, uiState),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = uiState.tiltEnabled
                    ? _pulseAnimation.value
                    : (_isDragging ? 1.1 : 1.0);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: orbSize.width,
                    height: orbSize.height,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.systemColors.primary,
                          widget.systemColors.secondary,
                          widget.systemColors.accent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: _isDragging || uiState.tiltEnabled
                          ? SynthTheme(systemColors: widget.systemColors)
                              .getGlow(GlowIntensity.engaged)
                          : SynthTheme(systemColors: widget.systemColors)
                              .getGlow(GlowIntensity.active),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Center icon
                        Icon(
                          uiState.tiltEnabled ? Icons.screen_rotation : Icons.control_camera,
                          color: Colors.white.withOpacity(0.8),
                          size: 40,
                        ),

                        // Pitch bend indicator (X-axis)
                        Positioned(
                          bottom: 8,
                          child: Text(
                            '${(_position.dx * uiState.orbPitchBendRange).toStringAsFixed(1)}st',
                            style: SynthTheme.textStyleCaption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

        // Range indicator overlay
        Positioned(
          left: centerX - 60,
          top: centerY - 60,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(120, 120),
              painter: RangeIndicatorPainter(
                pitchBendRange: uiState.orbPitchBendRange,
                color: widget.systemColors.primary.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Crosshair painter for origin marker
class CrosshairPainter extends CustomPainter {
  final Color color;

  CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Horizontal line
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );

    // Center circle
    canvas.drawCircle(center, 4, paint);
  }

  @override
  bool shouldRepaint(CrosshairPainter oldDelegate) => false;
}

/// Connection line painter (from origin to orb)
class ConnectionLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  ConnectionLinePainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(start, end, glowPaint);
  }

  @override
  bool shouldRepaint(ConnectionLinePainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}

/// Range indicator painter (shows pitch bend range as circle)
class RangeIndicatorPainter extends CustomPainter {
  final double pitchBendRange;
  final Color color;

  RangeIndicatorPainter({
    required this.pitchBendRange,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw concentric circles for pitch bend range
    for (var i = 1; i <= 3; i++) {
      final radius = (size.width / 2) * (i / 3);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw quadrant lines
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(RangeIndicatorPainter oldDelegate) {
    return pitchBendRange != oldDelegate.pitchBendRange;
  }
}
