# Synth-VIB3+ API Reference

Complete API documentation for all endpoints, methods, and data structures.

**A Paul Phillips Manifestation**
*Paul@clearseassolutions.com*

---

## Table of Contents

1. [Audio System](#audio-system)
   - [SynthesizerEngine](#synthesizerengine)
   - [Oscillator](#oscillator)
   - [Filter](#filter)
   - [Reverb](#reverb)
   - [Delay](#delay)
   - [AudioAnalyzer](#audioanalyzer)
2. [Synthesis Branch Manager](#synthesis-branch-manager)
   - [SoundFamily](#soundfamily)
   - [VoiceCharacter](#voicecharacter)
3. [Parameter Bridge](#parameter-bridge)
   - [ParameterBridge](#parameterbridge)
   - [AudioToVisualModulator](#audiotovisualmodulator)
   - [VisualToAudioModulator](#visualtoaudiomodulator)
   - [ParameterMapping](#parametermapping)
4. [Providers](#providers)
   - [AudioProvider](#audioprovider)
   - [VisualProvider](#visualprovider)
5. [VIB3 Engine](#vib3-engine)
   - [VIB3Engine](#vib3engine)
   - [VIB3EngineState](#vib3enginestate)
   - [AudioReactivityData](#audioreactivitydata)
6. [Models](#models)
   - [SynthPatch](#synthpatch)
   - [VisualState](#visualstate)
   - [MappingPreset](#mappingpreset)
7. [Enums](#enums)

---

## Audio System

### SynthesizerEngine

**File:** `lib/audio/synthesizer_engine.dart:51`

Core audio synthesis engine with dual oscillators, filter, and effects.

#### Constructor

```dart
SynthesizerEngine({
  double sampleRate = 44100.0,
  int bufferSize = 512,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sampleRate` | `double` | Audio sample rate (default: 44100.0) |
| `bufferSize` | `int` | Buffer size in samples (default: 512) |
| `oscillator1` | `Oscillator` | Primary oscillator |
| `oscillator2` | `Oscillator` | Secondary oscillator |
| `filter` | `Filter` | Multi-mode filter |
| `envelope` | `Envelope` | ADSR envelope |
| `reverb` | `Reverb` | Reverb effect |
| `delay` | `Delay` | Delay effect |
| `masterVolume` | `double` | Master output volume (0.0-1.0) |
| `mixBalance` | `double` | Oscillator mix (0=osc1, 1=osc2) |
| `stereoWidth` | `double` | Stereo spread (0=mono, 1=full) |
| `voiceCount` | `int` | Number of voices (1-16) |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `generateBuffer` | `int frames` | `Float32List` | Generate audio buffer |
| `setNote` | `int midiNote` | `void` | Set base note from MIDI |
| `modulateOscillator1Frequency` | `double semitones` | `void` | Modulate osc1 (±2 semitones) |
| `modulateOscillator2Frequency` | `double semitones` | `void` | Modulate osc2 (±2 semitones) |
| `modulateFilterCutoff` | `double amount` | `void` | Modulate filter (0-0.8) |
| `setWavetablePosition` | `double position` | `void` | Set wavetable morph (0-1) |
| `setVoiceCount` | `int count` | `void` | Set voice count (1-16) |
| `setReverbMix` | `double mix` | `void` | Set reverb wet/dry (0-1) |
| `setDelayTime` | `double ms` | `void` | Set delay time (0-1000ms) |
| `setStereoWidth` | `double width` | `void` | Set stereo width (0-1) |
| `setNoiseLevel` | `double level` | `void` | Set noise injection (0-0.3) |
| `setLFORate` | `double rateHz` | `void` | Set LFO rate (0.1-10 Hz) |
| `setLFODepth` | `double depth` | `void` | Set LFO depth (0-1) |

---

### Oscillator

**File:** `lib/audio/synthesizer_engine.dart:231`

Oscillator with frequency modulation and wavetable support.

#### Properties

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `waveform` | `Waveform` | enum | Current waveform type |
| `baseFrequency` | `double` | 20-20000 Hz | Base frequency |
| `frequencyModulation` | `double` | ±12 semitones | FM amount |
| `detune` | `double` | ±100 cents | Fine detune |
| `phase` | `double` | 0-2π | Current phase |
| `wavetablePosition` | `double` | 0-1 | Wavetable morph position |

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `nextSample()` | `double` | Generate next sample (-1 to 1) |

---

### Filter

**File:** `lib/audio/synthesizer_engine.dart:291`

Multi-mode filter with resonance and modulation.

#### Properties

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `type` | `FilterType` | enum | Filter type |
| `baseCutoff` | `double` | 20-20000 Hz | Cutoff frequency |
| `cutoffModulation` | `double` | 0-0.8 | Modulation amount |
| `resonance` | `double` | 0-1 | Resonance/Q |
| `envelopeAmount` | `double` | 0-1 | Envelope mod depth |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `process` | `double input` | `double` | Filter a sample |

---

### Reverb

**File:** `lib/audio/synthesizer_engine.dart:352`

Simple reverb effect with room simulation.

#### Properties

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `mix` | `double` | 0-1 | Wet/dry mix |
| `roomSize` | `double` | 0-1 | Room size |
| `damping` | `double` | 0-1 | High-frequency damping |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `process` | `double input` | `double` | Process sample through reverb |

---

### Delay

**File:** `lib/audio/synthesizer_engine.dart:389`

Delay effect with feedback.

#### Properties

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `delayTime` | `double` | 0-1000 ms | Delay time |
| `feedback` | `double` | 0-0.95 | Feedback amount |
| `mix` | `double` | 0-1 | Wet/dry mix |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `process` | `double input` | `double` | Process sample through delay |

---

### AudioAnalyzer

**File:** `lib/audio/audio_analyzer.dart:22`

FFT-based audio analysis for audio-reactive visuals.

#### Constructor

```dart
AudioAnalyzer({
  int fftSize = 2048,
  double sampleRate = 44100.0,
})
```

#### Frequency Bands

| Band | Min Hz | Max Hz |
|------|--------|--------|
| Bass | 20 | 250 |
| Mid | 250 | 2000 |
| High | 2000 | 8000 |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `computeFFT` | `Float32List audioBuffer` | `Float64List` | Compute FFT magnitudes |
| `getBandEnergy` | `Float64List magnitudes, double minFreq, double maxFreq` | `double` | Get energy in frequency band |
| `extractFeatures` | `Float32List audioBuffer` | `AudioReactivityData` | Extract all audio features |
| `computeSpectralCentroid` | `Float64List magnitudes` | `double` | Compute brightness (Hz) |
| `computeRMS` | `Float32List audioBuffer` | `double` | Compute RMS amplitude |
| `computeStereoWidth` | `Float32List left, Float32List right` | `double` | Compute stereo width |
| `normalizeEnergy` | `double energy, {double maxExpected, double smoothing}` | `double` | Normalize to 0-1 |

---

## Synthesis Branch Manager

### SynthesisBranchManager

**File:** `lib/synthesis/synthesis_branch_manager.dart:198`

Routes geometry to synthesis branches (Direct/FM/RingMod).

#### Constructor

```dart
SynthesisBranchManager({double sampleRate = 44100.0})
```

#### Geometry Routing

| Geometry Index | Core | Synthesis Branch |
|----------------|------|------------------|
| 0-7 | Base | Direct Synthesis |
| 8-15 | Hypersphere | FM Synthesis |
| 16-23 | Hypertetrahedron | Ring Modulation |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `currentGeometry` | `int` | Current geometry (0-23) |
| `visualSystem` | `VisualSystem` | Current visual system |
| `currentCore` | `PolytopeCor` | Current polytope core |
| `currentBaseGeometry` | `BaseGeometry` | Base geometry (0-7) |
| `soundFamily` | `SoundFamily` | Current sound family |
| `voiceCharacter` | `VoiceCharacter` | Current voice character |
| `configString` | `String` | Debug configuration string |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setGeometry` | `int geometry` | `void` | Set geometry (0-23) |
| `setVisualSystem` | `VisualSystem system` | `void` | Set visual system |
| `noteOn` | none | `void` | Trigger envelope |
| `noteOff` | none | `void` | Release envelope |
| `generateBuffer` | `int frames, double frequency` | `Float32List` | Generate audio |

---

### SoundFamily

**File:** `lib/synthesis/synthesis_branch_manager.dart:32`

Sound characteristics from visual system.

#### Presets

| System | Filter Q | Noise | Reverb | Brightness |
|--------|----------|-------|--------|------------|
| Quantum | 8.0 | 0.5% | 20% | 0.7 |
| Faceted | 5.5 | 1% | 30% | 0.6 |
| Holographic | 4.0 | 2% | 45% | 0.5 |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Family name |
| `waveformMix` | `List<double>` | [sine, square, triangle, saw] |
| `filterQ` | `double` | Resonance |
| `noiseLevel` | `double` | Noise amount (0-1) |
| `reverbMix` | `double` | Reverb mix (0-1) |
| `brightness` | `double` | Spectral tilt (0-1) |
| `harmonicAmplitudes` | `List<double>` | First 8 harmonics |

---

### VoiceCharacter

**File:** `lib/synthesis/synthesis_branch_manager.dart:86`

Voice characteristics from base geometry.

#### Presets

| Geometry | Attack | Release | Reverb | Harmonics | Detune |
|----------|--------|---------|--------|-----------|--------|
| Tetrahedron | 10ms | 250ms | 15% | 3 | 0 cents |
| Hypercube | 25ms | 400ms | 28% | 6 | 8 cents |
| Sphere | 60ms | 350ms | 25% | 4 | 0 cents |
| Torus | 15ms | 200ms | 20% | 5 | 5 cents |
| Klein Bottle | 35ms | 300ms | 35% | 5 | 12 cents |
| Fractal | 30ms | 500ms | 38% | 8 | 7 cents |
| Wave | 50ms | 450ms | 42% | 6 | 3 cents |
| Crystal | 2ms | 150ms | 48% | 5 | 0 cents |

---

## Parameter Bridge

### ParameterBridge

**File:** `lib/mapping/parameter_bridge.dart:24`

Orchestrates bidirectional audio-visual parameter flow at 60 FPS.

#### Constructor

```dart
ParameterBridge({
  required AudioProvider audioProvider,
  required VisualProvider visualProvider,
})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `audioToVisual` | `AudioToVisualModulator` | Audio→Visual modulator |
| `visualToAudio` | `VisualToAudioModulator` | Visual→Audio modulator |
| `currentPreset` | `MappingPreset` | Current mapping preset |
| `isRunning` | `bool` | Bridge running state |
| `currentFPS` | `double` | Current update FPS |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `start` | none | `void` | Start 60 FPS update loop |
| `stop` | none | `void` | Stop update loop |
| `loadPreset` | `MappingPreset preset` | `Future<void>` | Load mapping preset |
| `saveAsPreset` | `String name, String description` | `Future<MappingPreset>` | Save current mappings |
| `setAudioReactive` | `bool enabled` | `void` | Toggle audio reactivity |
| `setVisualReactive` | `bool enabled` | `void` | Toggle visual reactivity |

---

### AudioToVisualModulator

**File:** `lib/mapping/audio_to_visual.dart:22`

Maps audio features to visual parameters.

#### Default Mappings

| Audio Feature | Visual Parameter | Range | Curve |
|---------------|------------------|-------|-------|
| Bass Energy (20-250Hz) | Rotation Speed | 0.5-2.5x | Linear |
| Mid Energy (250-2kHz) | Tessellation Density | 3-8 | Exponential |
| High Energy (2k-8kHz) | Vertex Brightness | 0.5-1.0 | Linear |
| Spectral Centroid | Hue Shift | 0-360° | Linear |
| RMS Amplitude | Glow Intensity | 0-3 | Exponential |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `updateFromAudio` | `Float32List audioBuffer` | `void` | Update visuals from audio |
| `applyPreset` | `MappingPreset preset` | `void` | Apply mapping preset |
| `exportMappings` | none | `Map<String, ParameterMapping>` | Export current mappings |

---

### VisualToAudioModulator

**File:** `lib/mapping/visual_to_audio.dart:23`

Maps visual parameters to audio synthesis.

#### Default Mappings

| Visual Parameter | Audio Parameter | Range | Curve |
|------------------|-----------------|-------|-------|
| Rotation XY | Osc1 Detune | ±12 cents | Sinusoidal |
| Rotation XZ | Osc2 Detune | ±12 cents | Sinusoidal |
| Rotation YZ | Combined Detune | ±7 cents | Sinusoidal |
| Rotation XW | FM Depth | 0-2 semitones | Sinusoidal |
| Rotation YW | Ring Mod Depth | 0-100% | Sinusoidal |
| Rotation ZW | Filter Cutoff | ±40% | Sinusoidal |
| Morph Parameter | Waveform Crossfade | 0-1 | Linear |
| Chaos Amount | Noise Injection | 0-30% | Exponential |
| Rotation Speed | LFO Rate | 0.1-10 Hz | Logarithmic |
| Glow Intensity | Reverb Mix | 5-60% | Exponential |
| Tessellation Density | Voice Count | 1-8 | Linear |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `updateFromVisuals` | none | `void` | Update audio from visuals |
| `applyPreset` | `MappingPreset preset` | `void` | Apply mapping preset |
| `exportMappings` | none | `Map<String, ParameterMapping>` | Export current mappings |
| `enableVelocityModulation` | `bool enabled` | `void` | Enable rotation velocity mod |
| `enableComplexityHarmonics` | `bool enabled` | `void` | Enable complexity harmonics |
| `getModulationState` | none | `Map<String, dynamic>` | Get current modulation state |

---

### ParameterMapping

**File:** `lib/mapping/audio_to_visual.dart:137`

Configuration for a single parameter mapping.

#### Constructor

```dart
ParameterMapping({
  required String sourceParam,
  required String targetParam,
  required double minRange,
  required double maxRange,
  required MappingCurve curve,
})
```

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `map` | `double sourceValue` | `double` | Map 0-1 input to target range |

---

## Providers

### AudioProvider

**File:** `lib/providers/audio_provider.dart:28`

State management for audio synthesis system.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `synthesizerEngine` | `SynthesizerEngine` | Core synth engine |
| `audioAnalyzer` | `AudioAnalyzer` | FFT analyzer |
| `synthesisBranchManager` | `SynthesisBranchManager` | Branch router |
| `isInitialized` | `bool` | Initialization state |
| `isPcmAvailable` | `bool` | PCM audio available |
| `currentBuffer` | `Float32List?` | Current audio buffer |
| `currentFeatures` | `AudioReactivityData?` | Current audio features |
| `currentNote` | `int` | Current MIDI note |
| `isPlaying` | `bool` | Playback state |
| `masterVolume` | `double` | Master volume |
| `voiceCount` | `int` | Voice count |
| `activeNotes` | `List<int>` | Active MIDI notes |
| `mixBalance` | `double` | Oscillator mix |

#### Playback Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `startAudio` | none | `Future<void>` | Start audio generation |
| `stopAudio` | none | `Future<void>` | Stop audio generation |
| `playNote` | `int midiNote` | `void` | Play a note |
| `stopNote` | none | `void` | Stop current note |
| `noteOn` | `int midiNote` | `void` | Polyphonic note on |
| `noteOff` | `int midiNote` | `void` | Polyphonic note off |

#### Configuration Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setGeometry` | `int geometry` | `void` | Set geometry (0-23) |
| `setSystem` | `String systemName` | `void` | Set visual system |
| `setVisualSystem` | `String systemName` | `void` | Set visual system (alias) |
| `setMasterVolume` | `double volume` | `void` | Set master volume |
| `setMixBalance` | `double balance` | `void` | Set oscillator mix |
| `setVoiceCount` | `int count` | `void` | Set voice count |

#### Oscillator Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setOscillator1Waveform` | `Waveform waveform` | `void` | Set osc1 waveform |
| `setOscillator2Waveform` | `Waveform waveform` | `void` | Set osc2 waveform |
| `setOscillator1Detune` | `double cents` | `void` | Set osc1 detune |
| `setOscillator2Detune` | `double cents` | `void` | Set osc2 detune |
| `setPitchBend` | `double semitones` | `void` | Set pitch bend |
| `setVibratoDepth` | `double depth` | `void` | Set vibrato depth |

#### Filter Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setFilterType` | `FilterType type` | `void` | Set filter type |
| `setFilterCutoff` | `double cutoff` | `void` | Set cutoff (20-20000 Hz) |
| `setFilterResonance` | `double resonance` | `void` | Set resonance (0-1) |
| `setFilterEnvelopeAmount` | `double amount` | `void` | Set envelope amount |

#### Envelope Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setEnvelopeAttack` | `double attack` | `void` | Set attack (0.001-5s) |
| `setEnvelopeDecay` | `double decay` | `void` | Set decay (0.001-5s) |
| `setEnvelopeSustain` | `double sustain` | `void` | Set sustain (0-1) |
| `setEnvelopeRelease` | `double release` | `void` | Set release (0.001-10s) |

#### Effects Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setReverbMix` | `double mix` | `void` | Set reverb mix |
| `setReverbRoomSize` | `double roomSize` | `void` | Set room size |
| `setReverbDamping` | `double damping` | `void` | Set damping |
| `setDelayTime` | `double time` | `void` | Set delay time |
| `setDelayFeedback` | `double feedback` | `void` | Set delay feedback |
| `setDelayMix` | `double mix` | `void` | Set delay mix |

#### Synthesis Branch Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setFMDepth` | `double depth` | `void` | Set FM depth (Hypersphere) |
| `setRingModMix` | `double mix` | `void` | Set ring mod mix (Hypertetrahedron) |
| `setSynthesisBranch` | `int geometryIndex` | `void` | Set synthesis branch |

#### Audio Feature Getters

| Method | Returns | Description |
|--------|---------|-------------|
| `getBassEnergy()` | `double` | Bass energy (0-1) |
| `getMidEnergy()` | `double` | Mid energy (0-1) |
| `getHighEnergy()` | `double` | High energy (0-1) |
| `getSpectralCentroid()` | `double` | Spectral centroid (Hz) |
| `getRMS()` | `double` | RMS amplitude (0-1) |
| `getStereoWidth()` | `double` | Stereo width (0-1) |
| `getMetrics()` | `Map<String, dynamic>` | Performance metrics |
| `getSynthesisConfig()` | `String` | Current synth config |

---

### VisualProvider

**File:** `lib/providers/visual_provider.dart:25`

State management for VIB3+ visualization system.

#### Properties

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `currentSystemEnum` | `VisualSystem` | enum | Current visual system |
| `currentSystem` | `String` | - | System name (string) |
| `rotationXY` | `double` | 0-2π | XY plane rotation |
| `rotationXZ` | `double` | 0-2π | XZ plane rotation |
| `rotationYZ` | `double` | 0-2π | YZ plane rotation |
| `rotationXW` | `double` | 0-2π | XW plane rotation (4D) |
| `rotationYW` | `double` | 0-2π | YW plane rotation (4D) |
| `rotationZW` | `double` | 0-2π | ZW plane rotation (4D) |
| `rotationSpeed` | `double` | 0.1-5.0 | Rotation speed multiplier |
| `tessellationDensity` | `double` | 2-30 | Grid density |
| `vertexBrightness` | `double` | 0-1 | Vertex intensity |
| `hueShift` | `double` | 0-360 | Color hue offset |
| `glowIntensity` | `double` | 0-3 | Bloom/glow amount |
| `rgbSplitAmount` | `double` | 0-10 | Chromatic aberration |
| `saturation` | `double` | 0-1 | Color saturation |
| `morphParameter` | `double` | 0-1 | Geometry morph |
| `currentGeometry` | `int` | 0-23 | Current geometry index |
| `projectionDistance` | `double` | 5-15 | Camera distance |
| `layerSeparation` | `double` | 0-5 | Holographic depth |
| `activeVertexCount` | `int` | - | Active vertex count |
| `isAnimating` | `bool` | - | Animation state |
| `currentFPS` | `double` | - | Current frame rate |
| `systemColors` | `SystemColors` | - | System color scheme |

#### System Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `switchSystem` | `dynamic system` | `Future<void>` | Switch visual system |
| `setSystem` | `String systemName` | `Future<void>` | Set system (alias) |
| `setWebViewController` | `WebViewController controller` | `void` | Attach WebView |

#### Rotation Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `updateRotations` | `double deltaTime` | `void` | Update all rotations |
| `getRotationAngle` | `String plane` | `double` | Get rotation for plane |
| `setRotationXY` | `double angle` | `void` | Set XY rotation |
| `setRotationXZ` | `double angle` | `void` | Set XZ rotation |
| `setRotationYZ` | `double angle` | `void` | Set YZ rotation |
| `setRotationXW` | `double angle` | `void` | Set XW rotation |
| `setRotationYW` | `double angle` | `void` | Set YW rotation |
| `setRotationZW` | `double angle` | `void` | Set ZW rotation |
| `getRotationVelocity` | none | `double` | Get rotation velocity magnitude |

#### Visual Parameter Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `setRotationSpeed` | `double speed` | `void` | Set rotation speed |
| `setTessellationDensity` | `double density` | `void` | Set grid density |
| `setVertexBrightness` | `double brightness` | `void` | Set vertex brightness |
| `setHueShift` | `double hue` | `void` | Set hue shift |
| `setGlowIntensity` | `double intensity` | `void` | Set glow intensity |
| `setRGBSplitAmount` | `double amount` | `void` | Set RGB split |
| `setSaturation` | `double sat` | `void` | Set saturation |
| `setMorphParameter` | `double morph` | `void` | Set morph parameter |
| `setGeometry` | `int geometryIndex` | `Future<void>` | Set geometry (0-23) |
| `setProjectionDistance` | `double distance` | `void` | Set camera distance |
| `setLayerSeparation` | `double separation` | `void` | Set layer depth |

#### Query Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getMorphParameter()` | `double` | Get morph parameter |
| `getProjectionDistance()` | `double` | Get projection distance |
| `getLayerSeparation()` | `double` | Get layer separation |
| `getActiveVertexCount()` | `int` | Get vertex count |
| `getGeometryComplexity()` | `double` | Get geometry complexity |
| `getVisualState()` | `Map<String, dynamic>` | Get complete visual state |

#### Animation Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `startAnimation()` | `void` | Start animation loop |
| `stopAnimation()` | `void` | Stop animation loop |
| `updateFPS(double fps)` | `void` | Update FPS counter |
| `flushJSUpdatesNow()` | `Future<void>` | Force JS parameter flush |

---

## VIB3 Engine

### VIB3Engine

**File:** `lib/vib3/core/vib3_engine.dart:291`

Core VIB3+ visualization engine controller.

#### Constructor

```dart
VIB3Engine({VIB3EngineState? initialState})
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `state` | `VIB3EngineState` | Current engine state |
| `time` | `double` | Animation time |
| `isRunning` | `bool` | Running state |
| `currentFps` | `double` | Current FPS |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `updateState` | `VIB3EngineState newState` | `void` | Update full state |
| `setSystem` | `VisualSystem system` | `void` | Set visual system |
| `setGeometry` | `int geometryIndex` | `void` | Set geometry (0-23) |
| `setRotation` | `{double? xy, xz, yz, xw, yw, zw}` | `void` | Set rotations |
| `setVisualParameters` | `{int? tessellation, ...}` | `void` | Set visual params |
| `setAudioData` | `AudioReactivityData data` | `void` | Set audio data |
| `tick` | `double deltaSeconds` | `void` | Advance animation |
| `start` | none | `void` | Start engine |
| `stop` | none | `void` | Stop engine |
| `reset` | none | `void` | Reset to default |
| `getChaosValue` | `double base, double maxVariation` | `double` | Get chaos value |
| `getAudioModulatedValue` | `double base, double influence, {...}` | `double` | Get audio-modulated value |

---

### VIB3EngineState

**File:** `lib/vib3/core/vib3_engine.dart:115`

Complete VIB3+ engine state snapshot.

#### Factory Constructors

```dart
VIB3EngineState.quantum({int geometryIndex = 0})
VIB3EngineState.holographic({int geometryIndex = 0})
VIB3EngineState.faceted({int geometryIndex = 0})
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `system` | `VisualSystem` | quantum | Visual system |
| `geometryIndex` | `int` | 0 | Geometry (0-23) |
| `rotationXY/XZ/YZ/XW/YW/ZW` | `double` | 0.0 | Rotation angles |
| `animationSpeed` | `double` | 1.0 | Animation speed |
| `autoRotateSpeed` | `double` | 0.3 | Auto-rotate speed |
| `tessellationDensity` | `int` | 5 | Grid density |
| `vertexBrightness` | `double` | 0.8 | Vertex intensity |
| `hueShift` | `double` | 200.0 | Hue offset |
| `saturation` | `double` | 0.8 | Color saturation |
| `glowIntensity` | `double` | 1.0 | Glow amount |
| `rgbSplitAmount` | `double` | 0.0 | RGB split |
| `morphParameter` | `double` | 0.0 | Geometry morph |
| `chaosAmount` | `double` | 0.2 | Chaos/noise |
| `projectionDistance` | `double` | 8.0 | Camera distance |
| `fieldOfView` | `double` | 60.0 | FOV degrees |
| `layerSeparation` | `double` | 2.0 | Layer depth |
| `audioData` | `AudioReactivityData` | silent | Audio features |
| `audioReactivityStrength` | `double` | 0.5 | Audio influence |

#### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `coreIndex` | `int` | Synthesis branch (0-2) |
| `baseIndex` | `int` | Base geometry (0-7) |
| `isFMCore` | `bool` | Is FM synthesis branch |
| `isRingModCore` | `bool` | Is ring mod branch |

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `copyWith({...})` | `VIB3EngineState` | Create modified copy |
| `getEffectiveRotation(base, audioInfluence)` | `double` | Get audio-modulated rotation |

---

### AudioReactivityData

**File:** `lib/vib3/core/vib3_engine.dart:26`

Audio analysis data for visual modulation.

#### Constructor

```dart
AudioReactivityData({
  double bassEnergy = 0.0,
  double midEnergy = 0.0,
  double highEnergy = 0.0,
  double rmsAmplitude = 0.0,
  double spectralCentroid = 1000.0,
})
```

#### Factory Constructors

```dart
AudioReactivityData.silent  // Static const, all zeros
AudioReactivityData.fromFFT(List<double> bins, int sampleRate)
```

#### Properties

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `bassEnergy` | `double` | 0-1 | 20-250 Hz energy |
| `midEnergy` | `double` | 0-1 | 250-2000 Hz energy |
| `highEnergy` | `double` | 0-1 | 2000-8000 Hz energy |
| `rmsAmplitude` | `double` | 0-1 | Overall amplitude |
| `spectralCentroid` | `double` | Hz | Brightness measure |

---

## Models

### SynthPatch

**File:** `lib/models/synth_patch.dart:12`

Complete synthesizer preset configuration.

#### Factory Constructors

```dart
SynthPatch.defaultPatch()  // Sawtooth + square
SynthPatch.bass()          // Deep bass
SynthPatch.ambientPad()    // Lush pad
SynthPatch.lead()          // Bright lead
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Patch name |
| `description` | `String` | Patch description |
| `oscillator1Waveform` | `Waveform` | Osc1 waveform |
| `oscillator1Octave` | `int` | Osc1 octave offset |
| `oscillator1Detune` | `double` | Osc1 detune (cents) |
| `oscillator2Waveform` | `Waveform` | Osc2 waveform |
| `oscillator2Octave` | `int` | Osc2 octave offset |
| `oscillator2Detune` | `double` | Osc2 detune (cents) |
| `mixBalance` | `double` | Oscillator mix |
| `filterType` | `FilterType` | Filter type |
| `filterCutoff` | `double` | Cutoff (Hz) |
| `filterResonance` | `double` | Resonance |
| `reverbMix/RoomSize/Damping` | `double` | Reverb settings |
| `delayTime/Feedback/Mix` | `double` | Delay settings |
| `masterVolume` | `double` | Master volume |

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `applyToSynthesizer` | `SynthesizerEngine synth` | `void` | Apply patch |
| `toJson` | none | `Map<String, dynamic>` | Serialize to JSON |
| `fromJson` | `Map<String, dynamic> json` | `SynthPatch` | Deserialize |

---

### VisualState

**File:** `lib/models/visual_state.dart:10`

Complete visualization preset configuration.

#### Factory Constructors

```dart
VisualState.defaultState()  // Balanced quantum
VisualState.intense()       // High-energy holographic
VisualState.ambient()       // Slow, smooth
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | State name |
| `description` | `String` | State description |
| `system` | `String` | Visual system name |
| `rotationSpeedXW/YW/ZW` | `double` | 4D rotation speeds |
| `tessellationDensity` | `int` | Grid density |
| `vertexBrightness` | `double` | Vertex intensity |
| `hueShift` | `double` | Hue offset |
| `glowIntensity` | `double` | Glow amount |
| `rgbSplitAmount` | `double` | RGB split |
| `geometryIndex` | `int` | Geometry (0-23) |
| `morphParameter` | `double` | Geometry morph |
| `projectionDistance` | `double` | Camera distance |
| `layerSeparation` | `double` | Layer depth |

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `toJson()` | `Map<String, dynamic>` | Serialize to JSON |
| `fromJson(json)` | `VisualState` | Deserialize |

---

### MappingPreset

**File:** `lib/models/mapping_preset.dart:13`

Bidirectional parameter mapping configuration.

#### Factory Constructors

```dart
MappingPreset.defaultPreset()   // Balanced mappings
MappingPreset.bassHeavy()       // Aggressive bass reactivity
MappingPreset.ambientSpatial()  // Smooth ambient coupling
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Preset name |
| `description` | `String` | Preset description |
| `audioReactiveEnabled` | `bool` | Audio→Visual enabled |
| `visualReactiveEnabled` | `bool` | Visual→Audio enabled |
| `audioToVisualMappings` | `Map<String, ParameterMapping>` | Audio→Visual mappings |
| `visualToAudioMappings` | `Map<String, ParameterMapping>` | Visual→Audio mappings |

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `copyWith({...})` | `MappingPreset` | Create modified copy |
| `toJson()` | `Map<String, dynamic>` | Serialize to JSON |
| `fromJson(json)` | `MappingPreset` | Deserialize |

---

## Enums

### Waveform

**File:** `lib/audio/synthesizer_engine.dart:19`

```dart
enum Waveform {
  sine,       // Pure tone
  sawtooth,   // Bright, full harmonics
  square,     // Hollow, odd harmonics
  triangle,   // Soft, few harmonics
  wavetable,  // Morphable sine↔sawtooth
}
```

### FilterType

**File:** `lib/audio/synthesizer_engine.dart:28`

```dart
enum FilterType {
  lowpass,   // Attenuates highs
  highpass,  // Attenuates lows
  bandpass,  // Passes center frequency
  notch,     // Rejects center frequency
}
```

### VisualSystem

**File:** `lib/vib3/core/vib3_engine.dart:19`

```dart
enum VisualSystem {
  quantum,     // Pure harmonic - high resonance, bright
  holographic, // Spectral rich - multi-layer, warm
  faceted,     // Geometric hybrid - balanced
}
```

### MappingCurve

**File:** `lib/mapping/audio_to_visual.dart:179`

```dart
enum MappingCurve {
  linear,      // Direct 1:1 mapping
  exponential, // Accelerating curve (x²)
  logarithmic, // Decelerating curve (log)
  sinusoidal,  // S-curve, smooth transitions
}
```

### PolytopeCor

**File:** `lib/vib3/geometry/geometry_library.dart`

```dart
enum PolytopeCor {
  base,            // Direct synthesis (geometries 0-7)
  hypersphere,     // FM synthesis (geometries 8-15)
  hypertetrahedron, // Ring modulation (geometries 16-23)
}
```

### BaseGeometry

**File:** `lib/vib3/geometry/geometry_library.dart`

```dart
enum BaseGeometry {
  tetrahedron,  // 0: Fundamental, minimal
  hypercube,    // 1: Complex, dual oscillators
  sphere,       // 2: Smooth, filtered
  torus,        // 3: Cyclic, rhythmic
  kleinBottle,  // 4: Twisted, asymmetric
  fractal,      // 5: Recursive, self-modulating
  wave,         // 6: Flowing, sweeping
  crystal,      // 7: Crystalline, sharp attack
}
```

---

## Quick Reference: The 72 Combinations

```
Geometry Index = (Core × 8) + BaseGeometry

Core 0 (Base/Direct):      0-7
Core 1 (Hypersphere/FM):   8-15
Core 2 (Hypertetrahedron/RingMod): 16-23

× 3 Visual Systems (Quantum/Faceted/Holographic)
= 72 unique sound+visual combinations
```

---

*Document generated for Synth-VIB3+ v1.0*
*© 2025 Paul Phillips - Clear Seas Solutions LLC*
