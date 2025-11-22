# Visualizer Readiness & Go/No-Go Checklist

This note answers whether the current VIB34D visual stack "will work" and what is required to confidently ship it. It summarizes runtime safeguards already present and the remaining steps to validate them in this environment.

## What is already in place
- Single active stack enforcement: the embedded viewer destroys the current system before instantiating another, resetting performance counters and notifying Flutter about teardown/ready states to avoid stray WebGL contexts.
- Recovery + watchdogs: telemetry heartbeats include FPS, render gaps, audio staleness, and memory pressure; the runtime emits `viewer-warning` messages when thresholds trip so Flutter can surface reload guidance and keep performers informed.
- Parameter/audio resilience: parameter and audio snapshots are cached and reapplied after every switch or reload so performers keep their settings when changing systems or recovering from faults.

## What is required for this build to run here
1. **Install Flutter (same channel as the app)** with `tools/flutter_bootstrap.sh` (pinned to **Flutter 3.24.x / Dart 3.5** and unpacked into `tools/flutter`). The bootstrapper now registers the vendored SDK as a Git `safe.directory` to avoid ownership warnings inside containers. Export `PATH="$PWD/tools/flutter/bin:$PATH"` before running any Flutter commands, then run `flutter doctor` to provision desktop/web targets.
2. **Fetch dependencies**: run `flutter pub get` once Flutter is available (aligned to the updated `environment: sdk ">=3.5.0 <4.0.0"`).
3. **Analyzer pass**: run `tools/flutter_analyze.sh` to collect analyzer output in `tools/logs/flutter_analyze.log` (legacy issues still exist in unrelated audio modules/tests). The wrapper keeps the exit code but prevents the CLI from dumping thousands of warnings into the terminal.
4. **Targeted widget tests**: pump `VIB34DWidget` with mocked bridge messages to validate lifecycle transitions (boot → ready, switch, warning, fault) without a full WebView.
5. **Device/WebView smoke**: launch the app on desktop or web, switch among Quantum/Holographic/Faceted, and observe the HUD telemetry to confirm single-stack enforcement, audio freshness, **rotation snapshot mirroring (speed + XW/YW/ZW angles)**, and watchdog hints behave as expected.
6. **Resource/visibility rehearsals**: intentionally background the host window, simulate context loss, and apply memory pressure to verify the warning pulses and recovery pathways.
7. **CI parity**: GitHub Actions now mirrors steps 1–3 on every push/PR (`.github/workflows/flutter_ci.yml`) using the same bootstrapper, caching the SDK and pub artifacts, and uploading analyzer logs even when legacy findings remain.

## Quick go/no-go answer
- **Go** once Flutter is installed, dependencies are fetched, and phases 3–6 above pass without new warnings.
- **No-go** until the Flutter toolchain is provisioned and at least analyzer + widget tests are green; runtime safeguards exist but remain unverified in this container.

## Suggested commands (once Flutter is installed)
- `flutter doctor`
- `flutter pub get`
- `flutter analyze`
- `flutter test test/visualizer` *(widget/bridge simulations)*
- `flutter run -d chrome` *(observe HUD telemetry while switching systems)*
