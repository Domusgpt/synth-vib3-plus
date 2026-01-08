# VIB3+ Complete Control Specification

**Created**: January 8, 2026
**Author**: Claude (for Paul Phillips / Clear Seas Solutions)
**Status**: Phase 2 Implementation Ready

---

## 1. CONTROL ENDPOINT DOCUMENTATION

Every control in VIB3+ has BOTH a visual AND sonic endpoint. This is the core design philosophy.

### 1.1 Visual System Selector (3 options)

| Control | Visual Endpoint | Sonic Endpoint |
|---------|-----------------|----------------|
| **Quantum** | 5-layer extreme palette (purple→green→red→cyan→magenta), particle systems, explosive RGB separation | Sine waves, High filter Q (8-12), Low reverb, Pure harmonic synthesis |
| **Faceted** | Sharp edge detection, geometric fills, subtle vertex highlights, cooler palette | Square/Triangle waves, Moderate Q (4-8), Medium reverb, Geometric hybrid |
| **Holographic** | 5-layer parallax depth (density 0.4→2.5), chromatic aberration, moiré interference, shimmer | Sawtooth/Wavetable, Low Q (2-4), High reverb, Spectral rich |

**UI Widget**: 3-button horizontal selector at TOP of screen (always visible)
**Touch Target**: 56px height, equal thirds
**State Indicator**: Primary system color glow on active button

---

### 1.2 Polytope Core Selector (3 options)

Determines synthesis branch (geometry 0-23 divided into 3 groups of 8).

| Control | Visual Endpoint | Sonic Endpoint |
|---------|-----------------|----------------|
| **Base Core (0-7)** | Standard geometry rendering, no 4D warp | Direct synthesis with filtering only |
| **Hypersphere (8-15)** | 4D spherical warp projection, morphBlend scaling, sin wave depth | FM synthesis (frequency modulation) |
| **Hypertetrahedron (16-23)** | 4D tetrahedral warp, multi-basis projection, cos wave modulation | Ring modulation synthesis |

**UI Widget**: 3-button horizontal selector in GEOMETRY panel
**Touch Target**: 48px height, equal thirds
**Calculation**: `coreIndex = geometryIndex ~/ 8`

---

### 1.3 Base Geometry Selector (8 options)

Each base geometry defines BOTH the visual lattice pattern AND voice character.

| Geometry | Visual Lattice | Sonic Character |
|----------|---------------|-----------------|
| **0: Tetrahedron** | 4-vertex lattice, triangular edges, minimal vertices | Fundamental tone, minimal filtering, fast decay |
| **1: Hypercube** | 8-corner grid lattice, orthogonal edges, cube structure | Dual oscillators with detune, complex timbre |
| **2: Sphere** | Spherical lattice, concentric rings, smooth gradients | Smooth harmonics, low-pass filtered, long attack |
| **3: Torus** | Toroidal lattice, major/minor radius rings, donut topology | Rhythmic phase modulation, cyclic LFO |
| **4: Klein Bottle** | Twisted non-orientable surface, Möbius-like | Asymmetric stereo, phase inversion effects |
| **5: Fractal** | Recursive subdivision (4 iterations), self-similar | Self-modulating feedback, recursive harmonics |
| **6: Wave** | Interference patterns, 3D wave superposition | Sweeping filter, LFO-driven resonance |
| **7: Crystal** | Octahedral crystal structure, sharp faces | Sharp attack transients, crystalline highs |

**UI Widget**: 4x2 grid of touch buttons in GEOMETRY panel
**Touch Target**: 72px per button
**Calculation**: `baseGeometry = geometryIndex % 8`

---

### 1.4 6D Rotation Controls (6 sliders)

The fundamental audio-visual coupling. Each 4D rotation plane affects BOTH visual animation AND sonic parameters.

| Rotation | Visual Endpoint | Sonic Endpoint | Range |
|----------|-----------------|----------------|-------|
| **XY** | Rotate in XY plane (3D pitch/yaw analog) | Oscillator 1 detune | 0-2π → ±12 cents |
| **XZ** | Rotate in XZ plane (3D roll analog) | Oscillator 2 detune | 0-2π → ±12 cents |
| **YZ** | Rotate in YZ plane (tumble) | Combined detune (chorus effect) | 0-2π → ±7 cents |
| **XW** | Rotate into 4th dimension (X axis) | FM depth (Hypersphere core ONLY) | 0-2π → 0-2 semitones |
| **YW** | Rotate into 4th dimension (Y axis) | Ring mod depth (Hypertetra core ONLY) | 0-2π → 0-100% |
| **ZW** | Rotate into 4th dimension (Z axis) | Filter cutoff modulation | 0-2π → ±40% of base cutoff |

**UI Widget**: 6 horizontal sliders in "6D ROTATION" collapsible panel
**Slider Design**: Bidirectional from center for XY/XZ/YZ (detune), unidirectional for XW/YW/ZW
**Real-time Display**: Show both visual angle (rad) AND audio value (cents/% etc.)
**Conditional Visibility**:
- XW slider: Dimmed/disabled unless Hypersphere core selected
- YW slider: Dimmed/disabled unless Hypertetrahedron core selected
- ZW slider: Always active (filter affects all)

---

### 1.5 Visual Character Controls (6 sliders)

Each visual parameter has a corresponding sonic effect.

| Control | Visual Endpoint | Sonic Endpoint | Range | Unit |
|---------|-----------------|----------------|-------|------|
| **Hue** | Color palette rotation (HSV H component) | Spectral tilt (brightness EQ filter) | 0-360 | degrees |
| **Saturation** | Color vibrancy (HSV S component) | Harmonic richness (filter resonance boost) | 0-100 | % |
| **Brightness** | Overall luminosity (HSV V component) | Output gain (with soft limiter) | 0-100 | % |
| **Glow** | Bloom intensity, particle brightness, layer bleed | Reverb wet mix + Attack time | 0-100 | % → 5-60% reverb, 1-100ms attack |
| **Chaos** | Noise injection to geometry, random color bursts | Noise layer + Filter randomization | 0-100 | % → 0-30% noise |
| **Morph** | Geometry interpolation, warp intensity scaling | Waveform crossfade (sin↔saw↔square) | 0-100 | % |

**UI Widget**: 6 horizontal sliders in "VISUAL CHARACTER" collapsible panel
**Slider Design**: Unidirectional, 0 at left

---

### 1.6 Spatial/Density Control (1 slider)

| Control | Visual Endpoint | Sonic Endpoint | Range | Unit |
|---------|-----------------|----------------|-------|------|
| **Grid Density** | Tessellation density, lattice spacing | Voice count (polyphony) | 1-8 | voices |

**UI Widget**: Single slider in "SPATIAL" section OR at bottom of Visual Character panel
**Warning**: High values (6-8) increase CPU/GPU load significantly

---

### 1.7 Speed/Modulation Control

| Control | Visual Endpoint | Sonic Endpoint | Source |
|---------|-----------------|----------------|--------|
| **Auto-Rotation Speed** | Base rotation velocity (rad/sec) | LFO rate for all modulations | Manual slider OR audio-driven |
| **Audio Reactivity** | Visual response strength to audio | N/A (audio IS the source) | Strength slider (0-100%) |

**Design Decision**: Speed should be PRIMARILY audio-reactive (bass energy drives rotation), with manual override available.

---

## 2. UI ARCHITECTURE (REVISED)

### 2.1 Design Philosophy

**Key Principles**:
1. **Geometry is the "hero"** - Fixed prominent position at top
2. **ALL sliders in ONE scrollable panel** - Grouped by SONIC function
3. **System color themes UI** - Switching system changes entire UI palette
4. **Ghost offset shows audio reactivity** - Visual indicator of how audio modulates each param
5. **Labels reflect SONIC function** - What it DOES to sound, not what visual param it is

### 2.2 Screen Layout

```
┌────────────────────────────────────────────────────┐
│ ╔════════════════════════════════════════════════╗ │
│ ║ ◆ QUANTUM    ◇ FACETED    ◇ HOLOGRAPHIC       ║ │ ← System bar (56px)
│ ╚════════════════════════════════════════════════╝ │   Changes ALL UI colors
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │                                            │   │
│  │         VIB3+ SHADER CANVAS                │   │ ← Visualization
│  │         (No touch capture)                 │   │   Fills available space
│  │                                            │   │
│  └────────────────────────────────────────────┘   │
│                                                    │
│  ┌────────────────────────────────────────────┐   │
│  │        XY PERFORMANCE PAD                  │   │ ← Touch for notes
│  │    X: Pitch       Y: Assigned Param        │   │   120px fixed
│  └────────────────────────────────────────────┘   │
│                                                    │
│ ╔════════════════════════════════════════════════╗ │
│ ║ ═══════════ GEOMETRY HERO (FIXED) ═══════════ ║ │ ← Hero section
│ ║                                                ║ │   Always visible
│ ║ SYNTHESIS METHOD                               ║ │   ~200px
│ ║ ┌──────────┬──────────┬──────────┐            ║ │
│ ║ │  DIRECT  │    FM    │ RING MOD │            ║ │
│ ║ └──────────┴──────────┴──────────┘            ║ │
│ ║                                                ║ │
│ ║ VOICE CHARACTER                                ║ │
│ ║ ┌────┬────┬────┬────┐                         ║ │
│ ║ │FUND│CMPLX│SMTH│CYCL│                        ║ │
│ ║ ├────┼────┼────┼────┤                         ║ │
│ ║ │ASYM│RCRS│SWEP│CRSP│                         ║ │
│ ║ └────┴────┴────┴────┘                         ║ │
│ ╚════════════════════════════════════════════════╝ │
│                                                    │
│ ┌ ─ ─ ─ ─ ─ ─ ─ SCROLLABLE ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │
│ │ ╔══════════════════════════════════════════╗ │ │ ← Scrollable panel
│   ║      SYNTHESIS PARAMETERS                ║   │   Groups by sonic function
│ │ ╠══════════════════════════════════════════╣ │ │
│   ║ PITCH/DETUNE                             ║   │
│ │ ║ ●━━━━━━━━━━━━░░░░━━━━  Detune 1: +6c    ║ │ │
│   ║ ●━━━━━━━━━━━━━━░░━━━━  Detune 2: +9c    ║   │
│ │ ║ ●━━━━━━━━░░░░━━━━━━━━  Chorus: +3c      ║ │ │
│   ╠══════════════════════════════════════════╣   │
│ │ ║ MODULATION DEPTH                         ║ │ │
│   ║ ●━━━━━━━━━━━━━━━━░░░━  FM Depth: 1.2st  ║   │
│ │ ║ ○━━━━━━━━━━━━━━━━━━━━  Ring Mod: --     ║ │ │ ← Disabled (wrong core)
│   ║ ●━━━━━━━━━━━░░░░━━━━━  Filter Mod: ±25% ║   │
│ │ ╠══════════════════════════════════════════╣ │ │
│   ║ TONE SHAPING                             ║   │
│ │ ║ ●━━━━━━━━━━━━░░━━━━━━  Brightness: warm ║ │ │
│   ║ ●━━━━━━━━━━░░░░━━━━━━  Resonance: +4Q   ║   │
│ │ ║ ●━━━━━━━━━━━━━━░░━━━━  Output: -2dB     ║ │ │
│   ╠══════════════════════════════════════════╣   │
│ │ ║ SPACE & TEXTURE                          ║ │ │
│   ║ ●━━━━━━━━░░░░━━━━━━━━  Reverb: 25%      ║   │
│ │ ║ ●━━━░░━━━━━━━━━━━━━━━  Noise: 5%        ║ │ │
│   ║ ●━━━━━━━━━━━━━░░░━━━━  Waveform: sin→saw║   │
│ │ ╠══════════════════════════════════════════╣ │ │
│   ║ DENSITY & SPEED                          ║   │
│ │ ║ ●━━━━━━━━━━░░━━━━━━━━  Voices: 4        ║ │ │
│   ║ ●━━━━━━━━━━━━░░━━━━━━  LFO Rate: 2Hz    ║   │
│ │ ╚══════════════════════════════════════════╝ │ │
│ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │
└────────────────────────────────────────────────────┘
```

### 2.3 Slider Design with Ghost Offset

Each slider shows THREE elements:
1. **Base value** (solid thumb) - User's manual setting
2. **Ghost offset** (translucent thumb) - Where audio reactivity pushes it
3. **Activity indicator** - Brightness/pulse showing current sonic activity

```
┌────────────────────────────────────────────────────┐
│ Detune 1 (XY Rotation)                    +6.2c   │
│ ○━━━━━━━━━━━━━●━━━━━━◐━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│              ↑        ↑                           │
│         Base value   Ghost (audio pushing +2c)    │
│                                                   │
│ [ ░░░░░░░░░░░████████░░░░░░░░░░ ] Activity meter │
└────────────────────────────────────────────────────┘
```

**Ghost behavior**:
- Shows real-time audio reactivity effect
- Opacity: 40%
- Color: System accent color
- Position: Offset from base by audio modulation amount
- When audio is silent: Ghost overlaps base thumb exactly

### 2.4 Geometry Hero Section (FIXED)

Never scrolls, always visible. Uses SONIC terminology:

**Synthesis Method** (was "Polytope Core"):
- **DIRECT** - Clean, filtered synthesis (geometries 0-7)
- **FM** - Frequency modulation (geometries 8-15, Hypersphere)
- **RING MOD** - Ring modulation (geometries 16-23, Hypertetrahedron)

**Voice Character** (was "Base Geometry"):
| Button | Name | Visual | Sonic |
|--------|------|--------|-------|
| FUND | Fundamental | Tetrahedron | Minimal, pure |
| CMPLX | Complex | Hypercube | Dual-osc detune |
| SMTH | Smooth | Sphere | Filtered, soft |
| CYCL | Cyclic | Torus | Rhythmic, LFO |
| ASYM | Asymmetric | Klein | Stereo phase |
| RCRS | Recursive | Fractal | Feedback |
| SWEP | Sweeping | Wave | Filter sweep |
| CRSP | Crisp | Crystal | Sharp transient |

### 2.5 Slider Groups by Sonic Function

**PITCH/DETUNE** - Oscillator tuning controls
| Param | Source | Audio Effect | Range |
|-------|--------|--------------|-------|
| Detune 1 | XY Rotation | OSC 1 pitch offset | ±12 cents |
| Detune 2 | XZ Rotation | OSC 2 pitch offset | ±12 cents |
| Chorus | YZ Rotation | Combined detune (thickness) | ±7 cents |

**MODULATION DEPTH** - Synthesis modulation amounts
| Param | Source | Audio Effect | Range | Condition |
|-------|--------|--------------|-------|-----------|
| FM Depth | XW Rotation | Frequency mod depth | 0-2 semitones | FM core only |
| Ring Mod | YW Rotation | Ring mod intensity | 0-100% | Ring core only |
| Filter Mod | ZW Rotation | Cutoff modulation | ±40% | Always |

**TONE SHAPING** - Timbre/EQ controls
| Param | Source | Audio Effect | Range |
|-------|--------|--------------|-------|
| Brightness | Hue | Spectral tilt EQ | dark↔bright |
| Resonance | Saturation | Filter Q boost | 0-100% |
| Output | Brightness | Gain with limiter | 0-100% |

**SPACE & TEXTURE** - Effects and character
| Param | Source | Audio Effect | Range |
|-------|--------|--------------|-------|
| Reverb | Glow | Wet mix + attack | 5-60% |
| Noise | Chaos | Noise injection | 0-30% |
| Waveform | Morph | Shape crossfade | sin↔saw↔square |

**DENSITY & SPEED** - Complexity and motion
| Param | Source | Audio Effect | Range |
|-------|--------|--------------|-------|
| Voices | Grid Density | Polyphony count | 1-8 |
| LFO Rate | Speed (audio-driven) | Modulation speed | 0.1-10 Hz |

### 2.6 System Color Themes

When user switches system, ENTIRE UI recolors:

```dart
// QUANTUM - Electric/Plasma
quantumTheme:
  primary: #00FFFF    // Cyan
  accent: #FF00FF     // Magenta
  background: #0A0A1A // Near black with blue tint
  surface: #1A1A2E    // Dark blue-grey
  slider: LinearGradient(cyan → magenta)

// FACETED - Cool/Geometric
facetedTheme:
  primary: #4488FF    // Blue
  accent: #00FFAA     // Teal
  background: #0A0F14 // Near black with green tint
  surface: #1A2428    // Dark teal-grey
  slider: LinearGradient(blue → teal)

// HOLOGRAPHIC - Warm/Spectral
holographicTheme:
  primary: #FFAA00    // Gold
  accent: #FF4488     // Pink
  background: #140A0A // Near black with red tint
  surface: #2E1A1A    // Dark warm grey
  slider: LinearGradient(gold → pink)
```

**Transitions**: 300ms ease-out when switching systems

---

## 3. ACCESSIBILITY & UX CONSIDERATIONS

### 3.1 Touch Targets
- All buttons: Minimum 48dp (44pt iOS)
- Sliders: Full width minus 32px padding, 56px touch height
- Panel tabs: Full width ÷ 4, 56px height

### 3.2 Visual Feedback
- Active control: Primary system color highlight
- Value changes: Ripple animation
- Locked panels: Lock icon + subtle outline glow
- Disabled controls: 30% opacity, italic label

### 3.3 Slider Design
- Thumb: 28dp circle with system color
- Track: 4dp height, gradient from start to thumb position
- Value display: Above thumb during drag, next to label otherwise
- Dual readout: Both visual AND audio values shown

### 3.4 Color Coding by System
```dart
// Quantum (electric/plasma)
primary: Color(0xFF00FFFF),   // Cyan
accent: Color(0xFFFF00FF),    // Magenta

// Faceted (cool/geometric)
primary: Color(0xFF4488FF),   // Blue
accent: Color(0xFF00FFAA),    // Teal

// Holographic (warm/spectral)
primary: Color(0xFFFFAA00),   // Gold
accent: Color(0xFFFF4488),    // Pink
```

### 3.5 Gesture Handling
- Panel tabs: Single tap to toggle
- Panel tabs: Long press to lock
- Sliders: Drag to adjust
- Sliders: Double-tap to reset to default
- Anywhere outside panels: Tap to collapse all

---

## 4. PARAMETER FLOW DIAGRAM

```
┌─────────────┐
│   USER UI   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│                    VISUAL PROVIDER                       │
│  ┌──────────────────────────────────────────────────┐   │
│  │ system, geometry, rotationXY/XZ/YZ/XW/YW/ZW     │   │
│  │ hueShift, saturation, brightness, glowIntensity  │   │
│  │ chaosAmount, morphParameter, gridDensity         │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────┬──────────────────────────┬───────────────┘
               │                          │
               ▼                          ▼
┌──────────────────────────┐   ┌──────────────────────────┐
│   SHADER (vib3_core.frag) │   │     AUDIO PROVIDER       │
│   ┌──────────────────┐   │   │  ┌──────────────────┐    │
│   │ All 23 uniforms  │   │   │  │ SynthesisBranch  │    │
│   │ u_rotXY, u_hue   │   │   │  │ Manager          │    │
│   │ u_chaos, etc.    │   │   │  │                  │    │
│   └──────────────────┘   │   │  │ Detune, FM depth │    │
│                          │   │  │ Ring mod, Filter │    │
│   5-Layer Rendering      │   │  │ Reverb, Noise    │    │
│   ┌──────────────────┐   │   │  └──────────────────┘    │
│   │ Per-pixel SDF    │   │   │                          │
│   │ Layer compositing│   │   │   AUDIO OUTPUT           │
│   └──────────────────┘   │   └──────────────────────────┘
└──────────────────────────┘
               │
               ▼
         DISPLAY (60 FPS)
```

---

## 5. IMPLEMENTATION CHECKLIST (REVISED)

### Phase 2A: Core Infrastructure
- [ ] Add `rotationXY`, `rotationXZ`, `rotationYZ` to VisualProvider
- [ ] Add `saturation`, `chaosAmount` to VisualProvider
- [ ] Add audio reactivity offset tracking to each parameter
- [ ] Create system color theme provider/extension to SynthTheme
- [ ] Verify all 23 uniforms flow to shader correctly

### Phase 2B: Geometry Hero Section
- [ ] Create fixed GeometryHeroWidget (doesn't scroll)
- [ ] Rename UI from "Polytope Core" → "Synthesis Method" (DIRECT/FM/RING MOD)
- [ ] Rename UI from "Base Geometry" → "Voice Character" (FUND/CMPLX/SMTH/etc.)
- [ ] Wire to system color theme

### Phase 2C: Unified Slider Component
- [ ] Create `SynthParameterSlider` with:
  - Base value thumb (solid)
  - Ghost offset thumb (40% opacity, shows audio reactivity)
  - Activity meter bar
  - Dual readout (visual value + sonic value)
  - Disabled state styling (30% opacity)
- [ ] Support bidirectional mode (for detune sliders with ± range)

### Phase 3: Scrollable Parameter Panel
- [ ] Create `SynthesisParametersPanel` (single scrollable panel)
- [ ] Group sliders by SONIC function:
  - PITCH/DETUNE (3 sliders)
  - MODULATION DEPTH (3 sliders, 2 conditional)
  - TONE SHAPING (3 sliders)
  - SPACE & TEXTURE (3 sliders)
  - DENSITY & SPEED (2 sliders)
- [ ] Implement conditional enable/disable for FM Depth and Ring Mod based on current core

### Phase 4: Audio Coupling & Ghost Offset
- [ ] Connect visual provider changes to audio provider
- [ ] Implement ghost offset calculation from audio reactivity
- [ ] Test all 14 sliders with audio modulation
- [ ] Test system color theme switching (300ms transition)

### Phase 5: Polish & Testing
- [ ] Double-tap slider to reset to default
- [ ] Long-press geometry button for info tooltip
- [ ] Test all 72 combinations
- [ ] Performance profiling (target 60 FPS)
- [ ] Accessibility audit (touch targets, contrast)

---

## 6. FILES TO MODIFY/CREATE (REVISED)

### Modify:
| File | Changes |
|------|---------|
| `lib/providers/visual_provider.dart` | Add XY/XZ/YZ rotations, saturation, chaosAmount, audio offset tracking |
| `lib/ui/theme/synth_theme.dart` | Add system color themes (Quantum/Faceted/Holographic palettes) |
| `lib/ui/screens/synth_main_screen.dart` | New layout with hero section + scrollable panel |
| `lib/ui/components/collapsible_bezel.dart` | REMOVE (replacing with new layout) |

### Delete:
| File | Reason |
|------|--------|
| `lib/ui/panels/geometry_panel.dart` | Replaced by GeometryHeroWidget |
| `lib/ui/panels/synthesis_panel.dart` | Merged into SynthesisParametersPanel |
| `lib/ui/panels/effects_panel.dart` | Already removed (Phase 1) |
| `lib/ui/panels/mapping_panel.dart` | Already removed (Phase 1) |
| `lib/ui/components/collapsible_bezel.dart` | Replacing with simpler layout |

### Create:
| File | Purpose |
|------|---------|
| `lib/ui/components/geometry_hero.dart` | Fixed geometry selector (Synthesis Method + Voice Character) |
| `lib/ui/components/synth_parameter_slider.dart` | Unified slider with ghost offset + activity meter |
| `lib/ui/panels/synthesis_parameters_panel.dart` | Scrollable panel with all 14 sliders grouped by sonic function |
| `lib/ui/theme/system_color_theme.dart` | Color theme definitions per visual system |

---

## 7. PARAMETER MAPPING QUICK REFERENCE

For developers - complete mapping from UI label to provider property to shader uniform to audio effect:

| UI Label | Provider Property | Shader Uniform | Audio Effect |
|----------|-------------------|----------------|--------------|
| Detune 1 | `rotationXY` | `u_rotXY` | OSC1 detune ±12c |
| Detune 2 | `rotationXZ` | `u_rotXZ` | OSC2 detune ±12c |
| Chorus | `rotationYZ` | `u_rotYZ` | Combined ±7c |
| FM Depth | `rotationXW` | `u_rotXW` | FM 0-2st |
| Ring Mod | `rotationYW` | `u_rotYW` | Ring 0-100% |
| Filter Mod | `rotationZW` | `u_rotZW` | Cutoff ±40% |
| Brightness | `hueShift` | `u_hue` | Spectral tilt |
| Resonance | `saturation` | `u_saturation` | Filter Q |
| Output | `vertexBrightness` | `u_brightness` | Gain |
| Reverb | `glowIntensity` | `u_glowIntensity` | Wet mix 5-60% |
| Noise | `chaosAmount` | `u_chaos` | Noise 0-30% |
| Waveform | `morphParameter` | `u_morphFactor` | Shape crossfade |
| Voices | `tessellationDensity` | `u_gridDensity` | Polyphony 1-8 |
| LFO Rate | `rotationSpeed` | (internal) | LFO 0.1-10Hz |

---

*A Paul Phillips Manifestation*
*"The Revolution Will Not be in a Structured Format"*
