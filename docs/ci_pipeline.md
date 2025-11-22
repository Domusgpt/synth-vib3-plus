# Continuous Integration (GitHub Actions)

This project now ships with a lightweight Flutter CI workflow to keep the pinned toolchain and analyzer signals visible on every push and pull request.

## Workflow overview
- **File**: `.github/workflows/flutter_ci.yml`
- **Triggers**: `push`, `pull_request`, and manual `workflow_dispatch`.
- **Toolchain**: pins Flutter **3.24.0 (stable)** via `tools/flutter_bootstrap.sh`, matching the repository's Dart SDK constraint.
- **Caching**: caches the vendored Flutter SDK in `tools/flutter` and the pub cache (`~/.pub-cache`) keyed by `pubspec.lock`.
- **Analyzer**: runs `tools/flutter_analyze.sh` so the container-friendly wrapper captures logs in `tools/logs/flutter_analyze.log`.
- **Artifacts**: always uploads the analyzer log as `flutter-analyze-log` so failures in legacy modules are visible without breaking the pipeline.

## Phased CI expectations
1. **Bootstrap**: reuses the cached SDK when available; otherwise downloads and trusts it as a safe Git directory to avoid ownership warnings.
2. **Dependency resolve**: runs `flutter pub get` after exporting `tools/flutter/bin` onto `PATH`.
3. **Static analysis**: `tools/flutter_analyze.sh` executes with `continue-on-error: true` to surface the current baseline while keeping CI green until the legacy issues are addressed.
4. **Artifact capture**: analyzer output is persisted as an artifact for review; once the baseline is fixed, drop `continue-on-error` to enforce a hard gate.

## Local parity
Run the same steps locally to mirror CI:
```bash
CHANNEL=stable VERSION=3.24.0 tools/flutter_bootstrap.sh
export PATH="$PWD/tools/flutter/bin:$PATH"
flutter pub get
./tools/flutter_analyze.sh
```

## Next steps
- Add targeted `flutter test` suites for the visualizer bridge and HUD widgets, then wire them into the workflow (optionally allowed-to-fail while stabilizing).
- When the analyzer baseline is clean, remove `continue-on-error` so CI blocks regressions.
- Extend the workflow with platform smoke jobs (e.g., `flutter build web`) once the WebView stack is ready for automated environments.
