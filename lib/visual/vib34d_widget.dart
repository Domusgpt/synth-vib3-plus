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

enum _EngineSource { asset, network }

enum _EngineLoadPhase { initializing, loading, ready, failed }

class _VIB34DWidgetState extends State<VIB34DWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  String _statusMessage = 'Preparing VIB3+ engine...';
  _EngineSource? _activeEngineSource;
  _EngineLoadPhase _phase = _EngineLoadPhase.initializing;
  final Uri _fallbackEngineUri =
      Uri.parse('https://domusgpt.github.io/vib3-plus-engine/');

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('📨 VIB3+ Message: ${message.message}');
          if (message.message.startsWith('ERROR:')) {
            setState(() {
              _errorMessage = message.message.substring(6);
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _phase = _EngineLoadPhase.loading;
              _isLoading = true;
              _errorMessage = null;
              _statusMessage = _activeEngineSource == _EngineSource.network
                  ? 'Loading VIB3+ engine from network build...'
                  : 'Loading offline VIB3+ bundle...';
            });
          },
          onPageFinished: (String url) async {
            debugPrint('📄 Page loaded: $url');
            await _injectHelperFunctions();
            setState(() {
              _isLoading = false;
              _phase = _EngineLoadPhase.ready;
              _statusMessage = 'VIB3+ engine ready';
            });
            debugPrint('✅ VIB34D WebView ready');
          },
          onWebResourceError: (WebResourceError error) {
            _handleWebViewError(error.description);
            debugPrint('❌ WebView error: ${error.description}');
          },
        ),
      )
      ..enableZoom(false);

    await _loadEngine();

    widget.visualProvider.setWebViewController(_webViewController);
  }

  Future<void> _loadEngine({bool forceNetwork = false}) async {
    setState(() {
      _phase = _EngineLoadPhase.loading;
      _isLoading = true;
      _errorMessage = null;
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
    setState(() {
      _errorMessage = message;
      _statusMessage = 'VIB3+ engine unavailable';
      _phase = _EngineLoadPhase.failed;
      _isLoading = false;
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
        Positioned(
          left: 12,
          top: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyan),
                  SizedBox(height: 20),
                  Text(
                    'Loading VIB3+ Engine...',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontFamily: 'monospace',
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                    ElevatedButton.icon(
                      onPressed: () => _loadEngine(forceNetwork: true),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _activeEngineSource == _EngineSource.network
                            ? 'Retry Network Build'
                            : 'Retry with Network Build',
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
