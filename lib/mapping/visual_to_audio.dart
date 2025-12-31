/**
 * Visual → Audio Modulation System
 *
 * Maps visual parameter state to audio synthesis parameters:
 *
 * 3D ROTATIONS (newly added):
 * - XY Rotation → Oscillator 1 detune (±12 cents)
 * - XZ Rotation → Oscillator 2 detune (±12 cents)
 * - YZ Rotation → Combined detuning (±7 cents)
 *
 * 4D ROTATIONS:
 * - XW Rotation → FM depth / Osc1 Frequency (±2 semitones) - Hypersphere only
 * - YW Rotation → Ring mod depth / Osc2 Frequency (±2 semitones) - Hypertetrahedron only
 * - ZW Rotation → Filter Cutoff Frequency (±40%)
 *
 * OTHER MAPPINGS:
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
      // ========== 3D ROTATIONS → AUDIO (NEW!) ==========
      // XY rotation → Oscillator 1 detune (±12 cents)
      'rotationXY_to_osc1Detune': ParameterMapping(
        sourceParam: 'rotationXY',
        targetParam: 'oscillator1Detune',
        minRange: -12.0, // -12 cents
        maxRange: 12.0,  // +12 cents
        curve: MappingCurve.sinusoidal,
      ),
      // XZ rotation → Oscillator 2 detune (±12 cents)
      'rotationXZ_to_osc2Detune': ParameterMapping(
        sourceParam: 'rotationXZ',
        targetParam: 'oscillator2Detune',
        minRange: -12.0,
        maxRange: 12.0,
        curve: MappingCurve.sinusoidal,
      ),
      // YZ rotation → Combined detuning (±7 cents) - creates stereo width
      'rotationYZ_to_combinedDetune': ParameterMapping(
        sourceParam: 'rotationYZ',
        targetParam: 'combinedDetune',
        minRange: -7.0,
        maxRange: 7.0,
        curve: MappingCurve.sinusoidal,
      ),

      // ========== 4D ROTATIONS → AUDIO ==========
      // XW rotation → Osc1 frequency / FM depth (for Hypersphere synthesis)
      'rotationXW_to_osc1Freq': ParameterMapping(
        sourceParam: 'rotationXW',
        targetParam: 'oscillator1Frequency',
        minRange: -2.0, // -2 semitones
        maxRange: 2.0,  // +2 semitones
        curve: MappingCurve.sinusoidal,
      ),
      // YW rotation → Osc2 frequency / Ring mod depth (for Hypertetrahedron synthesis)
      'rotationYW_to_osc2Freq': ParameterMapping(
        sourceParam: 'rotationYW',
        targetParam: 'oscillator2Frequency',
        minRange: -2.0,
        maxRange: 2.0,
        curve: MappingCurve.sinusoidal,
      ),
      // ZW rotation → Filter cutoff modulation (±40%)
      'rotationZW_to_filterCutoff': ParameterMapping(
        sourceParam: 'rotationZW',
        targetParam: 'filterCutoff',
        minRange: 0.0,  // 0% modulation
        maxRange: 0.8,  // 80% modulation (±40%)
        curve: MappingCurve.sinusoidal,
      ),

      // ========== OTHER MAPPINGS ==========
      'morphParameter_to_wavetable': ParameterMapping(
        sourceParam: 'morphParameter',
        targetParam: 'wavetablePosition',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.linear,
      ),
      'projectionDistance_to_reverb': ParameterMapping(
        sourceParam: 'projectionDistance',
        targetParam: 'reverbMix',
        minRange: 0.0,
        maxRange: 1.0,
        curve: MappingCurve.exponential,
      ),
      'layerDepth_to_delay': ParameterMapping(
        sourceParam: 'layerDepth',
        targetParam: 'delayTime',
        minRange: 0.0,    // 0ms
        maxRange: 500.0,  // 500ms
        curve: MappingCurve.linear,
      ),
      // Chaos (RGB split) → Noise injection (0-30%)
      'chaos_to_noise': ParameterMapping(
        sourceParam: 'chaos',
        targetParam: 'noiseAmount',
        minRange: 0.0,
        maxRange: 0.3,  // 30% max noise
        curve: MappingCurve.exponential,
      ),
      // Speed → LFO rate (0.1 - 10 Hz)
      'speed_to_lfoRate': ParameterMapping(
        sourceParam: 'rotationSpeed',
        targetParam: 'lfoRate',
        minRange: 0.1,
        maxRange: 10.0,
        curve: MappingCurve.linear,
      ),
      // Saturation → Drive/distortion (0-1)
      'saturation_to_drive': ParameterMapping(
        sourceParam: 'saturation',
        targetParam: 'drive',
        minRange: 0.0,
        maxRange: 1.0,
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
      // 3D rotations (NEW!)
      'rotationXY': _normalizeRotation(visualProvider.getRotationAngle('XY')),
      'rotationXZ': _normalizeRotation(visualProvider.getRotationAngle('XZ')),
      'rotationYZ': _normalizeRotation(visualProvider.getRotationAngle('YZ')),
      // 4D rotations
      'rotationXW': _normalizeRotation(visualProvider.getRotationAngle('XW')),
      'rotationYW': _normalizeRotation(visualProvider.getRotationAngle('YW')),
      'rotationZW': _normalizeRotation(visualProvider.getRotationAngle('ZW')),
      // Other parameters
      'morphParameter': visualProvider.getMorphParameter(),
      'projectionDistance': _normalizeProjectionDistance(
        visualProvider.getProjectionDistance(),
      ),
      'layerDepth': _normalizeLayerDepth(
        visualProvider.getLayerSeparation(),
      ),
      // Chaos (RGB split) - 0-10 normalized to 0-1
      'chaos': (visualProvider.rgbSplitAmount / 10.0).clamp(0.0, 1.0),
      // Speed (rotation speed) - already 0-3, normalize to 0-1
      'rotationSpeed': (visualProvider.rotationSpeed / 3.0).clamp(0.0, 1.0),
      // Saturation - already 0-1
      'saturation': visualProvider.saturation,
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

    switch (paramName) {
      // 3D rotation targets (NEW!)
      case 'oscillator1Detune':
        synth.oscillator1.detune = value;
        break;
      case 'oscillator2Detune':
        synth.oscillator2.detune = value;
        break;
      case 'combinedDetune':
        // Apply to both oscillators for stereo width effect
        synth.oscillator1.detune += value * 0.5;
        synth.oscillator2.detune -= value * 0.5;
        break;
      // 4D rotation targets
      case 'oscillator1Frequency':
        synth.modulateOscillator1Frequency(value);
        break;
      case 'oscillator2Frequency':
        synth.modulateOscillator2Frequency(value);
        break;
      case 'filterCutoff':
        synth.modulateFilterCutoff(value);
        break;
      // Other targets
      case 'wavetablePosition':
        synth.setWavetablePosition(value);
        break;
      case 'reverbMix':
        synth.setReverbMix(value);
        break;
      case 'delayTime':
        synth.setDelayTime(value);
        audioProvider.synthesisBranchManager.setDelayTime(value); // SYNC
        break;
      // NEW: Chaos → Noise injection
      case 'noiseAmount':
        audioProvider.synthesisBranchManager.setNoiseAmount(value);
        break;
      // NEW: Speed → LFO rate
      case 'lfoRate':
        audioProvider.synthesisBranchManager.setLFORate(value);
        break;
      // NEW: Saturation → Drive/distortion
      case 'drive':
        audioProvider.synthesisBranchManager.setDrive(value);
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
      // 3D rotations (NEW!)
      'rotationXY': visualProvider.getRotationAngle('XY'),
      'rotationXZ': visualProvider.getRotationAngle('XZ'),
      'rotationYZ': visualProvider.getRotationAngle('YZ'),
      // 4D rotations
      'rotationXW': visualProvider.getRotationAngle('XW'),
      'rotationYW': visualProvider.getRotationAngle('YW'),
      'rotationZW': visualProvider.getRotationAngle('ZW'),
      // Other params
      'morphParameter': visualProvider.getMorphParameter(),
      'projectionDistance': visualProvider.getProjectionDistance(),
      'layerDepth': visualProvider.getLayerSeparation(),
      'vertexCount': visualProvider.getActiveVertexCount(),
      'voiceCount': audioProvider.getVoiceCount(),
      // Audio modulation state
      'osc1Detune': audioProvider.synthesizerEngine.oscillator1.detune,
      'osc2Detune': audioProvider.synthesizerEngine.oscillator2.detune,
      'osc1FreqMod': audioProvider.synthesizerEngine.oscillator1.frequencyModulation,
      'osc2FreqMod': audioProvider.synthesizerEngine.oscillator2.frequencyModulation,
      'filterCutoffMod': audioProvider.synthesizerEngine.filter.cutoffModulation,
    };
  }
}
