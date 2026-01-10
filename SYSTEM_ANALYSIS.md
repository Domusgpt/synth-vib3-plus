# System Analysis Report

## Overview

This document analyzes the Synth-VIB3+ architecture to identify what's working, what's broken, and what's missing.

---

## SHADER SYSTEM: VERIFIED WORKING

The fragment shader (`shaders/vib3_core.frag`) correctly implements:

### Three Visual Systems
- **Quantum** (u_system=0): 5-layer color explosions, extreme RGB separation
- **Faceted** (u_system=1): Clean geometric edges, sharp detection
- **Holographic** (u_system=2): 5-layer parallax depth with shimmer

### System Selection Code (lines 685-691)
```glsl
float isQuantum = step(u_system, 0.5);
float isFaceted = step(0.5, u_system) * step(u_system, 1.5);
float isHolo = step(1.5, u_system);

color = renderQuantum(uv, value, pos) * isQuantum;
color += renderFaceted(uv, value, pos) * isFaceted;
color += renderHolographic(uv, value, pos) * isHolo;
```

### 5-Layer Implementation

The layers are calculated **per-pixel in the shader**, not as separate Canvas draws:

**Holographic Layers:**
| Layer | Role | Density | Speed | Alpha |
|-------|------|---------|-------|-------|
| 0 | Background | 0.4x | 0.2x | 0.6 |
| 1 | Shadow | 0.8x | 0.3x | 0.4 |
| 2 | Content | 1.0x | 1.0x | 0.95 |
| 3 | Highlight | 1.5x | 0.8x | 0.8 |
| 4 | Accent | 2.5x | 0.4x | 0.3 |

---

## AUDIO → VISUAL: CONDITIONAL

Audio reactivity only works when:
1. `audioProvider.isPlaying == true`
2. `audioProvider.currentFeatures != null`

### Data Flow
```
AudioProvider.currentFeatures
    ↓
synth_main_screen.dart:275-285
    ↓
AudioReactivityData {
  bassEnergy, midEnergy, highEnergy, rmsAmplitude
}
    ↓
VIB3AnimatedShaderWidget(audioData: ...)
    ↓
Shader uniforms: u_bassEnergy, u_midEnergy, u_highEnergy, u_rmsAmplitude
```

### Shader Audio Usage
- Grid density: `gridSize *= 1.0 + u_bassEnergy * 0.3`
- Geometry intensity: `geomIntensity += u_rmsAmplitude * 0.3`
- Edge emphasis: `edge * (0.8 + u_midEnergy * 0.4)`
- Rotation modulation: `rotateXY(u_bassEnergy * 0.2)`

---

## IDENTIFIED ISSUES

### 1. Audio Not Playing (ROOT CAUSE)
- PCM initialization timing issue
- noteOn() called before PCM ready
- **Fix applied:** Wait for init completion

### 2. AudioData is NULL
Without audio playing, shader receives 0.0 for all audio uniforms.
No demo/test audio mode in main screen.

### 3. Visual Interaction Disabled
`synth_main_screen.dart:295`
```dart
enableInteraction: false,  // DISABLED
```

### 4. SoundFamily Not Applied
`SynthesisBranchManager` stores SoundFamily but doesn't apply:
- filterQ (8.0/5.5/4.0)
- reverbMix (0.20/0.30/0.45)
- waveformMix
- brightness
- noiseLevel

### 5. System Switch Only Changes Visuals
No actual sonic difference between Quantum/Faceted/Holographic.

---

## DEPENDENCY CHAIN

```
Audio PCM Working
    ↓
Synthesis Produces Sound
    ↓
FFT Analysis Generates Features
    ↓
AudioReactivityData Created
    ↓
Shader Receives Audio Uniforms
    ↓
Visual System Differences Visible
```

If any step in this chain breaks, visual reactivity stops.

---

## WHAT NEEDS FIXING

### Priority 1: Audio Output
- [ ] Verify PCM init timing fix works on device
- [ ] Add debug overlay showing audio state

### Priority 2: SoundFamily Application
- [ ] Wire filterQ to synthesizer filter
- [ ] Wire reverbMix to reverb effect
- [ ] Apply waveformMix to oscillator blend

### Priority 3: Visual Feedback
- [ ] Add demo audio mode (test signal)
- [ ] Consider enabling visual interaction
- [ ] Add system indicator showing current mode

---

## FILES TO REVIEW

- `shaders/vib3_core.frag` - Visual system rendering (WORKING)
- `lib/vib3/rendering/vib3_shader_renderer.dart` - Shader uniform binding (WORKING)
- `lib/ui/screens/synth_main_screen.dart` - Audio→Visual wiring (CONDITIONAL)
- `lib/providers/audio_provider.dart` - Audio generation (BROKEN)
- `lib/synthesis/synthesis_branch_manager.dart` - SoundFamily (NOT APPLIED)

---

*Generated: 2026-01-09*
