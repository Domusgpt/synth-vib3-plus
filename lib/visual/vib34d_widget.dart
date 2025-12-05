/**
 * VIB34D Widget
 *
 * Flutter WebView widget that displays the THREE VIB34D visualization systems
 * with full bidirectional parameter coupling to audio synthesis.
 *
 * Features:
 * - WebView-based visualization (full VIB3+ engine)
 * - Native fallback renderer when WebView fails
 * - Automatic retry and fallback logic
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
import 'vib3_native_widget.dart';

class VIB34DWidget extends StatefulWidget {
  final VisualProvider visualProvider;
  final AudioProvider audioProvider;

  /// Use native renderer instead of WebView
  final bool useNativeRenderer;

  /// Automatically fall back to native renderer on WebView failure
  final bool autoFallback;

  const VIB34DWidget({
    Key? key,
    required this.visualProvider,
    required this.audioProvider,
    this.useNativeRenderer = false,
    this.autoFallback = true,
  }) : super(key: key);

  @override
  State<VIB34DWidget> createState() => _VIB34DWidgetState();
}

class _VIB34DWidgetState extends State<VIB34DWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  int _loadRetryCount = 0;
  bool _useNativeFallback = false;
  final Uri _fallbackEngineUri =
      Uri.parse('https://domusgpt.github.io/vib3-plus-engine/');

  @override
  void initState() {
    super.initState();
    _useNativeFallback = widget.useNativeRenderer;
    if (!_useNativeFallback) {
      _initializeWebView();
    }
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
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) async {
            debugPrint('📄 Page loaded: $url');
            await _injectHelperFunctions();
            setState(() {
              _isLoading = false;
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

  Future<void> _loadEngine() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _webViewController.loadFlutterAsset('assets/vib3plus_flutter_full.html');
      debugPrint('✅ Loading VIB3+ engine from bundled asset');
    } catch (assetError) {
      debugPrint('⚠️ Asset load failed, attempting network fallback: $assetError');
      try {
        await _webViewController.loadRequest(_fallbackEngineUri);
        debugPrint('✅ Loaded VIB3+ engine from network fallback');
      } catch (networkError) {
        _handleWebViewError('Failed to load VIB3+ engine: $networkError');
      }
    }
  }

  void _handleWebViewError(String message) {
    _loadRetryCount++;

    // After 2 failed attempts, switch to native renderer if autoFallback is enabled
    if (_loadRetryCount >= 2 && widget.autoFallback) {
      debugPrint('⚠️ WebView failed $_loadRetryCount times, switching to native renderer');
      setState(() {
        _useNativeFallback = true;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  /// Switch to native renderer manually
  void switchToNativeRenderer() {
    setState(() {
      _useNativeFallback = true;
      _isLoading = false;
      _errorMessage = null;
    });
    debugPrint('🔄 Switched to native VIB3+ renderer');
  }

  /// Switch back to WebView renderer
  void switchToWebViewRenderer() {
    setState(() {
      _useNativeFallback = false;
      _loadRetryCount = 0;
    });
    _initializeWebView();
    debugPrint('🔄 Switched to WebView VIB3+ renderer');
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
    // Use native renderer if enabled
    if (_useNativeFallback) {
      return Stack(
        children: [
          // Native Flutter renderer
          const VIB3NativeWidget(
            audioReactive: true,
          ),

          // Indicator that we're using native renderer
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_fix_high, color: Colors.cyan, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Native Renderer',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: switchToWebViewRenderer,
                    child: const Icon(Icons.refresh, color: Colors.white54, size: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // WebView renderer
    return Stack(
      children: [
        // WebView with VIB3+ visualization
        WebViewWidget(controller: _webViewController),

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

        // Error message with fallback option
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
                    const Text(
                      'Error Loading Visualization',
                      style: TextStyle(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadEngine,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: switchToNativeRenderer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan.withOpacity(0.2),
                          ),
                          icon: const Icon(Icons.auto_fix_high, color: Colors.cyan),
                          label: const Text('Use Native',
                              style: TextStyle(color: Colors.cyan)),
                        ),
                      ],
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
