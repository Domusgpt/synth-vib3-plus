# Synth-VIB3+ Testing Guide

## Quick Start

```bash
# Run all local tests
./test_runner.sh all

# Run specific test types
./test_runner.sh unit       # Flutter unit tests
./test_runner.sh synthesis  # Pure Dart synthesis test
./test_runner.sh build      # Build debug APK
./test_runner.sh device     # Run on connected device
./test_runner.sh firebase   # Run on Firebase Test Lab
```

---

## Test Types

### 1. Synthesis Test (Pure Dart)

Tests all 72 synthesis combinations (3 systems × 24 geometries).

```bash
dart test_synthesis.dart
```

**Verifies:**
- All geometry indices (0-23) produce audio
- All visual systems (Quantum/Faceted/Holographic) work
- RMS and peak amplitude are non-zero
- Envelope attack/release behavior
- FM synthesis with musical ratios
- Ring modulation with perfect fifth

### 2. Unit Tests

```bash
flutter test
```

**Files:**
- `test/widget_test.dart` - Basic app loading tests

### 3. Integration Tests

```bash
flutter test integration_test/audio_playback_test.dart
```

**Tests:**
- `AudioProvider` initialization
- `noteOn()` triggers audio generation
- Buffer generation produces non-zero samples
- All synthesis branches produce audio
- Full app integration

---

## Firebase Test Lab

### Prerequisites

1. Install gcloud CLI: https://cloud.google.com/sdk/docs/install
2. Authenticate: `gcloud auth login`
3. Set project: `gcloud config set project YOUR_PROJECT_ID`
4. Enable Firebase Test Lab API

### Build Test APKs

```bash
./test_runner.sh build-test
```

Creates:
- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

### Run on Firebase Test Lab

```bash
./test_runner.sh firebase
```

Or manually:

```bash
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=oriole,version=33,locale=en,orientation=portrait \
  --timeout 10m
```

### Available Devices

| Model | Description | API Level |
|-------|-------------|-----------|
| oriole | Pixel 6 | 33 |
| panther | Pixel 7 | 33 |
| felix | Pixel Fold | 33 |
| redfin | Pixel 5 | 30 |

---

## Audio Debugging

The app includes verbose debug logging for audio issues.

### Debug Log Tags

```
🎹 [AudioProvider] noteOn() - Note trigger events
▶️ [AudioProvider] startAudio() - Audio engine startup
🔊 [AudioProvider] Buffer - Buffer generation status
⚠️ [AudioProvider] - Warnings (PCM not initialized, etc.)
❌ [AudioProvider] - Errors
```

### View Logs

```bash
# While app is running on device
adb logcat | grep -E "🎹|▶️|🔊|⚠️|❌"

# Or with Flutter
flutter logs | grep -E "AudioProvider"
```

### Expected Log Sequence (Working Audio)

```
🎹 [AudioProvider] noteOn(60) called
🎹 [AudioProvider] isInitialized=true, isPcmAvailable=true
🎹 [AudioProvider] playNote(60) - isPlaying=false
🎹 [AudioProvider] synthesisBranchManager.noteOn() called
🎹 [AudioProvider] Starting audio...
▶️ [AudioProvider] startAudio() called - already playing: false
▶️ [AudioProvider] Setting up timer with 11ms interval
▶️ [AudioProvider] Audio started! PCM available: true
🔊 [AudioProvider] Buffer #0: note=60, freq=261.6Hz
🔊 [AudioProvider] Buffer max amplitude: 0.4523
🔊 [AudioProvider] PCM feed successful
```

### Common Issues

| Log Message | Cause | Fix |
|-------------|-------|-----|
| `isPcmAvailable=false` | PCM not initialized | Check FlutterPcmSound setup |
| `Buffer max amplitude: 0.0000` | Envelope not triggered | Check noteOn() called |
| `PCM playback error` | Platform issue | Check audio permissions |
| `PCM NOT initialized` | FlutterPcmSound.setup() failed | Check platform support |

---

## Calibration Tests

After fixing audio, run these calibration tests:

### 1. All 72 Combinations

```bash
dart test_synthesis.dart
```

Should show non-zero RMS for all combinations.

### 2. Latency Test

Touch XY pad and measure time to audio output. Target: <10ms

### 3. Visual-Audio Sync

Verify visual changes sync with audio at 60fps.

### 4. Volume Levels

Check all combinations have balanced volume levels.

---

## CI/CD Integration

### GitHub Actions (Example)

```yaml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart test_synthesis.dart
      - run: flutter test
      - run: flutter build apk --debug
```

### Firebase Test Lab in CI

```yaml
  firebase-test:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v3
      - uses: google-github-actions/setup-gcloud@v1
      - run: ./test_runner.sh build-test
      - run: ./test_runner.sh firebase
```

---

## Adding New Tests

### Integration Test Template

```dart
testWidgets('My new test', (tester) async {
  final audioProvider = AudioProvider();
  await audioProvider.ensureInitialized();

  // Test setup
  audioProvider.setGeometry(0);

  // Action
  audioProvider.noteOn(60);

  // Wait for processing
  await Future.delayed(const Duration(milliseconds: 200));

  // Verify
  expect(audioProvider.isPlaying, isTrue);

  // Cleanup
  audioProvider.noteOff(60);
});
```

---

© 2026 Paul Phillips - Clear Seas Solutions LLC
