/**
 * Visual → Audio Modulation System
 *
 * Maps visual parameter state to audio synthesis parameters:
 * - 4D Rotation XW Plane → Oscillator 1 Frequency (±2 semitones)
 * - 4D Rotation YW Plane → Oscillator 2 Frequency (±2 semitones)
 * - 4D Rotation ZW Plane → Filter Cutoff Frequency (±40%)
 * - Polytope Vertex Count → Voice Count
 * - Geometry Morph Parameter → Wavetable Position
 * - Projection Distance → Reverb Wet/Dry Mix
 * - Holographic Layer Depth → Delay Time
 *
 * A Paul Phillips Manifestation
 */

import 'dart:math' as math;
import '../providers/audio_provider.dart';
import '../providers/visual_provider.dart';
import '../models/mapping_preset.dart';
import '../vib3/geometry/geometry_library.dart' show PolytopeCor;
import 'audio_to_visual.dart'; // For ParameterMapping and MappingCurve

class VisualToAudioModulator {
  final AudioProvider audioProvider;
  final VisualProvider visualProvider;

  // Mapping configuration
  Map<String, ParameterMapping> _mappings = {};

  VisualToAudioModulator({
    required this.audioProvider,
    required this.visualProvider,
  }) {
    _initializeDefaultMappings();
  }

  void _initializeDefaultMappings() {
    _mappings = {
      // === 3D-like rotations → Oscillator detuning (CLAUDE.md spec) ===
      'rotationXY_to_osc1Detune': ParameterMapping(
        sourceParam: 'rotationXY',
        targetParam: 'oscillator1Detune',
        minRange: -12.0, // -12 cents
        maxRange: 12.0,  // +12 cents
        curve: MappingCurve.sinusoidal,
      ),
      'rotationXZ_to_osc2Detune': ParameterMapping(
        sourceParam: 'rotationXZ',
        targetParam: 'oscillator2Detune',
        minRange: -12.0, // -12 cents
        maxRange: 12.0,  // +12 cents
        curve: MappingCurve.sinusoidal,
      ),
      'rotationYZ_to_combinedDetune': ParameterMapping(
        sourceParam: 'rotationYZ',
        targetParam: 'combinedDetune',
        minRange: -7.0,  // -7 cents
        maxRange: 7.0,   // +7 cents
        curve: MappingCurve.sinusoidal,
      ),

      // === 4D rotations → Synthesis branch modulation ===
      'rotationXW_to_fmDepth': ParameterMapping(
        sourceParam: 'rotationXW',
        targetParam: 'fmDepth',  // FM depth for Hypersphere core
        minRange: 0.0,
        maxRange: 2.0,  // 0-2 semitones
        curve: MappingCurve.sinusoidal,
      ),
      'rotationYW_to_ringModDepth': ParameterMapping(
        sourceParam: 'rotationYW',
        targetParam: 'ringModDepth',  // Ring mod for Hypertetrahedron core
        minRange: 0.0,
        maxRange: 1.0,  // 0-100%
        curve: MappingCurve.sinusoidal,
      ),
      'rotationZW_to_filterCutoff': ParameterMapping(
        sourceParam: 'rotationZW',
        targetParam: 'filterCutoff',
        minRange: -0.4,  // -40% modulation
        maxRange: 0.4,   // +40% modulation
        curve: MappingCurve.sinusoidal,
      ),

      // === Visual parameters → Audio effects ===
      'morphParameter_to_waveformCrossfade': ParameterMapping(
        sourceParam: 'morphParameter',
        targetParam: 'waveformCrossfade',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.linear,
      ),
      'chaosAmount_to_noiseInjection': ParameterMapping(
        sourceParam: 'chaosAmount',
        targetParam: 'noiseInjection',
        minRange: 0.0,
        maxRange: 0.3,  // 0-30%
        curve: MappingCurve.exponential,
      ),
      'rotationSpeed_to_lfoRate': ParameterMapping(
        sourceParam: 'rotationSpeed',
        targetParam: 'lfoRate',
        minRange: 0.1,   // 0.1 Hz
        maxRange: 10.0,  // 10 Hz
        curve: MappingCurve.logarithmic,
      ),
      'hueShift_to_spectralTilt': ParameterMapping(
        sourceParam: 'hueShift',
        targetParam: 'spectralTilt',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.linear,
      ),
      'glowIntensity_to_reverbMix': ParameterMapping(
        sourceParam: 'glowIntensity',
        targetParam: 'reverbMix',
        minRange: 0.05,  // 5%
        maxRange: 0.60,  // 60%
        curve: MappingCurve.exponential,
      ),
      'glowIntensity_to_attackTime': ParameterMapping(
        sourceParam: 'glowIntensity',
        targetParam: 'attackTime',
        minRange: 0.001, // 1ms
        maxRange: 0.100, // 100ms
        curve: MappingCurve.linear,
      ),
      'tessellationDensity_to_voiceCount': ParameterMapping(
        sourceParam: 'tessellationDensity',
        targetParam: 'voiceCount',
        minRange: 1.0,
        maxRange: 8.0,
        curve: MappingCurve.linear,
      ),

      // === Additional visual parameters ===
      'saturation_to_filterResonance': ParameterMapping(
        sourceParam: 'saturation',
        targetParam: 'filterResonance',
        minRange: 0.1,   // Low resonance
        maxRange: 0.9,   // High resonance (not self-oscillating)
        curve: MappingCurve.exponential,
      ),
      'vertexBrightness_to_harmonicIntensity': ParameterMapping(
        sourceParam: 'vertexBrightness',
        targetParam: 'harmonicIntensity',
        minRange: 0.3,   // Subdued harmonics
        maxRange: 1.0,   // Full harmonic content
        curve: MappingCurve.linear,
      ),
      'rgbSplit_to_stereoWidth': ParameterMapping(
        sourceParam: 'rgbSplitAmount',
        targetParam: 'stereoWidth',
        minRange: 0.0,   // Mono
        maxRange: 1.0,   // Full stereo spread
        curve: MappingCurve.linear,
      ),

      // === Legacy mappings (kept for backward compat) ===
      'layerDepth_to_delay': ParameterMapping(
        sourceParam: 'layerDepth',
        targetParam: 'delayTime',
        minRange: 0.0,     // 0ms
        maxRange: 500.0,   // 500ms
        curve: MappingCurve.linear,
      ),
    };
  }

  /// Main update function called at 60 FPS
  void updateFromVisuals() {
    // Read current visual state
    final visualState = _getVisualState();

    // Apply each mapping
    _mappings.forEach((key, mapping) {
      final sourceValue = visualState[mapping.sourceParam] ?? 0.0;
      final mappedValue = mapping.map(sourceValue);

      // Update corresponding audio parameter
      _updateAudioParameter(mapping.targetParam, mappedValue);
    });

    // Special case: vertex count to voice count (discrete mapping)
    final vertexCount = visualProvider.getActiveVertexCount();
    final voiceCount = _mapVertexCountToVoices(vertexCount);
    audioProvider.setVoiceCount(voiceCount);

    // **NEW**: Sync geometry to synthesis branch manager
    _syncGeometryToAudio();

    // **NEW**: Sync visual system to sound family
    _syncVisualSystemToAudio();
  }

  /// Sync geometry changes to audio provider
  void _syncGeometryToAudio() {
    // FIX: Visual provider's currentGeometry is already the full 0-23 index
    // that encodes both polytope core (0-7=Base, 8-15=Hypersphere, 16-23=Hypertetrahedron)
    // and base geometry (index % 8). No offset calculation needed.
    //
    // The visual system (Quantum/Faceted/Holographic) is SEPARATE and controls
    // sound family, NOT the polytope core / synthesis branch.
    final geometry = visualProvider.currentGeometry;
    audioProvider.setGeometry(geometry);
  }

  /// Sync visual system to audio sound family
  void _syncVisualSystemToAudio() {
    final system = visualProvider.currentSystem;
    audioProvider.setVisualSystem(system);
  }

  /// Extract current visual state as normalized values (0-1)
  Map<String, double> _getVisualState() {
    return {
      // === All 6 rotation planes (normalized 0-1) ===
      'rotationXY': _normalizeRotation(visualProvider.getRotationAngle('XY')),
      'rotationXZ': _normalizeRotation(visualProvider.getRotationAngle('XZ')),
      'rotationYZ': _normalizeRotation(visualProvider.getRotationAngle('YZ')),
      'rotationXW': _normalizeRotation(visualProvider.getRotationAngle('XW')),
      'rotationYW': _normalizeRotation(visualProvider.getRotationAngle('YW')),
      'rotationZW': _normalizeRotation(visualProvider.getRotationAngle('ZW')),

      // === Visual slider parameters ===
      'morphParameter': visualProvider.getMorphParameter(),
      'chaosAmount': visualProvider.rgbSplitAmount / 10.0,    // Normalize 0-10 to 0-1 (chaos)
      'rotationSpeed': visualProvider.rotationSpeed / 5.0,    // Normalize 0-5 to 0-1 (speed)
      'hueShift': visualProvider.hueShift / 360.0,            // Normalize 0-360 to 0-1 (hue)
      'glowIntensity': visualProvider.glowIntensity / 3.0,    // Normalize 0-3 to 0-1 (intensity)
      'tessellationDensity': (visualProvider.tessellationDensity - 2.0) / 28.0,  // Normalize 2-30 to 0-1 (density)
      'saturation': 0.7,  // TODO: Add saturation to VisualProvider (default 0.7)
      'vertexBrightness': visualProvider.vertexBrightness,    // Already 0-1
      'rgbSplitAmount': visualProvider.rgbSplitAmount / 10.0, // Normalize 0-10 to 0-1

      // === Holographic layer params ===
      'projectionDistance': _normalizeProjectionDistance(
        visualProvider.getProjectionDistance(),
      ),
      'layerDepth': _normalizeLayerDepth(
        visualProvider.getLayerSeparation(),
      ),
    };
  }

  /// Normalize rotation angle (0-2π) to (0-1)
  double _normalizeRotation(double angle) {
    return (angle % (2.0 * math.pi)) / (2.0 * math.pi);
  }

  /// Normalize projection distance (5-15) to (0-1)
  double _normalizeProjectionDistance(double distance) {
    return ((distance - 5.0) / 10.0).clamp(0.0, 1.0);
  }

  /// Normalize layer depth (0-5) to (0-1)
  double _normalizeLayerDepth(double depth) {
    return (depth / 5.0).clamp(0.0, 1.0);
  }

  /// Map vertex count to voice count (logarithmic scaling)
  int _mapVertexCountToVoices(int vertexCount) {
    // Map 10-10000 vertices to 1-16 voices logarithmically
    if (vertexCount < 10) return 1;
    if (vertexCount > 10000) return 16;

    final normalized = (math.log(vertexCount) - math.log(10)) /
                       (math.log(10000) - math.log(10));

    return (1 + normalized * 15).round().clamp(1, 16);
  }

  void _updateAudioParameter(String paramName, double value) {
    final synth = audioProvider.synthesizerEngine;
    final branchManager = audioProvider.synthesisBranchManager;

    switch (paramName) {
      // === Oscillator detuning (from 3D-like rotations) ===
      case 'oscillator1Detune':
        audioProvider.setOscillator1Detune(value);
        break;
      case 'oscillator2Detune':
        audioProvider.setOscillator2Detune(value);
        break;
      case 'combinedDetune':
        // Apply to both oscillators at half the value
        audioProvider.setOscillator1Detune(value * 0.5);
        audioProvider.setOscillator2Detune(value * 0.5);
        break;

      // === Synthesis branch-specific modulation ===
      case 'fmDepth':
        // Only applies to Hypersphere core (geometries 8-15)
        if (branchManager.currentCore == PolytopeCor.hypersphere) {
          audioProvider.setFMDepth(value);
        }
        break;
      case 'ringModDepth':
        // Only applies to Hypertetrahedron core (geometries 16-23)
        if (branchManager.currentCore == PolytopeCor.hypertetrahedron) {
          audioProvider.setRingModMix(value);
        }
        break;

      // === Filter modulation ===
      case 'filterCutoff':
        synth.modulateFilterCutoff(value);
        break;

      // === Waveform and envelope ===
      case 'waveformCrossfade':
        audioProvider.setMixBalance(value);  // Crossfade between oscillators
        break;
      case 'attackTime':
        audioProvider.setEnvelopeAttack(value);
        break;

      // === Effects ===
      case 'noiseInjection':
        // Add noise to the synth output (TODO: implement in synth engine)
        break;
      case 'lfoRate':
        // TODO: implement LFO rate in synth engine
        break;
      case 'spectralTilt':
        // Map hue to filter brightness - high value = brighter
        final brightness = 500 + value * 4000;  // 500-4500 Hz range
        synth.filter.baseCutoff = brightness;
        break;
      case 'reverbMix':
        synth.setReverbMix(value);
        break;
      case 'delayTime':
        synth.setDelayTime(value);
        break;

      // === Voice management ===
      case 'voiceCount':
        audioProvider.setVoiceCount(value.round().clamp(1, 8));
        break;

      // === Additional parameters ===
      case 'filterResonance':
        synth.filter.resonance = value.clamp(0.1, 0.9);
        break;
      case 'harmonicIntensity':
        // Modulate via mix balance (higher = more complex oscillator)
        synth.mixBalance = value;
        break;
      case 'stereoWidth':
        // TODO: Add stereoWidth to SynthesizerEngine
        // For now, modulate detune to create pseudo-stereo width
        audioProvider.setOscillator1Detune(value * 5.0);
        audioProvider.setOscillator2Detune(-value * 5.0);
        break;
    }
  }

  void applyPreset(MappingPreset preset) {
    _mappings = preset.visualToAudioMappings;
  }

  Map<String, ParameterMapping> exportMappings() {
    return Map.from(_mappings);
  }

  /// Advanced mapping: Use rotation velocity for dynamic modulation
  void enableVelocityModulation(bool enabled) {
    if (enabled) {
      // Track rotation velocity and map to filter resonance
      final velocity = visualProvider.getRotationVelocity();
      final resonance = (velocity * 0.5).clamp(0.0, 0.9);
      audioProvider.synthesizerEngine.filter.resonance = resonance;
    }
  }

  /// Advanced mapping: Use geometry complexity for harmonic richness
  void enableComplexityHarmonics(bool enabled) {
    if (enabled) {
      final complexity = visualProvider.getGeometryComplexity();
      // Higher complexity = more oscillator mixing
      final mixBalance = complexity.clamp(0.0, 1.0);
      audioProvider.synthesizerEngine.mixBalance = mixBalance;
    }
  }

  /// Get current modulation state for debugging/UI display
  Map<String, dynamic> getModulationState() {
    return {
      'rotationXW': visualProvider.getRotationAngle('XW'),
      'rotationYW': visualProvider.getRotationAngle('YW'),
      'rotationZW': visualProvider.getRotationAngle('ZW'),
      'morphParameter': visualProvider.getMorphParameter(),
      'projectionDistance': visualProvider.getProjectionDistance(),
      'layerDepth': visualProvider.getLayerSeparation(),
      'vertexCount': visualProvider.getActiveVertexCount(),
      'voiceCount': audioProvider.getVoiceCount(),
      'osc1FreqMod': audioProvider.synthesizerEngine.oscillator1.frequencyModulation,
      'osc2FreqMod': audioProvider.synthesizerEngine.oscillator2.frequencyModulation,
      'filterCutoffMod': audioProvider.synthesizerEngine.filter.cutoffModulation,
    };
  }
}
