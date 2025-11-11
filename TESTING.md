# Synth-VIB3+ Testing Guide

**Last Updated**: November 11, 2025
**Status**: Phase 3A Complete - Comprehensive Test Suite

---

## Overview

Synth-VIB3+ has a comprehensive testing framework covering all major systems including synthesis, parameter modulation, audio engines, and performance benchmarking.

### Test Coverage

| Component | Test File | Coverage | Tests |
|-----------|-----------|----------|-------|
| **Enhanced Parameter Modulation** | `test/mapping/enhanced_parameter_modulation_test.dart` | 100% | 50+ tests |
| **Performance Comparison** | `test/utils/performance_comparison_test.dart` | 100% | 40+ tests |
| **Audio Provider Enhanced** | `test/providers/audio_provider_enhanced_test.dart` | Logic: 100% | 35+ tests |
| **Visual-to-Audio Integration** | `test/mapping/visual_to_audio_integration_test.dart` | 100% | 30+ tests |
| **Synthesis Branch Manager** | `test/synthesis/synthesis_branch_manager_test.dart` | 100% | 25+ tests |

**Total**: 180+ comprehensive tests covering all Phase 2 and Phase 3A implementations.

---

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
# Enhanced parameter modulation tests
flutter test test/mapping/enhanced_parameter_modulation_test.dart

# Performance comparison tests
flutter test test/utils/performance_comparison_test.dart

# Audio provider tests
flutter test test/providers/audio_provider_enhanced_test.dart

# Visual-to-audio integration tests
flutter test test/mapping/visual_to_audio_integration_test.dart

# Synthesis branch manager tests
flutter test test/synthesis/synthesis_branch_manager_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### Run Tests in Watch Mode

```bash
flutter test --watch
```

---

## Test Organization

### Phase 2 Tests (Parameter Mapping Integration)

#### 1. Enhanced Parameter Modulation (`enhanced_parameter_modulation_test.dart`)

Tests all 6 modulation components:

**LFO (Low-Frequency Oscillator)**
- Initialization and defaults
- 5 waveform types (sine, triangle, square, saw, random)
- Phase tracking and wrapping
- Rate configuration (0.1-10 Hz)
- Reset functionality

**Chaos Generator**
- Lorenz attractor chaotic modulation
- Noise injection (0-30%)
- Filter randomization (0-50%)
- Smooth evolution (no sudden jumps)
- Chaos level scaling

**Spectral Tilt Filter**
- Frequency-dependent gain adjustment
- ±12dB tilt range
- Frequency response (boost/attenuation)
- Gain limiting (safe range)

**Polyphony Manager**
- Voice count mapping (1-8 voices)
- Smooth transitions (no audio pops)
- Target-based gradual changes

**Stereo Width Processor**
- Mid-side (M/S) processing
- Width range (0.0-2.0x)
- Projection mode presets
- Energy balance preservation

**Harmonic Richness Controller**
- Dynamic harmonic count (2-8)
- Exponential decay curves
- Spread and decay parameters
- Complexity mapping

**Integration Tests**
- All components working together
- 60 FPS update rate
- State export/import
- Reset functionality

Example test:
```dart
test('should generate sine waveform correctly', () {
  lfo.waveform = LFOWaveform.sine;
  lfo.rate = 1.0;

  final value1 = lfo.nextValue(0.0);
  expect(value1, closeTo(0.0, 0.01));

  final value2 = lfo.nextValue(0.25);
  expect(value2, closeTo(1.0, 0.01));
});
```

#### 2. Performance Comparison (`performance_comparison_test.dart`)

Tests the benchmarking framework:

**EnginePerformanceResult**
- Latency statistics (avg, min, max, stddev)
- Scoring system (0-100 scale)
- Latency score (target: <8ms = 100, >20ms = 0)
- Consistency score (target: <2ms stddev = 100)
- Overall score (70% latency + 30% consistency)
- JSON export

**EngineComparisonResult**
- Latency improvement calculation
- Improvement percentage
- Winner determination
- Recommendations ("Strongly recommend SoLoud", "Both similar", etc.)
- JSON export

**Comparison Scenarios**
- SoLoud much better than PCM
- Both engines similar performance
- PCM surprisingly better (edge case)

Example test:
```dart
test('should give 100 for latency <= 8ms', () {
  final result = EnginePerformanceResult(
    engine: AudioEngineType.soLoud,
    avgLatencyMs: 8.0,
    minLatencyMs: 7.0,
    maxLatencyMs: 9.0,
    buffersGenerated: 100,
    testDurationSeconds: 10.0,
    latencySamples: [7, 8, 9],
  );

  expect(result.latencyScore, equals(100.0));
});
```

#### 3. Audio Provider Enhanced (`audio_provider_enhanced_test.dart`)

Tests dual-engine provider logic:

**Geometry Management**
- Validation (0-23 range)
- Core index calculation (0-2)
- Base geometry extraction (0-7)

**Parameter Mapping**
- Glow → Reverb (5-60%)
- Glow → Attack (1-100ms)
- Parameter clamping

**Engine Switching**
- Current engine tracking
- State preservation during switch
- Playback resume after switch

**Performance Metrics**
- Metric tracking per engine
- Latency improvement calculation
- Comparison structure

**State Synchronization**
- Critical parameter sync
- Consistency across switch
- Visual system integration

Example test:
```dart
test('should map glow intensity to reverb correctly', () {
  expect(_glowToReverb(0.0), closeTo(0.05, 0.01)); // 5%
  expect(_glowToReverb(0.5), closeTo(0.325, 0.01)); // 32.5%
  expect(_glowToReverb(1.0), closeTo(0.60, 0.01)); // 60%
});
```

#### 4. Visual-to-Audio Integration (`visual_to_audio_integration_test.dart`)

Tests complete parameter mapping pipeline:

**Parameter Mapping**
- Chaos → Noise injection
- Speed → LFO rate
- Hue → Spectral tilt
- Glow → Reverb + Attack
- Tessellation → Polyphony
- Complexity → Harmonic richness
- Projection → Stereo width

**Mapping Curves**
- Linear
- Exponential
- Logarithmic
- Sinusoidal

**Visual State Normalization**
- Rotation angles (0-2π → 0-1)
- Projection distance (5-15 → 0-1)
- Layer depth (0-5 → 0-1)
- Vertex count → Voice count (logarithmic)

**Geometry Synchronization**
- Full geometry index calculation
- System offset lookup
- Validation

**Integration Scenarios**
- Typical performance setup
- Extreme parameter values
- Reset to safe defaults
- 60 FPS performance

Example test:
```dart
test('should map chaos level to noise injection correctly', () {
  final chaos = ChaosGenerator();

  chaos.setChaosLevel(0.0);
  expect(chaos.noiseLevel, equals(0.0));

  chaos.setChaosLevel(1.0);
  expect(chaos.noiseLevel, closeTo(0.3, 0.01)); // Max 30%
});
```

### Phase 1 Tests (Synthesis Branch Manager)

#### 5. Synthesis Branch Manager (`synthesis_branch_manager_test.dart`)

Tests the 72-combination system:

**Geometry Validation**
- Valid range (0-23)
- Invalid geometry handling
- Boundary cases

**Core Selection**
- Base core (0-7) → Direct synthesis
- Hypersphere core (8-15) → FM synthesis
- Hypertetrahedron core (16-23) → Ring modulation

**Voice Characteristics**
- 8 unique voice presets
- Musical envelopes
- Reverb settings
- Harmonic configurations

**Sound Families**
- Quantum (pure harmonic)
- Faceted (geometric hybrid)
- Holographic (spectral rich)

**Performance Tests**
- Buffer generation speed (<10ms for 512 samples)
- All 72 combinations valid
- Musical tuning accuracy (cents-based)

Example test:
```dart
test('should generate audio quickly (< 10ms for 512 samples)', () {
  manager.setGeometry(12);
  manager.noteOn();

  final stopwatch = Stopwatch()..start();
  manager.generateBuffer(512, 440.0);
  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(10));
});
```

---

## Test Categories

### Unit Tests

Test individual components in isolation:
- LFO waveform generation
- Chaos generator Lorenz attractor
- Spectral tilt filter processing
- Parameter mapping functions
- Geometry validation

### Integration Tests

Test interaction between components:
- Enhanced modulation system integration
- Visual-to-audio parameter pipeline
- Dual-engine state synchronization
- Complete mapping scenarios

### Performance Tests

Verify performance targets:
- 60 FPS update rate
- <10ms buffer generation
- Smooth voice transitions
- Rapid parameter changes

### Regression Tests

Prevent bugs from reoccurring:
- Parameter clamping
- Edge case handling
- Error recovery
- State reset

---

## Running Tests in CI/CD

Tests run automatically on GitHub Actions for all pushes and pull requests.

### CI Workflow

```yaml
# .github/workflows/flutter-ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test --machine > test-results.json
```

### Coverage Requirements

- **Target**: 85% overall coverage
- **Current**: ~70% coverage (increasing with Phase 3A tests)
- **Critical paths**: 100% coverage (synthesis, modulation, mapping)

---

## Writing New Tests

### Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:synth_vib3_plus/path/to/component.dart';

void main() {
  group('ComponentName', () {
    late ComponentType component;

    setUp(() {
      component = ComponentType();
    });

    tearDown(() {
      component.dispose();
    });

    test('should do something specific', () {
      // Arrange
      component.setValue(0.5);

      // Act
      final result = component.calculate();

      // Assert
      expect(result, closeTo(expectedValue, 0.01));
    });
  });
}
```

### Best Practices

1. **Descriptive Test Names**: Use "should" statements
   ```dart
   test('should map glow intensity to reverb correctly', () { });
   ```

2. **Arrange-Act-Assert Pattern**
   ```dart
   // Arrange
   final input = 0.5;

   // Act
   final result = function(input);

   // Assert
   expect(result, equals(expected));
   ```

3. **Use closeTo() for Floating Point**
   ```dart
   expect(result, closeTo(0.5, 0.01)); // ±0.01 tolerance
   ```

4. **Test Edge Cases**
   ```dart
   test('should handle minimum value', () {
     expect(() => validate(0.0), returnsNormally);
   });

   test('should handle maximum value', () {
     expect(() => validate(1.0), returnsNormally);
   });

   test('should throw on invalid value', () {
     expect(() => validate(-1.0), throwsArgumentError);
   });
   ```

5. **Group Related Tests**
   ```dart
   group('Latency Score', () {
     test('should give 100 for latency <= 8ms', () { });
     test('should give 0 for latency >= 20ms', () { });
     test('should scale linearly between 8ms and 20ms', () { });
   });
   ```

---

## Testing Tools

### Flutter Test Framework

Built-in testing framework with:
- Test runner
- Assertion library
- Mocking support
- Coverage analysis

### Useful Matchers

```dart
// Equality
expect(actual, equals(expected));
expect(actual, same(expected));

// Numeric
expect(value, closeTo(5.0, 0.1));
expect(value, greaterThan(0));
expect(value, lessThan(10));
expect(value, inRange(0, 10));

// Boolean
expect(condition, isTrue);
expect(condition, isFalse);

// Null
expect(value, isNull);
expect(value, isNotNull);

// Type
expect(object, isA<TypeName>());

// Exceptions
expect(() => function(), throwsException);
expect(() => function(), throwsArgumentError);
expect(() => function(), returnsNormally);

// Collections
expect(list, contains(element));
expect(list, isEmpty);
expect(list, hasLength(5));
expect(map, containsPair('key', 'value'));
```

---

## Performance Benchmarking

### Manual Benchmarking

```dart
test('should perform operation quickly', () {
  final stopwatch = Stopwatch()..start();

  // Perform operation
  for (int i = 0; i < 1000; i++) {
    component.process();
  }

  stopwatch.stop();

  // Verify performance target
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```

### Using PerformanceComparison

```dart
// In production code (requires AudioProviderEnhanced instance)
final comparison = PerformanceComparison(
  audioProvider: audioProvider,
);

// Run full comparison (10 seconds)
final result = await comparison.runComparison(
  durationSeconds: 10,
  noteToPlay: 60, // Middle C
);

print('PCM Latency: ${result.pcmResult.avgLatencyMs}ms');
print('SoLoud Latency: ${result.soLoudResult.avgLatencyMs}ms');
print('Improvement: ${result.latencyImprovementPercent}%');
print('Recommendation: ${result.recommendation}');

// Quick check (1 second)
final quickCheck = await comparison.quickLatencyCheck();

// Test all 72 combinations (comprehensive)
final allTests = await comparison.testAll72Combinations(
  samplesPerCombination: 5,
);
```

---

## Troubleshooting

### Tests Failing

1. **Check Flutter version**
   ```bash
   flutter --version
   # Should be 3.10.0 or higher
   ```

2. **Update dependencies**
   ```bash
   flutter pub get
   flutter pub upgrade
   ```

3. **Clean and rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter test
   ```

### Coverage Not Generating

```bash
# Install lcov (if not already installed)
sudo apt-get install lcov  # Linux
brew install lcov  # macOS

# Generate coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Specific Test Failing

```bash
# Run with verbose output
flutter test --verbose test/path/to/test.dart

# Run single test
flutter test test/path/to/test.dart --name "test name"
```

---

## Next Steps

### Phase 3B: Device Testing

After Phase 3A (unit/integration tests), the next steps require physical device:

1. **Deploy to Android Device**
   ```bash
   flutter run --release
   ```

2. **Run Performance Benchmarks**
   - Use in-app performance comparison UI
   - Test all 72 combinations
   - Measure latency improvements

3. **User Testing**
   - A/B test engine preference
   - Gather feedback on sound quality
   - Test on multiple devices

4. **Optimization**
   - Profile for bottlenecks
   - Optimize critical paths
   - Fine-tune buffer sizes

---

## Summary

Phase 3A delivers **180+ comprehensive tests** covering:
- ✅ Enhanced parameter modulation (50+ tests)
- ✅ Performance comparison framework (40+ tests)
- ✅ Dual-engine audio provider (35+ tests)
- ✅ Visual-to-audio integration (30+ tests)
- ✅ Synthesis branch manager (25+ tests)

All tests follow best practices and can be run locally or in CI/CD.

**Next**: Deploy to device for Phase 3B performance validation.

---

**A Paul Phillips Manifestation**
Paul@clearseassolutions.com
"The Revolution Will Not be in a Structured Format"
© 2025 Paul Phillips - Clear Seas Solutions LLC
