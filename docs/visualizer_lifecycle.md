# Visualizer Lifecycle & Phased Validation Plan

This document captures the contract between Flutter and the embedded VIB34D viewer along with the test strategy we now expect for every touch to the visual stack.

## Lifecycle Handshake

1. **Booting** – the HTML runtime spins up, preloads the three systems, and posts `viewer-ready` once WebGL contexts exist. Flutter must reply by flushing its parameter cache via `VisualProvider.handleViewerReady`.
2. **Syncing** – VisualProvider batches rotation/geometry/audio payloads and resends the active system selection. JavaScript acknowledges each `switchSystem` call through `system-ready` or `system-error`.
3. **Ready / Switching / Faulted** – Both sides maintain a single active five-layer stack. VisualProvider tracks the lifecycle in `VisualizerLifecyclePhase` so widgets can present accurate UX and fallback when faults occur.

Every message surfaces via the `FlutterBridge` channel and is mirrored into provider state. This makes it trivial to log/trace lifecycle transitions while debugging audio/visual coupling.

## Phased Testing Expectations

| Phase | What to run | Purpose |
| --- | --- | --- |
| 1. Static analysis | `flutter analyze` | Prevents regressions in provider/widget logic and keeps the bridge API compile-safe. |
| 2. Handshake simulation | Widget tests that pump `VIB34DWidget` with mocked JavaScript messages | Verifies lifecycle transitions (boot → sync → ready, plus error handling) without spinning up a full WebView. |
| 3. Instrumented device smoke test | Launch the Flutter app (desktop/web/mobile) with a connected synth session and capture screenshots/videos | Confirms canvases rotate correctly, the WebGL stack tears down between system switches, and HUD overlays communicate the current phase to performers. |

## Documentation & Observability Checklist

- Keep this file updated when we add lifecycle states or change the bridge contract.
- When adding new diagnostics, surface them through `viewer-lifecycle` payloads so Flutter can display them without additional plumbing.
- Archive screenshots or recordings of major UI changes alongside release notes to maintain a visual regression history.

## System-Level Enhancements (2025-02-14)

- **Parameter parity:** Each WebGL system (Quantum, Holographic, Faceted) now exposes an `applyBridgeParameters` entry point so Flutter’s canonical synth parameters map to the per-system shader uniforms without one-off script injections.
- **Audio parity:** `updateAudioReactive` is implemented across the three systems and the runtime mirrors Flutter FFT data into `window.audioReactive`, ensuring identical sonic modulation paths regardless of which stack is active.
- **Snapshot replay:** The embedded runtime retains the last parameter/audio snapshot and automatically replays it whenever a system is destroyed/recreated so switching stacks never resets performer settings.

## Additional Phased Validation

| Phase | What to run | Purpose |
| --- | --- | --- |
| 4. Parameter bridge contract | Unit test or integration harness that calls `window.vib34d.updateParameters` and inspects each system’s uniforms (via JS eval) | Confirms `applyBridgeParameters` correctly translates Flutter names into shader-specific uniforms. |
| 5. Audio parity audit | Pump synthetic FFT data through `VisualProvider.updateAudioReactive` while each system is active | Ensures the new JS `updateAudioReactive` hooks react identically across Quantum/Holographic/Faceted layers. |
