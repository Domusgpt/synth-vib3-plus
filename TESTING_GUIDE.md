# Synth-VIB3+ Testing Guide

## Prerequisites

### Required Software
1. **Flutter SDK**: Version 3.9.0 or later
   ```bash
   flutter --version  # Verify installation
   flutter doctor      # Check for issues
   ```

2. **Android Device** or **Android Emulator**
   - Minimum API level: 21 (Android 5.0)
   - Recommended: Physical device for performance testing
   - WebView support required

3. **Git**: For version control and deployment

### Environment Setup

```bash
# Navigate to project directory
cd /path/to/synth-vib3-plus

# Install dependencies
flutter pub get

# Verify no issues
flutter analyze

# Run tests (if any exist)
flutter test
```

## Build and Run

### Development Build (Debug Mode)

```bash
# Run on connected device
flutter run

# Run with verbose logging
flutter run -v

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>
```

### Release Build (Testing)

```bash
# Build APK for Android
flutter build apk --release

# Install on connected device
flutter install

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## Testing Checklist

### Phase 1: Core System Verification

#### Audio System Tests
- [ ] **Synthesizer Engine**
  - [ ] Oscillator 1 generates audio
  - [ ] Oscillator 2 generates audio
  - [ ] Waveforms can be changed (sine, saw, square, triangle)
  - [ ] Filter responds to cutoff changes
  - [ ] Filter resonance works
  - [ ] Reverb and delay effects audible

- [ ] **Synthesis Branch Manager**
  - [ ] Test all 3 synthesis branches:
    - [ ] Direct synthesis (geometries 0-7)
    - [ ] FM synthesis (geometries 8-15)
    - [ ] Ring modulation (geometries 16-23)
  - [ ] Each geometry produces unique sound
  - [ ] No audio glitches or crackling
  - [ ] Envelope attack/release working

- [ ] **Audio Analyzer**
  - [ ] FFT analysis produces valid data
  - [ ] Bass energy detection (20-250 Hz)
  - [ ] Mid energy detection (250-2000 Hz)
  - [ ] High energy detection (2000-8000 Hz)
  - [ ] Spectral centroid calculation
  - [ ] RMS amplitude tracking

#### Visual System Tests
- [ ] **VIB3+ WebView Integration**
  - [ ] WebView loads successfully
  - [ ] VIB3+ engine initializes
  - [ ] No JavaScript errors in console
  - [ ] Visualization renders at ~60 FPS

- [ ] **Visual Provider**
  - [ ] System switching works (Quantum, Faceted, Holographic)
  - [ ] Geometry selection works (0-7 for each system)
  - [ ] Rotation speed changes visible
  - [ ] Tessellation density changes visible
  - [ ] Hue shift works
  - [ ] Glow intensity changes visible

#### Parameter Bridge Tests
- [ ] **Bidirectional Coupling**
  - [ ] Parameter bridge starts automatically
  - [ ] Runs at 60 FPS (check debug overlay)
  - [ ] No performance degradation over time

- [ ] **Audio → Visual Modulation**
  - [ ] Bass energy modulates rotation speed
  - [ ] Mid energy modulates tessellation density
  - [ ] High energy modulates vertex brightness
  - [ ] Spectral centroid modulates hue shift
  - [ ] RMS amplitude modulates glow intensity

- [ ] **Visual → Audio Modulation**
  - [ ] XW rotation modulates oscillator 1 detune
  - [ ] YW rotation modulates oscillator 2 detune
  - [ ] ZW rotation modulates filter cutoff
  - [ ] Morph parameter modulates wavetable
  - [ ] Projection distance modulates reverb
  - [ ] Layer depth modulates delay time

### Phase 2: 72 Geometry Matrix Testing

Test each combination systematically (see GEOMETRY_MATRIX.md):

#### Quantum System (Geometries 0-7) - Direct Synthesis
- [ ] Geometry 0: Tetrahedron - Fundamental tone
- [ ] Geometry 1: Hypercube - Complex harmonics
- [ ] Geometry 2: Sphere - Smooth filtered
- [ ] Geometry 3: Torus - Cyclic modulation
- [ ] Geometry 4: Klein Bottle - Stereo movement
- [ ] Geometry 5: Fractal - Recursive complexity
- [ ] Geometry 6: Wave - Sweeping filters
- [ ] Geometry 7: Crystal - Sharp attacks

#### Faceted System (Geometries 8-15) - FM Synthesis
- [ ] Geometry 8: Tetrahedron - FM fundamental
- [ ] Geometry 9: Hypercube - FM complex
- [ ] Geometry 10: Sphere - FM smooth
- [ ] Geometry 11: Torus - FM cyclic
- [ ] Geometry 12: Klein Bottle - FM stereo
- [ ] Geometry 13: Fractal - FM recursive
- [ ] Geometry 14: Wave - FM sweeping
- [ ] Geometry 15: Crystal - FM sharp

#### Holographic System (Geometries 16-23) - Ring Modulation
- [ ] Geometry 16: Tetrahedron - Ring mod fundamental
- [ ] Geometry 17: Hypercube - Ring mod complex
- [ ] Geometry 18: Sphere - Ring mod smooth
- [ ] Geometry 19: Torus - Ring mod cyclic
- [ ] Geometry 20: Klein Bottle - Ring mod stereo
- [ ] Geometry 21: Fractal - Ring mod recursive
- [ ] Geometry 22: Wave - Ring mod sweeping
- [ ] Geometry 23: Crystal - Ring mod sharp

### Phase 3: UI/UX Testing

#### Main Screen Layout
- [ ] Top bezel visible and functional
- [ ] XY performance pad responsive
- [ ] Multi-touch support (up to 8 touches)
- [ ] Orb controller visible and draggable
- [ ] Bottom bezel collapsible panels work
- [ ] Portrait/landscape orientation handling

#### Performance Pad
- [ ] Touch positions accurately tracked
- [ ] Grid overlay toggle works
- [ ] Visual feedback on touch
- [ ] Note triggering on touch
- [ ] Smooth touch tracking (no jitter)

#### Tilt Sensor Integration
- [ ] Accelerometer data received
- [ ] Gyroscope data received
- [ ] Tilt modulation can be assigned
- [ ] Smooth tilt response
- [ ] No latency in tilt control

### Phase 4: Performance Testing

#### Frame Rate
- [ ] Visual system maintains 60 FPS
- [ ] No frame drops during audio generation
- [ ] Smooth animation throughout session
- [ ] Monitor FPS in debug overlay

#### Audio Latency
- [ ] Touch to sound latency < 10ms
- [ ] No audio buffer underruns
- [ ] No crackling or pops
- [ ] Stable audio throughput

#### Memory Usage
- [ ] Monitor memory over 30-minute session
- [ ] No memory leaks
- [ ] Stable memory footprint
- [ ] No crashes or freezes

#### Battery Usage
- [ ] Test on physical device
- [ ] Monitor battery drain rate
- [ ] Check CPU/GPU usage
- [ ] Verify acceptable power consumption

## Debugging Tools

### Enable Debug Overlay
Edit `/lib/ui/screens/synth_main_screen.dart`:
```dart
bool _shouldShowDebugOverlay(BuildContext context) {
  return true; // Set to true for debugging
}
```

Debug overlay shows:
- Current FPS
- Active visual system
- Current geometry index
- Orb controller position

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

Access at: http://127.0.0.1:9100

Features:
- Performance profiling
- Memory analysis
- Widget inspector
- Network monitoring

### Logging
Check logs with:
```bash
flutter logs

# Filter for specific tags
flutter logs | grep "🎵"  # Audio logs
flutter logs | grep "🎨"  # Visual logs
flutter logs | grep "⚡"  # Parameter bridge logs
```

## Common Issues and Solutions

### Issue: WebView not loading
**Solution**:
1. Check internet connectivity
2. Verify WebView is enabled on device
3. Check for JavaScript errors in logs
4. Try loading on different device

### Issue: No audio output
**Solution**:
1. Check device volume
2. Verify audio permissions in AndroidManifest.xml
3. Check AudioProvider initialization
4. Test with headphones

### Issue: Low FPS
**Solution**:
1. Disable unnecessary features
2. Reduce tessellation density
3. Test on physical device (not emulator)
4. Check for heavy processes running

### Issue: Parameter bridge not working
**Solution**:
1. Verify ParameterBridge is started in main.dart
2. Check providers are properly initialized
3. Enable debug logging
4. Verify 60 FPS timer is running

## Test Verification Script

A test script has been created to automate basic verification:

```bash
# Run automated tests (when Flutter is available)
./test_synth_vib3.sh
```

## Reporting Issues

When reporting issues, include:
1. Flutter version (`flutter --version`)
2. Device model and Android version
3. Steps to reproduce
4. Expected vs actual behavior
5. Screenshots/videos if applicable
6. Relevant logs from `flutter logs`

## Success Criteria

The application is considered ready for deployment when:
- [ ] All 72 geometry combinations produce unique sounds
- [ ] Visual system runs at 60 FPS consistently
- [ ] Audio latency < 10ms
- [ ] No crashes during 30-minute test session
- [ ] All bidirectional mappings work correctly
- [ ] UI is responsive and intuitive
- [ ] Memory usage is stable
- [ ] Battery drain is acceptable

---

A Paul Phillips Manifestation
Paul@clearseassolutions.com
"The Revolution Will Not be in a Structured Format"
© 2025 Paul Phillips - Clear Seas Solutions LLC
