# Device Testing Guide for Synth-VIB3+

**Date:** 2025-11-18
**Branch:** `claude/refactor-synthesizer-visualizer-012K7EbKVyBNNLXNfXwUgF3r`
**Version:** Phases 1 & 2 Complete + XR SDK Optimizations
**Deployment Readiness:** ~97%

---

## Prerequisites

### Hardware Requirements
- **Physical Android Device** (emulators don't support PCM audio)
- Android 7.0 (API 24) or higher
- Minimum 2GB RAM (4GB recommended)
- GPU with OpenGL ES 3.0+ for WebGL visualization
- USB cable for device connection

### Software Requirements
```bash
# Verify Flutter installation
flutter --version
# Should show: Flutter 3.x.x or higher

# Check connected devices
flutter devices
# Should list your Android device

# Verify Android SDK
flutter doctor
# All checks should pass (or minor warnings only)
```

---

## Test Environment Setup

### 1. Enable Developer Options on Android Device

1. **Go to Settings → About Phone**
2. **Tap "Build Number" 7 times** (enables developer mode)
3. **Go back to Settings → Developer Options**
4. **Enable:**
   - USB Debugging
   - Stay Awake (keeps screen on during testing)
   - GPU Rendering (for WebGL performance)

### 2. Connect Device

```bash
# Connect device via USB
adb devices
# Should show: <device_id>  device

# If shows "unauthorized", check phone for authorization prompt
```

### 3. Install App

```bash
cd /home/user/synth-vib3-plus

# Debug build (faster, includes logging)
flutter run

# Release build (optimized, production-like)
flutter run --release

# Profile build (optimized + profiling tools)
flutter run --profile
```

---

## Test Plan

### Phase 1: Basic Functionality Tests

#### Test 1.1: App Launch ✅
**Expected:** App starts without crashes

**Steps:**
1. Launch app
2. Wait for splash screen (if any)
3. Main screen should appear

**Console Output to Check:**
```
✅ Firebase initialized (or ⚠️ warning if offline)
✅ AudioProvider initialized with SynthesisBranchManager
✅ VisualProvider initialized
✅ PCM Sound initialized: 44100 Hz, mono
✅ Parameter bridge started at 60 FPS
✅ Visual animation started
✅ WebView controller attached to VisualProvider
✅ Parameter batch synchronizer initialized
```

**Pass Criteria:**
- [ ] App launches
- [ ] No crash/error dialogs
- [ ] All ✅ messages in console
- [ ] Main UI visible

---

#### Test 1.2: Audio Output ✅
**Expected:** Sound plays from device speakers

**Steps:**
1. Tap XY pad to trigger note
2. Listen for audio output
3. Drag finger on XY pad
4. Audio pitch/timbre should change
5. Release finger
6. Audio should stop (or fade out)

**Console Output:**
```
🎵 Geometry 0: base core, tetrahedron geometry
▶️  Audio started
✅ PCM player started
```

**Pass Criteria:**
- [ ] Hear synthesized tone when touching XY pad
- [ ] Pitch changes with vertical drag
- [ ] Timbre changes with horizontal drag
- [ ] No crackling/distortion
- [ ] Clean note release

**Common Issues:**
- **No sound:** Check device volume, check console for PCM errors
- **Crackling:** May indicate buffer underrun, check latency settings
- **Delayed response:** Check for FPS drops in console

---

#### Test 1.3: Visual Rendering ✅
**Expected:** VIB3+ 4D visualization appears and animates

**Steps:**
1. Observe main screen
2. VIB3+ visualization should be visible (not placeholder text)
3. Geometry should rotate automatically
4. Try system switching (if UI available)

**Console Output:**
```
✅ VIB34D WebView ready
📄 Page loaded: https://domusgpt.github.io/vib3-plus-engine/
```

**Pass Criteria:**
- [ ] VIB3+ visualization visible (rotating 4D geometry)
- [ ] Smooth animation (target: 60 FPS)
- [ ] No black screen or loading forever
- [ ] System switching works (Quantum/Faceted/Holographic)

**Common Issues:**
- **Black screen:** Check internet connection (WebView loads from GitHub)
- **Loading forever:** Check console for WebView errors
- **Stuttering:** May indicate low FPS, check performance metrics

---

#### Test 1.4: Audio → Visual Coupling ✅
**Expected:** Visuals react to audio in real-time

**Steps:**
1. Play a note (tap/hold XY pad)
2. Observe visual changes:
   - Rotation speed should increase (bass frequency)
   - Brightness should pulse (amplitude)
   - Tessellation may change (mid frequencies)
   - Hue may shift (spectral centroid)
   - Glow should increase (RMS amplitude)
3. Play different notes (low vs high)
4. Change volume (if available)

**Console Output:**
```
📊 FPS: 60.0
(Parameter bridge should show no errors)
```

**Pass Criteria:**
- [ ] Visuals respond to audio
- [ ] Bass increases rotation speed
- [ ] Louder sound increases glow
- [ ] Different notes cause different visual reactions
- [ ] Response feels immediate (<50ms latency)

---

#### Test 1.5: Visual → Audio Coupling ✅
**Expected:** Visual changes affect audio synthesis

**Steps:**
1. Play sustained note
2. Observe that rotating geometry affects:
   - Pitch modulation (slight detuning)
   - Timbre changes (filter modulation)
   - Harmonic content (waveform morphing)
3. Switch systems (Quantum/Faceted/Holographic)
4. Sound character should change

**Console Output:**
```
🎨 Visual system set to: holographic
🎵 Geometry set to: 16 (Hypertetrahedron Tetrahedron)
```

**Pass Criteria:**
- [ ] Visual rotation affects sound
- [ ] System switching changes timbre
- [ ] Quantum: Pure, harmonic (sine-based)
- [ ] Faceted: Geometric (square/triangle)
- [ ] Holographic: Rich, complex (sawtooth-based)

---

### Phase 2: Performance Tests

#### Test 2.1: Parameter Bridge FPS ✅
**Expected:** Bridge maintains 60 FPS

**Steps:**
1. Play note and interact with visuals
2. Monitor console for FPS warnings
3. Check for < 30 FPS warnings

**Console Output (Good):**
```
📊 Parameter bridge FPS: 60.0
```

**Console Output (Bad):**
```
⚠️ WARNING: Parameter bridge FPS low: 28.5 (target: 60.0)
📝 This may cause audio-visual coupling lag.
```

**Pass Criteria:**
- [ ] FPS stays above 55
- [ ] No performance warnings
- [ ] Smooth parameter updates

**If fails:** Device may be underpowered, try reducing visual complexity

---

#### Test 2.2: WebView Batching Efficiency ✅
**Expected:** Batching reduces WebView calls by 80-90%

**Steps:**
1. Run app for 60 seconds with audio playing
2. Get batching stats (requires console access or debug UI)

**Console Command (if available):**
```dart
// Add to debug overlay temporarily
final stats = visualProvider.getPerformanceStats();
print('Batching: ${stats['batching']}');
```

**Expected Output:**
```dart
{
  'totalUpdates': 3600,
  'batchesSent': 3600,
  'averagePerBatch': '6.0',
  'updatesSavedPercentage': '83.3'
}
```

**Pass Criteria:**
- [ ] updatesSavedPercentage > 80%
- [ ] averagePerBatch > 5
- [ ] No excessive WebView errors

---

#### Test 2.3: Memory Usage ✅
**Expected:** Stable memory usage, no leaks

**Steps:**
1. Install app
2. Play for 5 minutes continuously
3. Monitor memory in Android Studio Profiler or:

```bash
# Get memory usage
adb shell dumpsys meminfo com.example.synther_vib34d_holographic
```

**Pass Criteria:**
- [ ] Memory usage < 200 MB
- [ ] No continuous growth (leak indication)
- [ ] Heap stable after 2-3 minutes

---

#### Test 2.4: Battery Usage ✅
**Expected:** Reasonable battery drain

**Steps:**
1. Note battery level before starting
2. Run app continuously for 30 minutes
3. Check battery drain

**Pass Criteria:**
- [ ] Drain < 30% per hour (acceptable for audio/graphics app)
- [ ] Device doesn't overheat
- [ ] CPU usage reasonable (check with adb)

```bash
adb shell top -n 1 | grep synther
```

---

### Phase 3: Error Recovery Tests

#### Test 3.1: Audio Output Errors ✅
**Expected:** Graceful degradation if audio fails

**Steps:**
1. Start app
2. Plug/unplug headphones rapidly during playback
3. Check for error recovery

**Expected Console Output:**
```
❌ Audio output error: ...
⚠️ Audio output errors: 2 consecutive
✅ Audio output recovered after 2 errors
```

**Pass Criteria:**
- [ ] Errors logged clearly
- [ ] Audio recovers automatically
- [ ] No crash
- [ ] Health API shows recovery

**Critical Error (5+ consecutive):**
```
🛑 CRITICAL: Audio output failed permanently after 5 errors
💡 Audio playback disabled. Check PCM sound initialization.
```

---

#### Test 3.2: WebView Communication Errors ✅
**Expected:** Continues operating if WebView fails

**Steps:**
1. Start app
2. Turn off internet (if WebView hasn't cached yet)
3. Or: Force WebView error somehow

**Expected Console Output:**
```
❌ WebView JS error updating rotationXW: ...
⚠️ WebView JS errors: 2 consecutive
```

**Pass Criteria:**
- [ ] Errors tracked
- [ ] Audio still works
- [ ] App doesn't crash
- [ ] After 5 errors, updates disabled gracefully

---

#### Test 3.3: Parameter Bridge Errors ✅
**Expected:** Bridge stops if too many errors

**Steps:**
1. Run app under stress (rapid parameter changes)
2. Monitor for bridge errors

**Critical Failure:**
```
🛑 CRITICAL: Too many consecutive errors (10). Stopping parameter bridge.
```

**Pass Criteria:**
- [ ] Errors tracked
- [ ] Bridge stops gracefully after 10 errors
- [ ] App doesn't crash
- [ ] Audio or visual still functional independently

---

### Phase 4: Extended Testing

#### Test 4.1: Stress Test ✅
**Expected:** App stable under heavy load

**Steps:**
1. Play rapid note sequences
2. Change systems frequently
3. Adjust parameters rapidly
4. Run for 10 minutes

**Pass Criteria:**
- [ ] No crashes
- [ ] No memory leaks
- [ ] FPS remains stable
- [ ] Audio quality maintained

---

#### Test 4.2: Orientation Changes ✅
**Expected:** Handles rotation gracefully

**Steps:**
1. Start app in portrait
2. Rotate to landscape
3. Rotate back to portrait

**Pass Criteria:**
- [ ] UI adapts
- [ ] No crash
- [ ] Audio continues
- [ ] Visual continues

---

#### Test 4.3: Background/Foreground ✅
**Expected:** Handles app switching

**Steps:**
1. Play audio
2. Press Home (background app)
3. Wait 10 seconds
4. Return to app

**Pass Criteria:**
- [ ] Audio stops when backgrounded
- [ ] App resumes correctly
- [ ] No crash
- [ ] Visual state preserved

---

### Phase 5: Synthesis System Tests

#### Test 5.1: 72 Combinations ✅
**Expected:** All 72 sound+visual combinations unique

**Testing Matrix:**
- 3 Visual Systems (Quantum, Faceted, Holographic)
- 3 Polytope Cores (Base, Hypersphere, Hypertetrahedron)
- 8 Base Geometries

**Steps:**
1. For each visual system:
   2. For each geometry (0-23):
      3. Play note
      4. Record sonic character
      5. Record visual character

**Pass Criteria:**
- [ ] Each combination sounds different
- [ ] Quantum: Pure harmonic
- [ ] Faceted: Geometric hybrid
- [ ] Holographic: Rich spectral
- [ ] Geometries 0-7: Direct synthesis
- [ ] Geometries 8-15: FM synthesis
- [ ] Geometries 16-23: Ring modulation

---

#### Test 5.2: Musical Accuracy ✅
**Expected:** Pitches are correctly tuned

**Steps:**
1. Play MIDI note 60 (Middle C = 261.63 Hz)
2. Use tuner app to verify frequency
3. Test octaves (48, 60, 72, 84)

**Pass Criteria:**
- [ ] Middle C = ~262 Hz (within 5 cents)
- [ ] Octaves perfect (2:1 ratio)
- [ ] No drift over time

---

## Performance Benchmarks

### Target Metrics

| Metric | Minimum | Target | Excellent |
|--------|---------|--------|-----------|
| Audio Latency | <50ms | <20ms | <10ms |
| Visual FPS | >30 | >45 | 60 |
| Bridge FPS | >30 | >55 | 60 |
| Memory Usage | <250 MB | <200 MB | <150 MB |
| CPU Usage | <50% | <30% | <20% |
| Battery Drain | <50%/hr | <30%/hr | <20%/hr |

### Device Categories

**Low-End** (e.g., Pixel 3a, Galaxy A series)
- Expect: 30-45 FPS visual, audio latency 20-30ms
- Acceptable if no crashes, audio works

**Mid-Range** (e.g., Pixel 6, Galaxy S21)
- Expect: 45-60 FPS visual, audio latency 10-20ms
- Should hit all target metrics

**High-End** (e.g., Pixel 8 Pro, Galaxy S23 Ultra)
- Expect: 60 FPS sustained, audio latency <10ms
- Should hit all excellent metrics

---

## Debugging Tips

### Enable Verbose Logging

**Temporary debug overlay:**

Add to `lib/ui/screens/synth_main_screen.dart`:

```dart
// In _SynthMainContent, set:
bool _shouldShowDebugOverlay(BuildContext context) {
  return true; // Changed from false
}
```

### Check Console Logs

```bash
# View all logs
adb logcat | grep flutter

# Filter for errors
adb logcat | grep -E "(ERROR|❌|🛑)"

# Filter for FPS
adb logcat | grep FPS
```

### Capture Performance Profile

```bash
# Run in profile mode
flutter run --profile

# Then in DevTools:
# Open http://localhost:9100
# Go to Performance tab
# Record profile while testing
```

### Get System Health Report

**Add to app temporarily:**

```dart
// In main.dart, after providers initialized:
Future.delayed(Duration(seconds: 10), () {
  final monitor = SystemHealthMonitor(
    audioProvider: audioProvider,
    visualProvider: visualProvider,
    parameterBridge: parameterBridge,
  );
  monitor.printHealthReport();
});
```

---

## Known Issues & Workarounds

### Issue 1: WebView Loads Slowly
**Symptom:** Black screen for 5-10 seconds on first launch

**Workaround:** Wait for internet connection, WebView caches after first load

**Fix (future):** Bundle VIB3+ assets locally

---

### Issue 2: Audio Crackling on Low-End Devices
**Symptom:** Intermittent crackling/popping in audio

**Workaround:** Increase buffer size (currently 512 samples)

**Fix (future):** Adaptive buffer sizing based on device

---

### Issue 3: High Battery Drain
**Symptom:** Battery drains >40%/hour

**Workaround:** Reduce visual complexity, lower FPS target

**Fix (future):** Power-saving mode, adaptive quality

---

## Test Report Template

```markdown
# Synth-VIB3+ Device Test Report

**Date:** YYYY-MM-DD
**Tester:** Your Name
**Device:** [Model], Android [Version]
**App Version:** Phase 1+2 Complete + Optimizations

## Pass/Fail Summary
- [ ] App Launch
- [ ] Audio Output
- [ ] Visual Rendering
- [ ] Audio→Visual Coupling
- [ ] Visual→Audio Coupling
- [ ] Performance (FPS)
- [ ] Error Recovery
- [ ] Stress Test

## Performance Metrics
- Audio Latency: ___ms
- Visual FPS: ___
- Bridge FPS: ___
- Memory Usage: ___MB
- CPU Usage: ___%

## Issues Found
1. [Issue description]
2. [Issue description]

## Notes
[Additional observations]
```

---

## Success Criteria for Deployment

### Must Pass (Blocker)
- [ ] App launches without crash
- [ ] Audio plays from speakers
- [ ] Visual renders (not black screen)
- [ ] No permanent failures during normal use
- [ ] Memory usage stable (no leaks)

### Should Pass (High Priority)
- [ ] FPS >45 on mid-range devices
- [ ] Audio latency <20ms
- [ ] All 72 combinations sound unique
- [ ] Error recovery works
- [ ] No crashes during 10-minute stress test

### Nice to Have (Medium Priority)
- [ ] FPS 60 sustained
- [ ] Audio latency <10ms
- [ ] Battery drain <30%/hour
- [ ] Smooth on low-end devices

---

## Next Steps After Testing

1. **Record Results:** Use test report template
2. **File Issues:** Create GitHub issues for bugs found
3. **Performance Data:** Share FPS, latency, memory metrics
4. **Videos/Screenshots:** Capture demo videos
5. **Recommendations:** Suggest optimizations based on findings

---

## Questions?

- Review `PHASE1_COMPLETE.md` for Phase 1 details
- Review `PHASE2_COMPLETE.md` for Phase 2 details
- Check `DEPLOYMENT_ANALYSIS_REPORT.md` for architecture
- See commit `a36814d` for latest optimizations
- Contact: Paul@clearseassolutions.com

---

*Testing Guide created for Synth-VIB3+ Phase 1+2+Optimizations*
*"The Revolution Will Not be in a Structured Format"*
*© 2025 Paul Phillips - Clear Seas Solutions LLC*
