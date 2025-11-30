# Tooling setup (Flutter/Dart)

This project expects a local Flutter installation so analyzer checks and tests can run consistently. The repository includes a helper script that downloads a pinned SDK and emits the diagnostics needed for CI and local development.

## Install or refresh the Flutter SDK

```bash
# Installs Flutter 3.24.0 to /opt/flutter by default
./tooling/flutter_setup.sh
```

Environment overrides:
- `FLUTTER_HOME` – installation directory (defaults to `/opt/flutter`).
- `FLUTTER_CACHE` – cache location for the downloaded archive (defaults to `/tmp/flutter-cache`).

The script ensures `git` trusts the install path (useful for root/CI) and runs `flutter --version` plus `flutter doctor -v` for a quick health check.

## Standard local workflow

```bash
export PATH="${FLUTTER_HOME:-/opt/flutter}/bin:${PATH}"
flutter pub get
flutter analyze
flutter test
```

Run these steps before opening a PR to verify analyzer cleanliness and unit/widget coverage. Use `flutter analyze --no-pub` for incremental linting when dependencies are already fetched.
