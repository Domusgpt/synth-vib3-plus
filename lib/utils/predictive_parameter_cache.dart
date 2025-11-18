/**
 * Predictive Parameter Cache
 *
 * Inspired by vib34d-xr-quaternion-sdk's PredictiveRotorCache pattern.
 * Uses simple linear prediction to forecast parameter values for smoother
 * audio-visual coupling during frame gaps.
 *
 * Key Features:
 * - Linear velocity-based prediction
 * - Reduces parameter jitter
 * - Smooths audio-visual coupling
 * - Confidence-based blending
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class PredictedParameter {
  final double value;
  final double confidence; // 0-1, how confident we are in prediction
  final DateTime timestamp;

  PredictedParameter({
    required this.value,
    required this.confidence,
    required this.timestamp,
  });
}

class PredictiveParameterCache {
  // Parameter history (last N values for velocity calculation)
  final Map<String, List<_ParameterSnapshot>> _history = {};

  // Prediction settings
  static const int _historySize = 3;
  static const double _minConfidence = 0.3;
  static const double _maxPredictionMs = 50.0; // Max 50ms ahead

  // Statistics
  int _predictionsGenerated = 0;
  int _predictionHits = 0; // How often predictions were close
  DateTime _lastStatsReset = DateTime.now();

  /// Record a parameter value
  void record(String paramName, double value) {
    final snapshot = _ParameterSnapshot(
      value: value,
      timestamp: DateTime.now(),
    );

    if (!_history.containsKey(paramName)) {
      _history[paramName] = [];
    }

    _history[paramName]!.add(snapshot);

    // Keep only recent history
    if (_history[paramName]!.length > _historySize) {
      _history[paramName]!.removeAt(0);
    }
  }

  /// Predict parameter value at future timestamp
  PredictedParameter? predict(String paramName, {Duration? ahead}) {
    final history = _history[paramName];
    if (history == null || history.length < 2) {
      // Not enough history for prediction
      return null;
    }

    final now = DateTime.now();
    final targetTime = ahead != null
        ? now.add(ahead)
        : now.add(const Duration(milliseconds: 16)); // Default: next frame

    // Calculate velocity from recent history
    final velocity = _calculateVelocity(history);

    // Calculate time delta
    final lastSnapshot = history.last;
    final deltaMs = targetTime.difference(lastSnapshot.timestamp).inMilliseconds;

    // Don't predict too far ahead
    if (deltaMs > _maxPredictionMs) {
      return null;
    }

    // Linear prediction: value + velocity * time
    final predictedValue = lastSnapshot.value + (velocity * deltaMs / 1000.0);

    // Calculate confidence based on history consistency
    final confidence = _calculateConfidence(history, velocity);

    _predictionsGenerated++;

    return PredictedParameter(
      value: predictedValue,
      confidence: confidence,
      timestamp: targetTime,
    );
  }

  /// Calculate velocity from parameter history
  double _calculateVelocity(List<_ParameterSnapshot> history) {
    if (history.length < 2) return 0.0;

    // Use last two points for velocity
    final p1 = history[history.length - 2];
    final p2 = history[history.length - 1];

    final deltaValue = p2.value - p1.value;
    final deltaTimeMs = p2.timestamp.difference(p1.timestamp).inMilliseconds;

    if (deltaTimeMs == 0) return 0.0;

    // Return velocity in units per second
    return (deltaValue / deltaTimeMs) * 1000.0;
  }

  /// Calculate confidence in prediction based on history consistency
  double _calculateConfidence(
    List<_ParameterSnapshot> history,
    double predictedVelocity,
  ) {
    if (history.length < 3) {
      return _minConfidence;
    }

    // Calculate velocity variance (how consistent is the motion?)
    final velocities = <double>[];
    for (int i = 1; i < history.length; i++) {
      final p1 = history[i - 1];
      final p2 = history[i];
      final deltaValue = p2.value - p1.value;
      final deltaTimeMs = p2.timestamp.difference(p1.timestamp).inMilliseconds;
      if (deltaTimeMs > 0) {
        velocities.add((deltaValue / deltaTimeMs) * 1000.0);
      }
    }

    if (velocities.isEmpty) return _minConfidence;

    // Calculate standard deviation of velocities
    final mean = velocities.reduce((a, b) => a + b) / velocities.length;
    final variance = velocities
        .map((v) => math.pow(v - mean, 2))
        .reduce((a, b) => a + b) / velocities.length;
    final stdDev = math.sqrt(variance);

    // Low variance = high confidence
    // Map std dev to confidence (0-1)
    // If stdDev is 0 (perfect consistency), confidence is 1.0
    // If stdDev is high, confidence approaches minConfidence
    final confidence = 1.0 / (1.0 + stdDev);

    return confidence.clamp(_minConfidence, 1.0);
  }

  /// Get or predict parameter value
  double? getOrPredict(String paramName, {Duration? ahead}) {
    final history = _history[paramName];
    if (history == null || history.isEmpty) {
      return null;
    }

    // If we have very recent value, use it
    final lastSnapshot = history.last;
    final age = DateTime.now().difference(lastSnapshot.timestamp);
    if (age.inMilliseconds < 5) {
      return lastSnapshot.value;
    }

    // Otherwise, try to predict
    final prediction = predict(paramName, ahead: ahead);
    if (prediction != null && prediction.confidence >= _minConfidence) {
      return prediction.value;
    }

    // Fall back to last known value
    return lastSnapshot.value;
  }

  /// Verify prediction accuracy (call this when actual value arrives)
  void verifyPrediction(String paramName, double actualValue) {
    // Check if our last prediction was close
    final history = _history[paramName];
    if (history != null && history.length >= 2) {
      final predicted = history[history.length - 1].value;
      final error = (actualValue - predicted).abs();

      // Consider it a hit if error is less than 5% of value range
      // Assuming typical parameter ranges 0-1 or 0-360
      if (error < 0.05 || error < 18.0) {
        _predictionHits++;
      }
    }
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    final accuracy = _predictionsGenerated > 0
        ? (_predictionHits / _predictionsGenerated * 100).toStringAsFixed(1)
        : '0';

    return {
      'predictionsGenerated': _predictionsGenerated,
      'predictionHits': _predictionHits,
      'accuracyPercentage': accuracy,
      'parametersCached': _history.length,
      'elapsedSeconds': DateTime.now().difference(_lastStatsReset).inSeconds,
    };
  }

  /// Reset statistics
  void resetStats() {
    _predictionsGenerated = 0;
    _predictionHits = 0;
    _lastStatsReset = DateTime.now();
  }

  /// Clear all history
  void clearHistory() {
    _history.clear();
  }

  /// Clear history for specific parameter
  void clearParameter(String paramName) {
    _history.remove(paramName);
  }
}

/// Internal parameter snapshot
class _ParameterSnapshot {
  final double value;
  final DateTime timestamp;

  _ParameterSnapshot({
    required this.value,
    required this.timestamp,
  });
}
