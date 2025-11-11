/**
 * Visual State Model
 *
 * Represents a complete VIB34D visualization configuration
 * that can be saved, loaded, and recalled.
 *
 * A Paul Phillips Manifestation
 */

class VisualState {
  final String name;
  final String description;

  // System selection
  final String system; // 'quantum', 'holographic', 'faceted'

  // Rotation parameters
  final double rotationSpeedXW;
  final double rotationSpeedYW;
  final double rotationSpeedZW;

  // Visual parameters
  final int tessellationDensity;
  final double vertexBrightness;
  final double hueShift;
  final double glowIntensity;
  final double rgbSplitAmount;

  // Geometry
  final int geometryIndex;
  final double morphParameter;

  // Projection
  final double projectionDistance;
  final double layerSeparation;

  const VisualState({
    required this.name,
    required this.description,
    required this.system,
    required this.rotationSpeedXW,
    required this.rotationSpeedYW,
    required this.rotationSpeedZW,
    required this.tessellationDensity,
    required this.vertexBrightness,
    required this.hueShift,
    required this.glowIntensity,
    required this.rgbSplitAmount,
    required this.geometryIndex,
    required this.morphParameter,
    required this.projectionDistance,
    required this.layerSeparation,
  });

  /// Default visual state
  factory VisualState.defaultState() {
    return const VisualState(
      name: 'Default',
      description: 'Balanced quantum visualization',
      system: 'quantum',
      rotationSpeedXW: 0.5,
      rotationSpeedYW: 0.7,
      rotationSpeedZW: 0.3,
      tessellationDensity: 5,
      vertexBrightness: 0.8,
      hueShift: 180.0,
      glowIntensity: 1.0,
      rgbSplitAmount: 0.0,
      geometryIndex: 0,
      morphParameter: 0.0,
      projectionDistance: 8.0,
      layerSeparation: 2.0,
    );
  }

  /// Intense holographic state
  factory VisualState.intense() {
    return const VisualState(
      name: 'Intense',
      description: 'High-energy holographic visualization',
      system: 'holographic',
      rotationSpeedXW: 2.0,
      rotationSpeedYW: 1.5,
      rotationSpeedZW: 1.0,
      tessellationDensity: 8,
      vertexBrightness: 1.0,
      hueShift: 270.0,
      glowIntensity: 2.5,
      rgbSplitAmount: 5.0,
      geometryIndex: 1,
      morphParameter: 0.7,
      projectionDistance: 12.0,
      layerSeparation: 4.0,
    );
  }

  /// Calm ambient state
  factory VisualState.ambient() {
    return const VisualState(
      name: 'Ambient',
      description: 'Slow, smooth visualization',
      system: 'quantum',
      rotationSpeedXW: 0.2,
      rotationSpeedYW: 0.15,
      rotationSpeedZW: 0.1,
      tessellationDensity: 3,
      vertexBrightness: 0.6,
      hueShift: 90.0,
      glowIntensity: 0.5,
      rgbSplitAmount: 0.0,
      geometryIndex: 5,
      morphParameter: 0.3,
      projectionDistance: 10.0,
      layerSeparation: 1.5,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'system': system,
      'rotationSpeedXW': rotationSpeedXW,
      'rotationSpeedYW': rotationSpeedYW,
      'rotationSpeedZW': rotationSpeedZW,
      'tessellationDensity': tessellationDensity,
      'vertexBrightness': vertexBrightness,
      'hueShift': hueShift,
      'glowIntensity': glowIntensity,
      'rgbSplitAmount': rgbSplitAmount,
      'geometryIndex': geometryIndex,
      'morphParameter': morphParameter,
      'projectionDistance': projectionDistance,
      'layerSeparation': layerSeparation,
    };
  }

  /// Create from JSON
  factory VisualState.fromJson(Map<String, dynamic> json) {
    return VisualState(
      name: json['name'] as String,
      description: json['description'] as String,
      system: json['system'] as String,
      rotationSpeedXW: (json['rotationSpeedXW'] as num).toDouble(),
      rotationSpeedYW: (json['rotationSpeedYW'] as num).toDouble(),
      rotationSpeedZW: (json['rotationSpeedZW'] as num).toDouble(),
      tessellationDensity: json['tessellationDensity'] as int,
      vertexBrightness: (json['vertexBrightness'] as num).toDouble(),
      hueShift: (json['hueShift'] as num).toDouble(),
      glowIntensity: (json['glowIntensity'] as num).toDouble(),
      rgbSplitAmount: (json['rgbSplitAmount'] as num).toDouble(),
      geometryIndex: json['geometryIndex'] as int,
      morphParameter: (json['morphParameter'] as num).toDouble(),
      projectionDistance: (json['projectionDistance'] as num).toDouble(),
      layerSeparation: (json['layerSeparation'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'VisualState($name: $system)';
  }
}
