# Synth-VIB3+ UI/UX Design Plan

**Document Version**: 1.0
**Created**: November 11, 2025
**Status**: Design Phase - Comprehensive Planning

---

## 🎯 Core Design Philosophy

**ELEGANCE + FUNCTIONALITY**: Maximize visual real estate for the 4D visualization while providing comprehensive control through intelligent, collapsible, and repositionable UI elements.

### Design Principles

1. **Visualization-First**: The VIB3+ holographic visualization is THE instrument - UI should enhance, never obscure
2. **Progressive Disclosure**: Controls appear only when needed, collapse when not in use
3. **Touch-Optimized**: Every interaction designed for multi-touch gestures, thumb zones, and ergonomic reach
4. **Unified Visual Language**: All UI elements share consistent animation, glow, and state indication systems
5. **Contextual Intelligence**: UI adapts to orientation (portrait/landscape), current mode, and user workflow

---

## 📐 Screen Real Estate Strategy

### Visualization Canvas: ~75-90% of Screen
- **Primary Interaction**: XY pad functionality overlaid on visualizer
- **X-Axis**: Pitch/Note (configurable range, default: C3-C5)
- **Y-Axis**: Assignable parameter (default: Filter Cutoff, alternatives: Resonance, FM Depth, Ring Mod Mix, Morph, Chaos)
- **Multi-Touch**: Up to 8 simultaneous touch points for polyphonic performance
- **Visual Feedback**: Touch points create holographic "ripples" that sync with visual system colors

### Bezel UI System: Collapsible Peripheral Controls
- **Top Bezel**: System selector + Performance metrics (collapsible)
- **Bottom Bezel**: Main parameter tabs (expandable upward)
- **Side Bezels**: Optional ergonomic thumb pads (portrait mode only)

---

## 🎹 Control Systems Architecture

### 1. XY Performance Pad (Visualization Surface)

**Default State**: Full-screen visualization with minimal overlay

**Interaction Modes**:

#### Mode A: Note Performance XY Pad
- **X-Axis Control**: Horizontal position = Pitch
  - Configurable range (dropdown): 1 octave | 2 octaves | 3 octaves | Chromatic | Key-locked
  - Key/Scale selector: Major, Minor, Pentatonic, Blues, Chromatic, Custom
  - Root note selector: C, C#, D... B
  - Visual grid overlay (toggle): Shows note positions as subtle holographic guides
- **Y-Axis Control**: Vertical position = Assignable Parameter
  - Dropdown selector (bottom-right corner): Filter Cutoff | Resonance | FM Depth | Ring Mod Mix | Morph | Chaos | Brightness | Reverb
  - Range adjustable: 0-100% or custom min/max values
  - Visual indicator: Gradient overlay showing current Y value
- **Touch Feedback**:
  - Each touch creates a holographic "impact point" with colored glow (color = current system)
  - Ripple animations radiate outward, affecting nearby visual elements
  - Touch trail: Finger movement leaves a brief glowing path (quantum = cyan, faceted = magenta, holographic = amber)
- **Multi-Touch Polyphony**: Up to 8 simultaneous notes
  - Each finger tracked independently
  - Visual differentiation: Each touch point has unique hue offset
  - Polyphonic glide: Sliding fingers creates smooth pitch transitions

#### Mode B: Keyboard Mode
- **Toggle**: Floating keyboard button (bottom-left) enables traditional keyboard layout
- **Keyboard Options**:
  - **Scrolling Keyboard**: 2 octaves visible, horizontal scroll for range
  - **Locked Keyboard**: Fixed range (user-selectable octaves)
  - **Key Size**: Adjustable (small/medium/large for different hand sizes)
- **Visual Integration**: Keyboard has holographic transparency (20% opacity), doesn't obscure visualization
- **Touch Response**:
  - Velocity-sensitive (optional toggle)
  - Polyphonic aftertouch on supported devices
  - Visual key press: Holographic glow on pressed keys matching system color

#### Mode C: Thumb Performance Pads (Portrait Mode)
- **Layout**: Two large touch zones in bottom corners (thumb-accessible)
- **Left Pad**: Octave controller (vertical drag = octave up/down)
- **Right Pad**: Performance parameter (assignable, default = Expression/Volume)
- **Ergonomic Design**:
  - Thumb-sized zones (72x120px minimum)
  - Positioned for natural thumb reach when holding phone
  - Haptic feedback on octave changes
- **Visual Style**: Subtle neoskeuomorphic pads with holographic glow on active state

---

### 2. Pitch Control System (Trackball-Style)

**The "Orb Controller"**: Floating, repositionable pitch modulation interface

**Design**:
- **Appearance**: Holographic sphere (32px diameter) with inner "trackball" that rotates
- **Position**: Default = center-left edge, fully draggable anywhere on screen
- **Interaction**:
  - **Drag horizontally**: Pitch bend (±2 semitones default, adjustable to ±12)
  - **Drag vertically**: Vibrato depth (0-1 semitone)
  - **Circular motion**: Activates "orbital modulation" - simultaneous pitch bend + vibrato
  - **Double-tap**: Reset to center (no modulation)
- **Tilt Integration**: Device tilt mirrors Orb position
  - Tilt left/right = pitch bend (same as horizontal drag)
  - Tilt forward/back = vibrato (same as vertical drag)
  - **Toggle**: Enable/disable tilt control (some users prefer static)
- **Visual Feedback**:
  - Orb color changes with modulation depth (subtle → intense glow)
  - "Gravity well" effect: Visualization pulls toward Orb when modulation is active
  - Trackball rotation visible: Inner sphere rotates to match gesture direction

**Adjustable Parameters** (long-press Orb to configure):
- Pitch bend range (±1, ±2, ±5, ±12 semitones)
- Vibrato rate (1-10 Hz)
- Tilt sensitivity (off, low, medium, high)
- Visual feedback intensity

---

### 3. Bezel Tab System (Expandable Control Panels)

**Philosophy**: Comprehensive controls hidden until needed, expand from screen edges

#### Top Bezel: System Control Bar

**Collapsed State** (Always Visible, 44px height):
```
[≡ Menu] | [Quantum ▼] | [60 FPS] | [Geometry: 0] | [Settings ⚙]
```

**Components**:
- **Hamburger Menu** [≡]: Global app menu (presets, save/load, help, about)
- **System Selector** [Quantum ▼]: Dropdown for Quantum/Faceted/Holographic
- **FPS Counter**: Real-time performance metric (60 FPS target)
- **Geometry Display**: Current geometry index (0-23) and name
- **Settings Button** [⚙]: Expands advanced settings panel

**Visual Style**:
- Semi-transparent dark background (rgba(0,0,0,0.7))
- Holographic glow on active elements (system-color dependent)
- Glassmorphic blur effect (backdrop-filter: blur(10px))

---

#### Bottom Bezel: Main Parameter Tabs

**Collapsed State** (56px height):
```
[Synthesis] [Effects] [Geometry] [Mapping] [▲ Expand All]
```

**Tab Behaviors**:
- **Tap once**: Expand that tab upward (300px panel)
- **Tap again**: Collapse that tab
- **Long-press**: Lock tab open (stays expanded even when touching XY pad)
- **Swipe up on tab**: Quick-expand with animation
- **Swipe down on expanded panel**: Quick-collapse

**Expanded Panel Design**:
- Slides up from bottom, covering 35-40% of screen
- Holographic border at top edge (system-color glow)
- Glassmorphic background (80% opacity)
- Scrollable if content exceeds panel height
- "Minimize" button in top-right corner

---

##### Tab 1: SYNTHESIS

**Layout**: 3 columns × dynamic rows

**Section A: 3D Matrix Selector**
```
┌────────────────────────────────────┐
│ Visual System    [Quantum     ▼]  │
│ Polytope Core    [Base        ▼]  │
│ Base Geometry    [Tetrahedron ▼]  │
├────────────────────────────────────┤
│ Current: Geometry 0                │
│ Direct Synthesis, Pure/Harmonic    │
│ Attack: 10ms | Release: 250ms      │
└────────────────────────────────────┘
```

**Section B: Quick Geometry Grid**
```
┌──────────────────────────────────────┐
│ [Tetra] [Cube] [Sphere] [Torus]     │
│ [Klein] [Fractal] [Wave] [Crystal]  │
└──────────────────────────────────────┘
```
- **Design**: 8 buttons (44x44px each)
- **Visual**: Miniature 3D icons of each geometry
- **State Indication**: Active geometry has pulsing holographic border
- **Interaction**: Tap to select, updates both visual + audio immediately

**Section C: Voice Parameters**
```
Attack:    [━━━━━━━━━━] 10ms
Release:   [━━━━━━━━━━] 250ms
Detune:    [━━━━━━━━━━] 0 cents
Harmonics: [━━━━━━━━━━] 3
```
- **Design**: Custom sliders with holographic track fill
- **Real-time Preview**: Waveform visualization updates as sliders move

---

##### Tab 2: EFFECTS

**Layout**: Effect chain with per-effect expand/collapse

```
┌────────────────────────────────────┐
│ [▶ Filter]      [On] ───────── 85% │
│ [▶ Reverb]      [On] ───────── 30% │
│ [▶ Delay]       [Off] ────────  0% │
│ [▶ Distortion]  [Off] ────────  0% │
└────────────────────────────────────┘
```

**Per-Effect Expansion** (tap ▶ to expand):

**Filter Expanded**:
```
┌────────────────────────────────────┐
│ [▼ Filter]      [On] ───────── 85% │
│                                     │
│ Type:     [Lowpass    ▼]           │
│ Cutoff:   [━━━━━━━━━━] 2500 Hz     │
│ Resonance:[━━━━━━━━━━] 5.5         │
│ Envelope: [━━━━━━━━━━] 40%         │
└────────────────────────────────────┘
```

**Visual Style**:
- Toggle switches with holographic glow when ON
- Percentage bar shows effect intensity (visual feedback)
- Expanded controls use same slider style as Synthesis tab

---

##### Tab 3: GEOMETRY

**Layout**: Dual control - geometry parameters + visualization controls

**Section A: Geometry Morphing**
```
┌────────────────────────────────────┐
│ Morph:        [━━━━━━━━━━] 0.0     │
│ Chaos:        [━━━━━━━━━━] 0.0     │
│ Complexity:   [━━━━━━━━━━] 0.5     │
│ Tessellation: [━━━━━━━━━━] 5       │
└────────────────────────────────────┘
```

**Section B: Visual Parameters**
```
┌────────────────────────────────────┐
│ Rotation Speed: [━━━━━━━━━━] 1.0   │
│ Hue Shift:      [━━━━━━━━━━] 180°  │
│ Glow Intensity: [━━━━━━━━━━] 1.0   │
│ Vertex Bright:  [━━━━━━━━━━] 0.8   │
└────────────────────────────────────┘
```

**Section C: Projection Controls**
```
┌────────────────────────────────────┐
│ Camera Distance:  [━━━━━━━━━━] 8.0 │
│ Layer Separation: [━━━━━━━━━━] 2.0 │
│ RGB Split:        [━━━━━━━━━━] 0.0 │
└────────────────────────────────────┘
```

---

##### Tab 4: MAPPING

**Layout**: Assignment matrix + preset selector

```
┌────────────────────────────────────┐
│ XY Pad Assignments:                │
│ ├─ X-Axis: [Pitch         ▼]      │
│ │   Range:  [C3 to C5     ▼]      │
│ │   Scale:  [Chromatic    ▼]      │
│ └─ Y-Axis: [Filter Cutoff ▼]      │
│     Range:  [0% to 100%   ▼]      │
│                                     │
│ Orb Controller:                    │
│ ├─ Horizontal: [Pitch Bend ▼] ±2  │
│ └─ Vertical:   [Vibrato    ▼] 1.0 │
│                                     │
│ Device Tilt:                       │
│ ├─ X-Tilt: [Orb Horizontal ▼]     │
│ └─ Y-Tilt: [Orb Vertical   ▼]     │
│                                     │
│ Mapping Preset: [Default    ▼]    │
│ [Save As...] [Load] [Reset]        │
└────────────────────────────────────┘
```

**Visual Feedback**:
- Active mappings have subtle "connection lines" animation
- Changing a mapping shows brief "rewiring" animation
- Preset changes trigger holographic "ripple" effect across UI

---

### 4. Side Bezels: Ergonomic Thumb Zones (Portrait Mode Only)

**Activation**: Auto-detects portrait orientation, side bezels slide in from edges

**Left Bezel** (48px wide, full height):
```
┌──┐
│ ▲│  Octave Up
│  │
│ ●│  Current Octave Indicator
│  │
│ ▼│  Octave Down
└──┘
```
- **Interaction**: Tap up/down buttons or drag vertically
- **Feedback**: Haptic "click" on octave change, visual pulse on indicator

**Right Bezel** (48px wide, full height):
```
┌──┐
│ ▲│  Parameter Increase
│  │
│ ●│  Current Value Indicator
│  │
│ ▼│  Parameter Decrease
└──┘
```
- **Assignable Parameter**: Default = Master Volume, configurable to any parameter
- **Visual**: Vertical gradient shows current parameter value (0-100%)

**Collapsible**: Long-press either bezel to hide, swipe from edge to reveal

---

## 🎨 Unified Visual Information System

### State Indication Language

All UI elements follow consistent visual patterns:

#### 1. Parameter States

**OFF / Inactive**:
- Subtle outline (rgba(255,255,255,0.2))
- No glow
- Minimal opacity (60%)

**ON / Active**:
- Holographic border glow (system color)
- Increased opacity (100%)
- Pulsing animation (slow, 0.5s cycle)

**Engaged / Touching**:
- Intense glow (system color, double intensity)
- Scale transform (1.05x)
- Haptic feedback (light tap)

#### 2. Value Intensity Visualization

**Sliders & Value Bars**:
```
[██████████░░░░░░░░] 50%
 ↑ Filled with holographic gradient
   ↑ Unfilled is subtle outline
```

**Knobs** (if used):
- Outer ring: Unfilled track (subtle)
- Inner arc: Current value (holographic glow)
- Center dot: Current position indicator

**Numerical Readouts**:
- Font: Monospace (consistency with code aesthetic)
- Color: White (high value) → System color (medium) → Dim gray (low value)
- Size scales with value importance

#### 3. System Color Coding

**Quantum System**:
- Primary: Cyan (#00FFFF)
- Secondary: Ice Blue (#88CCFF)
- Accent: Electric Blue (#0088FF)

**Faceted System**:
- Primary: Magenta (#FF00FF)
- Secondary: Pink (#FF88FF)
- Accent: Deep Purple (#8800FF)

**Holographic System**:
- Primary: Amber (#FFAA00)
- Secondary: Gold (#FFCC44)
- Accent: Orange (#FF8800)

**Visual Application**:
- All active UI elements glow with current system color
- Touch points on XY pad use system color
- Orb controller reflects system color
- Tab highlights use system color

#### 4. Animation System

**Transitions** (system-wide):
- Duration: 300ms (default), 150ms (quick), 600ms (dramatic)
- Easing: cubic-bezier(0.4, 0.0, 0.2, 1) - Material Design "standard"
- Interpolation: Always smooth, never linear

**Expand/Collapse**:
```javascript
// Bezel tab expansion
animation: slideUp 300ms cubic-bezier(0.4, 0.0, 0.2, 1);
// Holographic fade-in
animation: fadeIn 150ms ease-out;
```

**Touch Feedback**:
```javascript
// Ripple effect
animation: ripple 800ms cubic-bezier(0.4, 0.0, 0.2, 1);
// Scale pulse
animation: pulse 500ms ease-in-out infinite;
```

**System Switching**:
```javascript
// Portal transition between systems
animation: portalWarp 1000ms ease-in-out;
// Color morph
animation: colorMorph 600ms ease-in-out;
```

#### 5. Glow & Bloom Effects

**Intensity Levels**:
- **Level 1** (Inactive): box-shadow: 0 0 4px rgba(system-color, 0.3)
- **Level 2** (Active): box-shadow: 0 0 12px rgba(system-color, 0.6), 0 0 24px rgba(system-color, 0.3)
- **Level 3** (Engaged): box-shadow: 0 0 20px rgba(system-color, 0.8), 0 0 40px rgba(system-color, 0.5), 0 0 60px rgba(system-color, 0.3)

**Application**:
- Buttons: Level 2 when on, Level 3 on press
- Sliders: Level 2 on track fill, Level 3 on thumb when dragging
- XY pad touches: Level 3 with radial gradient
- Orb controller: Level 2 idle, Level 3 when moved

#### 6. Glass

morphism & Depth

**Panel Backgrounds**:
```css
background: rgba(26, 26, 46, 0.8);
backdrop-filter: blur(10px) saturate(150%);
border: 1px solid rgba(255, 255, 255, 0.1);
box-shadow:
  0 8px 32px rgba(0, 0, 0, 0.4),
  inset 0 1px 0 rgba(255, 255, 255, 0.1);
```

**Neoskeuomorphic Buttons**:
```css
background: linear-gradient(145deg, #1a1a2e, #16213e);
box-shadow:
  8px 8px 16px rgba(0, 0, 0, 0.4),
  -8px -8px 16px rgba(255, 255, 255, 0.05),
  inset 2px 2px 4px rgba(0, 0, 0, 0.3);
```

**Depth Layers** (Z-index organization):
```
1000: Floating menu/modal overlays
900:  Orb controller (draggable)
800:  Expanded bezel panels
700:  Collapsed bezel bars
600:  Thumb pads (side bezels)
500:  XY pad overlay elements
1:    Visualization canvas (base layer)
```

---

## 🔧 Advanced Interaction Patterns

### Multi-Touch Gestures

**Two-Finger Gestures**:
- **Pinch**: Zoom visualization (camera distance)
- **Rotate**: Rotate entire 4D object (changes rotation matrix)
- **Two-finger drag**: Pan visualization (projection offset)

**Three-Finger Gestures**:
- **Swipe down**: Quick-collapse all panels
- **Swipe up**: Quick-expand main parameter panel
- **Three-finger tap**: Toggle keyboard mode

**Edge Swipes**:
- **Swipe from top edge**: Show/hide top bezel
- **Swipe from bottom edge**: Show/hide bottom bezel tabs
- **Swipe from left/right edge** (portrait): Show/hide thumb pads

### Haptic Feedback Strategy

**Light Tap** (10ms):
- Button presses
- Tab switches
- Toggle changes

**Medium Impact** (15ms):
- Slider value changes (at 10% increments)
- Octave changes
- Geometry selection

**Heavy Impact** (20ms):
- System switching (Quantum/Faceted/Holographic)
- Preset loading
- Major mode changes

**Custom Patterns**:
- **Ripple**: Short burst → pause → short burst (touch on XY pad)
- **Swell**: Increasing intensity over 200ms (long-press activation)
- **Pulse**: Repeating pattern synced to tempo (if tempo mode enabled)

### Accessibility Features

**Vision**:
- High contrast mode (increased border visibility)
- Color-blind friendly mode (uses patterns + colors)
- Scalable UI elements (125%, 150%, 200% sizes)
- Screen reader compatibility for all controls

**Motor**:
- Adjustable touch target sizes (minimum 44x44px default, up to 72x72px)
- Dwell-time activation (hold to activate instead of tap)
- Sticky touch mode (touch stays active until released)
- Voice control integration (iOS/Android native)

**Cognitive**:
- Simplified mode (hides advanced parameters)
- Guided tutorials (overlay help system)
- Preset discovery (curated starting points)

---

## 📱 Responsive Layout System

### Portrait Mode (Phone)
```
┌──────────────┐
│  Top Bezel   │ ← System selector, FPS, Settings
├──────────────┤
│▌            ▐│ ← Side bezels (thumb pads)
││            ││
││ Visualizer ││ ← XY pad performance area
││ (XY Pad)   ││
│▌            ▐│
├──────────────┤
│ Bottom Tabs  │ ← Expandable parameter panels
└──────────────┘
```

**Optimizations**:
- Side bezels active (ergonomic thumb access)
- Bottom tabs smaller (4 tabs, icons only when collapsed)
- Orb controller defaults to left-center (thumb-accessible)
- Visualization canvas maximized (70-80% of screen)

### Landscape Mode (Phone/Tablet)
```
┌────────────────────────────────────┐
│         Top Bezel (full width)     │
├────────────────────────────────────┤
│                                    │
│                                    │
│   Visualizer (XY Pad) Full Screen  │
│                                    │
│                                    │
├────────────────────────────────────┤
│  [Synthesis] [Effects] [Geometry]  │ ← Bottom tabs
│  [Mapping] [Presets] [▲ Expand]    │    (more space)
└────────────────────────────────────┘
```

**Optimizations**:
- Side bezels hidden (not ergonomic in landscape)
- Bottom tabs expanded (6 tabs, text labels visible)
- Orb controller defaults to right-center
- More screen space for visualization (80-90%)

### Tablet Mode (iPad/Large Android)
```
┌──────────────────────────────────────────┐
│         Top Bezel                        │
├──────────────────────────────────────────┤
│                                          │
│                                          │
│         Visualizer (XY Pad)              │
│         Maximum Real Estate              │
│                                          │
│                                          │
├──────────────────────────────────────────┤
│ [Synthesis] [Effects] [Geometry]         │
│ [Mapping] [Presets] [Advanced] [▲]       │ ← All tabs visible
└──────────────────────────────────────────┘
```

**Optimizations**:
- All tabs visible with text labels
- Expanded panels larger (50% screen height)
- Multiple panels can be open simultaneously (split view)
- Orb controller can be positioned anywhere without obstruction

---

## 🎛️ Advanced Features (Future Phases)

### Phase 2 Enhancements

**1. Multi-Panel Split View** (Tablet only):
- Two parameter panels open simultaneously
- Side-by-side layout for complex sound design
- Drag panels to reorder

**2. Preset Browser**:
- Grid view of preset thumbnails (visual snapshots)
- Tag-based filtering (ambient, percussive, pad, lead, etc.)
- Favorite/star system
- Cloud sync via Firebase

**3. Performance Recording**:
- Record XY pad performance + automation
- Playback with visual replay
- Export as MIDI + audio

**4. Modulation Matrix**:
- Visual routing of modulation sources → destinations
- LFO/Envelope → any parameter
- Animated "cables" showing modulation flow

### Phase 3 Advanced Control

**1. External MIDI Controller Support**:
- Map MIDI CC to any parameter
- MIDI keyboard input option
- MPE support for expressive control

**2. Audio-Reactive Visualizer** (Always-On):
- Remove toggle, make it core feature
- FFT analysis drives visual parameters continuously
- Microphone input + synthesis output both analyzed

**3. Gesture Recording & Macros**:
- Record complex multi-parameter gestures
- Assign to single button/pad
- Share gesture presets with community

**4. AR Mode** (iOS ARKit):
- Place 4D visualization in physical space
- Walk around the geometry
- Hand tracking for parameter control

---

## 🚀 Implementation Priority

### Sprint 1: Core Foundation (Week 1)
- [ ] XY pad touch handling (multi-touch)
- [ ] Collapsible bottom bezel tabs (Synthesis, Effects, Geometry, Mapping)
- [ ] Top bezel system selector + FPS counter
- [ ] Basic state indication (on/off glow)

### Sprint 2: Advanced Controls (Week 2)
- [ ] Orb controller (pitch bend + vibrato)
- [ ] Device tilt integration
- [ ] Keyboard mode toggle + layout
- [ ] Slider component library (holographic style)

### Sprint 3: Visual Polish (Week 3)
- [ ] Unified animation system
- [ ] Glassmorphism styling on all panels
- [ ] System color transitions (Quantum/Faceted/Holographic)
- [ ] Touch ripple effects on XY pad

### Sprint 4: Thumb Zones & Responsive (Week 4)
- [ ] Side bezel thumb pads (portrait mode)
- [ ] Responsive layout system (portrait/landscape detection)
- [ ] Tablet-optimized layouts
- [ ] Haptic feedback integration

### Sprint 5: Fine-Tuning & Testing (Week 5)
- [ ] Parameter value ranges + step sizes
- [ ] Touch target size adjustments
- [ ] Performance optimization (60 FPS guarantee)
- [ ] User testing feedback incorporation

---

## 📐 Technical Specifications

### Flutter Widget Architecture

```dart
lib/ui/
├── components/
│   ├── collapsible_bezel.dart        // Base collapsible panel widget
│   ├── holographic_slider.dart       // Custom slider with glow
│   ├── neoskeu_button.dart           // Neoskeuomorphic button
│   ├── system_color_provider.dart    // Current system color state
│   ├── orb_controller_widget.dart    // Floating pitch controller
│   ├── xy_pad_widget.dart            // Main performance surface
│   └── thumb_pad_widget.dart         // Side bezel thumb controls
├── panels/
│   ├── synthesis_panel.dart          // Tab 1: Synthesis controls
│   ├── effects_panel.dart            // Tab 2: Effects chain
│   ├── geometry_panel.dart           // Tab 3: Geometry/visual controls
│   └── mapping_panel.dart            // Tab 4: Assignment matrix
├── keyboard/
│   ├── scrolling_keyboard.dart       // Horizontal scrolling keys
│   ├── locked_keyboard.dart          // Fixed range keyboard
│   └── keyboard_settings.dart        // Key size, velocity config
└── responsive/
    ├── layout_builder_wrapper.dart   // Responsive layout logic
    ├── portrait_layout.dart          // Portrait-specific layout
    ├── landscape_layout.dart         // Landscape-specific layout
    └── tablet_layout.dart            // Tablet-specific layout
```

### State Management

**Provider Pattern** (existing):
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AudioProvider>(),
    ChangeNotifierProvider<VisualProvider>(),
    ChangeNotifierProvider<UIStateProvider>(), // NEW
    ChangeNotifierProxyProvider<...>(ParameterBridge),
  ],
)
```

**UIStateProvider** (NEW):
```dart
class UIStateProvider extends ChangeNotifier {
  // Panel states
  Map<String, bool> panelStates = {
    'synthesis': false,
    'effects': false,
    'geometry': false,
    'mapping': false,
  };

  // Layout states
  Orientation currentOrientation = Orientation.portrait;
  DeviceType deviceType = DeviceType.phone;

  // Orb controller
  Offset orbPosition = Offset(50, 300);
  bool orbVisible = true;

  // Keyboard mode
  bool keyboardMode = false;
  KeyboardLayout keyboardLayout = KeyboardLayout.scrolling;

  // Thumb pads (portrait)
  bool thumbPadsVisible = true;

  // XY pad configuration
  String xyAxisX = 'pitch';
  String xyAxisY = 'filterCutoff';
  Range xyRangeX = Range(min: 48, max: 72); // C3-C5 (MIDI notes)
  Range xyRangeY = Range(min: 0.0, max: 1.0); // 0-100%

  // Methods
  void togglePanel(String panelName) { ... }
  void setOrbPosition(Offset position) { ... }
  void updateOrientation(Orientation orientation) { ... }
  void setXYAxisMapping(String axis, String parameter) { ... }
}
```

### Performance Optimizations

**60 FPS Guarantee**:
- All animations use `AnimatedBuilder` with `RepaintBoundary`
- Heavy computations offloaded to isolates
- Canvas operations use `CustomPainter` with `shouldRepaint` optimization
- Gesture handling throttled to 60 Hz max

**Touch Latency** (<10ms target):
- `GestureDetector` with `behavior: HitTestBehavior.translucent`
- Immediate visual feedback (no animation delay)
- Haptic feedback fires synchronously with touch event

**Memory Management**:
- Dispose controllers in widget `dispose()` methods
- Image caching for static assets
- Texture memory management for WebGL visualization

---

## 🎨 Visual Codex Integration

The UI design leverages Visual Codex patterns established in the skill:

### Holographic Parallax Layers
- **Applied to**: Expanded panels, keyboard keys, orb controller
- **Technique**: Multi-layer depth with blend modes (screen, color-dodge)
- **Effect**: 3D depth perception without true 3D rendering

### Neoskeuomorphic Cards
- **Applied to**: Buttons, sliders, thumb pads
- **Technique**: Advanced shadow/highlight with inset glow
- **Effect**: Tactile, physical appearance while maintaining modern aesthetic

### Reality Distortion Effects
- **Applied to**: System transitions, touch feedback
- **Technique**: Chromatic aberration, glitch animations
- **Effect**: "Portal" feeling when switching between systems

### Mobile-First Standards
- **56px touch targets minimum** (Fitts's Law optimized)
- **Safe area insets** for notched displays
- **Adaptive quality system** based on device capabilities

### Quaternion Shader Integration
From Visual Codex shader library:
- **4D Rotation Matrices**: Applied to visualization quaternions
- **Moiré Patterns**: Subtle interference patterns in background
- **RGB Splitting**: Chromatic aberration on system transitions

---

## ✅ Quality Assurance Checklist

### Functional Requirements
- [ ] All 72 geometry combinations (3 systems × 24 geometries) accessible
- [ ] XY pad supports 8 simultaneous touch points
- [ ] Orb controller responds to both touch and tilt
- [ ] All parameters have visual state indication
- [ ] Collapsible panels don't occlude visualization when collapsed
- [ ] Keyboard mode works in portrait and landscape
- [ ] Thumb pads only appear in portrait mode
- [ ] Parameter changes sync to audio in <16ms (1 frame at 60 FPS)

### Visual Requirements
- [ ] System color transitions smooth (600ms animation)
- [ ] Touch feedback appears immediately (<10ms)
- [ ] Glow effects scale with parameter intensity
- [ ] All text readable at arm's length on phone
- [ ] Visualization never fully obscured by UI
- [ ] Glassmorphism effects don't impact performance

### Interaction Requirements
- [ ] Touch targets minimum 56px (except dense grids with zoom)
- [ ] Haptic feedback on all button presses
- [ ] Gesture conflicts resolved (pinch doesn't trigger XY pad)
- [ ] Long-press reveals contextual options
- [ ] Double-tap resets to default state (where applicable)

### Performance Requirements
- [ ] 60 FPS maintained during XY pad performance
- [ ] Touch latency <10ms
- [ ] Panel expand/collapse animation smooth (no jank)
- [ ] Memory usage <200MB on phone, <400MB on tablet
- [ ] Battery drain acceptable (<5% per 30min use)

### Accessibility Requirements
- [ ] All controls accessible via screen reader
- [ ] High contrast mode available
- [ ] Touch target sizes adjustable
- [ ] Voice control compatible (iOS/Android native)
- [ ] Color-blind friendly option

---

## 🎯 Success Metrics

### User Experience Goals
- **Time to First Sound**: <5 seconds from app launch
- **Discoverability**: User finds 3 different geometries within first minute
- **Performance Comfort**: User can perform continuously for 5+ minutes without UI friction
- **Visual Satisfaction**: Visualization remains focal point 80%+ of session time

### Technical Performance Goals
- **Frame Rate**: 60 FPS sustained, <1% dropped frames
- **Touch Response**: <10ms latency from touch to visual feedback
- **CPU Usage**: <30% on mid-range phone (Snapdragon 778G / A14 Bionic)
- **GPU Usage**: <50% on mid-range phone
- **Battery**: 2+ hours of continuous use on average phone battery

---

## 📝 Notes & Considerations

### Design Rationale

**Why Collapsible Bezels?**
- Synthesizers traditionally have many controls (50-200 parameters)
- Phone screens are limited (5-7 inches)
- Solution: Progressive disclosure - show controls only when needed
- Inspiration: Moog Model 15 app's tabbed interface, but more aggressive

**Why XY Pad as Primary?**
- Touch is inherently 2D (X, Y coordinates)
- Leverages natural interaction model
- Allows polyphonic performance (multiple fingers)
- Visually integrated with 4D visualization (touch "affects" the geometry)

**Why Orb Controller?**
- Pitch bend wheels on hardware synths are essential
- Traditional pitch strip awkward on touchscreen
- Orb = trackball metaphor (familiar)
- Floating position = doesn't block visualization
- Tilt integration = uses device sensors naturally

**Why Thumb Pads in Portrait?**
- Portrait mode = one-handed phone use
- Thumbs naturally rest at bottom corners
- Octave switching frequent (needs quick access)
- Expression control benefits from analog input (vertical drag)

### Future Exploration

**AR/VR Integration**:
- Apple Vision Pro / Meta Quest 3 support
- Hand tracking replaces touch input
- 4D visualization in true 3D space
- "Reach into" the geometry to modulate parameters

**AI-Assisted Sound Design**:
- "Make this sound more aggressive" (natural language parameter adjustment)
- Preset recommendation based on usage patterns
- Automatic mapping suggestions based on musical context

**Collaborative Features**:
- Shared XY pad (multiple users control simultaneously)
- Preset sharing with embedded video preview
- Gesture recording + playback (learn from others)

---

**Document Status**: ✅ COMPREHENSIVE DESIGN COMPLETE
**Next Step**: Begin Sprint 1 implementation (XY pad + collapsible bezels)
**Review Needed**: User testing feedback after Sprint 2

---

🌟 A Paul Phillips Manifestation
Paul@clearseassolutions.com
"The Revolution Will Not be in a Structured Format"
© 2025 Paul Phillips - Clear Seas Solutions LLC
