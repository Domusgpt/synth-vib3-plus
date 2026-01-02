# VIB3-CORE Complete System Analysis

## Source: https://github.com/Domusgpt/Vib3-CORE-Documented01-

This document provides a comprehensive analysis of the VIB3-CORE visualization system for porting to native Flutter/Dart.

---

## 1. SYSTEM OVERVIEW

VIB3-CORE is a browser-based WebGL visualization platform with **3 core visual systems**:

| System | Primary Effect | Key Characteristic |
|--------|---------------|-------------------|
| **Quantum** | Extreme color layers | 5 canvas layers, RGB separation |
| **Faceted** | Geometric edges | Dual-layer edge/fill, sharp facets |
| **Holographic** | Multi-layer depth | Chromatic aberration, interference patterns |

> **Note:** Polychora exists as a placeholder/experimental mode in the codebase but is not a production system. Implementation focuses on the 3 core systems above.

---

## 2. RENDERING ARCHITECTURE

### 2.1 Core Technology Stack

- **Rendering**: WebGL fragment shaders (NOT traditional vertex geometry)
- **Approach**: Full-screen quad with per-pixel computation
- **Projection**: 4D → 3D via perspective division: `w = 2.5 / (2.5 + p.w)`
- **Geometry**: Signed Distance Fields (SDF) computed per-pixel

### 2.2 Shader Pipeline

```
1. Vertex Shader: Minimal pass-through for full-screen quad
   attribute vec2 a_position;
   void main() { gl_Position = vec4(a_position, 0.0, 1.0); }

2. Fragment Shader: ALL computation happens here
   - 6D rotation matrices applied
   - SDF geometry calculation
   - Color and effect compositing
   - Output: gl_FragColor
```

### 2.3 Frame Loop

```javascript
render() {
    // 1. Clear framebuffer
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    // 2. Update 20+ uniforms (time, rotations, parameters)
    gl.uniform1f(u_time, time);
    gl.uniform2f(u_resolution, width, height);
    // ... all other uniforms

    // 3. Draw full-screen quad
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    // 4. Request next frame
    requestAnimationFrame(render);
}
```

---

## 3. GEOMETRY SYSTEM

### 3.1 24 Geometries = 8 Base × 3 Cores

**Base Geometries (0-7):**
| Index | Name | SDF Description |
|-------|------|-----------------|
| 0 | Tetrahedron | 5-cell (4-simplex) distance |
| 1 | Hypercube | Tesseract (8-cell) box distance |
| 2 | Sphere | 4D hypersphere radial distance |
| 3 | Torus | Clifford torus dual-radius |
| 4 | Klein Bottle | Parametric non-orientable surface |
| 5 | Fractal | Recursive Menger sponge 4D |
| 6 | Wave | Sinusoidal interference pattern |
| 7 | Crystal | 24-cell octahedral symmetry |

**Core Modifications:**
| Core Index | Name | Effect |
|------------|------|--------|
| 0 (geom 0-7) | Base | Raw geometry, no modification |
| 1 (geom 8-15) | Hypersphere | FM-style: `sin(d*10 + time*2) * 0.1` modulation |
| 2 (geom 16-23) | Hypertetrahedron | Ring-mod: `sin(d*15) * cos(len*8) * 0.08` |

**Geometry Index Calculation:**
```dart
int geometryIndex = 0-23;
int baseGeometry = geometryIndex % 8;  // 0-7
int coreType = geometryIndex ~/ 8;     // 0=Base, 1=Hypersphere, 2=Hypertetrahedron
```

### 3.2 SDF Functions (from actual VIB3-CORE)

```glsl
// Tesseract (Hypercube)
float sdHypercube(vec4 p) {
    vec4 q = abs(p) - 1.0;
    float outside = length(max(q, 0.0));
    float inside = max(max(max(q.x, q.y), q.z), q.w);
    return outside + min(inside, 0.0);
}

// 24-Cell (Crystal)
float sdCrystal(vec4 p) {
    vec4 q = abs(p);
    float d = max(max(q.x + q.y, q.z + q.w), max(q.x + q.z, q.y + q.w)) - 1.2;
    return d;
}

// Clifford Torus
float sdTorus(vec4 p) {
    float r1 = 0.8, r2 = 0.3;
    vec2 q = vec2(length(p.xy) - r1, length(p.zw) - r1);
    return length(q) - r2;
}
```

---

## 4. ROTATION SYSTEM

### 4.1 Six Degrees of Freedom

VIB3-CORE implements complete 6D rotation in 4D space:

| Rotation | Planes | Range | Effect |
|----------|--------|-------|--------|
| XY | X-Y | ±6.28 rad | Standard 3D rotation |
| XZ | X-Z | ±6.28 rad | Standard 3D rotation |
| YZ | Y-Z | ±6.28 rad | Standard 3D rotation |
| XW | X-W | ±2.0 rad | 4D hyperspace rotation |
| YW | Y-W | ±2.0 rad | 4D hyperspace rotation |
| ZW | Z-W | ±2.0 rad | 4D hyperspace rotation |

### 4.2 Rotation Matrix Implementation

```glsl
mat4 rotateXW(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat4(
        c, 0, 0, -s,
        0, 1, 0,  0,
        0, 0, 1,  0,
        s, 0, 0,  c
    );
}

vec4 apply6DRotation(vec4 pos) {
    pos = rotateXY(u_rot4dXY + u_time * 0.08) * pos;
    pos = rotateXZ(u_rot4dXZ + u_time * 0.09) * pos;
    pos = rotateYZ(u_rot4dYZ + u_time * 0.07) * pos;
    pos = rotateXW(u_rot4dXW + u_time * 0.10) * pos;
    pos = rotateYW(u_rot4dYW + u_time * 0.11) * pos;
    pos = rotateZW(u_rot4dZW + u_time * 0.12) * pos;
    return pos;
}
```

---

## 5. VISUAL SYSTEMS IN DETAIL

### 5.1 Quantum System

**Architecture:** 5 independent canvas layers with extreme RGB separation

| Layer | Role | Base Colors | Effect Intensity |
|-------|------|-------------|------------------|
| 0 | Background | Deep purple/black/blue | 0.02 separation |
| 1 | Shadow | Toxic green/yellow-green | 0.08 separation |
| 2 | Content | Red/orange/white-hot | 0.15 separation |
| 3 | Highlight | Electric cyan/blue | 0.25 separation |
| 4 | Accent | Magenta/violet/hot-pink | 0.30 separation |

**RGB Separation Techniques:**
- Background: Smooth sinusoidal modulation
- Shadow: Heavy vertical scanline distortion
- Content: Radial angle-based separation
- Highlight: Lightning-pattern chaos
- Accent: Multi-directional turbulence

### 5.2 Holographic System

**Key Effects:**
- Multi-layer depth compositing (5-7 layers)
- Chromatic aberration: RGB channel offset based on distance
- Moiré interference: Dual-frequency sine waves
- Grid overlay with dynamic line frequency
- Holographic shimmer: Time-dependent sinusoidal modulation

```glsl
// Chromatic aberration
color.r *= 1.0 + sin(dist * 10.0 + time) * aberration;
color.g *= 1.0 + sin(dist * 10.0 + time + 2.09) * aberration;
color.b *= 1.0 + sin(dist * 10.0 + time + 4.18) * aberration;
```

### 5.3 Faceted System

**Dual-Layer Rendering:**
1. **Structure Layer** (background): Darker, thinner lines, 0.3 alpha
2. **Highlight Layer** (foreground): Bright, thick edges, full intensity

**Edge Detection:**
```glsl
float edge = 1.0 - smoothstep(0.0, edgeWidth, abs(dist));
float fill = smoothstep(0.1, 0.0, dist) * 0.3;  // Interior fill
```

### 5.4 Polychora System (PLACEHOLDER - NOT FOR IMPLEMENTATION)

> **Status:** Polychora is a placeholder/experimental mode. Do NOT implement.
> Focus implementation on the 3 core systems: Quantum, Faceted, Holographic.

The Polychora code in VIB3-CORE contains experimental 4D polytope rendering
but is not part of the production visualization system.

---

## 6. AUDIO-VISUAL SONIC PARITY

**CRITICAL:** Every visual control is PAIRED to an audio parameter. User can directly manipulate the visualizer, and those changes affect the synthesizer. Additionally, audio output drives visual reactivity via FFT analysis.

### Two-Way Coupling:

```
┌──────────────────────────────────────────────────────────────────┐
│                      BIDIRECTIONAL FLOW                           │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   1. VISUAL CONTROL → AUDIO (User touches/gestures visualizer)   │
│      ───────────────────────────────────────────────────────     │
│      Rotate geometry → Changes oscillator detune                  │
│      Pinch/zoom → Changes filter cutoff                          │
│      Swipe → Changes FM/Ring mod depth                           │
│      Morph gesture → Changes waveform blend                      │
│                                                                   │
│   2. AUDIO OUTPUT → VISUAL REACTIVITY (FFT-based, separate)      │
│      ───────────────────────────────────────────────────────     │
│      Bass energy → Rotation speed boost                          │
│      Mid energy → Grid density modulation                        │
│      High energy → Vertex brightness                             │
│      Spectral centroid → Hue shift                               │
│      RMS amplitude → Glow intensity                              │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

The 3 visual systems define the sonic character - when user selects a visual system, they're selecting a synthesis preset.

### 6.1 Visual System → Sound Family Mapping

| Visual System | Synthesis Type | Waveform | Filter Q | Reverb |
|--------------|----------------|----------|----------|--------|
| **Quantum** | Pure harmonic | Sine waves | High (8-12) | Low |
| **Faceted** | Geometric hybrid | Square/Triangle | Moderate (4-8) | Medium |
| **Holographic** | Spectral rich | Sawtooth/Wavetable | Low (2-4) | High |

### 6.2 Geometry → Synthesis Branch Mapping

| Core (geom ÷ 8) | Synthesis Branch | Audio Effect |
|-----------------|------------------|--------------|
| 0 (geom 0-7) | Direct synthesis | Filtering only |
| 1 (geom 8-15) | FM synthesis | Frequency modulation |
| 2 (geom 16-23) | Ring modulation | Amplitude modulation |

### 6.3 Visual Parameter → Audio Parameter Coupling

**Rotation → Oscillator/Modulation:**
| Visual Rotation | Audio Effect |
|-----------------|--------------|
| XY Rotation | Oscillator 1 detune (±12 cents) |
| XZ Rotation | Oscillator 2 detune (±12 cents) |
| YZ Rotation | Combined detuning (±7 cents) |
| XW Rotation | FM depth (0-2 semitones) - Hypersphere core only |
| YW Rotation | Ring mod depth (0-100%) - Hypertetrahedron core only |
| ZW Rotation | Filter cutoff modulation (±40%) |

**Other Visual → Audio:**
| Visual Parameter | Audio Effect |
|------------------|--------------|
| Morph | Waveform crossfade (between base shapes) |
| Chaos | Noise injection (0-30%) + filter randomization |
| Speed | LFO rate for all modulations (0.1-10 Hz) |
| Hue Shift | Spectral tilt (brightness filter) |
| Glow Intensity | Reverb mix (5-60%) + attack time (1-100ms) |
| Grid Density | Voice count/polyphony (1-8 voices) |

### 6.4 Bidirectional Flow (60 FPS)

```
┌─────────────────────────────────────────────────────────────┐
│                    PARAMETER BRIDGE                          │
│                      (60 FPS loop)                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   SYNTH STATE → VISUAL              AUDIO ANALYSIS → VISUAL  │
│   ────────────────────              ──────────────────────   │
│   Filter cutoff → ZW Rotation       Bass energy → Speed      │
│   FM depth → XW Rotation            Mid energy → Grid        │
│   Detune → XY/XZ Rotation           High energy → Brightness │
│   Waveform → Morph parameter        Centroid → Hue shift     │
│   Noise mix → Chaos                 RMS → Glow intensity     │
│   Reverb → Glow intensity                                    │
│                                                              │
│   USER CONTROLS SYNTH → SYNTH DRIVES VISUALS                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### UI Control Names (User-Facing) vs Internal Visual Parameters (Behind Scenes)

| UI Label (Synth) | Internal Visual Parameter |
|-----------------|--------------------------|
| Filter Cutoff | ZW Rotation |
| Filter Resonance | Edge thickness |
| Oscillator Detune | XY/XZ Rotation |
| FM Depth | XW Rotation |
| Ring Mod Depth | YW Rotation |
| Waveform Blend | Morph factor |
| Noise Level | Chaos amount |
| Reverb Mix | Glow intensity |
| Voice Count | Grid density |

**Gesture → Synth Parameter (UI shows synth name, visual responds):**
| Gesture on Visualizer | Changes Synth Control |
|----------------------|----------------------|
| Rotate (drag) | Oscillator Detune |
| Pinch/zoom | Filter Cutoff |
| Two-finger twist | FM Depth / Ring Mod |
| Morph gesture | Waveform Blend |
| Shake | Noise Level |

**Audio Reactivity (FFT-based, modulates +/- from base state):**

> **Key concept:** Synth settings define the BASE visual state. Audio reactivity then modulates +/- around that base in real-time.

| Audio Feature | Modulation Effect | Range |
|--------------|-------------------|-------|
| Bass (20-250 Hz) | Rotation speed +/- | ±0.5x base |
| Mid (250-2k Hz) | Grid density +/- | ±20 from base |
| High (2k-8k Hz) | Vertex brightness +/- | ±0.3 from base |
| Spectral centroid | Hue shift +/- | ±30° from base |
| RMS amplitude | Glow intensity +/- | ±0.5 from base |

```
Example:
  User sets Filter Cutoff = 60%  →  Base ZW Rotation = 0.3
  Audio bass spike              →  ZW Rotation = 0.3 + 0.15 = 0.45
  Audio bass drops              →  ZW Rotation returns to 0.3
```

---

## 7. PARAMETER SYSTEM

### 7.1 Complete Parameter Reference

| Parameter | Type | Range | Default | Description |
|-----------|------|-------|---------|-------------|
| geometry | int | 0-23 | 0 | Geometry selector |
| rot4dXY | float | ±6.28 | 0.0 | XY plane rotation |
| rot4dXZ | float | ±6.28 | 0.0 | XZ plane rotation |
| rot4dYZ | float | ±6.28 | 0.0 | YZ plane rotation |
| rot4dXW | float | ±2.0 | 0.0 | XW hyperplane rotation |
| rot4dYW | float | ±2.0 | 0.0 | YW hyperplane rotation |
| rot4dZW | float | ±2.0 | 0.0 | ZW hyperplane rotation |
| gridDensity | float | 4-100 | 15 | Lattice spacing |
| morphFactor | float | 0-2 | 1.0 | Geometry blending |
| chaos | float | 0-1 | 0.2 | Noise amplitude |
| speed | float | 0.1-3 | 1.0 | Animation rate |
| hue | int | 0-360 | 200 | Base color hue |
| saturation | float | 0-1 | 0.8 | Color richness |
| intensity | float | 0-1 | 0.5 | Brightness |
| dimension | float | 3.0-4.5 | 3.5 | 4D projection level |

### 7.2 Audio Reactivity Mapping

| Frequency Band | Parameter Effect |
|----------------|------------------|
| Bass (20-250 Hz) | gridDensity +40, XW rotation |
| Mid (250-2000 Hz) | morphFactor +1.2, YW rotation |
| High (2000-8000 Hz) | hue +120°, ZW rotation |
| RMS Energy | chaos +0.6, intensity boost |

---

## 8. PORTING TO FLUTTER/DART

### 8.1 Technology Mapping

| VIB3-CORE (Web) | Flutter Equivalent |
|-----------------|-------------------|
| WebGL Fragment Shader | Flutter FragmentShader API (Impeller) |
| requestAnimationFrame | Ticker / AnimationController |
| Canvas 2D Context | CustomPainter (for compositing) |
| Web Audio API | just_audio + fft package |
| localStorage | SharedPreferences |
| Touch events | GestureDetector |

### 8.2 Flutter FragmentShader Approach

Flutter supports custom GLSL shaders via the FragmentShader API:

```dart
// 1. Create shader file: shaders/vib3.frag
// 2. Register in pubspec.yaml:
flutter:
  shaders:
    - shaders/vib3.frag

// 3. Load and use in widget:
class VIB3ShaderWidget extends StatefulWidget {
  @override
  _VIB3ShaderWidgetState createState() => _VIB3ShaderWidgetState();
}

class _VIB3ShaderWidgetState extends State<VIB3ShaderWidget> {
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/vib3.frag');
    setState(() => _shader = program.fragmentShader());
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) return Container();
    return CustomPaint(
      painter: VIB3ShaderPainter(
        shader: _shader!,
        time: _time,
        // ... other parameters
      ),
    );
  }
}
```

### 8.3 Shader Uniform Passing

```dart
class VIB3ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final VIB3EngineState state;

  @override
  void paint(Canvas canvas, Size size) {
    // Set uniforms (must match shader uniform order)
    shader.setFloat(0, size.width);   // u_resolution.x
    shader.setFloat(1, size.height);  // u_resolution.y
    shader.setFloat(2, time);         // u_time
    shader.setFloat(3, state.geometryIndex.toDouble());  // u_geometry
    shader.setFloat(4, state.rotationXY);  // u_rot4dXY
    shader.setFloat(5, state.rotationXZ);  // u_rot4dXZ
    // ... etc

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }
}
```

### 8.4 Required Files for Porting

```
lib/
├── vib3_shader/
│   ├── vib3_shader_widget.dart      # Main widget
│   ├── vib3_shader_painter.dart     # CustomPainter for shader
│   ├── vib3_engine_state.dart       # State management
│   └── parameter_controller.dart    # Parameter updates
│
shaders/
├── vib3_quantum.frag                # Quantum system shader
├── vib3_faceted.frag                # Faceted system shader
└── vib3_holographic.frag            # Holographic system shader
```

> **Note:** Only 3 shaders needed - one per visual system (Quantum, Faceted, Holographic).

---

## 9. IMPLEMENTATION PLAN

### Phase 1: Core Shader Infrastructure
1. Create Flutter FragmentShader wrapper widget
2. Port base 4D rotation matrices to GLSL
3. Port 8 base SDF geometry functions
4. Implement 4D→2D projection
5. Set up shader uniform passing from Dart

### Phase 2: Visual Systems (3 Systems)
1. **Quantum** - 5-layer compositing, extreme RGB separation
2. **Faceted** - Dual-layer edge/fill rendering
3. **Holographic** - Chromatic aberration, depth layers, interference

### Phase 3: Parameter Integration
1. Connect VIB3EngineState to shader uniforms
2. Implement audio reactivity mapping (bass→grid, mid→morph, high→hue)
3. Add gesture controls for 6D rotation
4. Sync with existing AudioProvider/VisualProvider

### Phase 4: Polish
1. Performance optimization (mobile GPU)
2. Smooth system transitions with crossfade
3. Preset saving/loading
4. UI integration with existing controls

---

## 10. KEY DIFFERENCES FROM CURRENT IMPLEMENTATION

| Aspect | Current (Broken) | VIB3-CORE (Correct) |
|--------|------------------|---------------------|
| Rendering | CPU vertex projection | GPU fragment shader |
| Geometry | Explicit vertices/edges | Per-pixel SDF |
| Color | Simple HSL blend | 5-layer RGB separation |
| Effects | Basic glow | Chromatic/glass/interference |
| Performance | Limited by CPU | GPU parallel |

---

## 11. REFERENCES

- VIB3-CORE Repository: https://github.com/Domusgpt/Vib3-CORE-Documented01-
- Flutter FragmentShader: https://api.flutter.dev/flutter/dart-ui/FragmentShader-class.html
- Impeller Documentation: https://github.com/flutter/engine/tree/main/impeller

---

*A Paul Phillips Manifestation*
*© 2025 Paul Phillips - Clear Seas Solutions LLC*
