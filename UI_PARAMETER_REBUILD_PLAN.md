# VIB3+ UI & Parameter System Rebuild Plan

**Created**: January 8, 2026
**Author**: Claude (for Paul Phillips / Clear Seas Solutions)
**Status**: Planning Phase

---

## 1. CURRENT STATE ANALYSIS

### 1.1 Critical Issues Identified

| Issue | Severity | Description |
|-------|----------|-------------|
| **Audio Touch Blocking** | CRITICAL | `VIB3AnimatedShaderWidget` has `GestureDetector` with `enableInteraction: true` that captures ALL touch events, blocking XY pad |
| **Effects Panel Grey/Useless** | HIGH | Panel renders but AudioProvider methods may not be properly wired |
| **Mapping Panel Grey/Useless** | HIGH | Uses UIStateProvider instead of actual parameter routing |
| **Sliders Disconnected** | HIGH | Sliders call provider methods but parameters don't reach synthesis/shader |
| **Missing 6D Rotation Sliders** | HIGH | Only 3 rotation sliders (XW, YW, ZW) - missing XY, XZ, YZ |
| **Wrong Parameter Groupings** | MEDIUM | Current panels don't match the audio-visual coupling design |

### 1.2 Current Panel Structure

```
CURRENT (Broken):
├── Geometry Panel
│   ├── BASE GEOMETRY (8 polytopes) ✅ Works
│   ├── POLYTOPE CORE (3 synthesis branches) ✅ Works
│   ├── SYNTHESIS MODULATION
│   │   ├── XW: FM Depth / Detune 1 (0-6.28) ⚠️ Wrong range/label
│   │   ├── YW: Ring Mod / Detune 2 (0-6.28) ⚠️ Wrong range/label
│   │   ├── ZW: Filter Cutoff (0-6.28) ⚠️ Wrong range
│   │   └── Modulation Rate (LFO) (0-2) ❓ Unclear purpose
│   └── SPATIAL SYNTHESIS
│       ├── Reverb Amount (5-15) ❌ Tied to projectionDistance
│       ├── Delay / Echo Depth (0-5) ❌ Tied to layerSeparation
│       └── Waveform Crossfade (0-1) ⚠️ morphParameter exists
│
├── Synthesis Panel
│   ├── SYNTHESIS BRANCH (Direct/FM/Ring) ✅ Works
│   ├── OSCILLATORS ❌ Disconnected from shader
│   │   ├── OSC 1 Tune (-12 to 12 cents)
│   │   ├── OSC 2 Tune (-12 to 12 cents)
│   │   └── Mix Balance (0-1)
│   └── ENVELOPE ❌ Disconnected
│       ├── Attack (0-2000ms)
│       ├── Decay (0-2000ms)
│       ├── Sustain (0-1)
│       └── Release (0-5000ms)
│
├── Effects Panel ❌ COMPLETELY GREY/BROKEN
│   ├── FILTER (Cutoff, Resonance, Env)
│   ├── REVERB (Mix, Room Size, Damping)
│   └── DELAY (Time, Feedback, Mix)
│
└── Mapping Panel ❌ COMPLETELY GREY/BROKEN
    ├── XY PAD CONFIGURATION
    ├── PITCH CONFIGURATION
    ├── ORB CONTROLLER
    └── VISUAL → AUDIO MODULATION (static display only)
```

### 1.3 Audio Touch Blocking Issue

**Root Cause**: In `synth_main_screen.dart:194`:
```dart
return VIB3AnimatedShaderWidget(
  ...
  enableInteraction: true,  // <-- This wraps shader in GestureDetector
);
```

The shader widget's `GestureDetector` captures all pan/scale events before they reach the XY Performance Pad below it in the widget tree.

### 1.4 What SHOULD Work (Design Spec)

From the original architecture document:

**Visual System → Sound Family:**
| Visual System | Waveform | Filter Q | Reverb |
|---------------|----------|----------|--------|
| Quantum | Sine waves | High (8-12) | Low |
| Faceted | Square/Triangle | Moderate (4-8) | Medium |
| Holographic | Sawtooth/Wavetable | Low (2-4) | High |

**6D Rotation → Audio Modulation:**
| Rotation | Audio Effect | Applies To |
|----------|--------------|------------|
| XY | Oscillator 1 detune (±12 cents) | All |
| XZ | Oscillator 2 detune (±12 cents) | All |
| YZ | Combined detuning (±7 cents) | All |
| XW | FM depth (0-2 semitones) | Hypersphere core only |
| YW | Ring mod depth (0-100%) | Hypertetrahedron core only |
| ZW | Filter cutoff modulation (±40%) | All |

**Visual Parameters → Audio:**
| Visual Parameter | Audio Effect |
|-----------------|--------------|
| Morph | Waveform crossfade |
| Chaos | Noise injection (0-30%) + filter randomization |
| Speed | LFO rate for all modulations (0.1-10 Hz) |
| Hue Shift | Spectral tilt (brightness filter) |
| Glow Intensity | Reverb mix (5-60%) + attack time (1-100ms) |
| Grid Density | Voice count/polyphony (1-8 voices) |

---

## 2. NEW UI ARCHITECTURE

### 2.1 Philosophy: "Visual-First, Audio-Coupled"

Every control affects BOTH visual AND audio simultaneously. No separate "audio-only" panels.

### 2.2 Proposed Panel Structure

```
NEW DESIGN:
├── GEOMETRY (Keep, Minor Fixes)
│   ├── Polytope Core Selector (3 buttons) ✅
│   └── Base Geometry Grid (8 buttons) ✅
│
├── 6D ROTATION (NEW - Combined Visual+Audio)
│   ├── XY Rotation → Detune 1 (±12 cents)
│   ├── XZ Rotation → Detune 2 (±12 cents)
│   ├── YZ Rotation → Combined Detune (±7 cents)
│   ├── XW Rotation → FM Depth (Hypersphere only)
│   ├── YW Rotation → Ring Mod Depth (Hypertetra only)
│   └── ZW Rotation → Filter Cutoff Mod (±40%)
│
├── VISUAL CHARACTER (NEW - Replaces scattered params)
│   ├── Hue Shift (0-360°) → Spectral Tilt
│   ├── Saturation (0-100%) → Harmonic Richness
│   ├── Intensity/Brightness (0-100%) → Output Gain
│   ├── Glow (0-100%) → Reverb Mix + Attack
│   ├── Chaos (0-100%) → Noise + Filter Random
│   └── Morph (0-100%) → Waveform Crossfade
│
├── SPATIAL (NEW - Replaces Effects Panel)
│   ├── Grid Density (1-8) → Voice Count
│   └── Speed → Audio-Reactive (removed as slider, driven by audio)
│
└── DELETE: Effects Panel, Mapping Panel
    (Move useful Mapping features to XY Pad settings overlay)
```

### 2.3 Touch Handling Fix

**Solution**: Disable shader gesture handling, let XY pad handle all touches:

```dart
// synth_main_screen.dart
return VIB3AnimatedShaderWidget(
  ...
  enableInteraction: false,  // <-- Disable shader touch handling
);
```

The 6D rotation will be controlled by:
1. Dedicated sliders in the 6D ROTATION panel
2. Optionally: tilt sensors (already partially implemented)
3. Audio reactivity (bass → speed, etc.)

---

## 3. PARAMETER FLOW ARCHITECTURE

### 3.1 Visual Parameters (VisualProvider)

```dart
// Current params that WORK:
currentSystem      // 'quantum', 'faceted', 'holographic'
currentGeometry    // 0-23
rotationXW, YW, ZW // 0-2π (need to add XY, XZ, YZ)
hueShift          // 0-360
glowIntensity     // 0-1
morphParameter    // 0-1
rotationSpeed     // 0-2

// NEED TO ADD:
rotationXY, XZ, YZ  // 0-2π
saturation          // 0-1
chaosAmount         // 0-1
```

### 3.2 Shader Uniforms (vib3_core.frag)

The shader already accepts all these uniforms:
```glsl
uniform float u_rotXY, u_rotXZ, u_rotYZ;  // Currently not passed!
uniform float u_rotXW, u_rotYW, u_rotZW;  // ✅ Passed
uniform float u_hue;                       // ✅ Passed
uniform float u_saturation;               // Need to pass
uniform float u_brightness;               // ✅ Passed (as vertexBrightness)
uniform float u_glowIntensity;            // ✅ Passed
uniform float u_chaos;                    // Need to pass
uniform float u_morphFactor;              // ✅ Passed
uniform float u_gridDensity;              // ✅ Passed (as tessellationDensity)
```

### 3.3 Audio Routing (AudioProvider → SynthesisBranchManager)

The `SynthesisBranchManager` already has:
- `setGeometry(int index)` - routes to Direct/FM/RingMod
- `setSystemTimbre(VisualSystem system)` - sets waveform/Q/reverb
- `processVisualParameters(...)` - applies rotation to audio

**Key Issue**: The shader widget doesn't call AudioProvider methods when rotations change!

---

## 4. IMPLEMENTATION PHASES

### Phase 1: Critical Fixes (Session 1)
- [ ] Fix audio touch blocking (`enableInteraction: false`)
- [ ] Verify audio actually plays when XY pad touched
- [ ] Remove grey Effects Panel
- [ ] Remove grey Mapping Panel

### Phase 2: Add Missing Rotations (Session 2)
- [ ] Add `rotationXY`, `rotationXZ`, `rotationYZ` to VisualProvider
- [ ] Pass all 6 rotations to shader
- [ ] Create new 6D ROTATION panel with 6 sliders
- [ ] Wire rotations to audio (detune, FM depth, ring mod, filter)

### Phase 3: Visual Character Panel (Session 3)
- [ ] Add `saturation`, `chaosAmount` to VisualProvider
- [ ] Pass to shader
- [ ] Create VISUAL CHARACTER panel
- [ ] Wire to audio (spectral tilt, noise, etc.)

### Phase 4: Audio-Visual Coupling Validation (Session 4)
- [ ] Test all 72 geometry combinations
- [ ] Calibrate parameter ranges to avoid crackling
- [ ] Add parameter smoothing where needed
- [ ] Performance testing

### Phase 5: Polish (Session 5)
- [ ] Slider visual polish
- [ ] Add parameter value displays
- [ ] Add preset save/load
- [ ] Final testing

---

## 5. SLIDER DESIGN PRINCIPLES

### 5.1 Unified Slider Component

Each slider should show:
1. **Label** with visual AND audio function
2. **Current value** (numeric)
3. **Unit** (%, Hz, cents, etc.)
4. **Visual indicator** that changes with value

### 5.2 Example Slider Labels

| Slider | Label Format |
|--------|--------------|
| XY Rotation | "XY Rotation → Detune 1: ±8.5 cents" |
| Glow | "Glow → Reverb: 45%" |
| Chaos | "Chaos → Noise + Random: 12%" |

### 5.3 Parameter Ranges (Calibrated)

| Parameter | Visual Range | Audio Range | Notes |
|-----------|--------------|-------------|-------|
| Rotation XY/XZ/YZ | 0-2π rad | ±12/±12/±7 cents | Linear map |
| Rotation XW | 0-2π rad | 0-2 semitones FM | Hypersphere only |
| Rotation YW | 0-2π rad | 0-100% ring mod | Hypertetra only |
| Rotation ZW | 0-2π rad | ±40% filter cutoff | Relative to base |
| Hue | 0-360° | Spectral tilt | Affects brightness EQ |
| Saturation | 0-100% | Harmonic richness | Filter resonance boost |
| Brightness | 0-100% | Output gain | With limiter |
| Glow | 0-100% | 5-60% reverb + 1-100ms attack | Compound mapping |
| Chaos | 0-100% | 0-30% noise + filter random | Compound mapping |
| Morph | 0-100% | Waveform crossfade | Between geometry shapes |
| Grid Density | 1-8 | 1-8 voices | Direct map, affects CPU |

---

## 6. FILE CHANGES REQUIRED

### 6.1 Files to Modify

| File | Changes |
|------|---------|
| `lib/ui/screens/synth_main_screen.dart` | Set `enableInteraction: false` |
| `lib/providers/visual_provider.dart` | Add XY, XZ, YZ rotations, saturation, chaos |
| `lib/vib3/rendering/vib3_shader_renderer.dart` | Pass missing uniforms |
| `lib/ui/panels/geometry_panel.dart` | Simplify to just geometry selection |
| `lib/mapping/parameter_bridge.dart` | Wire rotation changes to audio |

### 6.2 Files to Delete

| File | Reason |
|------|--------|
| `lib/ui/panels/effects_panel.dart` | Grey/broken, redundant |
| `lib/ui/panels/mapping_panel.dart` | Grey/broken, features move elsewhere |

### 6.3 Files to Create

| File | Purpose |
|------|---------|
| `lib/ui/panels/rotation_panel.dart` | 6D rotation sliders with audio coupling |
| `lib/ui/panels/visual_character_panel.dart` | Hue, sat, bright, glow, chaos, morph |

---

## 7. SUCCESS CRITERIA

### 7.1 Audio Must Work
- [ ] Touching XY pad triggers notes
- [ ] Notes have correct pitch based on X position
- [ ] Y position modulates assigned parameter
- [ ] Audio doesn't crackle or pop
- [ ] System switch changes timbre immediately

### 7.2 Visual Must Work
- [ ] All 3 systems render correctly
- [ ] All 24 geometries render correctly
- [ ] Rotation sliders animate the visualization
- [ ] Parameters update in real-time (60 FPS)

### 7.3 Coupling Must Work
- [ ] Rotation changes affect both visual AND audio
- [ ] Audio reactivity modulates visuals
- [ ] Each of 72 combinations has unique character
- [ ] Parameter changes are smooth (no pops)

---

## APPENDIX A: Quick Reference - 72 Combinations

```
System × Core × Base = 72 unique combinations

QUANTUM (Pure Harmonic):
├── Base Core (Direct) × 8 geometries = 8 combos
├── Hypersphere (FM) × 8 geometries = 8 combos
└── Hypertetrahedron (Ring) × 8 geometries = 8 combos
Total: 24

FACETED (Geometric Hybrid):
├── Base Core × 8 = 8
├── Hypersphere × 8 = 8
└── Hypertetrahedron × 8 = 8
Total: 24

HOLOGRAPHIC (Spectral Rich):
├── Base Core × 8 = 8
├── Hypersphere × 8 = 8
└── Hypertetrahedron × 8 = 8
Total: 24

GRAND TOTAL: 72 unique audio-visual combinations
```

---

**Document Version**: 1.0
**Next Session**: Begin Phase 1 - Critical Fixes

*A Paul Phillips Manifestation*
*"The Revolution Will Not be in a Structured Format"*
