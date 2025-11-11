# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Synth-VIB3+ is a unified audio-visual synthesizer for Flutter/Android that couples VIB3+ 4D holographic visualization with multi-branch synthesis. Every visual parameter controls BOTH visual and sonic aspects simultaneously through a bidirectional parameter bridge running at 60 FPS.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Build Android APK
flutter build apk --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Clean build artifacts (helpful when build directory causes slowness)
flutter clean
```

## Architecture: The 3D Matrix System

The system combines three hierarchical dimensions to create 72 unique sound+visual combinations:

### Three Levels of Control

1. **Visual System** (3 options) → **Sound Family** (timbre character)
   - Quantum: Pure harmonic synthesis (sine waves, high resonance Q: 8-12)
   - Faceted: Geometric hybrid synthesis (square/triangle waves, moderate Q: 4-8)
   - Holographic: Spectral rich synthesis (sawtooth/wavetable, low Q: 2-4, high reverb)

2. **Polytope Core** (3 options) → **Synthesis Branch** (synthesis method)
   - Base (geometries 0-7): Direct synthesis with filtering
   - Hypersphere (geometries 8-15): FM synthesis
   - Hypertetrahedron (geometries 16-23): Ring modulation

3. **Base Geometry** (8 options) → **Voice Character** (envelope, reverb, harmonics)
   - Tetrahedron (0): Fundamental, minimal filtering
   - Hypercube (1): Complex, dual oscillators with detune
   - Sphere (2): Smooth, filtered harmonics
   - Torus (3): Cyclic, rhythmic phase modulation
   - Klein Bottle (4): Twisted, asymmetric stereo
   - Fractal (5): Recursive, self-modulating
   - Wave (6): Flowing, sweeping filters
   - Crystal (7): Crystalline, sharp attack transients

### Geometry Index Calculation

```dart
int geometryIndex = 0-23;  // User-selected geometry
int coreIndex = geometryIndex ~/ 8;  // 0=Base, 1=Hypersphere, 2=Hypertetrahedron
int baseGeometry = geometryIndex % 8;  // 0-7 (Tetrahedron through Crystal)

// Example: geometryIndex 11 = Hypersphere Torus
// coreIndex = 11 ~/ 8 = 1 (Hypersphere = FM synthesis)
// baseGeometry = 11 % 8 = 3 (Torus = cyclic voice character)
```

## Core Architecture Components

### Bidirectional Parameter Flow

The `ParameterBridge` (`lib/mapping/parameter_bridge.dart`) orchestrates all parameter coupling at 60 FPS:

- **Audio → Visual**: FFT analysis modulates visual rotation speed, tessellation density, vertex brightness, hue shift, and glow intensity
- **Visual → Audio**: 6D rotation modulates detuning, FM/ring mod depth, filter cutoff; morph controls waveform crossfade; chaos adds noise injection

### Key Files and Their Roles

```
lib/
├── main.dart                              # App entry, provider setup, main UI
├── providers/
│   ├── audio_provider.dart                # Audio system state management
│   └── visual_provider.dart               # VIB3+ visual parameter state
├── mapping/
│   ├── parameter_bridge.dart              # Central 60 FPS bidirectional coupling
│   ├── audio_to_visual.dart               # FFT → visual modulation
│   └── visual_to_audio.dart               # Quaternion/geometry → synthesis
├── audio/
│   ├── synthesizer_engine.dart            # Core synthesis (oscillators, filter, effects)
│   └── audio_analyzer.dart                # FFT analysis for audio reactivity
├── synthesis/
│   └── synthesis_branch_manager.dart      # Routes geometry to Direct/FM/RingMod
├── visual/
│   ├── vib34d_widget.dart                 # WebView integration for VIB3+ engine
│   └── vib34d_native_bridge.dart          # Flutter ↔ JavaScript communication
└── models/
    ├── visual_state.dart                  # Visual parameter data structures
    ├── synth_patch.dart                   # Synthesis preset data
    └── mapping_preset.dart                # Bidirectional mapping configurations
```

### The VIB3+ WebView System

VIB3+ runs as a WebGL visualization inside a Flutter WebView. Communication happens through JavaScript message passing:

- Flutter → JS: Send visual parameter updates via `webViewController.runJavaScript()`
- JS → Flutter: Visual state changes trigger callbacks to `VisualProvider`
- All VIB3+ source files are in `assets/src/`, `assets/js/`, `assets/styles/`

## Parameter Mappings Reference

### Visual Controls Audio

| Visual Parameter | Audio Effect |
|-----------------|--------------|
| XY Rotation | Oscillator 1 detune (±12 cents) |
| XZ Rotation | Oscillator 2 detune (±12 cents) |
| YZ Rotation | Combined detuning (±7 cents) |
| XW Rotation | FM depth (0-2 semitones) - Hypersphere only |
| YW Rotation | Ring mod depth (0-100%) - Hypertetrahedron only |
| ZW Rotation | Filter cutoff modulation (±40%) |
| Morph | Waveform crossfade |
| Chaos | Noise injection (0-30%) + filter randomization |
| Speed | LFO rate for all modulations (0.1-10 Hz) |
| Hue Shift | Spectral tilt (brightness filter) |
| Glow Intensity | Reverb mix (5-60%) + attack time (1-100ms) |
| Tessellation Density | Voice count/polyphony (1-8 voices) |

### Audio Controls Visual

| Audio Feature | Visual Effect |
|--------------|---------------|
| Bass Energy (20-250 Hz) | Rotation speed (0.5x-2.5x) |
| Mid Energy (250-2000 Hz) | Tessellation density (3-8) |
| High Energy (2000-8000 Hz) | Vertex brightness (0.5-1.0) |
| Spectral Centroid | Hue shift (dark→red, bright→cyan) |
| RMS Amplitude | Glow intensity |

## Implementation Status

See `PROJECT_STATUS.md` for current development phase. As of creation:

- Phase 1 (Core System): IN PROGRESS - synthesis branch manager under development
- Phase 2 (Parameter Mapping): NOT STARTED
- Phase 3 (UI Integration): NOT STARTED
- Phase 4 (Polish & Testing): NOT STARTED

## Development Notes

### Platform Support

- **Primary**: Android (phone/tablet)
- **Development**: Linux/WSL
- **Blocked**: Web builds (Firebase package conflicts)

### Performance Targets

- Visual FPS: 60 minimum
- Audio latency: <10ms
- Parameter update rate: 60 Hz (matches visual frame rate)
- Sample rate: 44100 Hz
- Buffer size: 512 samples

### Firebase Integration

Firebase is configured for preset cloud sync:
- `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage` in `pubspec.yaml`
- Android permissions configured in `android/app/src/main/AndroidManifest.xml`
- Web builds fail due to Firebase web compatibility - use Android device for testing

### Critical Architecture Patterns

1. **All visual parameters are dual-purpose**: Every visual control MUST affect both rendering and synthesis
2. **60 FPS parameter bridge**: The `ParameterBridge` timer loop is the heartbeat of the entire system
3. **Three-level synthesis routing**: Always calculate `coreIndex` and `baseGeometry` from `geometryIndex` to route to correct synthesis branch and apply voice character
4. **Audio reactivity is always on**: This is a core feature, not a toggle (UI may need adjustment)

### State Management

Uses Provider pattern with three main providers:
- `AudioProvider`: Manages `SynthesizerEngine` and audio playback
- `VisualProvider`: Manages VIB3+ visual state and WebView communication
- `ParameterBridge`: Orchestrates bidirectional flow between the two

## Testing

Tests are in `test/`. The main test file is `test/widget_test.dart`.

When adding new synthesis engines or parameter mappings, verify:
1. All 72 combinations (3 systems × 24 geometries) have unique sonic+visual character
2. Parameter changes update at 60 Hz without dropping frames
3. Audio latency remains <10ms
4. No crackling or discontinuities in audio output

---

A Paul Phillips Manifestation
Paul@clearseassolutions.com
"The Revolution Will Not be in a Structured Format"
© 2025 Paul Phillips - Clear Seas Solutions LLC
