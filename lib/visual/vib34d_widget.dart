/**
 * VIB34D Widget
 *
 * Flutter WebView widget that displays the THREE VIB34D visualization systems
 * with full bidirectional parameter coupling to audio synthesis.
 *
 * Features:
 * - WebView-based visualization using hosted VIB3+ engine
 * - Full support for Faceted, Quantum, and Holographic systems
 * - Bidirectional parameter communication via JavaScript bridge
 *
 * The VIB3+ engine is loaded from the hosted GitHub Pages URL because
 * ES modules with relative imports don't work with Flutter's local asset system.
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

  /// Initial system to display: 'faceted', 'quantum', or 'holographic'
  final String initialSystem;

  /// Hide VIB3+ UI controls (use Flutter controls instead)
  final bool hideUIControls;

  const VIB34DWidget({
    Key? key,
    required this.visualProvider,
    required this.audioProvider,
    this.initialSystem = 'faceted',
    this.hideUIControls = true,
  }) : super(key: key);

  @override
  State<VIB34DWidget> createState() => _VIB34DWidgetState();
}

class _VIB34DWidgetState extends State<VIB34DWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  int _loadRetryCount = 0;
  bool _engineReady = false;

  /// Hosted VIB3+ engine URL - ES modules require proper web server
  Uri get _vib3EngineUri {
    // Build URL with parameters for Flutter integration
    final params = <String, String>{
      'system': widget.initialSystem,
      if (widget.hideUIControls) 'hideui': 'true',
      'flutter': 'true', // Signal to VIB3+ that we're in Flutter context
    };
    return Uri.parse('https://domusgpt.github.io/vib3-plus-engine/')
        .replace(queryParameters: params);
  }

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
        onMessageReceived: _handleJavaScriptMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
              _engineReady = false;
            });
          },
          onPageFinished: (String url) async {
            debugPrint('📄 VIB3+ page loaded: $url');
            await _injectFlutterBridge();
            setState(() {
              _isLoading = false;
            });
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

  /// Handle messages from JavaScript
  void _handleJavaScriptMessage(JavaScriptMessage message) {
    final msg = message.message;
    debugPrint('📨 VIB3+ → Flutter: $msg');

    if (msg.startsWith('READY:')) {
      setState(() {
        _engineReady = true;
        _errorMessage = null;
      });
      debugPrint('✅ VIB3+ engine ready with all three systems');
      // Sync initial system from widget
      _syncInitialState();
    } else if (msg.startsWith('SYSTEM:')) {
      // VIB3+ notified us of a system change
      final system = msg.substring(7).trim().toLowerCase();
      debugPrint('📱 VIB3+ system changed to: $system');
    } else if (msg.startsWith('ERROR:')) {
      final error = msg.substring(6).trim();
      debugPrint('❌ VIB3+ error: $error');
      setState(() {
        _errorMessage = error;
      });
    } else if (msg.startsWith('PARAM:')) {
      // VIB3+ sent a parameter update back
      // Format: PARAM:name=value
      _handleParameterUpdate(msg.substring(6));
    }
  }

  /// Handle parameter updates from VIB3+
  void _handleParameterUpdate(String paramString) {
    final parts = paramString.split('=');
    if (parts.length == 2) {
      final name = parts[0].trim();
      final value = double.tryParse(parts[1].trim());
      if (value != null) {
        debugPrint('📊 Parameter from VIB3+: $name = $value');
        // Can update VisualProvider here if needed
      }
    }
  }

  /// Sync initial state to VIB3+
  Future<void> _syncInitialState() async {
    try {
      await _webViewController.runJavaScript('''
        if (window.switchSystem) {
          window.switchSystem('${widget.initialSystem}');
          console.log('✅ Flutter synced initial system: ${widget.initialSystem}');
        }
      ''');
    } catch (e) {
      debugPrint('⚠️ Error syncing initial state: $e');
    }
  }

  Future<void> _loadEngine() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('🚀 Loading VIB3+ engine from: $_vib3EngineUri');

    try {
      await _webViewController.loadRequest(_vib3EngineUri);
      debugPrint('✅ VIB3+ engine request sent');
    } catch (e) {
      _handleWebViewError('Failed to load VIB3+ engine: $e');
    }
  }

  void _handleWebViewError(String message) {
    _loadRetryCount++;

    if (_loadRetryCount < 3) {
      // Retry loading
      debugPrint('⚠️ Load attempt $_loadRetryCount failed, retrying...');
      Future.delayed(const Duration(seconds: 2), () {
        _loadEngine();
      });
      return;
    }

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  /// Inject Flutter bridge functions into VIB3+
  Future<void> _injectFlutterBridge() async {
    try {
      await _webViewController.runJavaScript('''
        // Flutter Bridge for VIB3+ ↔ Flutter communication
        console.log('🔗 Injecting Flutter Bridge...');

        // Batch parameter updates for better performance
        window.flutterUpdateParameters = function(params) {
          if (!window.updateParameter) {
            FlutterBridge.postMessage('ERROR: VIB3+ not ready yet');
            return;
          }

          Object.entries(params).forEach(([key, value]) => {
            try {
              window.updateParameter(key, value);
            } catch (e) {
              console.error('Parameter update failed:', key, e);
            }
          });
        };

        // Notify Flutter of parameter changes from VIB3+
        window.notifyFlutterParameter = function(name, value) {
          FlutterBridge.postMessage('PARAM:' + name + '=' + value);
        };

        // Notify Flutter of system changes
        const originalSwitchSystem = window.switchSystem;
        if (originalSwitchSystem) {
          window.switchSystem = function(systemName) {
            originalSwitchSystem(systemName);
            FlutterBridge.postMessage('SYSTEM:' + systemName);
          };
        }

        // Global error handler
        window.addEventListener('error', function(e) {
          FlutterBridge.postMessage('ERROR: ' + e.message);
        });

        // Check if VIB3+ is ready
        const checkReady = setInterval(() => {
          if (window.switchSystem && window.updateParameter) {
            clearInterval(checkReady);
            FlutterBridge.postMessage('READY: VIB3+ Faceted/Quantum/Holographic systems loaded');
            console.log('✅ VIB3+ ready, Flutter bridge active');
          }
        }, 100);

        // Timeout after 15 seconds
        setTimeout(() => {
          clearInterval(checkReady);
          if (!window.switchSystem) {
            FlutterBridge.postMessage('ERROR: VIB3+ initialization timeout');
          }
        }, 15000);

        console.log('✅ Flutter Bridge injection complete');
      ''');
      debugPrint('✅ Flutter bridge injected into VIB3+');
    } catch (e) {
      debugPrint('❌ Error injecting Flutter bridge: $e');
    }
  }

  /// Reload the VIB3+ engine
  void reloadEngine() {
    setState(() {
      _loadRetryCount = 0;
      _engineReady = false;
    });
    _loadEngine();
  }

  /// Switch to a different VIB3+ system
  Future<void> switchSystem(String systemName) async {
    if (!_engineReady) {
      debugPrint('⚠️ Cannot switch system - VIB3+ not ready');
      return;
    }

    try {
      await _webViewController.runJavaScript('''
        if (window.switchSystem) {
          window.switchSystem('$systemName');
        }
      ''');
      debugPrint('✅ Switched to $systemName system');
    } catch (e) {
      debugPrint('❌ Error switching system: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView with VIB3+ visualization (Faceted, Quantum, Holographic)
        WebViewWidget(controller: _webViewController),

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
                    'Loading VIB3+ Engine...',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initializing ${widget.initialSystem.toUpperCase()} system',
                    style: TextStyle(
                      color: Colors.cyan.withOpacity(0.6),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Ready indicator (brief flash)
        if (_engineReady && !_isLoading)
          Positioned(
            bottom: 8,
            right: 8,
            child: AnimatedOpacity(
              opacity: _engineReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.cyan, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'VIB3+',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Error message with retry option
        if (_errorMessage != null && !_isLoading)
          Container(
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.orange, size: 48),
                    const SizedBox(height: 20),
                    const Text(
                      'VIB3+ Engine Connection Issue',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Unable to load the visualization engine.\nPlease check your internet connection.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: reloadEngine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.withOpacity(0.2),
                        foregroundColor: Colors.cyan,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
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

/// Getter for current geometry index from visual provider
extension VIB34DWidgetExtension on _VIB34DWidgetState {
  /// Get the current geometry index
  int get geometryIndex => widget.visualProvider.currentGeometry;

  /// Get current system name
  String get currentSystemName => widget.visualProvider.currentSystem;
}
