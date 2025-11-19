/**
 * System Health Monitor
 *
 * Aggregates health status from all system components:
 * - Audio output health
 * - Visual WebView communication health
 * - Parameter bridge health
 * - Overall system performance
 *
 * Provides comprehensive diagnostics for debugging and monitoring.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/foundation.dart';
import '../providers/audio_provider.dart';
import '../providers/visual_provider.dart';
import '../mapping/parameter_bridge.dart';

class SystemHealthMonitor {
  final AudioProvider audioProvider;
  final VisualProvider visualProvider;
  final ParameterBridge parameterBridge;

  SystemHealthMonitor({
    required this.audioProvider,
    required this.visualProvider,
    required this.parameterBridge,
  });

  /// Get comprehensive system health status
  Map<String, dynamic> getSystemHealth() {
    final audioHealth = audioProvider.getAudioOutputHealth();
    final visualHealth = visualProvider.getWebViewHealth();
    final bridgeHealth = parameterBridge.getErrorStats();

    final overallHealthy = audioHealth['isHealthy'] as bool &&
                           visualHealth['isHealthy'] as bool &&
                           bridgeHealth['isHealthy'] as bool;

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'overallHealthy': overallHealthy,
      'audio': audioHealth,
      'visual': visualHealth,
      'parameterBridge': bridgeHealth,
      'performance': {
        'bridgeFPS': parameterBridge.currentFPS.toStringAsFixed(1),
        'visualFPS': visualProvider.currentFPS.toStringAsFixed(1),
        'audioPlaying': audioProvider.isPlaying,
        'voiceCount': audioProvider.voiceCount,
      },
    };
  }

  /// Print human-readable system health report
  void printHealthReport() {
    final health = getSystemHealth();
    final overall = health['overallHealthy'] as bool;

    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🏥 SYSTEM HEALTH REPORT');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('Timestamp: ${health['timestamp']}');
    debugPrint('Overall Status: ${overall ? "✅ HEALTHY" : "❌ ISSUES DETECTED"}');
    debugPrint('');

    // Audio health
    final audio = health['audio'] as Map<String, dynamic>;
    debugPrint('🔊 AUDIO SYSTEM:');
    debugPrint('  Status: ${audio['isHealthy'] ? "✅ Healthy" : "❌ Unhealthy"}');
    debugPrint('  PCM Initialized: ${audio['pcmInitialized']}');
    debugPrint('  Total Errors: ${audio['totalOutputErrors']}');
    debugPrint('  Consecutive Errors: ${audio['consecutiveErrors']}');
    debugPrint('  Output Failed: ${audio['audioOutputFailed']}');
    debugPrint('');

    // Visual health
    final visual = health['visual'] as Map<String, dynamic>;
    debugPrint('🎨 VISUAL SYSTEM:');
    debugPrint('  Status: ${visual['isHealthy'] ? "✅ Healthy" : "❌ Unhealthy"}');
    debugPrint('  WebView Initialized: ${visual['webViewInitialized']}');
    debugPrint('  Total JS Errors: ${visual['totalJSErrors']}');
    debugPrint('  Consecutive Errors: ${visual['consecutiveErrors']}');
    debugPrint('  Communication Failed: ${visual['communicationFailed']}');
    if (visual['lastErrorTime'] != null) {
      debugPrint('  Last Error: ${visual['lastErrorTime']}');
    }
    debugPrint('');

    // Parameter bridge health
    final bridge = health['parameterBridge'] as Map<String, dynamic>;
    debugPrint('🔄 PARAMETER BRIDGE:');
    debugPrint('  Status: ${bridge['isHealthy'] ? "✅ Healthy" : "❌ Unhealthy"}');
    debugPrint('  Total Errors: ${bridge['totalErrors']}');
    debugPrint('  Consecutive Errors: ${bridge['consecutiveErrors']}');
    if (bridge['lastErrorTime'] != null) {
      debugPrint('  Last Error: ${bridge['lastErrorTime']}');
      debugPrint('  Error Message: ${bridge['lastErrorMessage']}');
    }
    debugPrint('');

    // Performance metrics
    final perf = health['performance'] as Map<String, dynamic>;
    debugPrint('📊 PERFORMANCE:');
    debugPrint('  Bridge FPS: ${perf['bridgeFPS']}');
    debugPrint('  Visual FPS: ${perf['visualFPS']}');
    debugPrint('  Audio Playing: ${perf['audioPlaying']}');
    debugPrint('  Voice Count: ${perf['voiceCount']}');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// Get quick status emoji for UI display
  String getStatusEmoji() {
    final health = getSystemHealth();
    final overall = health['overallHealthy'] as bool;
    return overall ? '✅' : '⚠️';
  }

  /// Get list of active issues
  List<String> getActiveIssues() {
    final health = getSystemHealth();
    final issues = <String>[];

    final audio = health['audio'] as Map<String, dynamic>;
    if (!audio['isHealthy']) {
      if (audio['audioOutputFailed']) {
        issues.add('Audio output permanently failed');
      } else if (audio['consecutiveErrors'] > 0) {
        issues.add('Audio output experiencing errors (${audio['consecutiveErrors']} consecutive)');
      }
    }

    final visual = health['visual'] as Map<String, dynamic>;
    if (!visual['isHealthy']) {
      if (visual['communicationFailed']) {
        issues.add('WebView communication permanently failed');
      } else if (visual['consecutiveErrors'] > 0) {
        issues.add('WebView experiencing errors (${visual['consecutiveErrors']} consecutive)');
      } else if (!visual['webViewInitialized']) {
        issues.add('WebView not initialized');
      }
    }

    final bridge = health['parameterBridge'] as Map<String, dynamic>;
    if (!bridge['isHealthy']) {
      issues.add('Parameter bridge errors detected (${bridge['consecutiveErrors']} consecutive)');
    }

    final perf = health['performance'] as Map<String, dynamic>;
    final bridgeFPS = double.tryParse(perf['bridgeFPS'] as String) ?? 0.0;
    if (bridgeFPS < 30.0) {
      issues.add('Low parameter bridge FPS: ${perf['bridgeFPS']}');
    }

    return issues;
  }

  /// Check if system is critically unhealthy (requires intervention)
  bool isCritical() {
    final health = getSystemHealth();
    final audio = health['audio'] as Map<String, dynamic>;
    final visual = health['visual'] as Map<String, dynamic>;
    final bridge = health['parameterBridge'] as Map<String, dynamic>;

    return audio['audioOutputFailed'] as bool ||
           visual['communicationFailed'] as bool ||
           (bridge['consecutiveErrors'] as int) >= 5;
  }
}
