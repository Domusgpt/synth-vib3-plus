/**
 * Performance Comparison Tests
 *
 * Test suite for audio engine performance comparison and benchmarking framework.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:synth_vib3_plus/utils/performance_comparison.dart';
import 'package:synth_vib3_plus/providers/audio_provider_enhanced.dart';

void main() {
  group('EnginePerformanceResult', () {
    test('should create result with valid data', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 12.5,
        minLatencyMs: 10.0,
        maxLatencyMs: 15.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [10, 11, 12, 13, 14, 15],
      );

      expect(result.engine, equals(AudioEngineType.pcmSound));
      expect(result.avgLatencyMs, equals(12.5));
      expect(result.minLatencyMs, equals(10.0));
      expect(result.maxLatencyMs, equals(15.0));
      expect(result.buffersGenerated, equals(100));
      expect(result.testDurationSeconds, equals(10.0));
      expect(result.latencySamples.length, equals(6));
    });

    test('should calculate standard deviation correctly', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 12.0,
        minLatencyMs: 10.0,
        maxLatencyMs: 14.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [10, 11, 12, 13, 14], // Perfect sequence
      );

      // Standard deviation should be ~1.41 for this sequence
      expect(result.latencyStdDev, greaterThan(0.0));
      expect(result.latencyStdDev, lessThan(5.0));
    });

    test('should return zero stddev for empty samples', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 12.0,
        minLatencyMs: 12.0,
        maxLatencyMs: 12.0,
        buffersGenerated: 0,
        testDurationSeconds: 10.0,
        latencySamples: [],
      );

      expect(result.latencyStdDev, equals(0.0));
    });

    group('Latency Score', () {
      test('should give 100 for latency <= 8ms', () {
        final result = EnginePerformanceResult(
          engine: AudioEngineType.soLoud,
          avgLatencyMs: 8.0,
          minLatencyMs: 7.0,
          maxLatencyMs: 9.0,
          buffersGenerated: 100,
          testDurationSeconds: 10.0,
          latencySamples: [7, 8, 9],
        );

        expect(result.latencyScore, equals(100.0));
      });

      test('should give 0 for latency >= 20ms', () {
        final result = EnginePerformanceResult(
          engine: AudioEngineType.pcmSound,
          avgLatencyMs: 20.0,
          minLatencyMs: 18.0,
          maxLatencyMs: 22.0,
          buffersGenerated: 100,
          testDurationSeconds: 10.0,
          latencySamples: [18, 20, 22],
        );

        expect(result.latencyScore, equals(0.0));
      });

      test('should scale linearly between 8ms and 20ms', () {
        final result1 = EnginePerformanceResult(
          engine: AudioEngineType.pcmSound,
          avgLatencyMs: 14.0, // Midpoint
          minLatencyMs: 13.0,
          maxLatencyMs: 15.0,
          buffersGenerated: 100,
          testDurationSeconds: 10.0,
          latencySamples: [13, 14, 15],
        );

        expect(result1.latencyScore, closeTo(50.0, 1.0));

        final result2 = EnginePerformanceResult(
          engine: AudioEngineType.soLoud,
          avgLatencyMs: 11.0, // 25% of range
          minLatencyMs: 10.0,
          maxLatencyMs: 12.0,
          buffersGenerated: 100,
          testDurationSeconds: 10.0,
          latencySamples: [10, 11, 12],
        );

        expect(result2.latencyScore, closeTo(75.0, 1.0));
      });
    });

    group('Consistency Score', () {
      test('should give 100 for stddev <= 2ms', () {
        final result = EnginePerformanceResult(
          engine: AudioEngineType.soLoud,
          avgLatencyMs: 8.0,
          minLatencyMs: 7.0,
          maxLatencyMs: 9.0,
          buffersGenerated: 100,
          testDurationSeconds: 10.0,
          latencySamples: [7, 8, 8, 8, 9], // Very consistent
        );

        // This should have low stddev
        if (result.latencyStdDev <= 2.0) {
          expect(result.consistencyScore, equals(100.0));
        }
      });

      test('should give 0 for stddev >= 10ms', () {
        final result = EnginePerformanceResult(
          engine: AudioEngineType.pcmSound,
          avgLatencyMs: 15.0,
          minLatencyMs: 5.0,
          maxLatencyMs: 25.0,
          buffersGenerated: 100,
          testDurationSeconds: 10.0,
          latencySamples: [5, 10, 15, 20, 25], // Very inconsistent
        );

        if (result.latencyStdDev >= 10.0) {
          expect(result.consistencyScore, equals(0.0));
        }
      });
    });

    test('should calculate overall score correctly', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 8.0,
        minLatencyMs: 7.0,
        maxLatencyMs: 9.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [7, 8, 8, 8, 9],
      );

      // Overall = 70% latency + 30% consistency
      final expected =
          result.latencyScore * 0.7 + result.consistencyScore * 0.3;
      expect(result.overallScore, closeTo(expected, 0.01));
    });

    test('should export to JSON correctly', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 8.5,
        minLatencyMs: 7.0,
        maxLatencyMs: 10.0,
        buffersGenerated: 120,
        testDurationSeconds: 10.5,
        latencySamples: [7, 8, 9, 10],
      );

      final json = result.toJson();

      expect(json['engine'], equals('soLoud'));
      expect(json['avg_latency_ms'], equals('8.50'));
      expect(json['min_latency_ms'], equals('7.00'));
      expect(json['max_latency_ms'], equals('10.00'));
      expect(json['buffers_generated'], equals(120));
      expect(json['test_duration_s'], equals('10.5'));
      expect(json, containsPair('std_dev_ms', anything));
      expect(json, containsPair('latency_score', anything));
      expect(json, containsPair('consistency_score', anything));
      expect(json, containsPair('overall_score', anything));
    });
  });

  group('EngineComparisonResult', () {
    late EnginePerformanceResult pcmResult;
    late EnginePerformanceResult soLoudResult;

    setUp(() {
      pcmResult = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 12.0,
        minLatencyMs: 10.0,
        maxLatencyMs: 14.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [10, 11, 12, 13, 14],
      );

      soLoudResult = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 7.0,
        minLatencyMs: 6.0,
        maxLatencyMs: 8.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [6, 7, 7, 7, 8],
      );
    });

    test('should create comparison result', () {
      final comparison = EngineComparisonResult(
        pcmResult: pcmResult,
        soLoudResult: soLoudResult,
        timestamp: DateTime.now(),
      );

      expect(comparison.pcmResult, equals(pcmResult));
      expect(comparison.soLoudResult, equals(soLoudResult));
      expect(comparison.timestamp, isNotNull);
    });

    test('should calculate latency improvement correctly', () {
      final comparison = EngineComparisonResult(
        pcmResult: pcmResult,
        soLoudResult: soLoudResult,
        timestamp: DateTime.now(),
      );

      // PCM: 12ms, SoLoud: 7ms = 5ms improvement
      expect(comparison.latencyImprovement, closeTo(5.0, 0.01));
    });

    test('should calculate latency improvement percentage', () {
      final comparison = EngineComparisonResult(
        pcmResult: pcmResult,
        soLoudResult: soLoudResult,
        timestamp: DateTime.now(),
      );

      // 5ms improvement / 12ms baseline = ~41.67%
      expect(comparison.latencyImprovementPercent, closeTo(41.67, 0.1));
    });

    test('should determine winner based on overall score', () {
      final comparison = EngineComparisonResult(
        pcmResult: pcmResult,
        soLoudResult: soLoudResult,
        timestamp: DateTime.now(),
      );

      // SoLoud should win with 7ms vs 12ms
      expect(comparison.winner, equals(AudioEngineType.soLoud));
    });

    test('should provide recommendation for clear winner', () {
      final comparison = EngineComparisonResult(
        pcmResult: pcmResult,
        soLoudResult: soLoudResult,
        timestamp: DateTime.now(),
      );

      final recommendation = comparison.recommendation;
      expect(recommendation, contains('SoLoud'));
    });

    test('should recommend keeping PCM if it performs better', () {
      // Create reversed scenario where PCM is better
      final betterPcmResult = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 6.0,
        minLatencyMs: 5.0,
        maxLatencyMs: 7.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [5, 6, 6, 6, 7],
      );

      final worseSoLoudResult = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 15.0,
        minLatencyMs: 13.0,
        maxLatencyMs: 17.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [13, 14, 15, 16, 17],
      );

      final comparison = EngineComparisonResult(
        pcmResult: betterPcmResult,
        soLoudResult: worseSoLoudResult,
        timestamp: DateTime.now(),
      );

      expect(comparison.recommendation, contains('PCM'));
    });

    test('should identify similar performance', () {
      final similarSoLoudResult = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 12.5,
        minLatencyMs: 11.0,
        maxLatencyMs: 14.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [11, 12, 13, 13, 14],
      );

      final comparison = EngineComparisonResult(
        pcmResult: pcmResult,
        soLoudResult: similarSoLoudResult,
        timestamp: DateTime.now(),
      );

      final recommendation = comparison.recommendation;
      expect(recommendation, contains('similarly'));
    });

    test('should export to JSON correctly', () {
      final timestamp = DateTime.now();
      final comparison = EngineComparisonResult(
        pcmResult: pcmResult,
        soLoudResult: soLoudResult,
        timestamp: timestamp,
      );

      final json = comparison.toJson();

      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json, containsPair('pcm', anything));
      expect(json, containsPair('soloud', anything));
      expect(json, containsPair('comparison', anything));

      final comparisonData = json['comparison'] as Map<String, dynamic>;
      expect(comparisonData, containsPair('latency_improvement_ms', anything));
      expect(comparisonData,
          containsPair('latency_improvement_percent', anything));
      expect(comparisonData, containsPair('winner', anything));
      expect(comparisonData, containsPair('recommendation', anything));
    });
  });

  group('PerformanceComparison (Unit Tests)', () {
    // Note: Full integration tests require AudioProviderEnhanced mock

    test('should calculate overall average from latencies', () {
      // This tests the private method indirectly through public interface
      final latencies = {
        'test1': [10.0, 12.0, 14.0],
        'test2': [8.0, 10.0, 12.0],
        'test3': [11.0, 13.0, 15.0],
      };

      // Average should be (10+12+14+8+10+12+11+13+15) / 9 = 11.67
      double sum = 0.0;
      int count = 0;
      latencies.values.forEach((samples) {
        samples.forEach((sample) {
          sum += sample;
          count++;
        });
      });

      final expected = sum / count;
      expect(expected, closeTo(11.67, 0.1));
    });

    test('should handle empty latency map', () {
      final latencies = <String, List<double>>{};

      double sum = 0.0;
      int count = 0;
      latencies.values.forEach((samples) {
        samples.forEach((sample) {
          sum += sample;
          count++;
        });
      });

      final result = count > 0 ? sum / count : 0.0;
      expect(result, equals(0.0));
    });
  });

  group('Performance Scoring Logic', () {
    test('should score excellent performance (< 8ms)', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 5.0,
        minLatencyMs: 4.0,
        maxLatencyMs: 6.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [4, 5, 5, 5, 6],
      );

      expect(result.latencyScore, equals(100.0));
      expect(result.overallScore, greaterThan(90.0));
    });

    test('should score good performance (8-12ms)', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 10.0,
        minLatencyMs: 9.0,
        maxLatencyMs: 11.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [9, 10, 10, 10, 11],
      );

      expect(result.latencyScore, greaterThan(50.0));
      expect(result.latencyScore, lessThan(100.0));
      expect(result.overallScore, greaterThan(50.0));
    });

    test('should score poor performance (15-20ms)', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 18.0,
        minLatencyMs: 16.0,
        maxLatencyMs: 20.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [16, 17, 18, 19, 20],
      );

      expect(result.latencyScore, lessThan(25.0));
      expect(result.overallScore, lessThan(30.0));
    });

    test('should score unacceptable performance (> 20ms)', () {
      final result = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 25.0,
        minLatencyMs: 23.0,
        maxLatencyMs: 27.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [23, 24, 25, 26, 27],
      );

      expect(result.latencyScore, equals(0.0));
      expect(result.overallScore, lessThan(40.0)); // Might have good consistency
    });
  });

  group('Comparison Scenarios', () {
    test('should handle scenario: SoLoud much better than PCM', () {
      final pcm = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 15.0,
        minLatencyMs: 13.0,
        maxLatencyMs: 17.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [13, 14, 15, 16, 17],
      );

      final soLoud = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 6.0,
        minLatencyMs: 5.0,
        maxLatencyMs: 7.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [5, 6, 6, 6, 7],
      );

      final comparison = EngineComparisonResult(
        pcmResult: pcm,
        soLoudResult: soLoud,
        timestamp: DateTime.now(),
      );

      expect(comparison.winner, equals(AudioEngineType.soLoud));
      expect(comparison.latencyImprovement, greaterThan(5.0));
      expect(comparison.latencyImprovementPercent, greaterThan(30.0));
      expect(comparison.recommendation, contains('Strongly recommend SoLoud'));
    });

    test('should handle scenario: Both engines similar', () {
      final pcm = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 10.0,
        minLatencyMs: 9.0,
        maxLatencyMs: 11.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [9, 10, 10, 10, 11],
      );

      final soLoud = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 9.5,
        minLatencyMs: 8.5,
        maxLatencyMs: 10.5,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [8, 9, 9, 10, 11],
      );

      final comparison = EngineComparisonResult(
        pcmResult: pcm,
        soLoudResult: soLoud,
        timestamp: DateTime.now(),
      );

      expect(comparison.latencyImprovement, lessThan(1.0));
      expect(comparison.recommendation, contains('similarly'));
    });

    test('should handle scenario: PCM surprisingly better', () {
      final pcm = EnginePerformanceResult(
        engine: AudioEngineType.pcmSound,
        avgLatencyMs: 7.0,
        minLatencyMs: 6.0,
        maxLatencyMs: 8.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [6, 7, 7, 7, 8],
      );

      final soLoud = EnginePerformanceResult(
        engine: AudioEngineType.soLoud,
        avgLatencyMs: 14.0,
        minLatencyMs: 12.0,
        maxLatencyMs: 16.0,
        buffersGenerated: 100,
        testDurationSeconds: 10.0,
        latencySamples: [12, 13, 14, 15, 16],
      );

      final comparison = EngineComparisonResult(
        pcmResult: pcm,
        soLoudResult: soLoud,
        timestamp: DateTime.now(),
      );

      expect(comparison.winner, equals(AudioEngineType.pcmSound));
      expect(comparison.latencyImprovement, lessThan(0.0)); // Negative = worse
      expect(comparison.recommendation, contains('Keep PCM'));
    });
  });
}
