/**
 * Mapping Preset Model
 *
 * Defines a complete bidirectional parameter mapping configuration
 * that can be saved, loaded, and shared.
 *
 * A Paul Phillips Manifestation
 */

import '../mapping/audio_to_visual.dart';

class MappingPreset {
  final String name;
  final String description;
  final bool audioReactiveEnabled;
  final bool visualReactiveEnabled;
  final Map<String, ParameterMapping> audioToVisualMappings;
  final Map<String, ParameterMapping> visualToAudioMappings;

  const MappingPreset({
    required this.name,
    required this.description,
    required this.audioReactiveEnabled,
    required this.visualReactiveEnabled,
    required this.audioToVisualMappings,
    required this.visualToAudioMappings,
  });

  /// Default preset with balanced mappings
  factory MappingPreset.defaultPreset() {
    return MappingPreset(
      name: 'Default Mappings',
      description: 'Standard audio-visual coupling with balanced reactivity',
      audioReactiveEnabled: true,
      visualReactiveEnabled: true,
      audioToVisualMappings: {
        'bassEnergy_to_rotationSpeed': ParameterMapping(
          sourceParam: 'bassEnergy',
          targetParam: 'rotationSpeed',
          minRange: 0.5,
          maxRange: 2.5,
          curve: MappingCurve.linear,
        ),
        'midEnergy_to_tessellationDensity': ParameterMapping(
          sourceParam: 'midEnergy',
          targetParam: 'tessellationDensity',
          minRange: 3.0,
          maxRange: 8.0,
          curve: MappingCurve.exponential,
        ),
        'highEnergy_to_vertexBrightness': ParameterMapping(
          sourceParam: 'highEnergy',
          targetParam: 'vertexBrightness',
          minRange: 0.5,
          maxRange: 1.0,
          curve: MappingCurve.linear,
        ),
        'spectralCentroid_to_hueShift': ParameterMapping(
          sourceParam: 'spectralCentroid',
          targetParam: 'hueShift',
          minRange: 0.0,
          maxRange: 360.0,
          curve: MappingCurve.linear,
        ),
        'rms_to_glowIntensity': ParameterMapping(
          sourceParam: 'rms',
          targetParam: 'glowIntensity',
          minRange: 0.0,
          maxRange: 3.0,
          curve: MappingCurve.exponential,
        ),
      },
      visualToAudioMappings: {
        'rotationXW_to_osc1Freq': ParameterMapping(
          sourceParam: 'rotationXW',
          targetParam: 'oscillator1Frequency',
          minRange: -2.0,
          maxRange: 2.0,
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
          minRange: 0.0,
          maxRange: 0.8,
          curve: MappingCurve.sinusoidal,
        ),
      },
    );
  }

  /// Bass-heavy preset with aggressive reactivity
  factory MappingPreset.bassHeavy() {
    return MappingPreset(
      name: 'Bass Heavy',
      description: 'Emphasizes low-frequency reactivity with aggressive rotation',
      audioReactiveEnabled: true,
      visualReactiveEnabled: false,
      audioToVisualMappings: {
        'bassEnergy_to_rotationSpeed': ParameterMapping(
          sourceParam: 'bassEnergy',
          targetParam: 'rotationSpeed',
          minRange: 1.0,
          maxRange: 5.0,
          curve: MappingCurve.exponential,
        ),
        'bassEnergy_to_glowIntensity': ParameterMapping(
          sourceParam: 'bassEnergy',
          targetParam: 'glowIntensity',
          minRange: 1.0,
          maxRange: 8.0,
          curve: MappingCurve.exponential,
        ),
        'midEnergy_to_rgbSplit': ParameterMapping(
          sourceParam: 'midEnergy',
          targetParam: 'rgbSplitAmount',
          minRange: 0.0,
          maxRange: 10.0,
          curve: MappingCurve.linear,
        ),
      },
      visualToAudioMappings: {},
    );
  }

  /// Ambient spatial preset with smooth modulation
  factory MappingPreset.ambientSpatial() {
    return MappingPreset(
      name: 'Ambient Spatial',
      description: 'Smooth audio-visual coupling for ambient soundscapes',
      audioReactiveEnabled: true,
      visualReactiveEnabled: true,
      audioToVisualMappings: {
        'spectralCentroid_to_hueShift': ParameterMapping(
          sourceParam: 'spectralCentroid',
          targetParam: 'hueShift',
          minRange: 0.0,
          maxRange: 360.0,
          curve: MappingCurve.logarithmic,
        ),
        'rms_to_layerDepth': ParameterMapping(
          sourceParam: 'rms',
          targetParam: 'layerSeparation',
          minRange: 0.0,
          maxRange: 5.0,
          curve: MappingCurve.exponential,
        ),
      },
      visualToAudioMappings: {
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
          minRange: 0.0,
          maxRange: 500.0,
          curve: MappingCurve.linear,
        ),
      },
    );
  }

  /// Copy with modified fields
  MappingPreset copyWith({
    String? name,
    String? description,
    bool? audioReactiveEnabled,
    bool? visualReactiveEnabled,
    Map<String, ParameterMapping>? audioToVisualMappings,
    Map<String, ParameterMapping>? visualToAudioMappings,
  }) {
    return MappingPreset(
      name: name ?? this.name,
      description: description ?? this.description,
      audioReactiveEnabled: audioReactiveEnabled ?? this.audioReactiveEnabled,
      visualReactiveEnabled: visualReactiveEnabled ?? this.visualReactiveEnabled,
      audioToVisualMappings: audioToVisualMappings ?? this.audioToVisualMappings,
      visualToAudioMappings: visualToAudioMappings ?? this.visualToAudioMappings,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'audioReactiveEnabled': audioReactiveEnabled,
      'visualReactiveEnabled': visualReactiveEnabled,
      'audioToVisualMappings': audioToVisualMappings.map(
        (key, mapping) => MapEntry(key, _mappingToJson(mapping))
      ),
      'visualToAudioMappings': visualToAudioMappings.map(
        (key, mapping) => MapEntry(key, _mappingToJson(mapping))
      ),
    };
  }

  /// Create from JSON
  factory MappingPreset.fromJson(Map<String, dynamic> json) {
    return MappingPreset(
      name: json['name'] as String,
      description: json['description'] as String,
      audioReactiveEnabled: json['audioReactiveEnabled'] as bool,
      visualReactiveEnabled: json['visualReactiveEnabled'] as bool,
      audioToVisualMappings: (json['audioToVisualMappings'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, _mappingFromJson(value))
      ),
      visualToAudioMappings: (json['visualToAudioMappings'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, _mappingFromJson(value))
      ),
    );
  }

  /// Helper: ParameterMapping to JSON
  static Map<String, dynamic> _mappingToJson(ParameterMapping mapping) {
    return {
      'sourceParam': mapping.sourceParam,
      'targetParam': mapping.targetParam,
      'minRange': mapping.minRange,
      'maxRange': mapping.maxRange,
      'curve': mapping.curve.toString(),
    };
  }

  /// Helper: JSON to ParameterMapping
  static ParameterMapping _mappingFromJson(Map<String, dynamic> json) {
    return ParameterMapping(
      sourceParam: json['sourceParam'] as String,
      targetParam: json['targetParam'] as String,
      minRange: (json['minRange'] as num).toDouble(),
      maxRange: (json['maxRange'] as num).toDouble(),
      curve: MappingCurve.values.firstWhere(
        (e) => e.toString() == json['curve'],
        orElse: () => MappingCurve.linear,
      ),
    );
  }

  @override
  String toString() {
    return 'MappingPreset($name: audio→visual=${audioToVisualMappings.length}, visual→audio=${visualToAudioMappings.length})';
  }
}
