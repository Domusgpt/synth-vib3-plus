# Synth-VIB3+ Test Suite

Comprehensive testing for the audio-visual synthesizer application.

## Table of Contents

1. [Test Philosophy](#test-philosophy)
2. [Test Architecture](#test-architecture)
3. [Running Tests](#running-tests)
4. [Test Categories](#test-categories)
5. [Performance Benchmarks](#performance-benchmarks)
6. [Firebase Test Lab](#firebase-test-lab)
7. [CI/CD Integration](#cicd-integration)
8. [Writing New Tests](#writing-new-tests)

---

## Test Philosophy

### Why These Tests Matter

Synth-VIB3+ is a **real-time audio-visual synthesizer** with strict timing requirements:

| Constraint | Requirement | Why |
|------------|-------------|-----|
| **Audio Latency** | <10ms buffer generation | Prevent audible gaps/clicks |
| **Visual FPS** | 60 FPS (16.6ms/frame) | Smooth 4D animation |
| **Touch Response** | <100ms | Responsive UI feel |
| **Memory** | No leaks | Long session stability |

### Testing Strategy

```
                    ┌─────────────────────────────────────┐
                    │     Firebase Test Lab (E2E)         │
                    │   Real devices, real conditions     │
                    └─────────────────────────────────────┘
                                     ▲
                    ┌─────────────────────────────────────┐
                    │     Integration Tests               │
                    │   Audio ↔ Visual parameter bridge   │
                    └─────────────────────────────────────┘
                                     ▲
        ┌───────────────────┐                 ┌───────────────────┐
        │   Audio Unit      │                 │   Visual Unit     │
        │   Tests           │                 │   Tests           │
        │   - Oscillators   │                 │   - 6D Rotations  │
        │   - Filters       │                 │   - Parameters    │
        │   - Effects       │                 │   - Geometry      │
        └───────────────────┘                 └───────────────────┘
                                     ▲
                    ┌─────────────────────────────────────┐
                    │     Performance Benchmarks          │
                    │   Timing verification at all levels │
                    └─────────────────────────────────────┘
```

---

## Test Architecture

```
test/
├── audio/
│   └── synthesizer_engine_test.dart    # 40+ audio synthesis tests
├── providers/
│   └── visual_provider_test.dart       # 50+ visual state tests
├── integration/
│   └── parameter_bridge_test.dart      # 25+ coupling tests
├── performance/
│   └── benchmark_test.dart             # Timing verification
├── vib3_test.dart                      # VIB3+ 4D geometry (28 tests)
└── widget_test.dart                    # Basic widget tests

integration_test/
├── app_test.dart                       # Firebase Test Lab E2E
└── test_driver.dart                    # Instrumentation driver

test_driver/
└── integration_test.dart               # Flutter drive integration

scripts/
└── run_firebase_tests.sh               # Automated Test Lab runner
```

### Test Count Summary

| Category | File | Test Count |
|----------|------|------------|
| Audio Synthesis | `synthesizer_engine_test.dart` | 40+ |
| Visual Provider | `visual_provider_test.dart` | 50+ |
| Parameter Bridge | `parameter_bridge_test.dart` | 25+ |
| VIB3+ Geometry | `vib3_test.dart` | 28 |
| Performance | `benchmark_test.dart` | 15+ |
| E2E | `app_test.dart` | 10+ |
| **Total** | | **~170 tests** |

---

## Running Tests

### Quick Start

```bash
# Run everything
flutter test

# Run with verbose output
flutter test --reporter expanded

# Run specific category
flutter test test/audio/
flutter test test/providers/
flutter test test/integration/
flutter test test/performance/
```

### Coverage Report

```bash
# Generate coverage
flutter test --coverage

# View HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Watch Mode (Development)

```bash
# Re-run tests on file changes
flutter test --watch
```

---

## Test Categories

### 1. Synthesizer Engine Tests

**File:** `test/audio/synthesizer_engine_test.dart`

Tests the complete audio synthesis chain:

#### Oscillator Tests

| Test | What It Verifies |
|------|------------------|
| `Sine wave oscillates between -1 and 1` | Output bounded correctly |
| `Sine wave has correct frequency` | Zero crossings match expected rate |
| `Square wave has correct duty cycle` | 50% positive/negative samples |
| `Sawtooth wave rises linearly` | Monotonic increase in first quarter |
| `Triangle wave is symmetric` | Peak equals negative trough |
| `Wavetable morphs between sine and sawtooth` | Position 0=sine, 1=saw |
| `Frequency modulation shifts pitch correctly` | +12 semitones = 2x frequency |
| `Detune adds cents-level frequency shift` | 100 cents = 1 semitone |

#### Filter Tests

| Test | What It Verifies |
|------|------------------|
| `Lowpass filter attenuates high frequencies` | 5kHz signal reduced by >50% |
| `Lowpass filter passes low frequencies` | 100Hz signal passes >70% |
| `Filter cutoff modulation affects response` | Modulation changes effective cutoff |
| `Highpass filter attenuates low frequencies` | Bass content removed |
| `Bandpass filter passes middle frequencies` | Signal at cutoff passes through |
| `Filter output is always bounded` | Never exceeds ±1.0 |

#### Effects Tests

| Test | What It Verifies |
|------|------------------|
| `Dry signal passes through with mix=0` | Pure dry signal |
| `Reverb adds decay tail` | Non-zero output after impulse |
| `Delay produces echo after specified time` | Echo at correct sample offset |
| `Feedback creates multiple echoes` | Multiple peaks detected |
| `Noise injection adds randomness` | Consecutive buffers differ |
| `LFO rate is clamped to valid range` | 0.1-10 Hz enforced |

#### Integration Tests

| Test | What It Verifies |
|------|------------------|
| `Generate buffer produces correct sample count` | 512 samples = 512 length |
| `Generated samples are within valid range` | All samples in [-1, 1] |
| `Master volume scales output correctly` | 0.5 volume = ~0.5 RMS |
| `Mix balance controls oscillator blend` | Balance shifts between osc1/osc2 |
| `MIDI note sets correct base frequency` | Note 69 = 440 Hz |

---

### 2. Visual Provider Tests

**File:** `test/providers/visual_provider_test.dart`

Tests visual parameter state management:

#### Initialization Tests

| Test | What It Verifies |
|------|------------------|
| `Initial system is Faceted` | Default visual system |
| `Initial rotations are zero` | All 6 planes start at 0 |
| `Initial visual parameters have valid defaults` | Speed=1, density=8, brightness=0.8 |
| `Initial geometry state is valid` | Geometry 0, morph 0, vertices >0 |

#### 6D Rotation Tests

| Test | What It Verifies |
|------|------------------|
| `setRotationXY updates correctly and wraps at 2π` | Angle modulo 2π |
| `setRotationXZ/YZ/XW/YW/ZW updates correctly` | Each plane independent |
| `getRotationAngle returns correct values for all planes` | Read what was written |
| `getRotationAngle is case insensitive` | "xy" = "XY" = "Xy" |
| `updateRotations advances all 4D angles` | XW/YW/ZW change |
| `rotation speed affects updateRotations rate` | 2x speed = ~2x rotation |

#### Parameter Clamping Tests

| Parameter | Range | Test |
|-----------|-------|------|
| `rotationSpeed` | 0.1-5.0 | Below/above clamped |
| `tessellationDensity` | 2-30 | Below/above clamped |
| `vertexBrightness` | 0-1 | Below/above clamped |
| `hueShift` | 0-360 | Wraps at 360 |
| `glowIntensity` | 0-3 | Below/above clamped |
| `rgbSplitAmount` | 0-10 | Below/above clamped |
| `saturation` | 0-1 | Below/above clamped |
| `morphParameter` | 0-1 | Below/above clamped |
| `projectionDistance` | 5-15 | Below/above clamped |
| `layerSeparation` | 0-5 | Below/above clamped |

#### Visual System Tests

| Test | What It Verifies |
|------|------------------|
| `switchSystem changes to Quantum/Faceted/Holographic` | System enum updates |
| `switchSystem accepts string input` | "quantum", "HOLOGRAPHIC" work |
| `switchSystem updates vertex count per system` | Quantum=120, Holo=500, Faceted=50 |
| `setGeometry updates currentGeometry` | Index stored correctly |
| `setGeometry clamps to valid range 0-23` | Out of range clamped |
| `All 24 geometries can be selected` | Loop through all |

#### State Notification Tests

| Test | What It Verifies |
|------|------------------|
| `Rotation changes trigger notification` | Listener called |
| `Visual parameter changes trigger notification` | Listener called |
| `updateRotations triggers notification` | Listener called |
| `getVisualState returns complete state` | All keys present |

---

### 3. Parameter Bridge Tests

**File:** `test/integration/parameter_bridge_test.dart`

Tests bidirectional audio↔visual coupling:

#### Audio → Visual Tests

| Test | What It Verifies |
|------|------------------|
| `Silent audio produces minimal visual modulation` | No change on silence |
| `Bass-heavy audio increases rotation speed` | 100Hz signal affects speed |
| `High frequency audio affects vertex brightness` | 5kHz signal affects brightness |
| `Modulator extracts correct frequency bands` | Mixed signal processed |

#### Visual → Audio Tests

| Test | What It Verifies |
|------|------------------|
| `XY rotation modulates oscillator 1 detune` | Rotation → pitch shift |
| `Morph parameter affects waveform crossfade` | Morph → wavetable position |
| `Chaos affects noise injection` | RGB split → noise level |
| `Rotation speed affects LFO rate` | Visual speed → LFO Hz |
| `All 6 rotation planes are mapped` | Each plane readable |

#### Preset Tests

| Test | What It Verifies |
|------|------------------|
| `Default preset has audio reactive enabled` | Default configuration |
| `Can toggle audio reactive mode` | Enable/disable works |
| `Can toggle visual reactive mode` | Enable/disable works |
| `Loading preset updates bridge configuration` | Name and settings change |
| `Saving preset captures current state` | State serialized correctly |

#### 72 Combination Coverage

```dart
test('All 72 system+geometry combinations produce valid modulation', () async {
  final systems = [VisualSystem.quantum, VisualSystem.faceted, VisualSystem.holographic];

  for (final system in systems) {
    for (int geom = 0; geom < 24; geom++) {
      // Each of 3 × 24 = 72 combinations tested
      await visualProvider.switchSystem(system);
      await visualProvider.setGeometry(geom);
      modulator.updateFromVisuals();

      expect(visualProvider.currentSystemEnum, equals(system));
      expect(visualProvider.geometryIndex, equals(geom));
    }
  }
});
```

---

## Performance Benchmarks

**File:** `test/performance/benchmark_test.dart`

### Audio Buffer Benchmarks

| Benchmark | Target | Why |
|-----------|--------|-----|
| 512 samples | <10ms | 512 samples @ 44100Hz = 11.6ms of audio |
| 1024 samples | <20ms | Larger buffer for higher latency systems |
| Full effects chain | <15ms | Reverb + delay + noise + LFO |

### Visual Update Benchmarks

| Benchmark | Target | Why |
|-----------|--------|-----|
| Parameter update | <1ms | Many updates per frame |
| updateRotations | <5ms | Called every frame |
| getVisualState | <0.5ms | State serialization |

### Matrix/Geometry Benchmarks

| Benchmark | Target | Why |
|-----------|--------|-----|
| 6D rotation matrix | <100μs | 6 matrix multiplications |
| Vertex rotation (16-120 vertices) | <1ms | Transform all polytope vertices |
| 4D→3D projection (100 vertices) | <0.5ms | Perspective divide |
| Polytope generation | <10ms | Cache miss case |

### Full Frame Budget Test

```dart
test('Full frame update fits within 16.6ms budget', () {
  // Simulates complete frame:
  // 1. Update visual rotations
  // 2. Generate rotation matrix
  // 3. Rotate polytope vertices
  // 4. Project to 3D
  // 5. Generate audio buffer

  // Average must be <16.6ms (60 FPS)
  // Max should be <33ms (30 FPS floor)
});
```

---

## Firebase Test Lab

### Device Matrix

| Device | Model ID | Android | Type |
|--------|----------|---------|------|
| Pixel 6 | `oriole` | 13 | Phone |
| Pixel 5 | `redfin` | 11 | Phone |
| Pixel 3 | `blueline` | 9 | Phone |
| Galaxy A12 | `a12` | 11 | Phone |
| Tab S3 | `griffin` | 7 | Tablet |

### E2E Test Categories

| Test | What It Verifies |
|------|------------------|
| `App launches without crash` | Basic stability |
| `App displays main UI elements` | Scaffold present |
| `Can switch between visual systems` | System buttons work |
| `App handles geometry changes` | No crash on cycling |
| `Visual rendering maintains acceptable frame rate` | >25 FPS |
| `App responds to touch within acceptable latency` | <100ms |
| `Audio system initializes without error` | No audio crash |
| `Slider widgets are interactable` | UI responsive |
| `App remains stable after extended use` | No memory leaks |

### Running on Test Lab

**Option 1: Script**
```bash
./scripts/run_firebase_tests.sh
```

**Option 2: Manual**
```bash
# Build APKs
flutter build apk --debug
cd android
./gradlew app:assembleAndroidTest
./gradlew app:assembleDebug -Ptarget=integration_test/app_test.dart

# Upload to Test Lab
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=oriole,version=33 \
  --timeout 30m
```

**Option 3: Firebase Console (from phone)**
1. Go to https://console.firebase.google.com/project/_/testlab
2. Upload APKs
3. Select devices
4. Run test

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info

  firebase-test-lab:
    runs-on: ubuntu-latest
    needs: unit-tests
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --debug
      - run: |
          cd android
          ./gradlew app:assembleAndroidTest
          ./gradlew app:assembleDebug -Ptarget=integration_test/app_test.dart
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - uses: google-github-actions/setup-gcloud@v2
      - run: |
          gcloud firebase test android run \
            --type instrumentation \
            --app build/app/outputs/apk/debug/app-debug.apk \
            --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
            --device model=oriole,version=33 \
            --timeout 15m
```

---

## Writing New Tests

### Adding a New Synthesis Feature

1. **Unit test in `test/audio/`**
```dart
test('New feature works correctly', () {
  synth.setNewFeature(0.5);
  final buffer = synth.generateBuffer(512);

  // Verify output characteristics
  expect(_calculateRMS(buffer), greaterThan(0.0));
});
```

2. **Add to visual mapping if applicable**
```dart
// In test/integration/parameter_bridge_test.dart
test('Visual parameter X affects audio feature Y', () {
  visualProvider.setParameterX(0.5);
  modulator.updateFromVisuals();
  // Verify audio state changed
});
```

3. **Benchmark if timing-critical**
```dart
// In test/performance/benchmark_test.dart
test('New feature completes within budget', () {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < 1000; i++) {
    synth.newFeature();
  }
  stopwatch.stop();
  expect(stopwatch.elapsedMicroseconds / 1000, lessThan(1000));
});
```

### Test Naming Conventions

```dart
// Good: Describes behavior and expectation
test('Lowpass filter attenuates frequencies above cutoff', () {});
test('XY rotation modulates oscillator 1 detune by ±12 cents', () {});

// Bad: Vague or implementation-focused
test('Filter test', () {});
test('setRotationXY works', () {});
```

### Matcher Reference

```dart
// Numeric comparisons
expect(value, equals(42));
expect(value, closeTo(0.5, 0.01));       // Within 0.01 of 0.5
expect(value, inInclusiveRange(0, 1));   // 0 <= value <= 1
expect(value, lessThan(10));
expect(value, greaterThan(0));

// Collections
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, hasLength(5));
expect(list, contains(42));

// Types
expect(obj, isA<MyClass>());
expect(obj, isNotNull);

// Boolean
expect(condition, isTrue);
expect(condition, isFalse);
```

---

## Coverage Goals

| Module | Target | Priority |
|--------|--------|----------|
| `synthesizer_engine.dart` | 90% | Critical - audio core |
| `visual_provider.dart` | 85% | High - state management |
| `parameter_bridge.dart` | 80% | High - integration |
| `vib3_engine.dart` | 85% | High - visual core |
| `geometry_library.dart` | 90% | Medium - pure functions |
| `audio_analyzer.dart` | 75% | Medium - FFT wrapper |

---

## Troubleshooting

### Common Issues

**Tests timeout on CI**
```yaml
# Increase timeout
- run: flutter test --timeout 300s
```

**Firebase Test Lab "No tests found"**
```bash
# Ensure test APK built with correct target
./gradlew app:assembleDebug -Ptarget=integration_test/app_test.dart
```

**Flaky performance tests**
```dart
// Warm up before measuring
for (int i = 0; i < 10; i++) {
  synth.generateBuffer(512);
}
// Then start timing
```

**Memory tests fail on low-end devices**
```dart
// Reduce iteration count for CI
const iterations = isCI ? 1000 : 10000;
```

---

*A Paul Phillips Manifestation*
*© 2025 Paul Phillips - Clear Seas Solutions LLC*
