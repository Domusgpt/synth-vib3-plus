# Synth-VIB3+ Architecture

## Overview

Synth-VIB3+ is a unified audio-visual synthesizer that couples VIB3+ 4D holographic visualization with multi-branch synthesis. Every visual parameter controls both visual and sonic aspects simultaneously.

## Core Concept: Unified Parameter System

**Every parameter is BOTH visual AND sonic**

- Changing geometry changes BOTH what you see AND what you hear
- Rotating in 4D changes BOTH visual rotation AND pitch/filter characteristics
- Morphing changes BOTH visual morphology AND waveform
- ALL parameters are dual-purpose

## Three-Level Hierarchy

**IMPORTANT**: The hierarchy is a 3D matrix where ALL THREE levels interact:

```
Geometry Index = (Core × 8) + BaseGeometry
Example: Hypersphere Torus = (1 × 8) + 3 = 11

FINAL SOUND = SoundFamily (from System) + SynthesisBranch (from Core) + VoiceCharacter (from BaseGeometry)
```

### Level 1: Visual Systems → Sound Families (Timbre Character)

The **Visual System** (Quantum/Faceted/Holographic) controls the **Sound Family** - the overall timbre character and filter characteristics that apply ACROSS all synthesis branches and geometries.

#### Quantum System (Harmonic/Pure)
**Visual**: Precise geometric forms with mathematical accuracy
**Sonic**: Pure harmonic synthesis characteristics
- Sine-dominant waveforms (even when using FM or Ring Mod)
- High resonance filters (Q: 8-12)
- Minimal noise injection (< 5%)
- Clean, crystalline timbres
- **Applies to**: All Base, Hypersphere, AND Hypertetrahedron geometries

#### Faceted System (Geometric/Hybrid)
**Visual**: Sharp polygonal forms with defined edges
**Sonic**: Geometric/Hybrid synthesis characteristics
- Square and triangle waves (even when using FM or Ring Mod)
- Moderate resonance (Q: 4-8)
- Sharp transients, clear attacks
- Structured, architectural sounds
- **Applies to**: All Base, Hypersphere, AND Hypertetrahedron geometries

#### Holographic System (Spectral/Rich)
**Visual**: Flowing, layered, atmospheric forms
**Sonic**: Spectral/Rich synthesis characteristics
- Wavetable and sawtooth waves (even when using FM or Ring Mod)
- Low resonance (Q: 2-4)
- High reverb mix (40-60%)
- Atmospheric, evolving timbres
- **Applies to**: All Base, Hypersphere, AND Hypertetrahedron geometries

### Level 2: Polytope Cores → Synthesis Branches (Synthesis Method)

The **Polytope Core** (Base/Hypersphere/Hypertetrahedron) controls the **Synthesis Branch** - the fundamental synthesis method used to generate sound.

#### Base Core (Geometries 0-7) → Direct Synthesis
**Visual**: Original base polytope forms (no additional hypersphere/hypertetra wrapper)
**Synthesis Method**: Direct oscillator output with filtering
- Two oscillators tuned in unison or slight detune
- Multimode filter (lowpass/bandpass/highpass)
- Simple envelope (ADSR)
- Straightforward, immediate sound
- **Works with**: All 3 sound families (Quantum/Faceted/Holographic)

#### Hypersphere Core (Geometries 8-15) → FM Synthesis
**Visual**: Base geometries wrapped in hypersphere (sphere in 4D)
**Synthesis Method**: Frequency modulation
- Carrier oscillator modulated by modulator
- FM depth controlled by 4D rotation (XW, YW)
- Complex harmonic content
- Metallic, bell-like, or growling timbres
- **Works with**: All 3 sound families (Quantum=clean FM, Faceted=aggressive FM, Holographic=atmospheric FM)

#### Hypertetrahedron Core (Geometries 16-23) → Ring Modulation
**Visual**: Base geometries wrapped in hypertetrahedron (simplex in 4D)
**Synthesis Method**: Ring modulation (multiplication)
- Two oscillators multiplied together
- Ring mod depth controlled by 4D rotation (YW)
- Creates sum and difference frequencies
- Inharmonic, metallic sounds
- **Works with**: All 3 sound families (Quantum=pure ring mod, Faceted=harsh ring mod, Holographic=evolving ring mod)

### Level 3: Geometries → Voice Characters (Fine Detail)

The **Base Geometry** (Tetrahedron/Hypercube/Sphere/Torus/Klein/Fractal/Wave/Crystal) controls the **Voice Character** - the fine details of envelope, reverb, and harmonic content.

Each of the 8 base geometries has unique sonic characteristics that apply regardless of which system or core is active:

**Example**: A "Torus" geometry will have cyclic phase modulation and rhythmic filter sweeps whether it's:
- Quantum Torus (geometry 3) = Direct synthesis with pure timbres
- Faceted Hypersphere Torus (geometry 11) = FM synthesis with geometric timbres
- Holographic Hypertetrahedron Torus (geometry 19) = Ring mod synthesis with rich timbres

## 3D Matrix Examples

To make the hierarchy crystal clear, here are specific examples:

### Example 1: Quantum Base Tetrahedron (Geometry 0)
- **Visual System**: Quantum (precise, mathematical)
- **Polytope Core**: Base (no wrapper)
- **Base Geometry**: Tetrahedron (4 vertices)
- **Synthesis Branch**: Direct (from Base core)
- **Sound Family**: Harmonic/Pure (from Quantum system)
- **Voice Character**: Fundamental (from Tetrahedron geometry)
- **Result**: Pure sine wave, minimal filtering, straightforward direct synthesis

### Example 2: Faceted Hypersphere Torus (Geometry 11)
- **Visual System**: Faceted (sharp polygonal forms)
- **Polytope Core**: Hypersphere (wrapped in 4D sphere)
- **Base Geometry**: Torus (donut shape)
- **Synthesis Branch**: FM synthesis (from Hypersphere core)
- **Sound Family**: Geometric/Hybrid (from Faceted system, square/triangle waves)
- **Voice Character**: Cyclic (from Torus geometry, rhythmic filters)
- **Result**: FM synthesis using square waves as carrier/modulator, moderate resonance, rhythmic filter sweeps

### Example 3: Holographic Hypertetrahedron Crystal (Geometry 23)
- **Visual System**: Holographic (flowing, layered, atmospheric)
- **Polytope Core**: Hypertetrahedron (wrapped in 4D simplex)
- **Base Geometry**: Crystal (faceted crystalline)
- **Synthesis Branch**: Ring modulation (from Hypertetrahedron core)
- **Sound Family**: Spectral/Rich (from Holographic system, sawtooth waves)
- **Voice Character**: Crystalline (from Crystal geometry, sharp attacks, high resonance)
- **Result**: Ring modulation using sawtooth waves, low-Q filter, high reverb, very fast attack, inharmonic metallic bell-like sound

### Complete 72-Combination Space

There are **72 unique sound+visual combinations** total:
- 3 Visual Systems × 24 Geometries = 72 combinations
- OR: 3 Systems × 3 Cores × 8 Base Geometries = 72 combinations

Each combination is UNIQUE because it combines:
1. **Timbre character** from the Visual System
2. **Synthesis method** from the Polytope Core
3. **Voice details** from the Base Geometry

### The 8 Base Geometries (Detailed)

#### 1. Tetrahedron (Fundamental)
**Visual**: Simple 4-vertex polytope
**Sonic**:
- Single oscillator (sine for Quantum, square for Faceted, saw for Holographic)
- Minimal filtering (gentle lowpass)
- Short attack (5ms), medium release (200ms)
- Reverb: 10%
- **Use Case**: Bass notes, pure tones

#### 2. Hypercube (Complex)
**Visual**: 8-vertex tesseract projection
**Sonic**:
- Dual oscillators with ±7 cents detune
- Moderate filtering (resonant lowpass, Q: 6)
- Medium attack (20ms), long release (500ms)
- Reverb: 25%
- **Use Case**: Pads, sustained chords

#### 3. Sphere (Smooth)
**Visual**: Continuous curved surface
**Sonic**:
- Filtered harmonics (removes odd harmonics)
- Gentle lowpass filter (Q: 2)
- Slow attack (50ms), medium release (300ms)
- Reverb: 20%
- **Use Case**: Smooth leads, flutes

#### 4. Torus (Cyclic)
**Visual**: Donut-shaped form with cyclic symmetry
**Sonic**:
- Phase modulation applied cyclically
- Rhythmic filter sweeps (sync to rotation speed)
- Fast attack (10ms), short release (150ms)
- Reverb: 15%
- **Use Case**: Rhythmic elements, arpeggios

#### 5. Klein Bottle (Twisted)
**Visual**: Non-orientable surface (twisted topology)
**Sonic**:
- Asymmetric stereo (L/R phase offset)
- Chorus effect (5-10ms delay)
- Medium attack (30ms), medium release (250ms)
- Reverb: 30%
- **Use Case**: Wide stereo pads, chorus effects

#### 6. Fractal (Recursive)
**Visual**: Self-similar recursive patterns
**Sonic**:
- Self-modulating oscillators (feedback)
- Complex harmonic series
- Variable attack (10-50ms), long release (600ms)
- Reverb: 35%
- **Use Case**: Evolving textures, drones

#### 7. Wave (Flowing)
**Visual**: Undulating wave patterns
**Sonic**:
- Sweeping filters (LFO-controlled cutoff)
- High filter resonance (Q: 10)
- Slow attack (40ms), long release (400ms)
- Reverb: 40%
- **Use Case**: Sweeping pads, ocean sounds

#### 8. Crystal (Crystalline)
**Visual**: Faceted crystalline structures
**Sonic**:
- Sharp attack transients
- High resonance peaks (Q: 12)
- Very fast attack (1ms), short release (100ms)
- Reverb: 45%
- **Use Case**: Plucks, bells, percussive tones

## Parameter Mappings: Visual → Sonic

### 6D Rotation (Core Visual Parameter)

#### XY Rotation (3D Plane 1)
**Visual**: Rotation in standard XY plane
**Sonic**: Oscillator 1 detune
- Range: ±12 cents
- Smooth transitions

#### XZ Rotation (3D Plane 2)
**Visual**: Rotation in XZ plane
**Sonic**: Oscillator 2 detune
- Range: ±12 cents
- Creates beating patterns when combined with XY

#### YZ Rotation (3D Plane 3)
**Visual**: Rotation in YZ plane
**Sonic**: Combined detuning effect
- Range: ±7 cents both oscillators
- Subtle chorusing

#### XW Rotation (4D Plane 1)
**Visual**: Rotation into 4th dimension W
**Sonic**: FM depth modulation (for Hypersphere core)
- Range: 0-2 semitones
- Creates harmonic complexity

#### YW Rotation (4D Plane 2)
**Visual**: Rotation in YW 4D plane
**Sonic**: Ring mod depth (for Hypertetrahedron core)
- Range: 0-100% wet/dry mix
- Increases inharmonicity

#### ZW Rotation (4D Plane 3)
**Visual**: Rotation in ZW 4D plane
**Sonic**: Filter cutoff modulation
- Range: ±40% of base cutoff
- Brightens/darkens timbre

### Morph Parameter
**Visual**: Interpolates between geometry variants
**Sonic**: Waveform crossfade
- Quantum: sine → triangle → saw
- Faceted: square → pulse → saw
- Holographic: wavetable A → B → C

### Chaos Parameter
**Visual**: Adds randomness to vertex positions
**Sonic**: Noise injection + filter randomization
- Adds white noise (0-30% mix)
- Randomizes filter cutoff (±10%)
- Creates gritty, unstable timbres

### Speed Parameter
**Visual**: Animation/rotation speed
**Sonic**: LFO rate for ALL modulations
- Controls filter sweep rate
- Controls vibrato speed
- Controls tremolo speed
- Range: 0.1-10 Hz

### Hue Shift
**Visual**: Color rotation through spectrum
**Sonic**: Spectral tilt (brightness filter)
- Red (hue: 0°) = Dark (lowpass, cutoff at 2kHz)
- Yellow (hue: 60°) = Warm (gentle boost at 1kHz)
- Green (hue: 120°) = Neutral (flat response)
- Cyan (hue: 180°) = Cool (gentle boost at 4kHz)
- Blue (hue: 240°) = Bright (highpass, cutoff at 500Hz)
- Magenta (hue: 300°) = Mixed (notch filter at 1kHz)

### Glow Intensity
**Visual**: Brightness/bloom effect
**Sonic**: Reverb mix + attack time
- Low glow (0.0) = 5% reverb, 1ms attack
- High glow (3.0) = 60% reverb, 100ms attack
- Creates sense of space and smoothness

### Tessellation Density
**Visual**: Subdivision level of geometry
**Sonic**: Voice count (polyphony)
- Density 1-3 = 1 voice (monophonic)
- Density 4-6 = 3 voices (triad)
- Density 7-8 = 5 voices (pentatonic)
- Density 9-10 = 8 voices (full polyphony)

### Projection Mode
**Visual**: Method of projecting 4D→3D→2D
**Sonic**: Stereo width + spatial processing
- Orthographic = Mono (no stereo separation)
- Perspective = Wide stereo (90° width)
- Stereographic = Ultra-wide (180° width)

### Complexity Parameter
**Visual**: Additional geometric detail
**Sonic**: Harmonic richness
- Low complexity = Fundamental + 2 harmonics
- High complexity = Fundamental + 8 harmonics
- Affects timbre brightness

## Audio Reactivity System (Always On)

Audio analysis runs continuously and modulates visual parameters:

### Bass Energy (20-250 Hz)
**Modulates**: Rotation speed (all 6 axes)
- Range: 0.5x to 2.5x base speed
- Creates pulsing, rhythmic visuals

### Mid Energy (250-2000 Hz)
**Modulates**: Tessellation density
- Range: 3 to 8
- More energy = more subdivisions

### High Energy (2000-8000 Hz)
**Modulates**: Vertex brightness
- Range: 0.5 to 1.0
- Brighter vertices on high-frequency content

### Spectral Centroid
**Modulates**: Hue shift
- Low centroid (dark timbre) = red/orange hues
- High centroid (bright timbre) = cyan/blue hues

### RMS Amplitude
**Modulates**: Glow intensity
- Quiet = minimal glow
- Loud = maximum glow and bloom

## Device Input Mapping (Assignable)

### Tilt X (Phone tilted left/right)
**Assignable to**:
- Pitch bend (±2 semitones)
- Filter cutoff (±50%)
- Stereo pan (-100% to +100%)
- Reverb mix (0-80%)

### Tilt Y (Phone tilted forward/back)
**Assignable to**:
- Vibrato depth (0-1 semitone)
- Tremolo depth (0-50%)
- Distortion amount (0-100%)
- Delay feedback (0-80%)

### Pinch/Spread Gesture
**Controls**: Master volume + visual zoom
- Pinch in = quieter, zoomed out
- Spread out = louder, zoomed in

### Touch XY Position
**Controls**: Multi-parameter pad
- X axis: Morph parameter
- Y axis: Chaos parameter

## UI Architecture

### Single Unified Control Panel

#### Section 1: System/Core/Geometry Selector
- Dropdown: Quantum / Faceted / Holographic
- Dropdown: Base / Hypersphere / Hypertetrahedron
- Grid: 8 geometry buttons with visual+sonic preview

#### Section 2: 6D Rotation Controls
- 6 sliders (XY, XZ, YZ, XW, YW, ZW)
- Visual: Shows rotation angle
- Sonic: Shows detuning/modulation amount

#### Section 3: Morphology & Effects
- Morph slider (visual interpolation + waveform blend)
- Chaos slider (visual randomness + noise injection)
- Speed slider (animation + LFO rate)

#### Section 4: Color & Ambience
- Hue Shift dial (color + spectral tilt)
- Glow Intensity slider (brightness + reverb)

#### Section 5: Geometry Complexity
- Tessellation density (subdivisions + polyphony)
- Projection mode (3D view + stereo width)
- Complexity slider (detail + harmonics)

#### Section 6: Device Input Assignments
- Tilt X → [Dropdown: Pitch / Filter / Pan / Reverb]
- Tilt Y → [Dropdown: Vibrato / Tremolo / Distortion / Delay]

#### Section 7: Audio Reactivity (Always On, No Toggle)
- Display showing current audio analysis values
- Visual feedback of what's being modulated
- Cannot be disabled (core feature)

## Implementation Priority

### Phase 1: Core System (Week 1)
- Implement 3 synthesis branches (Direct, FM, Ring Mod)
- Create 8 geometry voice presets
- Connect geometry selection to synthesis engine

### Phase 2: Parameter Mapping (Week 2)
- Map 6D rotation to detuning/modulation
- Implement morph → waveform crossfade
- Connect chaos → noise injection
- Link speed → LFO system

### Phase 3: UI Integration (Week 3)
- Merge VIB3+ visual controls with synthesis controls
- Create unified parameter panel
- Implement device tilt assignment system
- Remove audio reactivity toggle (make permanent)

### Phase 4: Polish & Testing (Week 4)
- Optimize performance (60 FPS target)
- Test all 72 combinations (3 systems × 24 geometries)
- Verify each combination has unique sonic+visual character
- Deploy to Android device for real-world testing

## File Structure

```
lib/
├── synthesis/
│   ├── direct_synthesis_engine.dart       # Base core synthesis
│   ├── fm_synthesis_engine.dart           # Hypersphere core FM
│   ├── ring_mod_synthesis_engine.dart     # Hypertetrahedron ring mod
│   ├── geometry_voice_bank.dart           # 8 voice characters
│   └── sound_family_manager.dart          # System→family mapping
├── mapping/
│   ├── unified_parameter_bridge.dart      # Central parameter hub
│   ├── rotation_to_synthesis_mapper.dart  # 6D rotation mappings
│   ├── audio_reactive_system.dart         # Always-on reactivity
│   └── device_input_mapper.dart           # Tilt/touch assignments
├── visualization/
│   ├── vib3plus_integration.dart          # VIB3+ WebView
│   └── visual_parameter_controller.dart   # Visual state management
└── ui/
    ├── unified_control_panel.dart         # Main UI
    ├── geometry_selector_widget.dart      # Grid selector
    ├── rotation_controls_widget.dart      # 6D sliders
    └── device_assignment_widget.dart      # Tilt mapping UI
```

---

A Paul Phillips Manifestation
Paul@clearseassolutions.com
"The Revolution Will Not be in a Structured Format"
© 2025 Paul Phillips - Clear Seas Solutions LLC
