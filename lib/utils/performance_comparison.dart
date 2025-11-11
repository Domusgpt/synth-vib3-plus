/**
 * Performance Comparison Utility
 *
 * Provides comprehensive performance comparison between audio engines,
 * tracking latency, CPU usage, memory, and audio quality metrics.
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../providers/audio_provider_enhanced.dart';
import 'logger.dart';

/// Performance test result for a single engine
class EnginePerformanceResult {
  final AudioEngineType engine;
  final double avgLatencyMs;
  final double minLatencyMs;
  final double maxLatencyMs;
  final int buffersGenerated;
  final double testDurationSeconds;
  final List<int> latencySamples;

  const EnginePerformanceResult({
    required this.engine,
    required this.avgLatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.buffersGenerated,
    required this.testDurationSeconds,
    required this.latencySamples,
  });

  /// Calculate standard deviation of latency
  double get latencyStdDev {
    if (latencySamples.isEmpty) return 0.0;

    final double mean = avgLatencyMs;
    final double sumSquaredDiff = latencySamples.fold<double>(
      0.0,
      (double sum, int sample) => sum + ((sample - mean) * (sample - mean)),
    );

    return (sumSquaredDiff / latencySamples.length).abs();
  }

  /// Latency quality score (0-100, higher is better)
  double get latencyScore {
    // Target: <8ms = 100, >20ms = 0
    if (avgLatencyMs <= 8.0) return 100.0;
    if (avgLatencyMs >= 20.0) return 0.0;
    return ((20.0 - avgLatencyMs) / 12.0) * 100.0;
  }

  /// Consistency score (0-100, higher is better)
  /// Based on standard deviation - lower deviation = more consistent
  double get consistencyScore {
    // Target: <2ms stddev = 100, >10ms = 0
    if (latencyStdDev <= 2.0) return 100.0;
    if (latencyStdDev >= 10.0) return 0.0;
    return ((10.0 - latencyStdDev) / 8.0) * 100.0;
  }

  /// Overall performance score (0-100)
  double get overallScore => (latencyScore * 0.7) + (consistencyScore * 0.3);

  Map<String, dynamic> toJson() => {
        'engine': engine.name,
        'avg_latency_ms': avgLatencyMs.toStringAsFixed(2),
        'min_latency_ms': minLatencyMs.toStringAsFixed(2),
        'max_latency_ms': maxLatencyMs.toStringAsFixed(2),
        'std_dev_ms': latencyStdDev.toStringAsFixed(2),
        'buffers_generated': buffersGenerated,
        'test_duration_s': testDurationSeconds.toStringAsFixed(1),
        'latency_score': latencyScore.toStringAsFixed(1),
        'consistency_score': consistencyScore.toStringAsFixed(1),
        'overall_score': overallScore.toStringAsFixed(1),
      };
}

/// Comprehensive engine comparison result
class EngineComparisonResult {
  final EnginePerformanceResult pcmResult;
  final EnginePerformanceResult soLoudResult;
  final DateTime timestamp;

  const EngineComparisonResult({
    required this.pcmResult,
    required this.soLoudResult,
    required this.timestamp,
  });

  /// Latency improvement (positive = SoLoud is faster)
  double get latencyImprovement =>
      pcmResult.avgLatencyMs - soLoudResult.avgLatencyMs;

  /// Latency improvement percentage
  double get latencyImprovementPercent =>
      (latencyImprovement / pcmResult.avgLatencyMs) * 100.0;

  /// Winner based on overall score
  AudioEngineType get winner => soLoudResult.overallScore >
          pcmResult.overallScore
      ? AudioEngineType.soLoud
      : AudioEngineType.pcmSound;

  /// Get recommendation
  String get recommendation {
    if (soLoudResult.overallScore > pcmResult.overallScore + 10.0) {
      return 'Strongly recommend SoLoud engine';
    } else if (soLoudResult.overallScore > pcmResult.overallScore) {
      return 'Recommend SoLoud engine';
    } else if (pcmResult.overallScore > soLoudResult.overallScore + 10.0) {
      return 'Keep PCM engine';
    } else {
      return 'Both engines perform similarly';
    }
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'pcm': pcmResult.toJson(),
        'soloud': soLoudResult.toJson(),
        'comparison': {
          'latency_improvement_ms': latencyImprovement.toStringAsFixed(2),
          'latency_improvement_percent':
              latencyImprovementPercent.toStringAsFixed(1),
          'winner': winner.name,
          'recommendation': recommendation,
        },
      };
}

/// Performance comparison manager
class PerformanceComparison {
  final AudioProviderEnhanced audioProvider;

  PerformanceComparison({required this.audioProvider});

  /// Run comprehensive performance test
  Future<EngineComparisonResult> runComparison({
    int durationSeconds = 10,
    int noteToPlay = 60, // Middle C
  }) async {
    Logger.info(
      'Starting engine performance comparison',
      category: LogCategory.performance,
      metadata: {'duration_seconds': durationSeconds},
    );

    // Test PCM engine
    final EnginePerformanceResult pcmResult = await _testEngine(
      AudioEngineType.pcmSound,
      durationSeconds: durationSeconds,
      noteToPlay: noteToPlay,
    );

    // Small delay between tests
    await Future<void>.delayed(const Duration(seconds: 2));

    // Test SoLoud engine
    final EnginePerformanceResult soLoudResult = await _testEngine(
      AudioEngineType.soLoud,
      durationSeconds: durationSeconds,
      noteToPlay: noteToPlay,
    );

    final EngineComparisonResult result = EngineComparisonResult(
      pcmResult: pcmResult,
      soLoudResult: soLoudResult,
      timestamp: DateTime.now(),
    );

    Logger.info(
      'Engine comparison complete',
      category: LogCategory.performance,
      metadata: {
        'pcm_latency': pcmResult.avgLatencyMs.toStringAsFixed(2),
        'soloud_latency': soLoudResult.avgLatencyMs.toStringAsFixed(2),
        'improvement': result.latencyImprovement.toStringAsFixed(2),
        'winner': result.winner.name,
      },
    );

    return result;
  }

  /// Test a single engine
  Future<EnginePerformanceResult> _testEngine(
    AudioEngineType engine, {
    required int durationSeconds,
    required int noteToPlay,
  }) async {
    Logger.debug(
      'Testing engine',
      category: LogCategory.performance,
      metadata: {
        'engine': engine.name,
        'duration': durationSeconds,
      },
    );

    // Switch to test engine
    await audioProvider.switchEngine(engine);

    final List<int> latencySamples = [];
    final Stopwatch testTimer = Stopwatch()..start();
    int buffersGenerated = 0;

    // Start playing note
    await audioProvider.playNote(noteToPlay);

    // Collect samples for duration
    while (testTimer.elapsedMilliseconds < durationSeconds * 1000) {
      final Stopwatch bufferTimer = Stopwatch()..start();

      // Wait for next buffer
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bufferTimer.stop();
      latencySamples.add(bufferTimer.elapsedMilliseconds);
      buffersGenerated++;
    }

    // Stop playing
    await audioProvider.stopNote();

    testTimer.stop();

    // Calculate statistics
    final double avgLatency = latencySamples.isEmpty
        ? 0.0
        : latencySamples.reduce((int a, int b) => a + b) /
            latencySamples.length;
    final double minLatency = latencySamples.isEmpty
        ? 0.0
        : latencySamples.reduce((int a, int b) => a < b ? a : b).toDouble();
    final double maxLatency = latencySamples.isEmpty
        ? 0.0
        : latencySamples.reduce((int a, int b) => a > b ? a : b).toDouble();

    return EnginePerformanceResult(
      engine: engine,
      avgLatencyMs: avgLatency,
      minLatencyMs: minLatency,
      maxLatencyMs: maxLatency,
      buffersGenerated: buffersGenerated,
      testDurationSeconds: testTimer.elapsedMilliseconds / 1000.0,
      latencySamples: latencySamples,
    );
  }

  /// Quick latency check (1 second test)
  Future<Map<String, double>> quickLatencyCheck() async {
    final EnginePerformanceResult pcm = await _testEngine(
      AudioEngineType.pcmSound,
      durationSeconds: 1,
      noteToPlay: 60,
    );

    final EnginePerformanceResult soloud = await _testEngine(
      AudioEngineType.soLoud,
      durationSeconds: 1,
      noteToPlay: 60,
    );

    return {
      'pcm_latency_ms': pcm.avgLatencyMs,
      'soloud_latency_ms': soloud.avgLatencyMs,
      'improvement_ms': pcm.avgLatencyMs - soloud.avgLatencyMs,
      'improvement_percent':
          ((pcm.avgLatencyMs - soloud.avgLatencyMs) / pcm.avgLatencyMs) * 100.0,
    };
  }

  /// Test all 72 combinations (geometry × visual system)
  Future<Map<String, dynamic>> testAll72Combinations({
    int samplesPerCombination = 5,
  }) async {
    Logger.info(
      'Starting 72-combination test',
      category: LogCategory.performance,
      metadata: {'samples_per_combination': samplesPerCombination},
    );

    final Map<String, List<double>> pcmLatencies = {};
    final Map<String, List<double>> soLoudLatencies = {};

    // Test each geometry (0-23)
    for (int geo = 0; geo < 24; geo++) {
      // Test each visual system
      for (final VisualSystem system in VisualSystem.values) {
        final String key = '${system.name}_geo$geo';

        // Set geometry and system
        audioProvider.setGeometry(geo);
        audioProvider.setVisualSystem(system.name);

        // Test PCM
        await audioProvider.switchEngine(AudioEngineType.pcmSound);
        final List<double> pcmSamples = await _sampleLatency(
          samplesPerCombination,
        );
        pcmLatencies[key] = pcmSamples;

        // Test SoLoud
        await audioProvider.switchEngine(AudioEngineType.soLoud);
        final List<double> soLoudSamples = await _sampleLatency(
          samplesPerCombination,
        );
        soLoudLatencies[key] = soLoudSamples;

        if (kDebugMode && geo % 4 == 0) {
          Logger.debug(
            'Tested combination',
            category: LogCategory.performance,
            metadata: {
              'key': key,
              'pcm_avg':
                  (pcmSamples.reduce((double a, double b) => a + b) /
                          pcmSamples.length)
                      .toStringAsFixed(2),
              'soloud_avg':
                  (soLoudSamples.reduce((double a, double b) => a + b) /
                          soLoudSamples.length)
                      .toStringAsFixed(2),
            },
          );
        }
      }
    }

    // Calculate overall statistics
    final double pcmOverallAvg = _calculateOverallAverage(pcmLatencies);
    final double soLoudOverallAvg = _calculateOverallAverage(soLoudLatencies);

    Logger.info(
      '72-combination test complete',
      category: LogCategory.performance,
      metadata: {
        'pcm_avg': pcmOverallAvg.toStringAsFixed(2),
        'soloud_avg': soLoudOverallAvg.toStringAsFixed(2),
        'improvement': (pcmOverallAvg - soLoudOverallAvg).toStringAsFixed(2),
      },
    );

    return {
      'pcm_latencies': pcmLatencies,
      'soloud_latencies': soLoudLatencies,
      'pcm_overall_avg': pcmOverallAvg,
      'soloud_overall_avg': soLoudOverallAvg,
      'improvement_ms': pcmOverallAvg - soLoudOverallAvg,
      'improvement_percent':
          ((pcmOverallAvg - soLoudOverallAvg) / pcmOverallAvg) * 100.0,
    };
  }

  /// Sample latency for current configuration
  Future<List<double>> _sampleLatency(int samples) async {
    final List<double> latencies = [];

    for (int i = 0; i < samples; i++) {
      final Stopwatch timer = Stopwatch()..start();
      await audioProvider.playNote(60);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await audioProvider.stopNote();
      timer.stop();

      latencies.add(timer.elapsedMilliseconds.toDouble());
    }

    return latencies;
  }

  /// Calculate overall average from latency map
  double _calculateOverallAverage(Map<String, List<double>> latencies) {
    if (latencies.isEmpty) return 0.0;

    double sum = 0.0;
    int count = 0;

    for (final List<double> samples in latencies.values) {
      for (final double sample in samples) {
        sum += sample;
        count++;
      }
    }

    return count > 0 ? sum / count : 0.0;
  }
}
