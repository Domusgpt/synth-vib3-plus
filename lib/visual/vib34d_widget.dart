// VIB34D Widget
//
// Flutter WebView widget that displays the THREE VIB34D visualization systems
// with full bidirectional parameter coupling to audio synthesis.
//
// Integrates with:
// - VisualProvider for parameter state
// - AudioProvider for audio-reactive modulation
// - ParameterBridge for bidirectional coupling
//
// A Paul Phillips Manifestation
//
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/visual_provider.dart';
import '../providers/audio_provider.dart';

class VIB34DWidget extends StatefulWidget {
  final VisualProvider visualProvider;
  final AudioProvider audioProvider;

  const VIB34DWidget({
    super.key,
    required this.visualProvider,
    required this.audioProvider,
  });

  @override
  State<VIB34DWidget> createState() => _VIB34DWidgetState();
}

enum _EngineSource { asset, network }

enum _EngineLoadPhase { initializing, loading, ready, failed }

class _VIB34DWidgetState extends State<VIB34DWidget> {
  late final WebViewController _webViewController = _buildWebViewController();
  bool _isLoading = true;
  String? _errorMessage;
  String _statusMessage = 'Preparing VIB3+ engine...';
  _EngineSource? _activeEngineSource;
  _EngineLoadPhase _phase = _EngineLoadPhase.initializing;
  Timer? _loadWatchdog;
  double _progress = 0;
  DateTime? _bootStartedAt;
  DateTime? _readyAt;
  Duration? _timeToReady;
  String? _lastReadyMessage;
  static const _loadTimeout = Duration(seconds: 15);
  final Uri _fallbackEngineUri =
      Uri.parse('https://domusgpt.github.io/vib3-plus-engine/');

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _loadWatchdog?.cancel();
    super.dispose();
  }

  void _initializeWebView() async {
    await _loadEngine();

    widget.visualProvider.setWebViewController(_webViewController);
  }

  WebViewController _buildWebViewController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('📨 VIB3+ Message: ${message.message}');
          if (message.message.startsWith('ERROR:')) {
            _handleWebViewError(message.message.substring(6));
          } else if (message.message.startsWith('READY:')) {
            _resolveReady(message.message.substring(6));
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (_) {
            setState(() {
              _phase = _EngineLoadPhase.loading;
              _isLoading = true;
              _errorMessage = null;
              _statusMessage = _activeEngineSource == _EngineSource.network
                  ? 'Loading VIB3+ engine from network build...'
                  : 'Loading offline VIB3+ bundle...';
            });
            _startLoadWatchdog();
          },
          onPageFinished: (String url) async {
            debugPrint('📄 Page loaded: $url');
            await _injectHelperFunctions();
            setState(() {
              _statusMessage =
                  'Waiting for VIB3+ engine to signal readiness...';
            });
            debugPrint('✅ VIB34D WebView ready');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (request.isMainFrame && !_isEngineUrl(url)) {
              debugPrint('⛔️ Blocking external navigation to $url');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            _handleWebViewError(error.description);
            debugPrint('❌ WebView error: ${error.description}');
          },
        ),
      )
      ..enableZoom(false);
  }

  Future<void> _loadEngine({bool forceNetwork = false}) async {
    setState(() {
      _phase = _EngineLoadPhase.loading;
      _isLoading = true;
      _errorMessage = null;
      _progress = 0;
      _bootStartedAt = DateTime.now();
      _readyAt = null;
      _timeToReady = null;
      _lastReadyMessage = null;
      _statusMessage = forceNetwork
          ? 'Requesting VIB3+ engine from network...'
          : 'Booting offline VIB3+ bundle...';
    });

    final candidateSources = <_EngineSource>[
      if (!forceNetwork) _EngineSource.asset,
      _EngineSource.network,
    ];

    for (final source in candidateSources) {
      final succeeded = await _attemptEngineLoad(source);
      if (succeeded) {
        setState(() {
          _activeEngineSource = source;
          _statusMessage = source == _EngineSource.network
              ? 'Streaming VIB3+ engine from network build...'
              : 'Using offline VIB3+ bundle';
        });
        return;
      }
    }

    _handleWebViewError('Failed to load VIB3+ engine from any source');
  }

  Future<bool> _attemptEngineLoad(_EngineSource source) async {
    _loadWatchdog?.cancel();
    try {
      if (source == _EngineSource.asset) {
        await _webViewController
            .loadFlutterAsset('assets/vib3plus_flutter_full.html');
        debugPrint('✅ Loading VIB3+ engine from bundled asset');
      } else {
        await _webViewController.loadRequest(_fallbackEngineUri);
        debugPrint('✅ Loaded VIB3+ engine from network fallback');
      }
      return true;
    } catch (error) {
      debugPrint('⚠️ Engine load failed from $source: $error');
      return false;
    }
  }

  void _handleWebViewError(String message) {
    if (!mounted) return;
    _loadWatchdog?.cancel();
    setState(() {
      _errorMessage = message;
      _statusMessage = 'VIB3+ engine unavailable';
      _phase = _EngineLoadPhase.failed;
      _isLoading = false;
    });
  }

  void _startLoadWatchdog() {
    _loadWatchdog?.cancel();
    _loadWatchdog = Timer(_loadTimeout, () {
      _handleWebViewError(
        'Timed out waiting for VIB3+ engine to finish loading. Check your connection or try again.',
      );
    });
  }

  void _resolveReady(String readyMessage) {
    if (!mounted) return;
    _loadWatchdog?.cancel();
    _readyAt = DateTime.now();
    if (_bootStartedAt != null) {
      _timeToReady = _readyAt!.difference(_bootStartedAt!);
    }
    setState(() {
      _isLoading = false;
      _phase = _EngineLoadPhase.ready;
      _statusMessage = 'VIB3+ engine ready';
      if (_timeToReady != null) {
        _statusMessage =
            'VIB3+ engine ready in ${_timeToReady!.inMilliseconds} ms';
      }
      _lastReadyMessage = readyMessage.isNotEmpty
          ? readyMessage
          : (_lastReadyMessage ?? 'VIB3+ systems loaded');
      _progress = 1.0;
    });
  }

  /// Inject helper functions to batch parameter updates and handle errors
  Future<void> _injectHelperFunctions() async {
    try {
      await _webViewController.runJavaScript('''
        // Helper to batch parameter updates for better performance
        window.flutterUpdateParameters = function(params) {
          if (!window.updateParameter) {
            FlutterBridge.postMessage('ERROR: VIB3+ not ready yet');
            return;
          }

          // Apply each parameter
          Object.entries(params).forEach(([key, value]) => {
            try {
              window.updateParameter(key, value);
            } catch (e) {
              FlutterBridge.postMessage('ERROR: Failed to update ' + key + ': ' + e.message);
            }
          });
        };

        // Error handler
        window.addEventListener('error', function(e) {
          FlutterBridge.postMessage('ERROR: ' + e.message);
        });

        window.addEventListener('unhandledrejection', function(e) {
          const reason = e.reason && e.reason.message ? e.reason.message : 'Unhandled promise rejection';
          FlutterBridge.postMessage('ERROR: ' + reason);
        });

        // Notify Flutter when VIB3+ is ready
        if (window.switchSystem) {
          FlutterBridge.postMessage('READY: VIB3+ systems loaded');
        } else {
          // Wait for systems to load
          const checkReady = setInterval(() => {
            if (window.switchSystem) {
              clearInterval(checkReady);
              FlutterBridge.postMessage('READY: VIB3+ systems loaded');
            }
          }, 100);

          // Timeout after 10 seconds
          setTimeout(() => {
            clearInterval(checkReady);
            if (!window.switchSystem) {
              FlutterBridge.postMessage('ERROR: VIB3+ failed to initialize');
            }
          }, 10000);
        }
      ''');
      debugPrint('✅ Injected helper functions into VIB3+ WebView');
    } catch (e) {
      debugPrint('❌ Error injecting helper functions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView with VIB3+ visualization
        WebViewWidget(controller: _webViewController),

        // Status ribbon showing source and phase
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 12, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _phase == _EngineLoadPhase.ready
                              ? Icons.check_circle_outline
                              : Icons.sync,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_activeEngineSource != null)
                              Text(
                                _activeEngineSource == _EngineSource.network
                                    ? 'Source: Network build'
                                    : 'Source: Offline bundle',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            if (_phase == _EngineLoadPhase.loading)
                              Text(
                                'Progress: ${(100 * _progress).clamp(0, 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  letterSpacing: 0.2,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_phase == _EngineLoadPhase.loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value:
                            _progress > 0 && _progress < 1.0 ? _progress : null,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.cyan),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.cyan),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _activeEngineSource == _EngineSource.network
                        ? 'Streaming visualization from network build'
                        : 'Using offline visualization bundle',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Progress ${(100 * _progress).clamp(0, 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  if (_bootStartedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Boot started at ${_bootStartedAt!.toLocal().toIso8601String()}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Container(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 20),
                    Text(
                      'Error Loading Visualization',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _loadEngine(forceNetwork: true),
                          icon: const Icon(Icons.cloud_download),
                          label: Text(
                            _activeEngineSource == _EngineSource.network
                                ? 'Retry Network Build'
                                : 'Try Network Build',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _loadEngine(forceNetwork: false),
                          icon: const Icon(Icons.sd_storage),
                          label: const Text('Retry Offline Bundle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Diagnostics overlay for deeper visibility
        if (_phase != _EngineLoadPhase.failed)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _phase == _EngineLoadPhase.ready
                                  ? Icons.speed
                                  : Icons.timelapse,
                              color: Colors.cyanAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Engine diagnostics',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDiagnosticLine(
                          label: 'Phase',
                          value: _phase.name,
                        ),
                        _buildDiagnosticLine(
                          label: 'Source',
                          value: _activeEngineSource == _EngineSource.network
                              ? 'Network build'
                              : (_activeEngineSource == _EngineSource.asset
                                  ? 'Offline bundle'
                                  : 'Pending'),
                        ),
                        _buildDiagnosticLine(
                          label: 'Progress',
                          value:
                              '${(100 * _progress).clamp(0, 100).toStringAsFixed(0)}%',
                        ),
                        if (_timeToReady != null)
                          _buildDiagnosticLine(
                            label: 'Boot time',
                            value:
                                '${_timeToReady!.inMilliseconds} ms to ready',
                          ),
                        if (_lastReadyMessage != null)
                          _buildDiagnosticLine(
                            label: 'Handshake',
                            value: _lastReadyMessage!,
                          ),
                        if (_bootStartedAt != null)
                          _buildDiagnosticLine(
                            label: 'Started',
                            value: _bootStartedAt!
                                .toLocal()
                                .toIso8601String()
                                .split('T')
                                .join(' '),
                          ),
                        _buildDiagnosticLine(
                          label: 'Watchdog',
                          value: '${_loadTimeout.inSeconds}s timeout',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDiagnosticLine({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isEngineUrl(String url) {
    if (url.startsWith('data:') || url.startsWith('about:blank')) {
      return true;
    }

    if (url.contains('vib3plus_flutter_full.html') ||
        url.contains('flutter_asset')) {
      return true;
    }

    if (url.startsWith(_fallbackEngineUri.toString())) {
      return true;
    }

    return false;
  }
}
