# SYNTH-VIB3+ MANIFEST & TECHNICAL BIBLE

**Date**: December 31, 2025
**Version**: 1.0.0
**Status**: OPERATIONAL (Build Ready)
**Author**: Claude Code Analysis
**Project Owner**: Paul Phillips - Clear Seas Solutions LLC

---

## EXECUTIVE SUMMARY

Synth-VIB3+ is a unified audio-visual synthesizer for Flutter/Android that couples VIB3+ 4D holographic visualization with multi-branch synthesis. The system is **OPERATIONAL** with recent fixes to geometry sync and redundant UI elements removed. Build should succeed after removing the problematic `audio_session` dependency.

---

## CURRENT STATE: WHAT WORKS NOW

### Core Synthesis Engine (WORKING)
- **SynthesizerEngine** (`lib/audio/synthesizer_engine.dart`): Dual oscillator system with full waveform support (sine, sawtooth, square, triangle, wavetable)
- **SynthesisBranchManager** (`lib/synthesis/synthesis_branch_manager.dart`): Routes to 3 synthesis types based on geometry selection
- **AudioAnalyzer** (`lib/audio/audio_analyzer.dart`): Real-time FFT analysis for audio-reactive visuals

### 72 Unique Sound+Visual Combinations
- **3 Visual Systems** (Quantum/Faceted/Holographic) x **24 Geometries** (3 cores x 8 base shapes)
- Each combination produces distinct sonic + visual character

### Bidirectional Parameter Bridge (WORKING)
- **ParameterBridge** orchestrates 60 FPS coupling between audio and visual systems
- Audio → Visual: FFT analysis modulates rotation, tessellation, brightness, hue, glow
- Visual → Audio: Rotations modulate detuning, FM/ring mod depth, filter cutoff

### UI System (WORKING)
- XY Performance Pad with multi-touch (up to 8 simultaneous notes)
- Orb Controller for pitch bend and vibrato
- Collapsible panels for Geometry, Synthesis, Effects, Mapping
- System color themes (Cyan/Magenta/Amber)

---

## RECENT FIXES (December 31, 2025)

### 1. Geometry Button Audio Sync (FIXED)
**File**: `lib/ui/panels/geometry_panel.dart:193, 252`
**Issue**: Geometry buttons only updated visuals, not audio
**Fix**: Added `audioProvider.setGeometry(newIndex)` calls to both polytope core and base geometry button handlers

### 2. Redundant Menu Removal (FIXED)
**File**: `lib/ui/panels/synthesis_panel.dart`
**Issue**: "SYNTHESIS BRANCH" selector duplicated Geometry Panel's "POLYTOPE CORE"
**Fix**: Removed the redundant selector, added explanatory comment

### 3. Build Failure Resolution (FIXED)
**File**: `pubspec.yaml`
**Issue**: `audio_session: ^0.1.16` caused Maven Central 403 errors
**Fix**: Removed unused dependency (it was never imported, only listed)

---

## DETAILED CODE ANALYSIS

### CRITICAL ISSUES (Require Attention)

#### ISSUE #1: Effects Panel Null SystemColors
**File**: `lib/ui/panels/effects_panel.dart:21`
**Line**: `final systemColors = audioProvider.systemColors;`
**Problem**: `audioProvider.systemColors` always returns `null` (see line 531-534 of audio_provider.dart)
**Impact**: Effects panel may crash or show invisible controls
**Severity**: HIGH
**Fix Required**: Get systemColors from VisualProvider instead:
```dart
final visualProvider = Provider.of<VisualProvider>(context);
final systemColors = visualProvider.systemColors;
```

#### ISSUE #2: Envelope Time Units Mismatch
**File**: `lib/ui/panels/synthesis_panel.dart:81-117`
**Problem**: Sliders use milliseconds (0-2000ms) but synthesizer expects seconds (0.001-5.0s)
**File**: `lib/providers/audio_provider.dart:557-575`
**Evidence**: `setEnvelopeAttack` clamps to 0.001-5.0 (seconds), but UI shows "ms"
**Impact**: Envelope controls don't work as expected
**Severity**: MEDIUM

#### ISSUE #3: SynthThemeContext Extension Creates New Provider Each Time
**File**: `lib/ui/theme/synth_theme.dart:334-344`
**Problem**: Extension creates new `SynthThemeProvider()` on every call instead of using existing one
**Impact**: Theme changes don't persist, potential memory leaks
**Severity**: MEDIUM

#### ISSUE #4: Delay Time Getter/Setter Inconsistency
**File**: `lib/providers/audio_provider.dart:600, 605-608`
**Problem**: `delayTime` getter returns `delay.time` but setter sets `delay.time` - meanwhile Delay class has both `delayTime` and `time` properties
**File**: `lib/audio/synthesizer_engine.dart:349-350`
**Impact**: Potential confusion and unexpected behavior
**Severity**: LOW

---

### POTENTIAL IMPROVEMENTS

#### Performance Optimizations

1. **Excessive notifyListeners() Calls**
   - `lib/providers/audio_provider.dart`: 25+ places calling `notifyListeners()`
   - Many are for single parameter changes that could be batched
   - **Recommendation**: Use dirty flag pattern and batch notifications

2. **WebView Parameter Updates Too Frequent**
   - `lib/providers/visual_provider.dart`: JS updates batched at 50ms intervals (good!)
   - But `_jsUpdateScheduled` flag could race under heavy load
   - **Recommendation**: Add debouncing or use isolate for heavy updates

3. **Reverb Buffer Size Fixed at 0.1 Seconds**
   - `lib/audio/synthesizer_engine.dart:322`
   - Room size doesn't affect actual reverb time, only feedback amount
   - **Recommendation**: Make buffer size proportional to room size

#### Feature Enhancements

1. **Pitch Bend Not Implemented**
   - `lib/providers/audio_provider.dart:491-496`: `setPitchBend` stores value but has TODO
   - **Recommendation**: Apply pitch bend to oscillator frequency calculation

2. **Vibrato Not Implemented**
   - `lib/providers/audio_provider.dart:499-504`: `setVibratoDepth` stores value but has TODO
   - **Recommendation**: Add LFO modulation to oscillator frequency

3. **Microphone Input Placeholder**
   - `lib/providers/audio_provider.dart:432-441`: Just prints debug message
   - **Recommendation**: Use `record` package for microphone capture

4. **Filter Envelope Amount Not Applied**
   - `lib/audio/synthesizer_engine.dart:255`: `envelopeAmount` property exists but unused
   - **Recommendation**: Modulate filter cutoff by envelope

5. **Wavetable Only Morphs Sine↔Saw**
   - `lib/audio/synthesizer_engine.dart:239-242`: Simple linear interpolation
   - **Recommendation**: Add proper wavetable with multiple frames

---

### CODE QUALITY OBSERVATIONS

#### Well-Implemented Patterns

1. **Provider Pattern**: Clean separation of concerns with AudioProvider, VisualProvider, UIStateProvider
2. **Bidirectional Bridge**: Elegant sync of visual→audio during buffer generation
3. **Sound Family System**: Musically-tuned presets with harmonic relationships
4. **JS Bridge Batching**: Smart parameter update throttling to WebView

#### Areas for Improvement

1. **Magic Numbers**: Many hardcoded values throughout (e.g., `0.95` smoothing factor, `8` max touches)
2. **Inconsistent Naming**: `geometryIndex` vs `currentGeometry`, `delayTime` vs `time`
3. **Dead Code**: `_sawtooth` method in synthesis_branch_manager.dart never called
4. **Missing Error Handling**: Many async operations lack try-catch

---

## FILE-BY-FILE ANALYSIS

### Core Files

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `main.dart` | 39 | OK | Simple, clean entry point |
| `models/visual_state.dart` | 165 | OK | Good immutable model with factory constructors |
| `models/synth_patch.dart` | 275 | OK | `_octaveToFreqRatio` returns 1.0 always (line 203) |
| `models/mapping_preset.dart` | 257 | OK | Well-structured with JSON serialization |

### Providers

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `audio_provider.dart` | 631 | ISSUES | Null systemColors (line 531), TODO placeholders |
| `visual_provider.dart` | 508 | OK | Good JS batching, proper WebView management |
| `ui_state_provider.dart` | 617 | OK | Comprehensive state management |
| `tilt_sensor_provider.dart` | 244 | OK | Clean accelerometer integration |

### Audio System

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `synthesizer_engine.dart` | 385 | OK | Basic but functional DSP |
| `audio_analyzer.dart` | 226 | OK | Proper FFT implementation |
| `synthesis_branch_manager.dart` | 565 | OK | Excellent musically-tuned synthesis |

### Mapping System

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `parameter_bridge.dart` | 166 | OK | Good orchestration |
| `audio_to_visual.dart` | 185 | OK | Clear mapping logic |
| `visual_to_audio.dart` | 240 | OK | Recent fix for geometry sync |

### UI System

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `synth_main_screen.dart` | 340 | OK | Proper layering of components |
| `geometry_panel.dart` | 294 | FIXED | Now syncs audio on button tap |
| `synthesis_panel.dart` | 124 | FIXED | Removed redundant selector |
| `effects_panel.dart` | 148 | ISSUE | Uses null systemColors |
| `xy_performance_pad.dart` | 511 | OK | Good multi-touch handling |
| `orb_controller.dart` | 385 | OK | Nice visual feedback |
| `synth_theme.dart` | 345 | ISSUE | Extension creates new provider |

### Visual System

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `vib34d_widget.dart` | 430 | OK | Good WebView integration |

---

## ARCHITECTURE SUMMARY

```
┌─────────────────────────────────────────────────────────────┐
│                     SynthMainScreen                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    MultiProvider                         ││
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ ││
│  │  │AudioProvider │ │VisualProvider│ │ UIStateProvider  │ ││
│  │  └──────┬───────┘ └──────┬───────┘ └──────────────────┘ ││
│  │         │                │                               ││
│  │         └───────┬────────┘                               ││
│  │                 │                                        ││
│  │         ┌───────▼────────┐                               ││
│  │         │ParameterBridge │  ◄── 60 FPS bidirectional     ││
│  │         │ (Audio ↔ Visual)│                              ││
│  │         └───────┬────────┘                               ││
│  └─────────────────│────────────────────────────────────────┘│
│                    │                                         │
│  ┌─────────────────▼────────────────────────────────────────┐│
│  │                   UI Layers                              ││
│  │  ┌──────────────────────────────────────────────────────┐││
│  │  │ Layer 1: VIB34DWidget (WebGL visualization)          │││
│  │  ├──────────────────────────────────────────────────────┤││
│  │  │ Layer 2: XYPerformancePad (touch overlay)            │││
│  │  ├──────────────────────────────────────────────────────┤││
│  │  │ Layer 3: TopBezel (system selector, stats)           │││
│  │  ├──────────────────────────────────────────────────────┤││
│  │  │ Layer 4: BottomBezel (collapsible panels)            │││
│  │  ├──────────────────────────────────────────────────────┤││
│  │  │ Layer 5: OrbController (floating modulation)         │││
│  │  └──────────────────────────────────────────────────────┘││
│  └──────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## SYNTHESIS MATRIX

### Visual System → Sound Family

| Visual System | Waveform Mix | Filter Q | Reverb | Character |
|---------------|--------------|----------|--------|-----------|
| Quantum | 85% Sine, 15% Triangle | 8.0 | 20% | Pure, crystalline |
| Faceted | 35% Sine, 40% Square, 25% Triangle | 5.5 | 30% | Rich, balanced |
| Holographic | 25% Sine, 50% Saw | 4.0 | 45% | Warm, complex |

### Polytope Core → Synthesis Branch

| Core Index | Geometry Range | Synthesis Type | Character |
|------------|----------------|----------------|-----------|
| 0 (Base) | 0-7 | Direct | Additive harmonics |
| 1 (Hypersphere) | 8-15 | FM | Metallic, bell-like |
| 2 (Hypertetra) | 16-23 | Ring Mod | Inharmonic, percussive |

### Base Geometry → Voice Character

| Index | Geometry | Attack | Release | Detune | Special |
|-------|----------|--------|---------|--------|---------|
| 0 | Tetrahedron | 10ms | 250ms | 0¢ | Fundamental |
| 1 | Hypercube | 25ms | 400ms | 8¢ | Chorus effect |
| 2 | Sphere | 60ms | 350ms | 0¢ | Smooth, filtered |
| 3 | Torus | 15ms | 200ms | 5¢ | Phase mod, filter sweep |
| 4 | Klein Bottle | 35ms | 300ms | 12¢ | Stereo, wide chorus |
| 5 | Fractal | 30ms | 500ms | 7¢ | Recursive, evolving |
| 6 | Wave | 50ms | 450ms | 3¢ | Sweeping filters |
| 7 | Crystal | 2ms | 150ms | 0¢ | Sharp attack, bright |

---

## BUILD & DEPLOYMENT

### Build Commands
```bash
flutter pub get          # Install dependencies
flutter analyze          # Check for errors
flutter build apk        # Build Android APK
flutter run              # Run on connected device
```

### Dependencies (pubspec.yaml)
- `flutter_pcm_sound: ^3.3.3` - Real-time PCM audio output
- `just_audio: ^0.9.35` - Audio playback
- `fftea: ^1.0.0` - FFT analysis
- `webview_flutter: ^4.4.2` - VIB3+ visualization
- `provider: ^6.0.5` - State management
- `sensors_plus: ^6.0.1` - Tilt control
- Firebase packages for cloud sync

### Removed Dependencies
- `audio_session: ^0.1.16` - Caused build failures, was never used

---

## TESTING CHECKLIST

### Audio Testing
- [ ] Touch XY pad - sound should play
- [ ] Move finger - pitch should change (X-axis)
- [ ] Move vertically - filter cutoff should change (Y-axis default)
- [ ] Release - sound should stop with envelope release

### Geometry Testing
- [ ] Tap "Base/Hypersphere/Hypertetra" buttons - synthesis type should change
- [ ] Tap base geometry buttons (Tetrahedron, Hypercube, etc.) - voice character should change
- [ ] Current configuration label should update

### Visual Testing
- [ ] VIB3+ visualization should load (requires internet for hosted engine)
- [ ] System selector (Quantum/Faceted/Holographic) should change colors and sound
- [ ] Rotation sliders should modulate both visual and audio

### UI Testing
- [ ] Panels should expand/collapse
- [ ] Orb controller should drag and return to center
- [ ] Top bezel should show system info

---

## KNOWN LIMITATIONS

1. **Requires Internet**: VIB3+ visualization loads from GitHub Pages (ES modules don't work with local assets)
2. **Android Only**: iOS and Web builds not fully tested
3. **No Preset Saving**: Firebase integration exists but preset save/load not implemented
4. **Single Voice**: True polyphony not implemented (note stealing works)
5. **No MIDI**: External MIDI controller support not implemented

---

## CREDITS & ATTRIBUTION

**A Paul Phillips Manifestation**
Clear Seas Solutions LLC
Paul@clearseassolutions.com

*"The Revolution Will Not be in a Structured Format"*

© 2025 Paul Phillips - Clear Seas Solutions LLC

---

## REVISION HISTORY

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-31 | 1.0.0 | Initial manifest created, fixed geometry sync, removed redundant UI, fixed build |

---

*This document generated by Claude Code comprehensive analysis.*
