/**
 * VIB34D Widget
 *
 * Flutter WebView widget that displays the THREE VIB34D visualization systems
 * with full bidirectional parameter coupling to audio synthesis.
 *
 * Integrates with:
 * - VisualProvider for parameter state
 * - AudioProvider for audio-reactive modulation
 * - ParameterBridge for bidirectional coupling
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/visual_provider.dart';
import '../providers/audio_provider.dart';

class VIB34DWidget extends StatefulWidget {
  final VisualProvider visualProvider;
  final AudioProvider audioProvider;

  const VIB34DWidget({
    Key? key,
    required this.visualProvider,
    required this.audioProvider,
  }) : super(key: key);

  @override
  State<VIB34DWidget> createState() => _VIB34DWidgetState();
}

class _VIB34DWidgetState extends State<VIB34DWidget> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _handleJavaScriptMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
            debugPrint('📄 VIB34D asset loaded');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Prevent external navigation
            return NavigationDecision.prevent;
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = error.description;
              _isLoading = false;
            });
            widget.visualProvider.markVisualizerNotReady();
            debugPrint('❌ WebView error: ${error.description}');
          },
        ),
      );

    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      await _webViewController.loadFlutterAsset('assets/vib34d_viewer.html');
      widget.visualProvider.setWebViewController(_webViewController);
      debugPrint('🚀 Loaded embedded VIB34D asset');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load VIB34D asset: $e';
        _isLoading = false;
      });
      widget.visualProvider.markVisualizerNotReady();
    }
  }

  void _handleJavaScriptMessage(JavaScriptMessage message) {
    debugPrint('📨 VIB34D message: ${message.message}');
    try {
      final dynamic decoded = jsonDecode(message.message);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
      final event = data['event'] as String?;
      if (event != null) {
        unawaited(widget.visualProvider.handleViewerEvent(event, data));
      }
      if (event == 'system-error' || event == 'viewer-error') {
        setState(() {
          _errorMessage = data['message'] as String? ?? 'Visualizer error';
          _isLoading = false;
        });
      } else if (event == 'system-ready' || event == 'viewer-ready') {
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('⚠️  Failed to decode VIB34D message: $error');
      if (message.message.startsWith('ERROR:')) {
        setState(() {
          _errorMessage = message.message.substring(6);
          _isLoading = false;
        });
        widget.visualProvider.markVisualizerNotReady();
      }
    }
  }

  void _reloadVisualizer() {
    widget.visualProvider.markVisualizerNotReady();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.visualProvider,
      builder: (context, _) {
        final phase = widget.visualProvider.lifecyclePhase;
        final note = widget.visualProvider.lifecycleNote;
        final label = widget.visualProvider.viewerLabel;
        final error =
            _errorMessage ?? widget.visualProvider.lastVisualizerError;
    final telemetry = widget.visualProvider.viewerTelemetry;
    final viewerHidden = widget.visualProvider.viewerHidden;
    final shouldBlock =
        _isLoading ||
        phase != VisualizerLifecyclePhase.ready ||
        error != null;

        return Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (shouldBlock) _buildBlockingOverlay(phase, note, error),
            _buildLifecycleBadge(phase, note, label, error),
            _buildTelemetryStrip(telemetry, viewerHidden),
          ],
        );
      },
    );
  }

  Widget _buildBlockingOverlay(
    VisualizerLifecyclePhase phase,
    String? note,
    String? error,
  ) {
    final bool showError = error != null;
    final Color accent = showError ? Colors.redAccent : _phaseColor(phase);
    final String headline = showError
        ? 'Visualizer Fault'
        : _phaseHeadline(phase);
    final String detail = showError
        ? error!
        : (note ?? 'Preparing visual subsystems…');

    return Container(
      color: Colors.black.withOpacity(showError ? 0.82 : 0.65),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showError)
              Icon(Icons.error_outline, color: accent, size: 48)
            else
              const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 24),
            Text(
              headline,
              style: TextStyle(
                color: accent,
                fontSize: 20,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            if (showError)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton.icon(
                  onPressed: _reloadVisualizer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload Visualizer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: accent,
                    shadowColor: Colors.transparent,
                    side: BorderSide(color: accent.withOpacity(0.8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifecycleBadge(
    VisualizerLifecyclePhase phase,
    String? note,
    String? label,
    String? error,
  ) {
    final bool showError = error != null;
    final Color accent = showError ? Colors.redAccent : _phaseColor(phase);
    final String headline = showError ? 'Faulted' : _phaseHeadline(phase);
    final String? detail = showError ? error : (note ?? label);

    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              headline,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  detail,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryStrip(
    Map<String, dynamic>? telemetry,
    bool viewerHidden,
  ) {
    if (telemetry == null) {
      return const SizedBox.shrink();
    }

    final system = (telemetry['system'] as String? ?? 'unknown').toUpperCase();
    final layers = telemetry['layers'] as int? ?? 0;
    final queueDepth = telemetry['commandQueue'] as int? ?? 0;
    final energy = (telemetry['audioEnergy'] as num?)?.toDouble() ?? 0.0;
    final timestamp = telemetry['timestamp'] as int?;
    DateTime? heartbeat;
    if (timestamp != null) {
      heartbeat = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      heartbeat = widget.visualProvider.lastTelemetryBeat;
    }
    final Duration? age = heartbeat != null
        ? DateTime.now().difference(heartbeat)
        : null;
    final bool stale = age != null && age > const Duration(seconds: 4);
    final double normalizedEnergy = energy < 0
        ? 0.0
        : (energy > 1.0 ? 1.0 : energy);
    final int energyPercent = (normalizedEnergy * 100).round();
    final String heartbeatLabel = _formatHeartbeatAge(age);
    final double? fps = widget.visualProvider.viewerFps;
    final double? rafGapMs = widget.visualProvider.viewerRafGapMs;
    final double? audioStalenessMs =
        widget.visualProvider.viewerAudioStalenessMs;
    final double? longestFrameMs = widget.visualProvider.viewerLongestFrameMs;
    final int? droppedFrames = widget.visualProvider.viewerDroppedFrames;
    final double? uptimeMs = widget.visualProvider.viewerUptimeMs;
    final double? systemUptimeMs = widget.visualProvider.viewerSystemUptimeMs;
    final String? healthHint = widget.visualProvider.viewerHealthHint;
    final bool reloadSuggested = widget.visualProvider.viewerShouldReload;
    final bool renderWarning = widget.visualProvider.viewerRenderLoopStalled;
    final bool audioWarning = widget.visualProvider.viewerAudioFeedStale;
    final bool telemetryStale = widget.visualProvider.viewerTelemetryStale;
    final double? memoryPercent =
        widget.visualProvider.viewerMemoryUsagePercent;
    final double? memoryUsed = widget.visualProvider.viewerMemoryUsedMb;
    final double? memoryLimit = widget.visualProvider.viewerMemoryLimitMb;
    final double? deviceMemory = widget.visualProvider.viewerDeviceMemoryGb;
    final int? cpuCores = widget.visualProvider.viewerCpuCores;
    final double? hiddenDurationMs =
        widget.visualProvider.viewerHiddenDurationMs;
    final bool memoryWarning = widget.visualProvider.viewerMemoryWarning;
    final bool hiddenWarning =
        viewerHidden && (hiddenDurationMs ?? 0) > 2500;
    final Color statusColor = viewerHidden
        ? Colors.amberAccent
        : renderWarning
        ? Colors.deepOrangeAccent
        : audioWarning || stale
        ? Colors.orangeAccent
        : Colors.tealAccent;
    final String status = viewerHidden
        ? 'Hidden'
        : renderWarning
        ? 'Render Stall'
        : audioWarning
        ? 'Audio Stale'
        : stale || telemetryStale
        ? 'Stale'
        : 'Live';
    final Color queueAccent = queueDepth > 0
        ? Colors.orangeAccent
        : Colors.white70;
    final Color fpsAccent = fps != null && fps < 55
        ? Colors.orangeAccent
        : Colors.cyanAccent;
    final Color rafAccent = renderWarning
        ? Colors.deepOrangeAccent
        : Colors.white70;
    final Color audioAccent = audioWarning
        ? Colors.orangeAccent
        : Colors.white70;
    final Color longestAccent = (longestFrameMs ?? 0) > 24
        ? Colors.orangeAccent
        : Colors.white70;
    final Color dropsAccent = (droppedFrames ?? 0) > 0
        ? Colors.orangeAccent
        : Colors.white70;
    final Color memoryAccent = memoryWarning
        ? Colors.pinkAccent
        : Colors.lightGreenAccent;
    final Color hiddenAccent = hiddenWarning
        ? Colors.orangeAccent
        : Colors.white70;

    return Positioned(
      left: 16,
      bottom: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: stale ? 0.85 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _telemetryBadge('System', system, accent: statusColor),
                  _telemetryBadge('Layers', '$layers'),
                  _telemetryBadge('Queue', '$queueDepth', accent: queueAccent),
                  _telemetryBadge(
                    'Energy',
                    '$energyPercent%',
                    accent: normalizedEnergy > 0.1
                        ? Colors.cyanAccent
                        : Colors.white54,
                  ),
                  _telemetryBadge('Heartbeat', heartbeatLabel),
                  _telemetryBadge(
                    'FPS',
                    fps != null ? fps.toStringAsFixed(0) : '—',
                    accent: fpsAccent,
                  ),
                  _telemetryBadge(
                    'Frame Gap',
                    _formatMilliseconds(rafGapMs),
                    accent: rafAccent,
                  ),
                  _telemetryBadge(
                    'Audio Age',
                    _formatMilliseconds(audioStalenessMs),
                    accent: audioAccent,
                  ),
                  _telemetryBadge(
                    'Longest',
                    _formatMilliseconds(longestFrameMs),
                    accent: longestAccent,
                  ),
                  _telemetryBadge(
                    'Drops',
                    droppedFrames?.toString() ?? '0',
                    accent: dropsAccent,
                  ),
                  _telemetryBadge(
                    'Status',
                    status.toUpperCase(),
                    accent: statusColor,
                  ),
                  if (memoryPercent != null)
                    _telemetryBadge(
                      'Memory',
                      '${memoryPercent.toStringAsFixed(0)}%',
                      accent: memoryAccent,
                    ),
                  if (memoryUsed != null && memoryLimit != null)
                    _telemetryBadge(
                      'Heap',
                      '${memoryUsed.toStringAsFixed(0)} / ${memoryLimit.toStringAsFixed(0)}MB',
                    ),
                  if (cpuCores != null)
                    _telemetryBadge('Cores', '$cpuCores'),
                  if (deviceMemory != null)
                    _telemetryBadge(
                      'Device RAM',
                      '${deviceMemory.toStringAsFixed(0)}GB',
                    ),
                  if (hiddenDurationMs != null && hiddenDurationMs > 0)
                    _telemetryBadge(
                      'Hidden',
                      _formatMilliseconds(hiddenDurationMs),
                      accent: hiddenAccent,
                    ),
                  if (uptimeMs != null)
                    _telemetryBadge(
                      'Uptime',
                      _formatMilliseconds(uptimeMs),
                      accent: Colors.white70,
                    ),
                  if (systemUptimeMs != null)
                    _telemetryBadge(
                      'System Age',
                      _formatMilliseconds(systemUptimeMs),
                      accent: Colors.white70,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (healthHint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    healthHint,
                    style: TextStyle(
                      color: reloadSuggested
                          ? Colors.pinkAccent
                          : Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    unawaited(widget.visualProvider.forceReloadVisualizer());
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        reloadSuggested ? Colors.pinkAccent : Colors.white70,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text(
                    'Force Reload',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telemetryBadge(String label, String value, {Color? accent}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            letterSpacing: 1.4,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: accent ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatHeartbeatAge(Duration? age) {
    if (age == null) {
      return '—';
    }
    if (age.inMilliseconds < 1000) {
      return '<1s';
    }
    if (age.inSeconds < 60) {
      return '${age.inSeconds}s';
    }
    return '${age.inMinutes}m';
  }

  String _formatMilliseconds(double? value) {
    if (value == null || value.isNaN) {
      return '—';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}s';
    }
    return '${value.toStringAsFixed(0)}ms';
  }

  Color _phaseColor(VisualizerLifecyclePhase phase) {
    switch (phase) {
      case VisualizerLifecyclePhase.booting:
        return Colors.cyanAccent;
      case VisualizerLifecyclePhase.waitingForViewer:
        return Colors.amberAccent;
      case VisualizerLifecyclePhase.syncingState:
        return Colors.lightBlueAccent;
      case VisualizerLifecyclePhase.switching:
        return Colors.deepPurpleAccent;
      case VisualizerLifecyclePhase.ready:
        return Colors.tealAccent;
      case VisualizerLifecyclePhase.faulted:
        return Colors.redAccent;
    }
  }

  String _phaseHeadline(VisualizerLifecyclePhase phase) {
    switch (phase) {
      case VisualizerLifecyclePhase.booting:
        return 'Booting Visual Stack';
      case VisualizerLifecyclePhase.waitingForViewer:
        return 'Waiting on WebView';
      case VisualizerLifecyclePhase.syncingState:
        return 'Syncing Parameters';
      case VisualizerLifecyclePhase.switching:
        return 'Switching Systems';
      case VisualizerLifecyclePhase.ready:
        return 'Visualizer Ready';
      case VisualizerLifecyclePhase.faulted:
        return 'Visualizer Fault';
    }
  }
}
