# Parameter Audit & Mapping Plan

**Purpose**: Document current state vs. planned state for all parameters

---

## PART 1: CURRENT UI STATE (What Exists Now)

### Panel: GEOMETRY (geometry_panel.dart)

| Slider | Current Visual Effect | Current Audio Effect | Notes |
|--------|----------------------|---------------------|-------|
| XW: FM Depth / Detune 1 | rotationXW (4D rotation) | NONE | Audio mapping not implemented |
| YW: Ring Mod / Detune 2 | rotationYW (4D rotation) | NONE | Audio mapping not implemented |
| ZW: Filter Cutoff | rotationZW (4D rotation) | NONE | Audio mapping not implemented |
| Modulation Rate (LFO) | rotationSpeed | NONE | Audio mapping not implemented |
| Reverb Amount | projectionDistance | NONE | Just stored, not sent to JS |
| Delay / Echo Depth | layerSeparation | NONE | Just stored, not sent to JS |
| Waveform Crossfade | morphParameter → morphFactor | NONE | |
| Density → Voice Count | tessellationDensity → gridDensity | NONE | |
| Chaos → Noise | rgbSplitAmount → chaos | NONE | |
| Hue → Spectral Tilt | hueShift → hue | NONE | |
| Glow → Reverb/Attack | glowIntensity → saturation | NONE | |
| Saturation → Resonance | saturation | NONE | |

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

## PART 3: PLANNED MAPPINGS (from CLAUDE.md)

### Visual → Audio (User Controls Visual, Audio Follows)

| Visual Parameter | Audio Effect | Status |
|-----------------|--------------|--------|
| XY Rotation | Oscillator 1 detune (±12 cents) | ✓ Implemented in Synthesis panel |
| XZ Rotation | Oscillator 2 detune (±12 cents) | ✓ Implemented in Synthesis panel |
| YZ Rotation | Combined detuning (±7 cents) | ✗ NOT IMPLEMENTED |
| XW Rotation | FM depth (0-2 semitones) - Hypersphere only | ✗ NOT IMPLEMENTED |
| YW Rotation | Ring mod depth (0-100%) - Hypertetrahedron only | ✗ NOT IMPLEMENTED |
| ZW Rotation | Filter cutoff modulation (±40%) | ✗ NOT IMPLEMENTED |
| Morph | Waveform crossfade | ✗ NOT IMPLEMENTED |
| Chaos | Noise injection (0-30%) + filter randomization | ✗ NOT IMPLEMENTED |
| Speed | LFO rate for all modulations (0.1-10 Hz) | ✗ NOT IMPLEMENTED |
| Hue Shift | Spectral tilt (brightness filter) | ✓ Via Cutoff→Hue in Synthesis |
| Glow Intensity | Reverb mix (5-60%) + attack time (1-100ms) | ✓ Via Reverb→Glow in Synthesis |
| Tessellation Density | Voice count/polyphony (1-8 voices) | ✗ NOT IMPLEMENTED |

### Audio → Visual (Audio Reactivity, Always On)

| Audio Feature | Visual Effect | Status |
|--------------|---------------|--------|
| Bass Energy (20-250 Hz) | Rotation speed (0.5x-2.5x) | ⚠️ OVERWRITES instead of modulates |
| Mid Energy (250-2000 Hz) | Tessellation density (3-8) | ⚠️ OVERWRITES instead of modulates |
| High Energy (2000-8000 Hz) | Vertex brightness (0.5-1.0) | ⚠️ OVERWRITES instead of modulates |
| Spectral Centroid | Hue shift (dark→red, bright→cyan) | ✓ Additive (correct) |
| RMS Amplitude | Glow intensity | ⚠️ OVERWRITES instead of modulates |

---

## PART 4: HIERARCHY (from CLAUDE.md)

### Level 1: Visual System → Sound Family

| System | Waveforms | Filter Q | Reverb | Character |
|--------|-----------|----------|--------|-----------|
| Quantum | Sine waves | 8-12 (high) | Low | Pure harmonic |
| Faceted | Square/triangle | 4-8 (moderate) | Medium | Geometric hybrid |
| Holographic | Sawtooth/wavetable | 2-4 (low) | High | Spectral rich |

### Level 2: Polytope Core → Synthesis Branch

| Core | Geometry Range | Synthesis Method |
|------|---------------|------------------|
| Base | 0-7 | Direct synthesis with filtering |
| Hypersphere | 8-15 | FM synthesis |
| Hypertetrahedron | 16-23 | Ring modulation |

### Level 3: Base Geometry → Voice Character

| Geometry | Index | Envelope | Character |
|----------|-------|----------|-----------|
| Tetrahedron | 0 | Fast attack | Fundamental, minimal filtering |
| Hypercube | 1 | Medium | Complex, dual oscillators with detune |
| Sphere | 2 | Slow attack | Smooth, filtered harmonics |
| Torus | 3 | Rhythmic | Cyclic, rhythmic phase modulation |
| Klein Bottle | 4 | Asymmetric | Twisted, asymmetric stereo |
| Fractal | 5 | Self-mod | Recursive, self-modulating |
| Wave | 6 | Sweeping | Flowing, sweeping filters |
| Crystal | 7 | Sharp | Crystalline, sharp attack transients |

---

## PART 5: ISSUES IDENTIFIED

### Issue A: Duplicate Sliders
Effects panel has audio-only duplicates of Synthesis panel's bidirectional sliders:
- Cutoff (Effects) vs Cutoff→Hue (Synthesis)
- Resonance (Effects) vs Resonance→Saturation (Synthesis)
- Reverb Mix (Effects) vs Reverb→Glow (Synthesis)
- Delay Mix (Effects) vs Delay→Distance (Synthesis)

**Solution**: Effects panel should have ONLY the unique parameters (Room Size, Damping, Delay Time, Delay Feedback, Filter Env)

### Issue B: Geometry Panel Has Visual-Only Duplicates
Geometry panel has visual-side controls that duplicate Synthesis panel:
- Hue → Spectral Tilt (same as Cutoff → Hue Shift)
- Glow → Reverb/Attack (same as Reverb Mix → Glow)
- Saturation → Resonance (same as Resonance → Saturation)

**Solution**: Geometry panel should have ONLY geometry-specific params (4D rotations, morph, chaos, tessellation)

### Issue C: Audio Reactivity Overwrites Base Values
In `audio_reactive_modulator.dart:323-333`, audio reactivity replaces user values:
```dart
tessellationDensity: modulatedTessellation,  // Should be: state.tessellationDensity + modulation
vertexBrightness: modulatedBrightness,       // Should be: state.vertexBrightness + modulation
glowIntensity: modulatedGlowIntensity,       // Should be: state.glowIntensity + modulation
chaosAmount: modulatedChaos,                 // Should be: state.chaosAmount + modulation
```

### Issue D: 4D Rotations Not Mapped to Audio
XW, YW, ZW rotations in Geometry panel only update visual, not audio.
Per CLAUDE.md:
- XW → FM depth (Hypersphere only)
- YW → Ring mod depth (Hypertetrahedron only)
- ZW → Filter cutoff modulation

---

## PART 6: PROPOSED PANEL STRUCTURE

### GEOMETRY Panel (Shape & Space)
- Polytope Core selector (Base/Hypersphere/Hypertetrahedron)
- Base Geometry grid (8 buttons)
- **XW → FM Depth** (bidirectional, Hypersphere core active)
- **YW → Ring Mod** (bidirectional, Hypertetra core active)
- **ZW → Filter Mod** (bidirectional)
- **Morph → Waveform** (bidirectional)
- **Chaos → Noise** (bidirectional)
- **Tessellation → Voice Count** (bidirectional)

### SYNTHESIS Panel (Sound Character)
- **XY Rotation → OSC 1 Detune** (bidirectional)
- **XZ Rotation → OSC 2 Detune** (bidirectional)
- **YZ Rotation → Combined Detune** (bidirectional) - NEW
- **Brightness → Mix Balance** (bidirectional)
- **Hue → Cutoff** (bidirectional)
- **Saturation → Resonance** (bidirectional)
- **Glow → Reverb** (bidirectional)
- **Speed → LFO Rate** (bidirectional) - NEW
- Envelope (ADSR) - audio only, acceptable

### EFFECTS Panel (Refinement)
- Filter Envelope Amount - unique
- Reverb Room Size - unique
- Reverb Damping - unique
- Delay Time - unique
- Delay Feedback - unique
- (Remove duplicates: Cutoff, Resonance, Reverb Mix, Delay Mix)

### MAPPING Panel (Configuration)
- XY Pad axis assignments
- Pitch range/scale
- Orb controller settings
- Tilt control settings

---

## NEXT STEPS

1. Fix audio reactivity to be additive (base + modulation)
2. Remove duplicate sliders from Effects panel
3. Remove duplicate sliders from Geometry panel
4. Implement missing audio mappings for 4D rotations
5. Implement morph → waveform crossfade
6. Implement chaos → noise injection
7. Implement tessellation → voice count
8. Add YZ rotation → combined detune
9. Add speed → LFO rate

---

*Document created for planning discussion*
