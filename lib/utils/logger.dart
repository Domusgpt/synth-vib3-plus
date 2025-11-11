/**
 * Synth-VIB3+ Logger
 *
 * Centralized logging utility with performance tracking, categorization,
 * and production-safe output. Designed for real-time audio applications
 * with minimal overhead.
 *
 * Features:
 * - Multiple log levels (debug, info, warning, error)
 * - Category-based filtering
 * - Performance timing utilities
 * - Production-safe (logs only in debug mode by default)
 * - Audio-specific performance metrics
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/foundation.dart';

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Log categories for filtering
enum LogCategory {
  audio,
  visual,
  mapping,
  ui,
  synthesis,
  performance,
  network,
  general,
}

/// Performance timer for measuring execution time
class PerformanceTimer {
  final String label;
  final DateTime _startTime;
  final LogCategory category;

  PerformanceTimer(
    this.label, {
    this.category = LogCategory.performance,
  }) : _startTime = DateTime.now();

  /// Stop the timer and log the elapsed time
  void stop() {
    final Duration elapsed = DateTime.now().difference(_startTime);
    Logger.performance(
      label,
      category: category,
      metadata: {'elapsed_ms': elapsed.inMilliseconds},
    );
  }

  /// Get elapsed time without stopping the timer
  Duration get elapsed => DateTime.now().difference(_startTime);
}

/// Main logger class
class Logger {
  static bool _isInitialized = false;
  static LogLevel _minLevel = LogLevel.debug;
  static Set<LogCategory> _enabledCategories = LogCategory.values.toSet();
  static bool _logTimestamps = true;
  static bool _logToConsole = true;
  static final List<String> _logBuffer = [];
  static const int _maxBufferSize = 1000;

  // Performance tracking
  static final Map<String, int> _performanceCounters = {};
  static final Map<String, int> _performanceTotals = {};

  /// Initialize the logger with configuration
  static void init({
    LogLevel minLevel = LogLevel.debug,
    Set<LogCategory>? enabledCategories,
    bool logTimestamps = true,
    bool logToConsole = true,
  }) {
    _isInitialized = true;
    _minLevel = minLevel;
    _enabledCategories = enabledCategories ?? LogCategory.values.toSet();
    _logTimestamps = logTimestamps;
    _logToConsole = logToConsole;

    info('Logger initialized', category: LogCategory.general);
  }

  /// Log a debug message
  static void debug(
    String message, {
    LogCategory category = LogCategory.general,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.debug, message, category, metadata);
  }

  /// Log an info message
  static void info(
    String message, {
    LogCategory category = LogCategory.general,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.info, message, category, metadata);
  }

  /// Log a warning
  static void warning(
    String message, {
    LogCategory category = LogCategory.general,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.warning, message, category, metadata);
  }

  /// Log an error
  static void error(
    String message, {
    LogCategory category = LogCategory.general,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final Map<String, dynamic> fullMetadata = metadata ?? {};
    if (error != null) {
      fullMetadata['error'] = error.toString();
    }
    if (stackTrace != null) {
      fullMetadata['stack_trace'] = stackTrace.toString();
    }
    _log(LogLevel.error, message, category, fullMetadata);
  }

  /// Log a performance metric
  static void performance(
    String operation, {
    LogCategory category = LogCategory.performance,
    Map<String, dynamic>? metadata,
  }) {
    final Map<String, dynamic> fullMetadata = metadata ?? {};

    // Track performance counter
    _performanceCounters[operation] =
        (_performanceCounters[operation] ?? 0) + 1;

    // Track total time if elapsed_ms is provided
    if (fullMetadata.containsKey('elapsed_ms')) {
      final int elapsedMs = fullMetadata['elapsed_ms'] as int;
      _performanceTotals[operation] =
          (_performanceTotals[operation] ?? 0) + elapsedMs;
      fullMetadata['avg_ms'] =
          (_performanceTotals[operation]! / _performanceCounters[operation]!)
              .toStringAsFixed(2);
    }

    fullMetadata['count'] = _performanceCounters[operation];

    _log(LogLevel.info, '⚡ $operation', category, fullMetadata);
  }

  /// Start a performance timer
  static PerformanceTimer startTimer(
    String label, {
    LogCategory category = LogCategory.performance,
  }) =>
      PerformanceTimer(label, category: category);

  /// Audio-specific performance logging
  static void audioLatency(
    String operation,
    int latencyMs, {
    Map<String, dynamic>? metadata,
  }) {
    final Map<String, dynamic> fullMetadata = metadata ?? {};
    fullMetadata['latency_ms'] = latencyMs;

    // Warning if latency exceeds target
    if (latencyMs > 10) {
      warning(
        '🎵 Audio latency high: $operation',
        category: LogCategory.audio,
        metadata: fullMetadata,
      );
    } else {
      debug(
        '🎵 Audio latency: $operation',
        category: LogCategory.audio,
        metadata: fullMetadata,
      );
    }
  }

  /// Frame rate logging
  static void frameRate(
    double fps, {
    Map<String, dynamic>? metadata,
  }) {
    final Map<String, dynamic> fullMetadata = metadata ?? {};
    fullMetadata['fps'] = fps.toStringAsFixed(1);

    // Warning if FPS drops below 60
    if (fps < 60.0) {
      warning(
        '🎬 Frame rate below target',
        category: LogCategory.performance,
        metadata: fullMetadata,
      );
    } else {
      debug(
        '🎬 Frame rate',
        category: LogCategory.performance,
        metadata: fullMetadata,
      );
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() => {
        'counters': Map<String, int>.from(_performanceCounters),
        'totals': Map<String, int>.from(_performanceTotals),
        'averages': _performanceCounters.map(
          (String key, int value) => MapEntry(
            key,
            (_performanceTotals[key] ?? 0) / value,
          ),
        ),
      };

  /// Reset performance statistics
  static void resetPerformanceStats() {
    _performanceCounters.clear();
    _performanceTotals.clear();
  }

  /// Get log buffer
  static List<String> getLogBuffer() => List<String>.from(_logBuffer);

  /// Clear log buffer
  static void clearLogBuffer() {
    _logBuffer.clear();
  }

  /// Core logging function
  static void _log(
    LogLevel level,
    String message,
    LogCategory category,
    Map<String, dynamic>? metadata,
  ) {
    // Skip if not initialized and in production mode
    if (!_isInitialized && kReleaseMode) return;

    // Check if level is enabled
    if (level.index < _minLevel.index) return;

    // Check if category is enabled
    if (!_enabledCategories.contains(category)) return;

    // Build log message
    final StringBuffer buffer = StringBuffer();

    // Timestamp
    if (_logTimestamps) {
      buffer.write('[${DateTime.now().toIso8601String()}] ');
    }

    // Level emoji
    buffer.write(_getLevelEmoji(level));
    buffer.write(' ');

    // Category
    buffer.write('[${category.name.toUpperCase()}] ');

    // Message
    buffer.write(message);

    // Metadata
    if (metadata != null && metadata.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(
        metadata.entries
            .map((MapEntry<String, dynamic> e) => '${e.key}=${e.value}')
            .join(', '),
      );
    }

    final String logLine = buffer.toString();

    // Add to buffer
    _logBuffer.add(logLine);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }

    // Output to console
    if (_logToConsole) {
      if (level == LogLevel.error) {
        debugPrint('❌ $logLine');
      } else if (level == LogLevel.warning) {
        debugPrint('⚠️  $logLine');
      } else {
        debugPrint(logLine);
      }
    }
  }

  /// Get emoji for log level
  static String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// Enable/disable category
  static void setCategory(LogCategory category, {required bool enabled}) {
    if (enabled) {
      _enabledCategories.add(category);
    } else {
      _enabledCategories.remove(category);
    }
  }

  /// Set minimum log level
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }
}
