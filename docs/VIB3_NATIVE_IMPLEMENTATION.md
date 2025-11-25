# VIB3+ Native Flutter Implementation

## Overview

The VIB3+ visualization system has been fully ported from JavaScript/WebView to native Flutter/Dart. This eliminates the WebView dependency and provides better performance, lower latency, and deeper integration with the audio synthesis engine.

## Architecture

### Core Mathematics (`lib/vib3/math/`)

#### `quaternion.dart`
- Complete quaternion implementation for spatial rotations
- Support for Euler angle conversion, SLERP interpolation, angular velocity
- Ported from vib34d-vib3plus SDK quaternion.dart

#### `rotation_4d.dart`
- Full 6D rotation system (XY, XZ, YZ, XW, YW, ZW planes)
- 4D→3D→2D projection pipeline
- Stereographic and perspective projection methods

### Geometry System (`lib/vib3/geometry/`)

#### `geometry_library.dart`
- Manages all 24 geometry configurations (8 base types × 3 cores)
- Provides metadata, variation parameters, and index encoding/decoding
- **8 Base Geometries:**
  1. Tetrahedron (5-cell / 4-simplex)
  2. Hypercube (Tesseract / 8-cell)
  3. Sphere (4D hypersphere approximation)
  4. Torus (4D hypertorus with double-rotation)
  5. Klein Bottle (non-orientable 4D surface)
  6. Fractal (recursive 4D structure)
  7. Wave (sinusoidal 4D pattern)
  8. Crystal (24-cell regular polytope)

- **3 Core Variants:**
  - Base (geometries 0-7): Direct synthesis
  - Hypersphere (geometries 8-15): FM synthesis
  - Hypertetrahedron (geometries 16-23): Ring modulation

#### `polytope_generator.dart`
- Generates vertices and edges for all 8 base geometries
- Each geometry has unique 4D structure and connectivity
- Returns `Polytope` objects with vertices (Vector4) and edges

### Rendering (`lib/vib3/rendering/`)

#### `vib3_native_renderer.dart`
- Production CustomPainter implementation
- Supports 3 visualization systems:
  - **Quantum**: Pure harmonic aesthetic (high contrast, single bright layer)
  - **Holographic**: Multi-layer depth field (5 layers at different W-depths)
  - **Faceted**: Geometric hybrid (dual-layer structure + highlights)
- Audio-reactive modulation (bass, mid, high, RMS)
- Depth-based rendering (closer vertices are brighter/larger)
- Glow effects with MaskFilter blur

### Widget Integration (`lib/vib3/`)

#### `vib3_native_widget.dart`
- Stateful widget that manages animation ticker
- 60 FPS rendering loop
- FPS tracking and reporting
- Audio reactivity integration (smoothed with exponential moving average)
- Real-time parameter updates from VisualProvider and AudioProvider

## Integration Points

### VisualProvider
The native renderer reads all parameters from `VisualProvider`:
- System selection (quantum/holographic/faceted)
- Geometry index (0-23)
- 4D rotation angles (XW, YW, ZW)
- Visual parameters (rotation speed, tessellation, brightness, hue, glow, etc.)
- Projection parameters (distance, layer separation)

### AudioProvider
Audio reactivity values (currently placeholder, ready for FFT integration):
- Bass energy (20-250 Hz)
- Mid energy (250-2000 Hz)
- High energy (2000-8000 Hz)
- RMS amplitude

### ParameterBridge
The 60 FPS parameter bridge (`lib/mapping/parameter_bridge.dart`) orchestrates bidirectional coupling:
- Audio → Visual: FFT modulates rotation speed, tessellation, brightness
- Visual → Audio: Rotation angles modulate detuning, FM depth, filter cutoff

## Performance

### Target Metrics
- **Visual FPS**: 60 minimum (tracked and displayed)
- **Audio latency**: <10ms (native synthesis engine)
- **Parameter update rate**: 60 Hz (matches visual frame rate)

### Optimization Strategies
1. **CustomPainter**: Direct Canvas rendering, no widget rebuilds
2. **shouldRepaint**: Only repaints when necessary parameters change
3. **Geometry caching**: Polytopes generated once, rotated per-frame
4. **Depth-based culling**: Could add back-face culling for complex geometries
5. **Edge batching**: All edges drawn in single pass per layer

## Usage

### Basic Integration
```dart
import 'package:synth_vib3_plus/vib3/vib3.dart';

// In your widget tree
VIB3NativeWidget()
```

### With Providers
```dart
Consumer2<VisualProvider, AudioProvider>(
  builder: (context, visualProvider, audioProvider, child) {
    return VIB3NativeWidget();
  },
)
```

### Switching Systems
```dart
visualProvider.switchSystem('quantum');   // or 'holographic', 'faceted'
```

### Switching Geometries
```dart
visualProvider.setGeometry(5);  // 0-23
```

### Modulating Parameters
```dart
// Visual → Audio
final rotationAngle = visualProvider.getRotationAngle('XW');
final morphParam = visualProvider.getMorphParameter();

// Audio → Visual
visualProvider.setRotationSpeed(1.5);
visualProvider.setTessellationDensity(7);
visualProvider.setHueShift(270.0);
```

## Development Status

### Completed ✅
- Full 4D mathematics system (quaternions, 6D rotations, projections)
- All 24 geometry generators
- Three visualization systems (Quantum, Holographic, Faceted)
- Native renderer with audio reactivity
- Integration with VisualProvider
- FPS tracking and display

### Pending 🔨
- FFT integration for real audio reactivity (currently using placeholders)
- Post-processing effects (RGB chromatic aberration)
- Advanced depth sorting for complex polytopes
- Geometry morphing animations
- Preset system for visual states
- Performance profiling on Android devices

## Testing

### Manual Testing Checklist
1. ✅ All 24 geometries render without crashes
2. ⏳ Each system (Quantum/Holographic/Faceted) has distinct visual character
3. ⏳ 4D rotations animate smoothly
4. ⏳ Audio reactivity modulates visuals
5. ⏳ 60 FPS maintained on target devices
6. ⏳ Parameter changes update in real-time
7. ⏳ No memory leaks during extended sessions

### Known Limitations
- No Flutter GPU shaders (using Canvas API instead)
- FFT analysis not yet connected (using placeholder values)
- ChromaticAberration effect not implemented (RGB split parameter exists but unused)
- Some complex geometries may need edge count optimization

## Migration Notes

### From WebView to Native

**Before:**
```dart
import '../../visual/vib34d_widget.dart';

VIB34DWidget(
  visualProvider: visualProvider,
  audioProvider: audioProvider,
)
```

**After:**
```dart
import '../../vib3/vib3.dart';

VIB3NativeWidget()  // Providers accessed via Consumer/Provider.of
```

### Benefits
1. **No network dependency**: Doesn't load from GitHub Pages
2. **Lower latency**: Direct Dart rendering, no JavaScript bridge
3. **Better performance**: Native Canvas API vs WebGL in WebView
4. **Deeper integration**: Direct access to Provider state
5. **Offline capable**: No internet required
6. **Smaller bundle**: No need to embed VIB3+ HTML/JS assets

## References

- **Source SDK**: [vib34d-vib3plus](https://github.com/Domusgpt/vib34d-vib3plus/tree/claude/add-flutter-dart-support-01WiDt1H7XB1FTsuQy3i2jZa)
- **Geometry Library**: `lib/src/geometry/geometry_library.dart` (Dart port)
- **Polychora System**: `src/core/PolychoraSystem.js` (shader-based, adapted to vertex-based)
- **Canvas Renderer**: `lib/src/web/canvas_renderer.dart` (inspiration for projection)

---

**Implementation**: Claude AI (Anthropic)
**Date**: 2025-01-20
**Project**: Synth-VIB3+ by Paul Phillips

"The Revolution Will Not be in a Structured Format"
