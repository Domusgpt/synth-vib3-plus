# Synth-VIB3+ Architecture Plan

## CORE DESIGN PRINCIPLE

**Every control has BOTH sonic AND visual effect. No exceptions.**

There are no "audio controls" or "visual controls" - only **unified parameters** that affect both simultaneously.

---

## THE 72-COMBINATION MATRIX

### Visual System (3) → Sound Family + Color Palette
| System | Sound Family | Visual Palette | Filter Q | Reverb | Harmonics |
|--------|--------------|----------------|----------|--------|-----------|
| **Quantum** | Pure/Harmonic | Cyan/Blue/Purple | 8-12 (resonant) | 20% | Sine-dominant |
| **Faceted** | Geometric/Hybrid | Orange/Yellow/Red | 4-8 (balanced) | 30% | Square/Triangle |
| **Holographic** | Spectral/Rich | Green/Teal/White | 2-4 (warm) | 45% | Sawtooth/Complex |

### Polytope Core (3) → Synthesis Branch + Geometry Warping
| Core | Synthesis | Visual Effect | Frequency Relationship |
|------|-----------|---------------|------------------------|
| **Base (0-7)** | Direct (additive) | Standard 4D projection | Fundamental + harmonics |
| **Hypersphere (8-15)** | FM Synthesis | Spherical warping | Carrier × modulator ratio |
| **Hypertetrahedron (16-23)** | Ring Modulation | Tetrahedral warping | Sum/difference frequencies |

### Base Geometry (8) → Voice Character + Vertex Structure
| Geometry | Voice Character | Vertices | Attack | Release | Detune |
|----------|-----------------|----------|--------|---------|--------|
| **Tetrahedron** | Fundamental | 5 | 10ms | 250ms | 0¢ |
| **Hypercube** | Complex | 16 | 25ms | 400ms | 8¢ |
| **Sphere** | Smooth | 120 | 60ms | 350ms | 0¢ |
| **Torus** | Cyclic | 200 | 15ms | 200ms | 5¢ |
| **Klein Bottle** | Twisted | 80 | 35ms | 300ms | 12¢ |
| **Fractal** | Recursive | 256 | 30ms | 500ms | 7¢ |
| **Wave** | Flowing | 64 | 50ms | 450ms | 3¢ |
| **Crystal** | Crystalline | 48 | 2ms | 150ms | 0¢ |

---

## UNIFIED PARAMETER MAPPING

### Primary Controls (Geometry Panel)

| Parameter | Visual Effect | Audio Effect |
|-----------|---------------|--------------|
| **System (Q/F/H)** | Color palette + shader style | Sound family (waveform mix, filter Q) |
| **Polytope Core** | 4D projection warping | Synthesis branch (Direct/FM/Ring) |
| **Base Geometry** | Vertex structure + count | Voice character (envelope, harmonics) |
| **XY Rotation** | Rotation in XY plane | OSC 1 detune (±12¢) |
| **XZ Rotation** | Rotation in XZ plane | OSC 2 detune (±12¢) |
| **YZ Rotation** | Rotation in YZ plane | Stereo width (combined detune) |
| **XW Rotation** | 4D rotation (W dimension) | FM depth (Hypersphere) / Freq mod |
| **YW Rotation** | 4D rotation (W dimension) | Ring mod depth (Hypertetra) / Freq mod |
| **ZW Rotation** | 4D rotation (W dimension) | Filter cutoff modulation (±40%) |
| **Speed** | Animation speed | LFO rate for all modulations |
| **Morph** | Geometry interpolation | Wavetable position / waveform crossfade |
| **Chaos** | RGB split + distortion | Noise injection (0-30%) + filter random |
| **Tessellation** | Subdivision density | Voice count / polyphony (1-8) |
| **Glow** | Bloom intensity | Reverb mix (5-60%) |
| **Projection Distance** | Camera distance | Reverb room size |
| **Layer Separation** | Holographic depth | Delay time (0-500ms) |
| **Hue** | Color hue offset | Spectral tilt (brightness filter) |
| **Brightness** | Vertex intensity | Output level modulation |
| **Saturation** | Color saturation | Harmonic richness / drive |

### XY Performance Pad
| Axis | Visual Effect | Audio Effect |
|------|---------------|--------------|
| **X Position** | Cursor horizontal | Pitch (MIDI note, scale-quantized) |
| **Y Position** | Cursor vertical | Assignable: Filter/Resonance/Morph/etc |
| **Touch Pressure** | Ripple intensity | Velocity / aftertouch |

### Orb Controller
| Control | Visual Effect | Audio Effect |
|---------|---------------|--------------|
| **X Drag** | Orb position X | Pitch bend (±1-12 semitones) |
| **Y Drag** | Orb position Y | Vibrato depth (0-2 semitones) |
| **Tilt X** | Auto-move X | Pitch bend via accelerometer |
| **Tilt Y** | Auto-move Y | Vibrato via accelerometer |

---

## PANEL RESTRUCTURE PROPOSAL

### Current Problem
- **Synthesis Panel** duplicates geometry controls (branch selector = core selector)
- **Effects Panel** has audio-only controls with no visual parity
- **Mapping Panel** is configuration, not performance

### Proposed Solution

#### Keep: Geometry Panel (Primary Performance)
All controls here affect BOTH audio and visual. This is the main performance interface.

#### Remove: Synthesis Panel
- Branch selector → already in Geometry Panel (Polytope Core)
- OSC tuning → XY/XZ rotation does this
- Envelope → derived from Base Geometry (or add override sliders to Geometry Panel)

#### Transform: Effects Panel → "Character Panel"
Make every effect have visual parity:
| Control | Audio | Visual |
|---------|-------|--------|
| **Drive/Saturation** | Harmonic distortion | Color saturation |
| **Warmth** | Low-pass filter | Warm color tint |
| **Space** | Reverb mix + size | Glow + projection distance |
| **Echo** | Delay time + feedback | Layer separation + trails |
| **Resonance** | Filter Q peak | Edge sharpness / glow focus |

#### Keep: Mapping Panel (Configuration)
This is setup, not performance. Keep for:
- XY pad axis assignment
- Pitch range configuration
- Scale selection
- Pitch bend/vibrato range

### Side Bezels (Portrait Mode)

**Left Bezel - Quick Octave/Range:**
| Button | Function |
|--------|----------|
| **Oct -** | Shift pitch range down 12 notes |
| **Oct +** | Shift pitch range up 12 notes |
| **Range** | Quick select: Bass/Mid/High register |

**Right Bezel - Quick Modulation:**
| Button | Function |
|--------|----------|
| **Filter±** | Quick filter sweep (already exists) |
| **Chaos±** | Quick chaos amount |
| **Space±** | Quick reverb/glow amount |

---

## WHAT'S BROKEN & FIX PLAN

### P0: Audio Not Playing
1. **Race condition** - audio init before PCM ready (FIXED in last commit)
2. **Touch occlusion** - XY pad may block events. Check `HitTestBehavior`

### P1: Controls Not Working
1. **Geometry buttons** - verify `setGeometry()` is being called
2. **Chaos** - XY pad maps chaos to morph (WRONG). Fix: map to actual chaos
3. **Grid density** - verify `setTessellationDensity()` reaches JS
4. **Speed** - currently affects rotation speed, should affect LFO rate too

### P2: Missing Parity
1. **Saturation** - add slider, map to audio drive + visual saturation
2. **FM/Ring depth** - implement stub methods in audio_provider
3. **Delay feedback** - already synced (fixed in last commit)

---

## IMPLEMENTATION ORDER

1. **Fix touch/audio conflict** - ensure XY pad doesn't block audio
2. **Wire broken controls** - geometry buttons, chaos, grid density
3. **Add saturation** - both audio (drive) and visual (color sat)
4. **Remove redundant panels** - consolidate synthesis into geometry
5. **Transform effects panel** - add visual parity to all effects
6. **Polish side bezels** - useful quick controls

---

## FILE CHANGES NEEDED

| File | Change |
|------|--------|
| `xy_performance_pad.dart` | Fix chaos mapping, check HitTestBehavior |
| `audio_provider.dart` | Implement setFMDepth(), setRingModMix(), add saturation |
| `synthesis_branch_manager.dart` | Add FM depth, ring mod depth, saturation/drive |
| `visual_provider.dart` | Add saturation parameter, wire to JS |
| `geometry_panel.dart` | Add saturation slider, verify all controls work |
| `synthesis_panel.dart` | Consider removing or merging into geometry |
| `effects_panel.dart` | Add visual parity indicators, transform to "Character Panel" |
| `collapsible_bezel.dart` | Update side bezel quick controls |

---

*A Paul Phillips Manifestation*
