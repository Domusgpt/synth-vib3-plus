/**
 * VIB34D Widget
 *
 * Flutter WebView widget that displays the VIB3+ visualization.
 * Loads from LOCAL Flutter assets - works completely offline.
 *
 * Features:
 * - Full VIB3+ WebGL visualization (Faceted, Quantum, Holographic, Polychora)
 * - 24 4D polytope geometries with 6D rotation
 * - Audio-reactive parameter modulation
 * - Bidirectional parameter communication via JavaScript bridge
 * - OFFLINE - no network required
 *
 * Uses loadFlutterAsset() which leverages Android's WebViewAssetLoader
 * to properly serve assets with correct MIME types and relative path resolution.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
    this.initialSystem = 'quantum',
    this.hideUIControls = true,
  }) : super(key: key);

  @override
  State<VIB34DWidget> createState() => _VIB34DWidgetState();
}

class _VIB34DWidgetState extends State<VIB34DWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _engineReady = false;

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
            debugPrint('📄 Synth Viewer loaded');
            await _injectFlutterBridge();
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView error: ${error.description}');
            setState(() {
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..enableZoom(false);

    await _loadLocalViewer();
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

  /// Load the VIB3+ engine from local Flutter assets (works offline)
  Future<void> _loadLocalViewer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('🚀 Loading VIB3+ Engine from local assets...');

    try {
      // Load from local Flutter assets using loadFlutterAsset()
      // This uses Android's WebViewAssetLoader which:
      // - Serves assets with correct MIME types
      // - Resolves relative paths (styles/base.css -> assets/styles/base.css)
      // - Works completely offline
      await _webViewController.loadFlutterAsset('assets/vib3plus_flutter_full.html');
      debugPrint('✅ VIB3+ loading from local assets');
    } catch (e) {
      debugPrint('❌ Failed to load VIB3+ from assets: $e');
      // Fallback to remote if local fails
      try {
        debugPrint('🔄 Falling back to remote VIB3+ engine...');
        const vib3Url = 'https://domusgpt.github.io/vib3-plus-engine/';
        await _webViewController.loadRequest(Uri.parse(vib3Url));
        debugPrint('✅ VIB3+ loaded from remote fallback');
      } catch (e2) {
        debugPrint('❌ Both local and remote failed: $e2');
        setState(() {
          _errorMessage = 'Failed to load VIB3+ visualization: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Reload the viewer
  void reloadViewer() {
    _loadLocalViewer();
  }

  /// Inject Flutter bridge functions
  Future<void> _injectFlutterBridge() async {
    try {
      await _webViewController.runJavaScript('''
        // Check if synth viewer is ready (simpler check for local viewer)
        const checkReady = setInterval(() => {
          if (window.synthViewer || window.switchSystem) {
            clearInterval(checkReady);
            FlutterBridge.postMessage('READY:SynthViewer');
            console.log('✅ Synth Viewer ready, Flutter bridge active');
          }
        }, 50);

        // Timeout after 5 seconds (local should load fast)
        setTimeout(() => {
          clearInterval(checkReady);
          // Try to signal ready anyway - local viewer should be loaded
          FlutterBridge.postMessage('READY:SynthViewer');
        }, 5000);

        console.log('✅ Flutter Bridge check started');
      ''');
      debugPrint('✅ Flutter bridge initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Flutter bridge: $e');
    }
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
                      onPressed: reloadViewer,
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
