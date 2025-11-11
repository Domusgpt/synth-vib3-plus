# Synth-VIB3+ Development Guide

**Version**: 1.0.0
**Last Updated**: November 11, 2025

This guide provides comprehensive information for developers working on Synth-VIB3+, covering development workflow, architecture patterns, and best practices specific to real-time audio synthesis applications.

---

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Project Architecture](#project-architecture)
3. [Development Workflow](#development-workflow)
4. [Code Quality Standards](#code-quality-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Performance Optimization](#performance-optimization)
7. [Audio-Specific Best Practices](#audio-specific-best-practices)
8. [Debugging Techniques](#debugging-techniques)
9. [Contributing Guidelines](#contributing-guidelines)

---

## Development Environment Setup

### Prerequisites

- **Flutter SDK**: 3.9.0 or higher
- **Dart SDK**: 3.9.0 or higher
- **Android Studio** or **VSCode** with Flutter extensions
- **Java JDK**: 17 (for Android builds)
- **Git**: Latest version
- **Android Device**: Physical device recommended for audio testing

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd synth-vib3-plus

# Install dependencies
flutter pub get

# Verify setup
flutter doctor -v

# Run tests to verify installation
flutter test

# Run on connected Android device
flutter run
```

### Recommended VSCode Extensions

The project includes `.vscode/extensions.json` with recommended extensions:

- **Dart** (`dart-code.dart-code`)
- **Flutter** (`dart-code.flutter`)
- **Error Lens** (`usernamehw.errorlens`)
- **GitLens** (`eamodio.gitlens`)
- **Better Comments** (`aaron-bond.better-comments`)
- **TODO Tree** (`gruntfuggly.todo-tree`)

Install all recommended extensions:
```bash
# VSCode will prompt you to install recommended extensions
# Or install manually from the Extensions panel
```

### Android Studio Setup

1. Install Flutter and Dart plugins
2. Configure Android SDK (API 21+)
3. Set up Android emulator or connect physical device
4. Enable USB debugging on your Android device

---

## Project Architecture

### High-Level Overview

Synth-VIB3+ uses a **bidirectional coupling architecture** where visual and audio parameters influence each other in real-time at 60 FPS.

```
┌─────────────────┐         ┌──────────────────┐
│                 │         │                  │
│  VIB3+ Visual   │ ◄─────► │  Audio Synthesis │
│  System         │         │  Engine          │
│                 │         │                  │
└────────┬────────┘         └────────┬─────────┘
         │                           │
         └───────────┬───────────────┘
                     │
              ┌──────▼──────┐
              │ Parameter   │
              │ Bridge      │
              │ (60 FPS)    │
              └─────────────┘
```

### Key Components

#### 1. **Audio System** (`lib/audio/`)
- `synthesizer_engine.dart` - Legacy dual-oscillator engine
- `audio_analyzer.dart` - FFT analysis for audio reactivity

#### 2. **Synthesis System** (`lib/synthesis/`)
- `synthesis_branch_manager.dart` - Routes geometry to Direct/FM/Ring Mod
- Implements the 3D matrix system (3 × 3 × 8 = 72 combinations)

#### 3. **Visual System** (`lib/visual/`)
- `vib34d_widget.dart` - WebView integration for VIB3+ engine
- `vib34d_native_bridge.dart` - Flutter ↔ JavaScript communication

#### 4. **Parameter Mapping** (`lib/mapping/`)
- `parameter_bridge.dart` - Bidirectional coupling orchestrator
- `audio_to_visual.dart` - FFT → visual modulation
- `visual_to_audio.dart` - 6D rotation → synthesis modulation

#### 5. **State Management** (`lib/providers/`)
- `audio_provider.dart` - Audio system state
- `visual_provider.dart` - VIB3+ visual parameters
- `ui_state_provider.dart` - UI state and interactions

#### 6. **UI Components** (`lib/ui/`)
- `components/` - Reusable UI widgets (sliders, pads, orb controller)
- `panels/` - Feature panels (synthesis, geometry, effects, mapping)
- `theme/` - Holographic theme system
- `screens/` - Main application screens

### The 3D Matrix System

The core concept: **3 × 3 × 8 = 72 unique combinations**

1. **Visual System** (3 options) → **Sound Family**
   - Quantum: Pure harmonic (sine-dominant)
   - Faceted: Geometric hybrid (balanced spectrum)
   - Holographic: Spectral rich (complex overtones)

2. **Polytope Core** (3 options) → **Synthesis Branch**
   - Base (geo 0-7): Direct synthesis
   - Hypersphere (geo 8-15): FM synthesis
   - Hypertetrahedron (geo 16-23): Ring modulation

3. **Base Geometry** (8 options) → **Voice Character**
   - Tetrahedron (0): Fundamental, pure
   - Hypercube (1): Complex, chorused
   - Sphere (2): Smooth, filtered
   - Torus (3): Cyclic, rhythmic
   - Klein Bottle (4): Twisted, spatial
   - Fractal (5): Recursive, evolving
   - Wave (6): Flowing, sweeping
   - Crystal (7): Crystalline, percussive

**Geometry Index Calculation**:
```dart
int geometryIndex = 0-23;  // User selection
int coreIndex = geometryIndex ~/ 8;  // 0, 1, or 2
int baseGeometry = geometryIndex % 8;  // 0-7
```

---

## Development Workflow

### Branch Strategy

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`claude/*`**: AI-assisted development branches
- **`feature/*`**: New feature branches
- **`fix/*`**: Bug fix branches

### Commit Message Format

Use semantic commit messages:

```
<type>(<scope>): <subject>

[optional body]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `perf`: Performance improvement
- `refactor`: Code refactoring
- `docs`: Documentation changes
- `test`: Adding/updating tests
- `chore`: Build/tooling changes

**Examples**:
```
feat(synthesis): add ring modulation engine for hypertetrahedron core
fix(audio): resolve buffer underrun on low-end devices
perf(mapping): optimize parameter bridge to maintain 60 FPS
docs(arch): update architecture diagram with synthesis branches
```

### Daily Development Cycle

1. **Pull latest changes**
   ```bash
   git pull origin develop
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make changes with tests**
   - Write failing test first (TDD)
   - Implement feature
   - Ensure tests pass

4. **Run quality checks**
   ```bash
   flutter analyze
   flutter test
   dart format .
   ```

5. **Commit and push**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   git push origin feature/your-feature-name
   ```

6. **Create pull request**
   - Link to relevant issues
   - Add description of changes
   - Request review

---

## Code Quality Standards

### Linting

The project uses comprehensive linting rules defined in `analysis_options.yaml`.

**Key rules**:
- `always_specify_types` - Explicit type annotations
- `prefer_const_constructors` - Performance optimization
- `avoid_print` - Use `Logger` instead
- `lines_longer_than_80_chars` - Code readability

**Run analyzer**:
```bash
flutter analyze
```

**Auto-fix issues**:
```bash
dart fix --apply
```

### Code Formatting

Use `dart format` with 80-character line limit:

```bash
# Format all Dart files
dart format .

# Check formatting without changes
dart format --set-exit-if-changed .
```

### Type Safety

This project enforces **strict type safety**:

```yaml
# analysis_options.yaml
analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
```

**Always specify types explicitly**:

✅ **Good**:
```dart
final List<double> buffer = Float32List(512);
final Map<String, int> counters = {};
```

❌ **Bad**:
```dart
final buffer = Float32List(512);  // Implicit type
final counters = {};  // Dynamic type
```

---

## Testing Guidelines

### Test Structure

Tests are organized to mirror `lib/` structure:

```
test/
├── audio/
│   └── synthesizer_engine_test.dart
├── synthesis/
│   └── synthesis_branch_manager_test.dart
├── mapping/
│   └── parameter_bridge_test.dart
└── widget_test.dart
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/synthesis/synthesis_branch_manager_test.dart

# Run tests matching name
flutter test --name="Synthesis"
```

### Test Guidelines

1. **Unit Tests**: Test individual classes/functions
2. **Widget Tests**: Test UI components
3. **Integration Tests**: Test full workflows
4. **Performance Tests**: Measure audio latency, FPS

**Example test structure**:

```dart
void main() {
  group('SynthesisBranchManager', () {
    late SynthesisBranchManager manager;

    setUp(() {
      manager = SynthesisBranchManager(sampleRate: 44100.0);
    });

    test('should accept valid geometry indices', () {
      for (int i = 0; i < 24; i++) {
        expect(() => manager.setGeometry(i), returnsNormally);
      }
    });

    test('should generate audio within bounds', () {
      manager.noteOn();
      final buffer = manager.generateBuffer(512, 440.0);

      for (final sample in buffer) {
        expect(sample, greaterThanOrEqualTo(-1.0));
        expect(sample, lessThanOrEqualTo(1.0));
      }
    });
  });
}
```

### Coverage Goals

- **Minimum**: 70% coverage
- **Target**: 85% coverage
- **Critical paths** (audio engine, synthesis): 95%+

---

## Performance Optimization

### Real-Time Audio Requirements

- **Audio Latency**: < 10ms target
- **Visual FPS**: 60 FPS minimum
- **Parameter Update Rate**: 60 Hz
- **Sample Rate**: 44100 Hz
- **Buffer Size**: 512 samples

### Performance Monitoring

Use the built-in `Logger` for performance tracking:

```dart
import 'package:synther_vib34d_holographic/utils/logger.dart';

// Time an operation
final timer = Logger.startTimer('audio_generation');
generateAudioBuffer();
timer.stop();

// Log audio latency
Logger.audioLatency('buffer_generation', latencyMs);

// Log frame rate
Logger.frameRate(currentFPS);
```

### Optimization Techniques

#### 1. **Const Constructors**

Use `const` wherever possible to avoid rebuilds:

```dart
// ✅ Good
const SizedBox(height: 16.0)

// ❌ Bad
SizedBox(height: 16.0)
```

#### 2. **Avoid Allocations in Audio Thread**

Never allocate objects in `generateBuffer()`:

```dart
// ✅ Good - reuse buffer
final _buffer = Float32List(512);
void generateBuffer() {
  for (int i = 0; i < _buffer.length; i++) {
    _buffer[i] = ...;
  }
}

// ❌ Bad - allocates every call
Float32List generateBuffer() {
  return Float32List(512);
}
```

#### 3. **Minimize Widget Rebuilds**

Use `RepaintBoundary` for complex visuals:

```dart
RepaintBoundary(
  child: VIB34DWidget(),
)
```

#### 4. **Profile Before Optimizing**

Always profile to find real bottlenecks:

```bash
flutter run --profile
```

Then use DevTools to identify issues.

---

## Audio-Specific Best Practices

### 1. **Thread Safety**

Audio generation may run on a separate thread. Avoid:
- Accessing UI state directly
- File I/O operations
- Network calls
- Heavy computations

### 2. **Buffer Management**

**Always**:
- Clamp samples to [-1.0, 1.0]
- Pre-allocate buffers
- Reuse buffers where possible

```dart
// Clamp output
buffer[i] = sample.clamp(-1.0, 1.0);
```

### 3. **Parameter Smoothing**

Smooth abrupt parameter changes to avoid clicks:

```dart
// Exponential smoothing
_smoothedValue += (_targetValue - _smoothedValue) * 0.1;
```

### 4. **Band-Limited Synthesis**

Prevent aliasing with band-limited waveforms:

```dart
// Use additive synthesis instead of naive square wave
double generateSquare(double phase) {
  double sample = 0.0;
  for (int h = 1; h <= 7; h += 2) {
    sample += sin(phase * h) / h;
  }
  return sample * 0.7;
}
```

### 5. **Logging in Audio Code**

**Never** use `print()` in audio code. Use `Logger` sparingly:

```dart
// ❌ Bad - kills performance
print('Generated buffer');

// ✅ Good - only in debug, infrequent
if (kDebugMode && frameCount % 60 == 0) {
  Logger.debug('Audio stats', category: LogCategory.audio);
}
```

---

## Debugging Techniques

### Audio Debugging

1. **Visualize Audio Buffer**
   - Plot waveform in debug UI
   - Check for discontinuities, DC offset

2. **Check Sample Rates**
   ```dart
   assert(sampleRate == 44100.0, 'Sample rate mismatch');
   ```

3. **Monitor Buffer Underruns**
   - Log when buffer isn't ready in time

4. **Test with Pure Tones**
   ```dart
   // Generate 440 Hz sine wave for testing
   void testAudio() {
     for (int i = 0; i < buffer.length; i++) {
       buffer[i] = sin(2.0 * pi * 440.0 * i / sampleRate);
     }
   }
   ```

### Visual Debugging

1. **Flutter DevTools**
   - Widget Inspector
   - Performance overlay
   - Memory profiler

2. **Enable Performance Overlay**
   ```dart
   MaterialApp(
     showPerformanceOverlay: true,
     // ...
   );
   ```

3. **Log Visual Parameters**
   ```dart
   Logger.debug(
     'Visual state',
     category: LogCategory.visual,
     metadata: {
       'rotation_xy': rotationXY,
       'morph': morphValue,
     },
   );
   ```

---

## Contributing Guidelines

### Code Review Checklist

Before submitting a PR:

- [ ] All tests pass (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Code is formatted (`dart format .`)
- [ ] Performance targets met (audio < 10ms, visual 60 FPS)
- [ ] Documentation updated
- [ ] Commit messages follow conventions
- [ ] No `print()` statements in production code

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Performance improvement
- [ ] Refactoring
- [ ] Documentation

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing performed
- [ ] Performance tested on device

## Checklist
- [ ] Tests pass
- [ ] No analyzer warnings
- [ ] Code formatted
- [ ] Documentation updated
```

---

## Additional Resources

- **Flutter Documentation**: https://docs.flutter.dev
- **Dart Language Tour**: https://dart.dev/guides/language/language-tour
- **Audio Plugin Documentation**: Check pubspec.yaml for package docs
- **Project Architecture**: See `ARCHITECTURE.md`
- **Project Status**: See `PROJECT_STATUS.md`

---

**A Paul Phillips Manifestation**
Paul@clearseassolutions.com
"The Revolution Will Not be in a Structured Format"
© 2025 Paul Phillips - Clear Seas Solutions LLC
