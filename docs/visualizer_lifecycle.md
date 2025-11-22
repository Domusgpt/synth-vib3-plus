# Visualizer Lifecycle & Phased Validation Plan

This document captures the contract between Flutter and the embedded VIB34D viewer along with the test strategy we now expect for every touch to the visual stack.

## Lifecycle Handshake

1. **Booting** – the HTML runtime spins up, preloads the three systems, and posts `viewer-ready` once WebGL contexts exist. Flutter must reply by flushing its parameter cache via `VisualProvider.handleViewerReady`.
2. **Syncing** – VisualProvider batches rotation/geometry/audio payloads and resends the active system selection. JavaScript acknowledges each `switchSystem` call through `system-ready` or `system-error`.
3. **Ready / Switching / Faulted** – Both sides maintain a single active five-layer stack. VisualProvider tracks the lifecycle in `VisualizerLifecyclePhase` so widgets can present accurate UX and fallback when faults occur.

- **Context guards:** Every canvas now registers `webglcontextlost/webglcontextrestored` hooks. A lost context emits `viewer-warning` plus a `system-initializing` pulse so Flutter can communicate the recovery, while the runtime force-destroys and rehydrates only the impacted stack.
- **Telemetry heartbeat:** The viewer publishes `viewer-telemetry` once per second with lifecycle, system name, layer count, queue depth, and current audio energy. `VisualProvider` caches the heartbeat so overlays can highlight stale or hidden sessions.
- **Frame-health instrumentation:** RequestAnimationFrame is now instrumented inside the HTML runtime so every heartbeat includes FPS, longest-frame (ms), RAF gap (ms since the last frame), audio staleness (ms since the last FFT payload), and total dropped frames. When any metric drifts beyond safe thresholds (>2.5 s audio gap or >350 ms RAF stall) the runtime emits `viewer-warning` pulses so Flutter can surface proactive guidance.
- **Visibility-aware throttling:** `document.visibilitychange/pageshow/pagehide` hooks now suspend warning thresholds while hidden, track how long the viewer has been backgrounded, and post `viewer-visibility` payloads (with `hiddenDurationMs`) so Flutter can show “hidden too long” hints.
- **Resource telemetry:** When `performance.memory` is available the runtime streams heap usage, heap limits, and derived `memoryPressure` (0–1). Flutter surfaces the values, flags >82% usage, and includes device RAM plus hardware concurrency for quick profiling.
- **Uptime + watchdog context:** Telemetry now carries total viewer uptime, per-system uptime, and a monotonically increasing sequence number. Performance counters reset on every switch or teardown so HUD badges reflect only the currently active stack.
- **Manual overrides:** `window.vib34d.forceReload()` is exposed for diagnostics and the Flutter HUD can trigger it via new reload affordances when telemetry stalls.

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
| 6. Context guard regression | Trigger `webglcontextlost` via DevTools (`gl.getExtension('WEBGL_lose_context').loseContext()`) while a system is running | Confirms `viewer-warning` plus forced rebuilds leave only one canvas stack alive and the Flutter HUD reports the recovery. |
| 7. Telemetry HUD verification | Run Flutter (desktop/web) and observe the new telemetry strip while switching systems | Guarantees performers see live system/layer/queue/energy stats and that stale/hidden states surface within 4 seconds. |
| 8. Frame-health instrumentation audit | Open DevTools Performance tab while the WebView runs, throttle audio updates, and confirm the HUD shows FPS, frame gap, audio age, and dropped-frame counts while triggering the new `viewer-warning` messages | Ensures the instrumentation thresholds fire correctly and Flutter visually distinguishes render vs. audio degradations. |
| 9. Visibility + background stress test | Background the Flutter host window for 5+ seconds, then foreground | Validates the hidden duration timer, ensures telemetry resumes instantly, and confirms the HUD shows amber “Hidden” badges instead of render warnings while backgrounded. |
| 10. Memory pressure rehearsal | Use Chrome DevTools to simulate low memory (Timeline → Memory) and observe telemetry | Confirms `memoryPressure` crosses the warning threshold, sends `viewer-warning`, and highlights the HUD badge in magenta with heap values populated. |
| 11. Telemetry watchdog + reload rehearsal | Block the bridge (e.g., DevTools simulate offline) for >8s, then recover | Verifies the provider marks telemetry as stale, surfaces the new health hint, and tints the reload control while keeping the lifecycle phase accurate. |
| 12. Uptime reset verification | Switch between all three systems in sequence while recording the HUD | Confirms uptime and longest-frame counters reset with each instantiation and never leak metrics from prior stacks. |
