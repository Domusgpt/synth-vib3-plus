# VIB3-CORE Complete System Analysis

## Source: https://github.com/Domusgpt/Vib3-CORE-Documented01-

This document provides a comprehensive analysis of the VIB3-CORE visualization system for porting to native Flutter/Dart.

---

## 1. SYSTEM OVERVIEW

VIB3-CORE is a browser-based WebGL visualization platform with 4 distinct rendering systems:

| System | Primary Effect | Key Characteristic |
|--------|---------------|-------------------|
| **Faceted** | Geometric edges | Dual-layer edge/fill, sharp facets |
| **Quantum** | Extreme color layers | 5 canvas layers, RGB separation |
| **Holographic** | Multi-layer depth | Chromatic aberration, interference patterns |
| **Polychora** | 4D polytopes | Glassmorphic rendering, 6 regular polytopes |

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

### 5.4 Polychora System

**6 Regular 4D Polytopes:**
| Polytope | Cells | Description |
|----------|-------|-------------|
| 5-Cell | 5 tetrahedra | 4D simplex |
| Tesseract | 8 cubes | 4D hypercube |
| 16-Cell | 16 tetrahedra | 4D orthoplex |
| 24-Cell | 24 octahedra | Unique to 4D |
| 600-Cell | 600 tetrahedra | Icosahedral symmetry |
| 120-Cell | 120 dodecahedra | Largest regular |

**Glassmorphic Rendering:**
- 5-layer compositing (background→accent)
- Refraction index modulation
- Procedural noise amplitude
- Flow direction vector field

---

## 6. PARAMETER SYSTEM

### 6.1 Complete Parameter Reference

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

### 6.2 Audio Reactivity Mapping

| Frequency Band | Parameter Effect |
|----------------|------------------|
| Bass (20-250 Hz) | gridDensity +40, XW rotation |
| Mid (250-2000 Hz) | morphFactor +1.2, YW rotation |
| High (2000-8000 Hz) | hue +120°, ZW rotation |
| RMS Energy | chaos +0.6, intensity boost |

---

## 7. PORTING TO FLUTTER/DART

### 7.1 Technology Mapping

| VIB3-CORE (Web) | Flutter Equivalent |
|-----------------|-------------------|
| WebGL Fragment Shader | Flutter FragmentShader API (Impeller) |
| requestAnimationFrame | Ticker / AnimationController |
| Canvas 2D Context | CustomPainter (for compositing) |
| Web Audio API | just_audio + fft package |
| localStorage | SharedPreferences |
| Touch events | GestureDetector |

### 7.2 Flutter FragmentShader Approach

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

### 7.3 Shader Uniform Passing

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

### 7.4 Required Files for Porting

```
lib/
├── vib3_shader/
│   ├── vib3_shader_widget.dart      # Main widget
│   ├── vib3_shader_painter.dart     # CustomPainter for shader
│   ├── vib3_engine_state.dart       # State management
│   └── parameter_controller.dart    # Parameter updates
│
shaders/
├── vib3_polychora.frag              # Polychora system shader
├── vib3_quantum.frag                # Quantum system shader
├── vib3_holographic.frag            # Holographic system shader
└── vib3_faceted.frag                # Faceted system shader
```

---

## 8. IMPLEMENTATION PLAN

### Phase 1: Core Shader Infrastructure
1. Create Flutter FragmentShader wrapper widget
2. Port base 4D rotation matrices to GLSL
3. Port 8 base SDF geometry functions
4. Implement 4D→2D projection

### Phase 2: Visual Systems
1. Port Faceted system (simplest - edge/fill only)
2. Port Polychora system (6 polytopes)
3. Port Quantum system (5-layer compositing)
4. Port Holographic system (chromatic effects)

### Phase 3: Parameter Integration
1. Connect VIB3EngineState to shader uniforms
2. Implement audio reactivity mapping
3. Add gesture controls for rotation
4. Sync with existing AudioProvider

### Phase 4: Polish
1. Performance optimization (mobile)
2. Smooth system transitions
3. Preset saving/loading
4. UI integration

---

## 9. KEY DIFFERENCES FROM CURRENT IMPLEMENTATION

| Aspect | Current (Broken) | VIB3-CORE (Correct) |
|--------|------------------|---------------------|
| Rendering | CPU vertex projection | GPU fragment shader |
| Geometry | Explicit vertices/edges | Per-pixel SDF |
| Color | Simple HSL blend | 5-layer RGB separation |
| Effects | Basic glow | Chromatic/glass/interference |
| Performance | Limited by CPU | GPU parallel |

---

## 10. REFERENCES

- VIB3-CORE Repository: https://github.com/Domusgpt/Vib3-CORE-Documented01-
- Flutter FragmentShader: https://api.flutter.dev/flutter/dart-ui/FragmentShader-class.html
- Impeller Documentation: https://github.com/flutter/engine/tree/main/impeller

---

*A Paul Phillips Manifestation*
*© 2025 Paul Phillips - Clear Seas Solutions LLC*
