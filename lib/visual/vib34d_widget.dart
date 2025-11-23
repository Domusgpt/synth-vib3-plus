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

class _VIB34DWidgetState extends State<VIB34DWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

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
          // Handle messages from VIB3+ (errors, events, etc.)
          if (message.message.startsWith('ERROR:')) {
            setState(() {
              _errorMessage = message.message.substring(6);
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            debugPrint('📄 Page loaded: $url');
            await _injectHelperFunctions();
            setState(() {
              _isLoading = false;
            });
            debugPrint('✅ VIB34D WebView ready');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = error.description;
              _isLoading = false;
            });
            debugPrint('❌ WebView error: ${error.description}');
          },
        ),
      );

    // Load VIB3+ from local assets (not GitHub Pages - has errors)
    await _webViewController.loadFlutterAsset('assets/vib3plus_viewer.html');

    // Attach controller to visual provider
    widget.visualProvider.setWebViewController(_webViewController);
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
                    'Loading VIB34D Systems...',
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
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
