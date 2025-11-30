# Synth-VIB3+ Testing Strategy

This project is now wired for a layered test approach that keeps heavy platform
integrations optional so we can run meaningful checks in CI and locally without
needing every device capability available.

## Tooling setup
- Install Flutter (stable) and ensure `flutter doctor -v` is clean for your
  platform. If Android SDK or Chrome are missing, you can still run pure Dart
  and widget tests. Use `./tooling/flutter_setup.sh` to fetch the pinned SDK
  quickly (see `docs/tooling_setup.md` for overrides).
- Run `flutter pub get` after updates to fetch dependencies.

## Fast feedback (headless)
- `flutter test` runs widget and provider coverage with the WebView and tilt
  sensors disabled by configuration flags.
- The default widget smoke test uses `SynthVIB3App` with `applySystemUi: false`
  and `enableVisualizer: false` to avoid platform channel calls while verifying
  the main scaffold builds.
- The tilt sensor provider now accepts a stream override, making it possible to
  feed deterministic accelerometer events in tests without real hardware.

## Visual engine checks
- For offline/CI runs, set `enableVisualizer: false` to skip the WebView. When
  validating the VIB3+ engine manually, use a real device or emulator and
  exercise both the bundled HTML (`assets/vib3plus_flutter_full.html`) and the
  network fallback.
- Use the diagnostics overlay in `VIB34DWidget` to confirm boot phase,
  handshake readiness, and watchdog timing when the visualizer is enabled.

## Phased validation before release
1. **Static & unit**: `flutter analyze` (if available), `flutter test`.
2. **Widget smoke**: Run the widget test suite with `applySystemUi` disabled to
   ensure the main screen renders without platform surfaces.
3. **Device/Emulator**: Launch the app with visualizer enabled, confirm tilt
   sensor interaction, and capture screenshots of the diagnostics overlay and
   loading states.
4. **Integration**: On devices with sensors and WebView support, validate the
   parameter bridge and XY pad modulation while recording boot timing from the
   diagnostics card.

Document the environment (Flutter/Dart versions, device model) alongside test
results so regressions are traceable.
