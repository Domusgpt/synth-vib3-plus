/**
 * Debug Console
 *
 * On-screen debug overlay for Android device testing.
 * Shows real-time logs AND live status panels.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';

/// Live status data for real-time monitoring
class DebugStatus {
  static final DebugStatus _instance = DebugStatus._internal();
  factory DebugStatus() => _instance;
  DebugStatus._internal();

  final List<VoidCallback> _listeners = [];

  // Visual state
  String visualSystem = 'Unknown';
  int geometryIndex = 0;
  double morphParameter = 0.0;
  double gridDensity = 0.0;

  // Audio state
  bool audioPlaying = false;
  double bassEnergy = 0.0;
  double midEnergy = 0.0;
  double highEnergy = 0.0;
  double rmsAmplitude = 0.0;
  int sampleRate = 0;

  // Performance
  double fps = 0.0;
  double shaderTime = 0.0;
  bool shaderLoaded = false;
  String? shaderError;

  void update({
    String? visualSystem,
    int? geometryIndex,
    double? morphParameter,
    double? gridDensity,
    bool? audioPlaying,
    double? bassEnergy,
    double? midEnergy,
    double? highEnergy,
    double? rmsAmplitude,
    int? sampleRate,
    double? fps,
    double? shaderTime,
    bool? shaderLoaded,
    String? shaderError,
  }) {
    if (visualSystem != null) this.visualSystem = visualSystem;
    if (geometryIndex != null) this.geometryIndex = geometryIndex;
    if (morphParameter != null) this.morphParameter = morphParameter;
    if (gridDensity != null) this.gridDensity = gridDensity;
    if (audioPlaying != null) this.audioPlaying = audioPlaying;
    if (bassEnergy != null) this.bassEnergy = bassEnergy;
    if (midEnergy != null) this.midEnergy = midEnergy;
    if (highEnergy != null) this.highEnergy = highEnergy;
    if (rmsAmplitude != null) this.rmsAmplitude = rmsAmplitude;
    if (sampleRate != null) this.sampleRate = sampleRate;
    if (fps != null) this.fps = fps;
    if (shaderTime != null) this.shaderTime = shaderTime;
    if (shaderLoaded != null) this.shaderLoaded = shaderLoaded;
    if (shaderError != null) this.shaderError = shaderError;

    for (final listener in _listeners) {
      listener();
    }
  }

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}

/// Global debug log storage
class DebugConsole {
  static final DebugConsole _instance = DebugConsole._internal();
  factory DebugConsole() => _instance;
  DebugConsole._internal();

  final List<DebugLogEntry> _logs = [];
  final List<VoidCallback> _listeners = [];
  static const int maxLogs = 50;

  List<DebugLogEntry> get logs => List.unmodifiable(_logs);

  void log(String message, {DebugLogLevel level = DebugLogLevel.info}) {
    _logs.add(DebugLogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
    ));

    // Trim old logs
    while (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    // Notify listeners
    for (final listener in _listeners) {
      listener();
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void clear() {
    _logs.clear();
    for (final listener in _listeners) {
      listener();
    }
  }

  // Convenience methods
  static void info(String message) => _instance.log(message, level: DebugLogLevel.info);
  static void warn(String message) => _instance.log(message, level: DebugLogLevel.warning);
  static void error(String message) => _instance.log(message, level: DebugLogLevel.error);
  static void success(String message) => _instance.log(message, level: DebugLogLevel.success);
  static void audio(String message) => _instance.log(message, level: DebugLogLevel.audio);
  static void visual(String message) => _instance.log(message, level: DebugLogLevel.visual);
}

enum DebugLogLevel {
  info,
  warning,
  visual,
  error,
  success,
  audio,
}

class DebugLogEntry {
  final String message;
  final DebugLogLevel level;
  final DateTime timestamp;

  DebugLogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  Color get color {
    switch (level) {
      case DebugLogLevel.info:
        return Colors.white70;
      case DebugLogLevel.warning:
        return Colors.orange;
      case DebugLogLevel.visual:
        return Colors.purple;
      case DebugLogLevel.error:
        return Colors.red;
      case DebugLogLevel.success:
        return Colors.green;
      case DebugLogLevel.audio:
        return Colors.cyan;
    }
  }

  String get prefix {
    switch (level) {
      case DebugLogLevel.info:
        return 'ℹ️';
      case DebugLogLevel.warning:
        return '⚠️';
      case DebugLogLevel.visual:
        return '🎨';
      case DebugLogLevel.error:
        return '❌';
      case DebugLogLevel.success:
        return '✅';
      case DebugLogLevel.audio:
        return '🔊';
    }
  }

  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${(timestamp.millisecond ~/ 10).toString().padLeft(2, '0')}';
  }
}

/// Debug console overlay widget with live status panel
class DebugConsoleOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DebugConsoleOverlay({
    Key? key,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<DebugConsoleOverlay> createState() => _DebugConsoleOverlayState();
}

class _DebugConsoleOverlayState extends State<DebugConsoleOverlay> {
  bool _isExpanded = false;
  bool _showLogs = false;  // Toggle between status and logs view
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    DebugConsole().addListener(_onLogUpdate);
    DebugStatus().addListener(_onStatusUpdate);
  }

  @override
  void dispose() {
    DebugConsole().removeListener(_onLogUpdate);
    DebugStatus().removeListener(_onStatusUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogUpdate() {
    // Defer setState to avoid calling during build phase
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
          if (_showLogs && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }
  }

  void _onStatusUpdate() {
    // Defer setState to avoid calling during build phase
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Widget _buildAudioBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 35,
          child: Text(label, style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace')),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 35,
          child: Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 8, fontFamily: 'monospace'),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPanel() {
    final status = DebugStatus();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual System Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            border: Border(left: BorderSide(color: Colors.purple, width: 2)),
          ),
          child: Row(
            children: [
              const Text('🎨 ', style: TextStyle(fontSize: 12)),
              Text(
                '${status.visualSystem.toUpperCase()} ',
                style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              Text(
                'Geom ${status.geometryIndex} ',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
              ),
              Text(
                'Morph: ${status.morphParameter.toStringAsFixed(1)} ',
                style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace'),
              ),
              Text(
                'Grid: ${status.gridDensity.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Audio Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status.audioPlaying ? Colors.cyan.withOpacity(0.15) : Colors.red.withOpacity(0.15),
            border: Border(left: BorderSide(color: status.audioPlaying ? Colors.cyan : Colors.red, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    status.audioPlaying ? '🔊 AUDIO ON' : '🔇 AUDIO OFF',
                    style: TextStyle(
                      color: status.audioPlaying ? Colors.cyan : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${status.sampleRate}Hz',
                    style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildAudioBar('BASS', status.bassEnergy, Colors.red),
              const SizedBox(height: 2),
              _buildAudioBar('MID', status.midEnergy, Colors.yellow),
              const SizedBox(height: 2),
              _buildAudioBar('HIGH', status.highEnergy, Colors.green),
              const SizedBox(height: 2),
              _buildAudioBar('RMS', status.rmsAmplitude, Colors.cyan),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Shader Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status.shaderLoaded ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
            border: Border(left: BorderSide(color: status.shaderLoaded ? Colors.green : Colors.orange, width: 2)),
          ),
          child: Row(
            children: [
              Text(
                status.shaderLoaded ? '✅ SHADER OK' : '⏳ SHADER...',
                style: TextStyle(
                  color: status.shaderLoaded ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FPS: ${status.fps.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 8),
              Text(
                't=${status.shaderTime.toStringAsFixed(1)}s',
                style: const TextStyle(color: Colors.white54, fontSize: 9, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        if (status.shaderError != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(4),
            color: Colors.red.withOpacity(0.3),
            child: Text(
              '❌ ${status.shaderError}',
              style: const TextStyle(color: Colors.red, fontSize: 9, fontFamily: 'monospace'),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,

        // Debug console (bottom of screen)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isExpanded ? 280 : 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.92),
                border: Border(
                  top: BorderSide(color: Colors.cyan.withOpacity(0.5), width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Header bar
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          _isExpanded ? Icons.expand_more : Icons.expand_less,
                          color: Colors.cyan,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (_isExpanded) {
                              setState(() => _showLogs = false);
                            } else {
                              setState(() => _isExpanded = true);
                            }
                          },
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              color: !_showLogs ? Colors.cyan : Colors.white54,
                              fontSize: 11,
                              fontWeight: !_showLogs ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (_isExpanded) {
                              setState(() => _showLogs = true);
                            } else {
                              setState(() {
                                _isExpanded = true;
                                _showLogs = true;
                              });
                            }
                          },
                          child: Text(
                            'LOGS (${DebugConsole().logs.length})',
                            style: TextStyle(
                              color: _showLogs ? Colors.cyan : Colors.white54,
                              fontSize: 11,
                              fontWeight: _showLogs ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_showLogs)
                          GestureDetector(
                            onTap: () => DebugConsole().clear(),
                            child: const Icon(Icons.delete_outline, color: Colors.white54, size: 18),
                          ),
                      ],
                    ),
                  ),

                  // Content area
                  if (_isExpanded)
                    Expanded(
                      child: _showLogs ? _buildLogList() : _buildStatusPanel(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: DebugConsole().logs.length,
      itemBuilder: (context, index) {
        final log = DebugConsole().logs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.timeString,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 4),
              Text(log.prefix, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  log.message,
                  style: TextStyle(color: log.color, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
