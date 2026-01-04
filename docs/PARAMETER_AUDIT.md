# Parameter Audit & Mapping Plan

**Purpose**: Document current state vs. planned state for all parameters

**Last Updated**: January 2026 - Corrected based on code trace

---

## PART 1: CURRENT UI STATE (What Exists Now)

### Panel: GEOMETRY (geometry_panel.dart)

| Slider | Current Visual Effect | Current Audio Effect | Notes |
|--------|----------------------|---------------------|-------|
| XW: FM Depth / Detune 1 | rotationXW (4D rotation) | fmDepth (Hypersphere) | ✓ WIRED in visual_to_audio.dart:95-101 |
| YW: Ring Mod / Detune 2 | rotationYW (4D rotation) | ringModDepth (Hypertetra) | ✓ WIRED in visual_to_audio.dart:104-110 |
| ZW: Filter Cutoff | rotationZW (4D rotation) | filterCutoff (±40%) | ✓ WIRED in visual_to_audio.dart:113-117 |
| Modulation Rate (LFO) | rotationSpeed | lfoRate (0.1-10 Hz) | ✓ WIRED in visual_to_audio.dart:140-143 |
| Reverb Amount | projectionDistance | NONE | Visual only, no audio mapping |
| Delay / Echo Depth | layerSeparation | NONE | Visual only, no audio mapping |
| Waveform Crossfade | morphParameter → morphFactor | waveformCrossfade | ✓ WIRED in visual_to_audio.dart:120-123 |
| Density → Voice Count | tessellationDensity → gridDensity | voiceCount (1-8) | ✓ WIRED in visual_to_audio.dart:146-149 |
| Chaos → Noise | rgbSplitAmount → chaos | noiseInjection + filterRand | ✓ WIRED in visual_to_audio.dart:126-137 |
| Hue → Spectral Tilt | hueShift → hue | spectralTilt | ✓ WIRED in visual_to_audio.dart:152-155 |
| Glow → Reverb/Attack | glowIntensity | reverbMix + attackTime | ✓ WIRED in visual_to_audio.dart:158-165 |
| Saturation → Resonance | saturation | filterResonance | ✓ WIRED in visual_to_audio.dart:168-171 |

### Panel: SYNTHESIS (synthesis_panel.dart)

| Slider | Current Visual Effect | Current Audio Effect | Notes |
|--------|----------------------|---------------------|-------|
| OSC 1 Tune → XY Rotation | rotationXY | oscillator1Detune | ✓ Bidirectional |
| OSC 2 Tune → XZ Rotation | rotationXZ | oscillator2Detune | ✓ Bidirectional |
| Mix Balance → Brightness | vertexBrightness | mixBalance | ✓ Bidirectional |
| Cutoff → Hue Shift | hueShift | filterCutoff | ✓ Bidirectional |
| Resonance → Saturation | saturation | filterResonance | ✓ Bidirectional |
| Reverb Mix → Glow | glowIntensity | reverbMix | ✓ Bidirectional |
| Delay Mix → Distance | projectionDistance | delayMix | ✓ Bidirectional |
| Attack | NONE | envelopeAttack | Audio only |
| Decay | NONE | envelopeDecay | Audio only |
| Sustain | NONE | envelopeSustain | Audio only |
| Release | NONE | envelopeRelease | Audio only |

### Panel: EFFECTS (effects_panel.dart)

| Slider | Current Visual Effect | Current Audio Effect | Notes |
|--------|----------------------|---------------------|-------|
| Cutoff | NONE | filterCutoff | **DUPLICATE** of Synthesis |
| Resonance | NONE | filterResonance | **DUPLICATE** of Synthesis |
| Filter Env | NONE | filterEnvelopeAmount | Unique |
| Reverb Mix | NONE | reverbMix | **DUPLICATE** of Synthesis |
| Room Size | NONE | reverbRoomSize | Unique |
| Damping | NONE | reverbDamping | Unique |
| Delay Time | NONE | delayTime | Unique |
| Delay Feedback | NONE | delayFeedback | Unique |
| Delay Mix | NONE | delayMix | **DUPLICATE** of Synthesis |

### Panel: MAPPING (mapping_panel.dart)

| Control | Function | Notes |
|---------|----------|-------|
| X-Axis selector | XY pad horizontal mapping | pitch, filter, resonance, etc. |
| Y-Axis selector | XY pad vertical mapping | pitch, filter, resonance, etc. |
| Pitch Range Start | MIDI note range | |
| Pitch Range End | MIDI note range | |
| Scale selector | Chromatic, Major, Minor, etc. | |
| Orb Pitch Bend | Pitch bend range | |
| Orb Vibrato Depth | Vibrato amount | |
| Tilt Control toggle | Enable/disable tilt | |

---

## PART 2: SHADER UNIFORMS (vib3_core.frag)

| Uniform | Range | Controlled By | Purpose |
|---------|-------|---------------|---------|
| u_resolution | vec2 | System | Screen size |
| u_time | float | System | Animation time |
| u_system | 0-2 | Q/F/H buttons | Visual system |
| u_geometry | 0-23 | Geometry grid | Base geometry + core |
| u_rotXY | 0-2π | rotationXY | 3D rotation |
| u_rotXZ | 0-2π | rotationXZ | 3D rotation |
| u_rotYZ | 0-2π | rotationYZ | 3D rotation |
| u_rotXW | 0-2π | rotationXW | 4D rotation |
| u_rotYW | 0-2π | rotationYW | 4D rotation |
| u_rotZW | 0-2π | rotationZW | 4D rotation |
| u_hue | 0-360 | hueShift | Color hue |
| u_saturation | 0-1 | saturation | Color saturation |
| u_brightness | 0-1 | vertexBrightness | Overall brightness |
| u_glowIntensity | 0-3 | glowIntensity | Bloom amount |
| u_rgbSplit | 0-10 | rgbSplitAmount | Chromatic aberration |
| u_morphFactor | 0-1 | morphParameter | Geometry morph |
| u_chaos | 0-1 | chaos | Noise/distortion |
| u_gridDensity | 2-30 | tessellationDensity | Pattern density |
| u_bassEnergy | 0-1 | Audio FFT | Audio reactivity |
| u_midEnergy | 0-1 | Audio FFT | Audio reactivity |
| u_highEnergy | 0-1 | Audio FFT | Audio reactivity |
| u_rmsAmplitude | 0-1 | Audio FFT | Audio reactivity |

---

## PART 3: VISUAL → AUDIO MAPPINGS (Code Trace Results)

**Source**: `lib/mapping/visual_to_audio.dart` lines 37-174

### 3D Rotations (Always Active)

| Visual Parameter | Audio Effect | Code Location | Status |
|-----------------|--------------|---------------|--------|
| XY Rotation | oscillator1Detune (±12 cents) | Lines 72-76 | ✓ WIRED |
| XZ Rotation | oscillator2Detune (±12 cents) | Lines 79-83 | ✓ WIRED |
| YZ Rotation | combinedDetune (±7 cents) | Lines 86-92 | ✓ WIRED |

### 4D Rotations (Core-Dependent)

| Visual Parameter | Audio Effect | Condition | Code Location | Status |
|-----------------|--------------|-----------|---------------|--------|
| XW Rotation | FM depth (0-2 semitones) | Hypersphere (geo 8-15) | Lines 95-101 | ✓ WIRED |
| YW Rotation | Ring mod depth (0-100%) | Hypertetrahedron (geo 16-23) | Lines 104-110 | ✓ WIRED |
| ZW Rotation | Filter cutoff mod (±40%) | All cores | Lines 113-117 | ✓ WIRED |

### Shape Parameters

| Visual Parameter | Audio Effect | Code Location | Status |
|-----------------|--------------|---------------|--------|
| Morph | Waveform crossfade | Lines 120-123 | ✓ WIRED |
| Chaos | Noise injection (0-30%) + filter randomization | Lines 126-137 | ✓ WIRED |
| Animation Speed | LFO rate (0.1-10 Hz) | Lines 140-143 | ✓ WIRED |
| Tessellation | Voice count (1-8) | Lines 146-149 | ✓ WIRED |

### Color/Effect Parameters

| Visual Parameter | Audio Effect | Code Location | Status |
|-----------------|--------------|---------------|--------|
| Hue Shift | Spectral tilt (brightness filter) | Lines 152-155 | ✓ WIRED |
| Glow Intensity | Reverb mix (5-60%) + attack time (1-100ms) | Lines 158-165 | ✓ WIRED |
| Saturation | Filter resonance | Lines 168-171 | ✓ WIRED |

---

## PART 4: AUDIO → VISUAL MAPPINGS (Audio Reactivity)

**Source**: `lib/mapping/audio_to_visual.dart` lines 39-77, `lib/vib3/audio/audio_reactive_modulator.dart`

| Audio Feature | Visual Effect | Status | Issue |
|--------------|---------------|--------|-------|
| Bass Energy (20-250 Hz) | Rotation speed (0.5x-2.5x) | ✓ WIRED | ⚠️ OVERWRITES base value |
| Mid Energy (250-2000 Hz) | Tessellation density (3-8) | ✓ WIRED | ⚠️ OVERWRITES base value |
| High Energy (2000-8000 Hz) | Vertex brightness (0.5-1.0) | ✓ WIRED | ⚠️ OVERWRITES base value |
| Spectral Centroid | Hue shift (dark→red, bright→cyan) | ✓ WIRED | ✓ Additive (correct) |
| RMS Amplitude | Glow intensity | ✓ WIRED | ⚠️ OVERWRITES base value |

---

## PART 5: HIERARCHY MAPPINGS (Working)

### Level 1: Visual System → Sound Family

**Source**: `lib/synthesis/synthesis_branch_manager.dart` lines 51-82

| System | Waveforms | Filter Q | Reverb | Status |
|--------|-----------|----------|--------|--------|
| Quantum | Sine waves | 8-12 (high) | Low | ✓ WORKING |
| Faceted | Square/triangle | 4-8 (moderate) | Medium | ✓ WORKING |
| Holographic | Sawtooth/wavetable | 2-4 (low) | High | ✓ WORKING |

### Level 2: Polytope Core → Synthesis Branch

**Source**: `lib/synthesis/synthesis_branch_manager.dart` lines 246-268, 326-333

| Core | Geometry Range | Synthesis Method | Status |
|------|---------------|------------------|--------|
| Base | 0-7 | Direct synthesis with filtering | ✓ WORKING |
| Hypersphere | 8-15 | FM synthesis | ✓ WORKING |
| Hypertetrahedron | 16-23 | Ring modulation | ✓ WORKING |

### Level 3: Base Geometry → Voice Character

**Source**: `lib/synthesis/synthesis_branch_manager.dart` lines 302-321

| Geometry | Index | Envelope | Character | Status |
|----------|-------|----------|-----------|--------|
| Tetrahedron | 0 | Fast attack | Fundamental, minimal filtering | ✓ WORKING |
| Hypercube | 1 | Medium | Complex, dual oscillators with detune | ✓ WORKING |
| Sphere | 2 | Slow attack | Smooth, filtered harmonics | ✓ WORKING |
| Torus | 3 | Rhythmic | Cyclic, rhythmic phase modulation | ✓ WORKING |
| Klein Bottle | 4 | Asymmetric | Twisted, asymmetric stereo | ✓ WORKING |
| Fractal | 5 | Self-mod | Recursive, self-modulating | ✓ WORKING |
| Wave | 6 | Sweeping | Flowing, sweeping filters | ✓ WORKING |
| Crystal | 7 | Sharp | Crystalline, sharp attack transients | ✓ WORKING |

---

## PART 6: ISSUES IDENTIFIED

### Issue A: Duplicate Sliders in Effects Panel
Effects panel has audio-only duplicates of Synthesis panel's bidirectional sliders:
- Cutoff (Effects) vs Cutoff→Hue (Synthesis)
- Resonance (Effects) vs Resonance→Saturation (Synthesis)
- Reverb Mix (Effects) vs Reverb→Glow (Synthesis)
- Delay Mix (Effects) vs Delay→Distance (Synthesis)

**Solution**: Effects panel should have ONLY the unique parameters (Room Size, Damping, Delay Time, Delay Feedback, Filter Env)

### Issue B: Duplicate Sliders in Geometry Panel
Geometry panel has visual-side controls that duplicate Synthesis panel:
- Hue → Spectral Tilt (same as Cutoff → Hue Shift)
- Glow → Reverb/Attack (same as Reverb Mix → Glow)
- Saturation → Resonance (same as Resonance → Saturation)

**Solution**: Geometry panel should have ONLY geometry-specific params (4D rotations, morph, chaos, tessellation)

### Issue C: Audio Reactivity Overwrites Base Values
In `audio_reactive_modulator.dart:323-333`, audio reactivity REPLACES user values instead of adding modulation:
```dart
// CURRENT (wrong):
tessellationDensity: modulatedTessellation,
vertexBrightness: modulatedBrightness,
glowIntensity: modulatedGlowIntensity,
chaosAmount: modulatedChaos,

// SHOULD BE (correct):
tessellationDensity: state.tessellationDensity + (modulatedTessellation - baseTessellation),
vertexBrightness: state.vertexBrightness + (modulatedBrightness - baseBrightness),
glowIntensity: state.glowIntensity + (modulatedGlowIntensity - baseGlow),
chaosAmount: state.chaosAmount + (modulatedChaos - baseChaos),
```

### Issue D: Visual→Audio Execution Timing ⚠️ CRITICAL
**Source**: `lib/providers/audio_provider.dart` line 162

Visual→Audio mappings are DEFINED in `visual_to_audio.dart` but only EXECUTED on PCM feed callback, NOT at 60 FPS.

Meanwhile Audio→Visual runs at 60 FPS via `parameter_bridge.dart` timer (lines 78-80).

**Result**: Visual changes affect audio only when audio is actively playing and feeding PCM data.

**Solution**: Add Visual→Audio update call to the 60 FPS timer in parameter_bridge.dart

### Issue E: XY/XZ/YZ Rotation Setters Not Triggered
The visual state has setters for rotationXY, rotationXZ, rotationYZ but:
- Synthesis panel: Has OSC1→XY and OSC2→XZ sliders that work
- No UI control for YZ rotation directly

**Note**: YZ rotation IS wired to audio (combinedDetune), just no slider for it currently.

---

## PART 7: PROPOSED PANEL STRUCTURE (Consolidated)

### GEOMETRY Panel (Shape & 4D Space)
- Polytope Core selector (Base/Hypersphere/Hypertetrahedron)
- Base Geometry grid (8 buttons)
- **XW → FM Depth** (shows only when Hypersphere active, geo 8-15)
- **YW → Ring Mod** (shows only when Hypertetrahedron active, geo 16-23)
- **ZW → Filter Mod** (always visible)
- **Morph → Waveform** (always visible)
- **Chaos → Noise** (always visible)
- **Tessellation → Voice Count** (always visible)

### SYNTHESIS Panel (3D Space & Sound Character)
- **XY Rotation → OSC 1 Detune** (bidirectional)
- **XZ Rotation → OSC 2 Detune** (bidirectional)
- **YZ Rotation → Combined Detune** (bidirectional) - ADD SLIDER
- **Brightness → Mix Balance** (bidirectional)
- **Hue → Cutoff** (bidirectional)
- **Saturation → Resonance** (bidirectional)
- **Glow → Reverb** (bidirectional)
- **Speed → LFO Rate** (bidirectional)
- Envelope (ADSR) - audio only, acceptable

### EFFECTS Panel (Refinement Only)
- Filter Envelope Amount
- Reverb Room Size
- Reverb Damping
- Delay Time
- Delay Feedback
- ~~Remove: Cutoff, Resonance, Reverb Mix, Delay Mix~~

### MAPPING Panel (Configuration)
- XY Pad axis assignments
- Pitch range/scale
- Orb controller settings
- Tilt control settings

---

## PART 8: NEXT STEPS (Priority Order)

### HIGH PRIORITY (Bugs)
1. **Fix audio reactivity to be additive** - `audio_reactive_modulator.dart:323-333`
   - Change from replacement to base + modulation offset

2. **Add Visual→Audio to 60 FPS loop** - `parameter_bridge.dart`
   - Ensure visual changes affect audio continuously, not just on PCM feed

### MEDIUM PRIORITY (Cleanup)
3. **Remove duplicate sliders from Effects panel**
   - Delete Cutoff, Resonance, Reverb Mix, Delay Mix sliders
   - Keep only: Filter Env, Room Size, Damping, Delay Time, Delay Feedback

4. **Remove duplicate sliders from Geometry panel**
   - Delete Hue, Glow, Saturation sliders
   - Keep only: 4D rotations, morph, chaos, tessellation

### LOW PRIORITY (Enhancements)
5. **Add YZ Rotation slider to Synthesis panel**
   - Mapping already exists in code, just needs UI control

6. **Conditional 4D rotation sliders**
   - Hide XW slider unless Hypersphere core (geo 8-15)
   - Hide YW slider unless Hypertetrahedron core (geo 16-23)

---

## SUMMARY

**Code Trace Findings** (January 2026):
- ✅ ALL Visual→Audio mappings ARE defined in `visual_to_audio.dart`
- ✅ System→Sound Family hierarchy WORKING
- ✅ Geometry→Branch routing WORKING
- ✅ Voice character per geometry WORKING
- ⚠️ Visual→Audio execution timing needs fix (not 60 FPS)
- ⚠️ Audio reactivity overwrites instead of modulates
- ⚠️ Duplicate sliders across panels need removal

The core bidirectional architecture IS implemented. Issues are execution timing and UI cleanup, not missing functionality.

---

*Document created for planning discussion*
*Updated with code trace corrections - January 2026*
