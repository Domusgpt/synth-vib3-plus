# Synth-VIB3+ Test Suite

Comprehensive testing for the audio-visual synthesizer application.

## Test Architecture

```
test/
├── audio/
│   └── synthesizer_engine_test.dart    # Oscillators, filters, LFO, effects
├── providers/
│   └── visual_provider_test.dart       # 6D rotations, parameters, state
├── integration/
│   └── parameter_bridge_test.dart      # Bidirectional audio↔visual coupling
├── performance/
│   └── benchmark_test.dart             # Frame budget, latency, throughput
├── vib3_test.dart                      # VIB3+ 4D geometry and rendering
└── widget_test.dart                    # Basic widget tests

integration_test/
├── app_test.dart                       # Firebase Test Lab e2e tests
└── test_driver.dart                    # Test driver for instrumentation

test_driver/
└── integration_test.dart               # Flutter drive integration
```

## Running Tests

### Unit Tests (Local)

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/audio/synthesizer_engine_test.dart

# Run with coverage
flutter test --coverage
```

### Performance Benchmarks

```bash
flutter test test/performance/benchmark_test.dart
```

### Integration Tests (Local)

```bash
# Run on connected device
flutter test integration_test/app_test.dart
```

### Firebase Test Lab

```bash
# Build and run on Firebase Test Lab
./scripts/run_firebase_tests.sh

# Or manually:
# 1. Build APKs
flutter build apk --debug
cd android && ./gradlew app:assembleAndroidTest
cd android && ./gradlew app:assembleDebug -Ptarget=integration_test/app_test.dart

# 2. Run on Test Lab
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=oriole,version=33
```

## Test Categories

### 1. Synthesizer Engine Tests (`test/audio/`)

Tests for core audio synthesis:

| Component | Tests |
|-----------|-------|
| **Oscillator** | Waveform accuracy (sine, saw, square, triangle, wavetable) |
| **Frequency Modulation** | Pitch shifting, detune, LFO modulation |
| **Filter** | Lowpass/highpass/bandpass response, cutoff modulation |
| **Reverb** | Wet/dry mix, decay tail, room size |
| **Delay** | Echo timing, feedback, mix |
| **Noise** | Injection levels, randomness verification |
| **LFO** | Rate range, depth, phase cycling |

### 2. Visual Provider Tests (`test/providers/`)

Tests for visual state management:

| Category | Tests |
|----------|-------|
| **6D Rotations** | XY, XZ, YZ, XW, YW, ZW plane rotations |
| **Parameter Clamping** | Density (2-30), brightness (0-1), hue (0-360) |
| **Visual Systems** | Quantum, Faceted, Holographic switching |
| **Geometry Selection** | All 24 geometries (0-23) |
| **State Notifications** | ChangeNotifier events |

### 3. Integration Tests (`test/integration/`)

Tests for audio-visual coupling:

| Coupling Direction | Tests |
|--------------------|-------|
| **Audio → Visual** | FFT → rotation speed, brightness, density |
| **Visual → Audio** | Rotation → detune, morph → waveform, chaos → noise |
| **Preset Management** | Load, save, toggle audio/visual reactive modes |
| **72 Combinations** | All 3 systems × 24 geometries produce valid state |

### 4. Performance Benchmarks (`test/performance/`)

Critical timing constraints:

| Metric | Target | Tolerance |
|--------|--------|-----------|
| Audio buffer (512 samples) | <10ms | Real-time audio |
| Audio buffer (1024 samples) | <20ms | Larger buffers |
| Full effects chain | <15ms | Reverb + delay + noise |
| Parameter update | <1ms | 60 FPS budget |
| updateRotations | <5ms | Animation frame |
| 6D rotation matrix | <100μs | Per-frame computation |
| Vertex rotation (16-120) | <1ms | Typical polytope |
| 4D→3D projection | <0.5ms | Per-frame |
| **Full frame budget** | <16.6ms | 60 FPS target |

### 5. Firebase Test Lab Tests (`integration_test/`)

End-to-end tests on real devices:

| Test Category | Purpose |
|---------------|---------|
| App Launch | Verify no crash on startup |
| Visual Systems | System switching works |
| Performance | Frame rate measurement |
| Touch Response | <100ms latency |
| Memory Stability | No leaks after extended use |

## Device Matrix

Firebase Test Lab runs on these devices:

| Device | Model | Android | Screen |
|--------|-------|---------|--------|
| Pixel 6 | oriole | 13 | Phone |
| Pixel 5 | redfin | 11 | Phone |
| Pixel 3 | blueline | 9 | Phone |
| Galaxy A12 | a12 | 11 | Phone |
| Tab S3 | griffin | 7 | Tablet |

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
```

### Firebase Test Lab in CI

```yaml
  firebase-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --debug
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - run: ./scripts/run_firebase_tests.sh
```

## Test Coverage Goals

| Module | Target Coverage |
|--------|-----------------|
| synthesizer_engine.dart | 90% |
| visual_provider.dart | 85% |
| parameter_bridge.dart | 80% |
| vib3_engine.dart | 85% |
| geometry_library.dart | 90% |

## Adding New Tests

When adding new features:

1. **Unit test first** - Add tests to appropriate `test/` subdirectory
2. **Verify boundaries** - Test parameter clamping and edge cases
3. **Check performance** - Add benchmark if timing-critical
4. **Integration test** - If affects audio↔visual coupling
5. **Run full suite** - `flutter test` before committing

---

*A Paul Phillips Manifestation*
