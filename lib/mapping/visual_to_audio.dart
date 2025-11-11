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
      'rotationXW_to_osc1Freq': ParameterMapping(
        sourceParam: 'rotationXW',
        targetParam: 'oscillator1Frequency',
        minRange: -2.0, // -2 semitones
        maxRange: 2.0,  // +2 semitones
        curve: MappingCurve.sinusoidal,
      ),
      'rotationYW_to_osc2Freq': ParameterMapping(
        sourceParam: 'rotationYW',
        targetParam: 'oscillator2Frequency',
        minRange: -2.0,
        maxRange: 2.0,
        curve: MappingCurve.sinusoidal,
      ),
      'rotationZW_to_filterCutoff': ParameterMapping(
        sourceParam: 'rotationZW',
        targetParam: 'filterCutoff',
        minRange: 0.0,  // 0% modulation
        maxRange: 0.8,  // 80% modulation (±40%)
        curve: MappingCurve.sinusoidal,
      ),
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
  }

  /// Extract current visual state as normalized values (0-1)
  Map<String, double> _getVisualState() {
    return {
      'rotationXW': _normalizeRotation(visualProvider.getRotationAngle('XW')),
      'rotationYW': _normalizeRotation(visualProvider.getRotationAngle('YW')),
      'rotationZW': _normalizeRotation(visualProvider.getRotationAngle('ZW')),
      'morphParameter': visualProvider.getMorphParameter(),
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

    switch (paramName) {
      case 'oscillator1Frequency':
        synth.modulateOscillator1Frequency(value);
        break;
      case 'oscillator2Frequency':
        synth.modulateOscillator2Frequency(value);
        break;
      case 'filterCutoff':
        synth.modulateFilterCutoff(value);
        break;
      case 'wavetablePosition':
        synth.setWavetablePosition(value);
        break;
      case 'reverbMix':
        synth.setReverbMix(value);
        break;
      case 'delayTime':
        synth.setDelayTime(value);
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
