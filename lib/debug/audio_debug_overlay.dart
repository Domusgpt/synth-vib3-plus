/// Audio Debug Overlay
///
/// Displays real-time audio state for debugging during Firebase Test Lab runs.
/// Shows initialization status, playback state, and buffer metrics.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioDebugOverlay extends StatefulWidget {
  final bool enabled;

  const AudioDebugOverlay({
    super.key,
    this.enabled = true,
  });

  @override
  State<AudioDebugOverlay> createState() => _AudioDebugOverlayState();
}

class _AudioDebugOverlayState extends State<AudioDebugOverlay> {
  Timer? _refreshTimer;
  int _touchCount = 0;
  String _lastTouchTime = 'Never';
  double _maxAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    // Refresh UI every 100ms to show real-time state
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void recordTouch() {
    _touchCount++;
    _lastTouchTime = DateTime.now().toString().split('.').first.split(' ').last;
    if (mounted) setState(() {});
  }

  void updateAmplitude(double amp) {
    if (amp > _maxAmplitude) {
      _maxAmplitude = amp;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        // Update max amplitude from current buffer
        final buffer = audio.currentBuffer;
        if (buffer != null && buffer.isNotEmpty) {
          double maxAmp = 0;
          for (int i = 0; i < buffer.length; i++) {
            if (buffer[i].abs() > maxAmp) maxAmp = buffer[i].abs();
          }
          if (maxAmp > _maxAmplitude) _maxAmplitude = maxAmp;
        }

        final metrics = audio.getMetrics();

        return Positioned(
          top: 40,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: audio.isPlaying ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(audio),
                const Divider(color: Colors.white24, height: 8),
                _buildStatusRow('PCM Init', audio.isPcmAvailable,
                  audio.isPcmAvailable ? 'YES' : 'NO'),
                _buildStatusRow('Playing', audio.isPlaying,
                  audio.isPlaying ? 'YES' : 'NO'),
                _buildStatusRow('Initialized', audio.isInitialized,
                  audio.isInitialized ? 'YES' : 'NO'),
                const SizedBox(height: 4),
                _buildInfoRow('Note', '${audio.currentNote} (${_noteName(audio.currentNote)})'),
                _buildInfoRow('Volume', '${(audio.masterVolume * 100).toInt()}%'),
                _buildInfoRow('Buffers/s', metrics['buffersPerSecond'] ?? '0'),
                const SizedBox(height: 4),
                _buildAmplitudeBar(_maxAmplitude),
                const SizedBox(height: 4),
                _buildInfoRow('Max Amp', _maxAmplitude.toStringAsFixed(4)),
                _buildInfoRow('Touch #', '$_touchCount'),
                _buildInfoRow('Last Touch', _lastTouchTime),
                const SizedBox(height: 4),
                _buildInfoRow('Branch', audio.currentSynthesisBranch),
                _buildInfoRow('Config', audio.getSynthesisConfig()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AudioProvider audio) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          audio.isPlaying ? Icons.volume_up : Icons.volume_off,
          color: audio.isPlaying ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          'AUDIO DEBUG',
          style: TextStyle(
            color: audio.isPlaying ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: audio.isPlaying ? Colors.green : Colors.red,
            boxShadow: audio.isPlaying ? [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ] : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool status, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: status ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmplitudeBar(double amplitude) {
    final normalizedAmp = (amplitude * 100).clamp(0.0, 100.0);
    final color = amplitude > 0.5 ? Colors.orange :
                  amplitude > 0.1 ? Colors.green : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amplitude',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 150,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white24),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: normalizedAmp / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: amplitude > 0.1 ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ] : null,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${normalizedAmp.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _noteName(int midiNote) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    final note = midiNote % 12;
    return '${noteNames[note]}$octave';
  }
}

/// Global key to access debug overlay from anywhere
final audioDebugOverlayKey = GlobalKey<_AudioDebugOverlayState>();

/// Helper function to record touch from XY pad
void recordDebugTouch() {
  audioDebugOverlayKey.currentState?.recordTouch();
}

/// Helper function to update amplitude from audio callback
void updateDebugAmplitude(double amp) {
  audioDebugOverlayKey.currentState?.updateAmplitude(amp);
}
