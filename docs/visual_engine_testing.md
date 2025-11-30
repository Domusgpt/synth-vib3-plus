# VIB3+ Visual Engine Testing Plan

## Environments and tooling
- **Flutter stable channel** with `flutter config --enable-web` for WebView validation on Android/iOS and web.
- **webview_flutter** integration tests run with `flutter drive` or `flutter test` using device/emulator targets.
- Network debugging via `flutter run --verbose` and browser DevTools for the embedded engine page.

## Phased verification
1. **Static checks**
   - `flutter format lib/visual/vib34d_widget.dart` to enforce style.
   - `flutter analyze` for lint/typing coverage.
2. **Offline-first path**
   - Build/install a debug APK and toggle airplane mode.
   - Launch the visualizer and confirm the ribbon reports *Offline bundle* with a stable progress completion.
3. **Network build path**
   - Restore connectivity and relaunch.
   - Observe the ribbon reporting *Network build* and validate the progress bar moves to 100% before the ready state.
4. **Error and timeout handling**
   - Point `_fallbackEngineUri` at an invalid host in a local branch and confirm the error overlay surfaces retry buttons for both offline and network paths.
   - Introduce throttled connectivity (e.g., `tc` on Android emulator) to trigger the 15s watchdog timeout.
5. **Bridge sanity**
   - With DevTools console open, emit `FlutterBridge.postMessage('ERROR: test')` and verify the app surfaces the message.
   - Invoke `FlutterBridge.postMessage('READY: ok')` to confirm ready-state transitions without reloads.
6. **Diagnostics overlay**
   - Confirm the bottom-right diagnostics card appears while loading and after readiness, and that it reports phase, source, progress, watchdog timeout, and the most recent handshake text.
   - Measure and note *Boot time* values for both offline and network paths; track regressions if the metric drifts upward between builds.
   - Ensure the *Started* timestamp updates per attempt to validate that reloads correctly reset state.

## Documentation
- Capture screenshots of ribbon, progress, and error overlays on both offline and network paths.
- Capture screenshots of the diagnostics card in loading and ready states, including the boot-time metric.
- Record logs from `flutter run` to correlate status messages with console events for regressions.
