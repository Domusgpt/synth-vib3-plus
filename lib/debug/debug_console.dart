/**
 * Debug Console
 *
 * On-screen debug overlay for Android device testing.
 * Shows real-time logs without needing logcat.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';

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
}

enum DebugLogLevel {
  info,
  warning,
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

/// Debug console overlay widget
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    DebugConsole().addListener(_onLogUpdate);
  }

  @override
  void dispose() {
    DebugConsole().removeListener(_onLogUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogUpdate() {
    if (mounted) {
      setState(() {});
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
              height: _isExpanded ? 250 : 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                border: Border(
                  top: BorderSide(
                    color: Colors.cyan.withOpacity(0.5),
                    width: 1,
                  ),
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
                        const Text(
                          'DEBUG CONSOLE',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${DebugConsole().logs.length} logs',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            DebugConsole().clear();
                          },
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Log list
                  if (_isExpanded)
                    Expanded(
                      child: ListView.builder(
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
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  log.prefix,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: TextStyle(
                                      color: log.color,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
