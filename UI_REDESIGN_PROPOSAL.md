# Synth-VIB3+ UI Redesign Proposal

**Date**: January 10, 2026
**Author**: Claude (Analysis Session)
**Status**: Proposal for Review

---

## Executive Summary

This document proposes a complete UI rebuild focused on **touch ergonomics**, **screen real estate optimization**, and **seamless control access**. The goal is to create an interface that feels like a professional instrument, not an app with buttons.

---

## Current UI Issues Analysis

### Issue 1: Menu Doesn't Expand/Scroll
**Root Cause**: The `ListView` inside `AnimatedContainer` with `Column` parent creates constraint conflicts during height animation.

**Current Structure**:
```
AnimatedContainer (154px → 520px)
└── Column
    ├── SizedBox(130px) → Hero section (ALWAYS VISIBLE)
    ├── GestureDetector(24px) → Expand bar
    └── if (expanded) Expanded
        └── ListView → Sliders
```

**Problem**: When `Column` receives an animated height, the `Expanded` widget calculates its constraints before animation completes, causing scroll physics issues.

### Issue 2: Tiny Tap Targets
- 8 voice buttons at ~40px wide each
- 3 method buttons at ~80px wide
- System buttons too small for thumb accuracy

**Ergonomic Minimum**: 48px × 48px (Apple HIG), 56px preferred

### Issue 3: Information Overload in Hero
- 3 rows of controls crammed into 130px
- Labels too small (9px font)
- No visual hierarchy

### Issue 4: XY Pad Dominates but Underperforms
- Takes 60-75% of screen
- Only controls pitch (X) and one parameter (Y)
- Visualization could be interaction surface itself

### Issue 5: Controls Buried Behind Expansion
- Must tap, wait for animation, then scroll to reach sliders
- Defeats the purpose of a live performance instrument

### Issue 6: No Contextual Adaptation
- Same controls visible regardless of synthesis branch
- FM-only controls shown even when using Direct synthesis

---

## Proposed UI Architecture

### Design Philosophy: "Glass Cockpit"

Like an aircraft glass cockpit, all essential information and controls should be:
1. **Visible at a glance** - No hunting through menus
2. **Reachable with thumbs** - Controls in natural grip zones
3. **Context-aware** - Show what's relevant now
4. **Feedback-rich** - Every touch produces visual+haptic response

### Screen Zones (Portrait Phone)

```
┌─────────────────────────────────────┐
│          TOP STATUS BAR             │  ← 48px: System/FPS/Geometry
│              (slim)                 │
├─────────────────────────────────────┤
│                                     │
│                                     │
│       4D VISUALIZATION CANVAS       │  ← 50% screen: Interactive!
│    (touch here = note + visual)     │
│                                     │
│                                     │
├─────────────────────────────────────┤
│     QUICK ACCESS STRIP              │  ← 72px: 4 most-used params
├─────────────────────────────────────┤
│                                     │
│       MATRIX SELECTOR GRID          │  ← 160px: System/Method/Voice
│     (always visible, scrollable)    │     as proper touch grid
│                                     │
├─────────────────────────────────────┤
│    PARAMETER DRAWER (swipe up)      │  ← 0-300px: Full param access
└─────────────────────────────────────┘
```

---

## Detailed Component Specifications

### 1. Top Status Bar (48px)

**Purpose**: Minimal status, not controls

```
┌───┬───┬───┬───────────────────┬────────┐
│ Q │ F │ H │ FM: Torus         │ 60 FPS │
└───┴───┴───┴───────────────────┴────────┘
```

- **System indicators** (Q/F/H): Color-coded dots, tap to switch
- **Current config**: "Method: Voice" format
- **FPS**: Only shown if <55 (performance warning)

**Interaction**: Tap anywhere → slide down for settings overlay

### 2. Visualization Canvas (50% of screen)

**Critical Change**: Make visualization the primary interaction surface

**Current**: XYPerformancePad overlays VIB3 shader, touches go to pad only
**Proposed**: VIB3 shader IS the interaction surface

```dart
class InteractiveVisualization extends StatefulWidget {
  // Touch the geometry itself to play notes
  // - Horizontal position → pitch (as before)
  // - Vertical position → Y-axis parameter
  // - Touch pressure (if available) → velocity
  // - Multi-touch → polyphony
  // - Long press → sustain
  // - Swipe gestures → parameter modulation
}
```

**Visual Feedback**:
- Touch ripples emanate from 4D geometry vertices
- Active notes highlighted with system-color glow on geometry
- Sustained notes pulse at LFO rate

### 3. Quick Access Strip (72px)

**Purpose**: 4 most-used parameters, always visible, large touch targets

```
┌────────────┬────────────┬────────────┬────────────┐
│   FILTER   │  REVERB    │   MORPH    │   CHAOS    │
│  ═══════   │  ═══════   │  ═══════   │  ═══════   │
│    1.2kHz  │    35%     │    0.4     │    12%     │
└────────────┴────────────┴────────────┴────────────┘
```

**Each parameter**:
- 72px × 72px touch target (comfortable thumb size)
- Vertical drag = adjust value
- Double-tap = reset to default
- Shows current value below
- Activity meter shows audio reactivity

**Context Adaptation**:
- **Direct mode**: Filter, Reverb, Morph, Output
- **FM mode**: Filter, FM Depth, Reverb, Morph
- **Ring mode**: Filter, Ring Mix, Reverb, Morph

### 4. Matrix Selector Grid (160px)

**Purpose**: Replace cramped hero with proper touch grid

**Layout**:
```
┌─────────────────────────────────────┐
│ SYSTEM    [QUAN] [FACE] [HOLO]      │  ← 48px row
├─────────────────────────────────────┤
│ METHOD    [DIRECT]  [FM]   [RING]   │  ← 48px row
├─────────────────────────────────────┤
│ VOICE  [1][2][3][4][5][6][7][8]     │  ← 48px row (scrollable)
└─────────────────────────────────────┘
```

**Button Specifications**:
- System buttons: 72px wide, color-coded backgrounds
- Method buttons: 80px wide, icon + text
- Voice buttons: 48px square, emoji/icon for geometry type

**Voice Button Icons** (CustomPainter-based vector graphics):
```
0: Tetrahedron (Fundamental) - Equilateral triangle
1: Hypercube (Complex) - Nested rotated squares with connecting lines
2: Sphere (Smooth) - Circle with 3D arc suggestions
3: Torus (Cyclic) - Donut/ring shape
4: Klein Bottle (Twisted) - Figure-8/infinity curve
5: Fractal (Recursive) - Sierpinski-style nested triangles
6: Wave (Flowing) - Sine wave
7: Crystal (Sharp) - 8-pointed star burst
```

**Implementation**: See `lib/ui/components/geometry_icons.dart` for CustomPainter implementations.

**Interaction**:
- Tap = select
- Long press = preview (plays demo note with that setting)
- Horizontal scroll for voice row on smaller screens

### 5. Parameter Drawer (Swipe-Up, 0-300px)

**Purpose**: Full parameter access when needed, hidden when not

**Trigger**: Swipe up from bottom edge OR tap "More" button

**Structure**:
```
┌─────────────────────────────────────┐
│ ═══════════ drag handle ═══════════ │  ← 24px
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │ PITCH   │ │ MOD     │ │ TONE    │ │  ← Tab bar
│ └─────────┘ └─────────┘ └─────────┘ │
├─────────────────────────────────────┤
│                                     │
│  [Slider] [Slider] [Slider]         │  ← Horizontal scroll
│   Detune1  Detune2   Chorus         │     3 sliders per tab
│                                     │
│  (swipe left/right for more)        │
└─────────────────────────────────────┘
```

**Tab Categories**:
1. **PITCH**: Detune 1, Detune 2, Chorus
2. **MOD**: FM Depth*, Ring Mix*, Filter Mod (*context-dependent)
3. **TONE**: Brightness, Resonance, Output
4. **SPACE**: Reverb, Noise, Waveform
5. **TIME**: Voices, LFO Rate

**Slider Design**:
- Large vertical sliders (200px tall)
- Ghost value indicator for audio reactivity
- Snap points for common values
- Label shows both visual parameter name and sonic effect

---

## Side Controls (Portrait Mode)

### Left Thumb Zone
```
┌────┐
│OCT │  ← Octave up
│ +  │
├────┤
│OCT │  ← Octave down
│ -  │
└────┘
```

### Right Thumb Zone
```
┌────┐
│FILT│  ← Filter sweep up
│ ↑  │
├────┤
│FILT│  ← Filter sweep down
│ ↓  │
└────┘
```

**Size**: 56px × 80px per button (generous thumb target)

---

## Orb Controller Redesign

**Current**: Fixed position floating orb, conflicts with panel expansion

**Proposed**: Gesture-based activation

```
┌─────────────────────────────────────┐
│                                     │
│   (two-finger pinch anywhere)       │
│           ↓                         │
│     ┌───────────┐                   │
│     │    ORB    │   ← Appears at    │
│     │   ◎  ◎    │     finger midpoint│
│     │  pitch/vib│                   │
│     └───────────┘                   │
│                                     │
└─────────────────────────────────────┘
```

- **Activation**: Two-finger pinch or designated corner touch
- **X-axis**: Pitch bend (±12 semitones)
- **Y-axis**: Vibrato depth
- **Release**: Snaps back to center with spring animation

---

## Landscape Mode Layout

For tablets and landscape orientation:

```
┌───────────────────────────────────────────────────────────┐
│ [Q][F][H] │  FM: Torus  │ 60 FPS │ [Grid][Tilt][Settings]│
├───────────┼─────────────────────────────────────────────┼─┤
│           │                                             │ │
│  MATRIX   │                                             │F│
│  SELECTOR │      4D VISUALIZATION CANVAS                │I│
│           │                                             │L│
│  [SYSTEM] │                                             │T│
│  [METHOD] │                                             │E│
│  [VOICE]  │                                             │R│
│           │                                             │ │
├───────────┼─────────────────────────────────────────────┼─┤
│  QUICK    │     PARAMETER SLIDERS (horizontal row)      │ │
│  PARAMS   │  [===][===][===][===][===][===][===][===]   │ │
└───────────┴─────────────────────────────────────────────┴─┘
```

**Landscape Benefits**:
- Matrix selector always visible on left
- Sliders horizontal at bottom
- Maximum visualization area
- Filter controls on right edge

---

## Animation & Feedback Specifications

### Touch Feedback
```dart
// Every touch produces:
1. Visual ripple (200ms, ease-out)
2. Haptic feedback (light impact on iOS, vibrate(10) on Android)
3. Sound preview for note touches (if enabled)
```

### State Transitions
```dart
// Panel expansion
Duration: 300ms
Curve: Curves.easeOutCubic
Height: 0 → 300px with spring overshoot

// Button selection
Duration: 150ms
Curve: Curves.easeOut
Color: Interpolate to system primary

// Value change
Duration: 50ms (near-instant for responsiveness)
Visual: Slider thumb glow pulse
```

### Audio-Visual Sync
```dart
// Ghost offset animation
Update rate: 60 FPS (locked to visual frame rate)
Smoothing: Exponential moving average (α = 0.3)
Max offset: 15% of slider range
```

---

## Implementation Priority

### Phase 1: Fix Current Issues (Immediate)
1. ✅ Fix PCM initialization race condition
2. Fix menu scroll by restructuring AnimatedContainer content
3. Increase tap target sizes to minimum 48px

### Phase 2: Quick Access Strip (High Priority)
1. Add 72px quick access strip with 4 context-aware parameters
2. Implement vertical drag gesture for adjustment
3. Add activity meters

### Phase 3: Matrix Selector Rebuild (High Priority)
1. Redesign system/method/voice selector as proper touch grid
2. Add icons for voice characters
3. Implement preview on long-press

### Phase 4: Parameter Drawer (Medium Priority)
1. Replace ListView with horizontal PageView
2. Add tab navigation
3. Redesign sliders as large vertical controls

### Phase 5: Interactive Visualization (Stretch)
1. Merge XYPerformancePad into VIB3 shader widget
2. Add geometry-aware touch targets
3. Implement pressure sensitivity where available

---

## Code Structure Changes

### New Files Needed
```
lib/ui/
├── layouts/
│   ├── portrait_layout.dart      # Portrait-specific arrangement
│   └── landscape_layout.dart     # Landscape-specific arrangement
├── components/
│   ├── quick_access_strip.dart   # 4-parameter quick controls
│   ├── matrix_selector.dart      # System/Method/Voice grid
│   ├── parameter_drawer.dart     # Swipe-up full params
│   ├── gesture_orb.dart          # Pinch-activated pitch bend
│   └── touch_target_button.dart  # Base class for large buttons
└── widgets/
    ├── vertical_slider.dart      # Large touch-friendly slider
    └── activity_meter.dart       # Audio reactivity indicator
```

### Modified Files
```
lib/ui/screens/synth_main_screen.dart  # Complete rebuild
lib/ui/theme/synth_theme.dart          # Add touch target sizes
lib/providers/ui_state_provider.dart   # Add drawer state
```

---

## Accessibility Considerations

1. **Minimum touch targets**: 48px × 48px (WCAG 2.1 AAA)
2. **Color contrast**: All text >4.5:1 ratio
3. **Motion reduction**: Respect `MediaQuery.reduceMotion`
4. **Screen reader labels**: All interactive elements labeled
5. **Focus indicators**: Visible keyboard focus for external keyboards

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Touch response | <16ms | ~20ms |
| Animation FPS | 60 | 60 |
| Gesture recognition | <50ms | ~80ms |
| Panel expansion | 300ms | 350ms |

---

## Summary

This redesign transforms Synth-VIB3+ from "an app with a synthesizer" to "a synthesizer instrument". Key changes:

1. **Larger touch targets** - Everything fingertip-friendly
2. **Always-visible essentials** - No hunting through menus
3. **Context-aware controls** - Show what's relevant
4. **Visualization as instrument** - Touch the geometry, not over it
5. **Gesture-based modulation** - Natural, instrument-like interaction

The implementation can be done incrementally, starting with the scroll fix and tap target improvements, then building toward the full vision.

---

*"The best interface is no interface at all - just you and the instrument."*

A Paul Phillips Manifestation
