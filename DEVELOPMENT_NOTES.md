# Synth-VIB3+ Development Notes

## Native VIB3+ 4D Visualizer Implementation

This document summarizes the native Dart implementation of the VIB3+ 4D holographic visualizer, replacing the WebView-based approach.

---

## Architecture Overview

### The 3D Matrix System (72 Unique Combinations)

```
Level 1: Visual System (3) → Sound Family
├── Quantum:     Pure harmonic synthesis (sine, high Q: 8-12)
├── Faceted:     Geometric hybrid (square/triangle, moderate Q: 4-8)
└── Holographic: Spectral rich (sawtooth/wavetable, low Q: 2-4)

Level 2: Polytope Core (3) → Synthesis Branch
├── Base (0-7):            Direct synthesis with filtering
├── Hypersphere (8-15):    FM synthesis
└── Hypertetrahedron (16-23): Ring modulation

Level 3: Base Geometry (8) → Voice Character
├── 0: Tetrahedron  - Fundamental, minimal filtering
├── 1: Hypercube    - Complex, dual oscillators with detune
├── 2: Sphere       - Smooth, filtered harmonics
├── 3: Torus        - Cyclic, rhythmic phase modulation
├── 4: Klein Bottle - Twisted, asymmetric stereo
├── 5: Fractal      - Recursive, self-modulating
├── 6: Wave         - Flowing, sweeping filters
└── 7: Crystal      - Crystalline, sharp attack transients
```

**Total Combinations:** 3 Systems × 3 Cores × 8 Geometries = 72 unique sound+visual states

---

## Key Files Modified

### 1. `lib/vib3/` - Native VIB3+ Engine

| File | Purpose |
|------|---------|
| `core/vib3_engine.dart` | Core engine with `VisualSystem` enum, `AudioReactivityData` |
| `geometry/geometry_library.dart` | Shared `BaseGeometry`, `CoreVariant`/`PolytopeCor` enums |
| `widget/vib3_widget.dart` | Flutter `CustomPainter` for native 4D rendering |
| `math/rotation_4d.dart` | 6D rotation matrices (XY, XZ, YZ, XW, YW, ZW) |
| `rendering/vib3_native_renderer.dart` | Stereographic 4D→3D→2D projection |

### 2. `lib/providers/`

| File | Changes |
|------|---------|
| `visual_provider.dart` | Added 6D rotation (XY, XZ, YZ planes), saturation property |
| `audio_provider.dart` | Uses native `AudioReactivityData` directly (no conversion) |

### 3. `lib/audio/`

| File | Changes |
|------|---------|
| `audio_analyzer.dart` | Returns `AudioReactivityData` natively |
| `synthesizer_engine.dart` | Added stereoWidth, noiseInjection, LFO (rate/depth) |

### 4. `lib/mapping/`

| File | Purpose |
|------|---------|
| `audio_to_visual.dart` | FFT → visual modulation (bass→speed, mid→density, etc.) |
| `visual_to_audio.dart` | 6D rotation → synth params (complete slider mappings) |
| `parameter_bridge.dart` | Central 60 FPS bidirectional coupling |

### 5. `lib/ui/screens/synth_main_screen.dart`

Changed from WebView to native `VIB3Widget`:
```dart
import '../../vib3/widget/vib3_widget.dart';

Widget _buildVisualizationLayer(BuildContext context) {
  return Consumer2<VisualProvider, AudioProvider>(
    builder: (context, visualProvider, audioProvider, child) {
      return VIB3Widget(
        system: visualProvider.currentSystemEnum,
        geometryIndex: visualProvider.geometryIndex,
        audioData: audioProvider.currentFeatures,
        onStateChanged: (state) {
          // Sync all 6 rotations back to provider
          visualProvider.setRotationXY(state.rotationXY);
          visualProvider.setRotationXZ(state.rotationXZ);
          visualProvider.setRotationYZ(state.rotationYZ);
          visualProvider.setRotationXW(state.rotationXW);
          visualProvider.setRotationYW(state.rotationYW);
          visualProvider.setRotationZW(state.rotationZW);
        },
      );
    },
  );
}
```

---

## Parameter Mappings

### Visual → Audio (All Sliders Connected)

| Visual Parameter | Audio Effect | Range |
|-----------------|--------------|-------|
| Rotation XY | Oscillator 1 detune | ±12 cents |
| Rotation XZ | Oscillator 2 detune | ±12 cents |
| Rotation YZ | Combined detuning | ±7 cents |
| Rotation XW | FM depth (Hypersphere only) | 0-2 semitones |
| Rotation YW | Ring mod depth (Hypertetrahedron only) | 0-100% |
| Rotation ZW | Filter cutoff modulation | ±40% |
| Morph | Waveform crossfade | 0-1 |
| Chaos (rgbSplit) | Noise injection | 0-30% |
| Speed | LFO rate | 0.1-10 Hz |
| Hue Shift | Spectral tilt (filter brightness) | 500-4500 Hz |
| Glow Intensity | Reverb mix + attack time | 5-60% / 1-100ms |
| Density | Voice count | 1-8 voices |
| Saturation | Filter resonance | 0.1-0.9 |
| Vertex Brightness | Harmonic intensity | 0.3-1.0 |

### Audio → Visual

| Audio Feature | Visual Effect | Range |
|--------------|---------------|-------|
| Bass Energy (20-250 Hz) | Rotation speed | 0.5x-2.5x |
| Mid Energy (250-2000 Hz) | Tessellation density | 3-8 |
| High Energy (2000-8000 Hz) | Vertex brightness | 0.5-1.0 |
| Spectral Centroid | Hue shift | 0-360° |
| RMS Amplitude | Glow intensity | 0-3 |

---

## Shared Type System

All types are now defined once and imported everywhere:

```dart
// From vib3_engine.dart
enum VisualSystem { quantum, faceted, holographic }

class AudioReactivityData {
  final double bassEnergy;
  final double midEnergy;
  final double highEnergy;
  final double rmsAmplitude;
  final double spectralCentroid;
}

// From geometry_library.dart
enum BaseGeometry { tetrahedron, hypercube, sphere, torus, kleinBottle, fractal, wave, crystal }
enum CoreVariant { base, hypersphere, hypertetrahedron }
typedef PolytopeCor = CoreVariant;  // Alias for synthesis compatibility
```

**Usage in other files:**
```dart
import '../vib3/core/vib3_engine.dart' show VisualSystem, AudioReactivityData;
import '../vib3/geometry/geometry_library.dart' show PolytopeCor, BaseGeometry;
```

---

## SynthesizerEngine Enhancements

### New Features Added

1. **Stereo Width** (`lib/audio/synthesizer_engine.dart:73`)
   - Maps to rgbSplit visual parameter
   - Creates pseudo-stereo via oscillator detuning (±5 cents)

2. **Noise Injection** (`lib/audio/synthesizer_engine.dart:82-84`)
   - Maps to chaos visual parameter
   - Adds 0-30% white noise to synth output

3. **LFO (Low Frequency Oscillator)** (`lib/audio/synthesizer_engine.dart:86-89`)
   - Maps to rotation speed
   - Rate: 0.1-10 Hz
   - Modulates oscillator frequency and filter cutoff

### API Methods

```dart
synth.setStereoWidth(0.5);     // 0-1, from rgbSplit
synth.setNoiseLevel(0.15);     // 0-0.3 (30% max), from chaos
synth.setLFORate(2.0);         // 0.1-10 Hz, from rotation speed
synth.setLFODepth(0.5);        // 0-1, modulation intensity
```

---

## Visual Provider Updates

### New Properties

| Property | Range | Purpose |
|----------|-------|---------|
| `_saturation` | 0-1 | Color saturation (was hardcoded 0.7) |
| `_rotationXY` | 0-2π | XY plane rotation → Osc1 detune |
| `_rotationXZ` | 0-2π | XZ plane rotation → Osc2 detune |
| `_rotationYZ` | 0-2π | YZ plane rotation → Combined detune |
| `_tessellationDensity` | 2-30 | Grid density (changed from 3-8) |

### Getters and Setters

```dart
double get saturation => _saturation;
void setSaturation(double sat) {
  _saturation = sat.clamp(0.0, 1.0);
  _updateJavaScriptParameter('saturation', _saturation);
  notifyListeners();
}
```

---

## Commits Summary

| Commit | Description |
|--------|-------------|
| `cb32460` | Integrate native VIB3+ visualizer with full bidirectional audio coupling |
| `2ef45a0` | Add VIB3+ unit tests and CI testing pipeline |
| `99f2573` | Consolidate type system: native audio format and shared geometry enums |
| `7037d54` | Add complete visual slider → audio parameter mappings |
| `5ba0ac3` | Fix density/gridDensity range to 2-30 |
| `a9715a9` | Add saturation, stereoWidth, noiseInjection, and LFO to audio-visual coupling |

---

## Testing

Unit tests are in `test/vib3/`:

- `vib3_engine_test.dart` - Engine initialization and state management
- `geometry_library_test.dart` - Polytope generation and vertex counts
- `audio_reactive_modulator_test.dart` - Audio reactivity calculations

All 28 VIB3 unit tests pass.

---

## Pending/Future Work

1. **Stereo Audio Output** - Currently using pseudo-stereo via detuning; true stereo requires dual buffer generation
2. **Wavetable Morphing** - Currently linear sine→saw; could add more complex wavetables
3. **Visual System Effects** - Per-system post-processing shaders (glow for Quantum, scanlines for Holographic)

---

*A Paul Phillips Manifestation*
*© 2025 Paul Phillips - Clear Seas Solutions LLC*
