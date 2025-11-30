// VIB3+ Geometry Library
//
// Manages 24 geometry configurations (8 base types × 3 cores)
// Provides metadata, parameters, and geometry resolution
//
// Ported from vib34d-vib3plus GeometryLibrary.js
//
// A Paul Phillips Manifestation
//
/// Base geometry types (8 variants)
enum BaseGeometry {
  tetrahedron,    // 0
  hypercube,      // 1
  sphere,         // 2
  torus,          // 3
  kleinBottle,    // 4
  fractal,        // 5
  wave,           // 6
  crystal,        // 7
}

/// Core variants (3 types) - determines synthesis branch
enum CoreVariant {
  base,             // 0: Direct synthesis (geometries 0-7)
  hypersphere,      // 1: FM synthesis (geometries 8-15)
  hypertetrahedron, // 2: Ring modulation (geometries 16-23)
}

/// Complete geometry metadata
class GeometryMetadata {
  final int index;           // 0-23
  final String name;         // Full name
  final int baseIndex;       // 0-7
  final String baseKey;      // 'tetrahedron', 'hypercube', etc.
  final String baseName;     // 'Tetrahedron', 'Hypercube', etc.
  final int coreIndex;       // 0-2
  final String coreKey;      // 'base', 'hypersphere', 'hypertetrahedron'
  final String coreName;     // 'Base', 'Hypersphere', 'Hypertetrahedron'
  final bool isLegacyCore;   // Compatibility flag

  const GeometryMetadata({
    required this.index,
    required this.name,
    required this.baseIndex,
    required this.baseKey,
    required this.baseName,
    required this.coreIndex,
    required this.coreKey,
    required this.coreName,
    this.isLegacyCore = false,
  });

  @override
  String toString() => 'GeometryMetadata($index: $name = $coreName $baseName)';
}

/// Variation parameters for rendering and audio
class VariationParameters {
  final double gridDensity;    // Tessellation level
  final double morphFactor;    // Geometry morph amount
  final double chaos;          // Randomization amount
  final double speed;          // Animation speed
  final double hue;            // Color hue (0-360°)

  const VariationParameters({
    required this.gridDensity,
    required this.morphFactor,
    required this.chaos,
    required this.speed,
    required this.hue,
  });

  @override
  String toString() =>
      'VariationParameters(grid: $gridDensity, morph: $morphFactor, chaos: $chaos, speed: $speed, hue: $hue)';
}

/// VIB3+ Geometry Library
class GeometryLibrary {
  static const int baseCount = 8;
  static const int coreCount = 3;
  static const int totalGeometries = baseCount * coreCount; // 24

  /// Base geometry names
  static const List<String> baseNames = [
    'Tetrahedron',
    'Hypercube',
    'Sphere',
    'Torus',
    'Klein Bottle',
    'Fractal',
    'Wave',
    'Crystal',
  ];

  /// Base geometry keys
  static const List<String> baseKeys = [
    'tetrahedron',
    'hypercube',
    'sphere',
    'torus',
    'kleinBottle',
    'fractal',
    'wave',
    'crystal',
  ];

  /// Core variant names
  static const List<String> coreNames = [
    'Base',
    'Hypersphere',
    'Hypertetrahedron',
  ];

  /// Core variant keys
  static const List<String> coreKeys = [
    'base',
    'hypersphere',
    'hypertetrahedron',
  ];

  /// Encode geometry index from base and core indices
  static int encodeGeometryIndex(int baseIndex, int coreIndex) {
    return coreIndex * baseCount + baseIndex;
  }

  /// Decode geometry index to base and core indices
  static (int baseIndex, int coreIndex) decodeGeometryIndex(int geometryIndex) {
    final coreIndex = geometryIndex ~/ baseCount;
    final baseIndex = geometryIndex % baseCount;
    return (baseIndex, coreIndex);
  }

  /// Resolve geometry index from various inputs
  static int resolveGeometryIndex({
    int? geometryIndex,
    int? baseIndex,
    int? coreIndex,
    String? baseKey,
    String? coreKey,
  }) {
    // Direct index provided
    if (geometryIndex != null) {
      return geometryIndex % totalGeometries;
    }

    // Resolve from keys
    final resolvedBase = baseKey != null
        ? baseKeys.indexOf(baseKey) % baseCount
        : (baseIndex ?? 0) % baseCount;

    final resolvedCore = coreKey != null
        ? coreKeys.indexOf(coreKey) % coreCount
        : (coreIndex ?? 0) % coreCount;

    return encodeGeometryIndex(resolvedBase, resolvedCore);
  }

  /// Get complete metadata for a geometry
  static GeometryMetadata getGeometryMetadata(int geometryIndex) {
    final index = geometryIndex % totalGeometries;
    final (baseIndex, coreIndex) = decodeGeometryIndex(index);

    final baseName = baseNames[baseIndex];
    final baseKey = baseKeys[baseIndex];
    final coreName = coreNames[coreIndex];
    final coreKey = coreKeys[coreIndex];

    return GeometryMetadata(
      index: index,
      name: '$coreName $baseName',
      baseIndex: baseIndex,
      baseKey: baseKey,
      baseName: baseName,
      coreIndex: coreIndex,
      coreKey: coreKey,
      coreName: coreName,
      isLegacyCore: coreIndex == 0, // Base core is legacy
    );
  }

  /// Get variation parameters for a geometry
  static VariationParameters getVariationParameters(int geometryIndex) {
    final index = geometryIndex % totalGeometries;
    final (baseIndex, coreIndex) = decodeGeometryIndex(index);

    // Base parameters scale with complexity level (0-2 for the three cores)
    final level = coreIndex;
    var gridDensity = 8.0 + (level * 4.0);
    var morphFactor = 0.5 + (level * 0.3);
    var chaos = level * 0.15;
    var speed = 0.8 + (level * 0.2);
    var hue = _calculateHue(baseIndex, level);

    // Apply base-specific multipliers
    final multipliers = _getBaseMultipliers(baseIndex);
    gridDensity *= multipliers['gridDensity']!;
    morphFactor *= multipliers['morphFactor']!;
    chaos *= multipliers['chaos']!;
    speed *= multipliers['speed']!;

    // Apply core-specific multipliers
    final coreMultipliers = _getCoreMultipliers(coreIndex);
    gridDensity *= coreMultipliers['gridDensity']!;
    morphFactor *= coreMultipliers['morphFactor']!;
    chaos *= coreMultipliers['chaos']!;
    speed *= coreMultipliers['speed']!;

    return VariationParameters(
      gridDensity: gridDensity,
      morphFactor: morphFactor,
      chaos: chaos,
      speed: speed,
      hue: hue,
    );
  }

  /// Get base-specific multipliers
  static Map<String, double> _getBaseMultipliers(int baseIndex) {
    switch (baseIndex) {
      case 0: // Tetrahedron
        return {
          'gridDensity': 1.2,
          'morphFactor': 1.0,
          'chaos': 1.0,
          'speed': 1.0,
        };
      case 1: // Hypercube
        return {
          'gridDensity': 1.0,
          'morphFactor': 0.8,
          'chaos': 1.0,
          'speed': 1.0,
        };
      case 2: // Sphere
        return {
          'gridDensity': 1.0,
          'morphFactor': 1.0,
          'chaos': 1.5,
          'speed': 1.0,
        };
      case 3: // Torus
        return {
          'gridDensity': 1.0,
          'morphFactor': 1.0,
          'chaos': 1.0,
          'speed': 1.3,
        };
      case 4: // Klein Bottle
        return {
          'gridDensity': 0.7,
          'morphFactor': 1.4,
          'chaos': 1.0,
          'speed': 1.0,
        };
      case 5: // Fractal
        return {
          'gridDensity': 0.5,
          'morphFactor': 1.0,
          'chaos': 2.0,
          'speed': 1.0,
        };
      case 6: // Wave
        return {
          'gridDensity': 1.0,
          'morphFactor': 1.0,
          'chaos': 0.5,
          'speed': 1.8,
        };
      case 7: // Crystal
        return {
          'gridDensity': 1.5,
          'morphFactor': 0.6,
          'chaos': 1.0,
          'speed': 1.0,
        };
      default:
        return {
          'gridDensity': 1.0,
          'morphFactor': 1.0,
          'chaos': 1.0,
          'speed': 1.0,
        };
    }
  }

  /// Get core-specific multipliers
  static Map<String, double> _getCoreMultipliers(int coreIndex) {
    switch (coreIndex) {
      case 0: // Base
        return {
          'gridDensity': 1.0,
          'morphFactor': 1.0,
          'chaos': 1.0,
          'speed': 1.0,
        };
      case 1: // Hypersphere (FM)
        return {
          'gridDensity': 1.1,
          'morphFactor': 1.25,
          'chaos': 1.2,
          'speed': 1.0,
        };
      case 2: // Hypertetrahedron (Ring mod)
        return {
          'gridDensity': 0.95,
          'morphFactor': 1.35,
          'chaos': 1.15,
          'speed': 1.1,
        };
      default:
        return {
          'gridDensity': 1.0,
          'morphFactor': 1.0,
          'chaos': 1.0,
          'speed': 1.0,
        };
    }
  }

  /// Calculate hue based on base and level
  static double _calculateHue(int baseIndex, int level) {
    // Spread hues across spectrum based on base geometry
    final baseHue = (baseIndex / baseCount) * 360.0;

    // Shift hue based on core level
    final levelShift = level * 45.0; // 0°, 45°, 90°

    return (baseHue + levelShift) % 360.0;
  }

  /// Get all geometries as list
  static List<GeometryMetadata> getAllGeometries() {
    return List.generate(
      totalGeometries,
      (index) => getGeometryMetadata(index),
    );
  }

  /// Get geometries for a specific base
  static List<GeometryMetadata> getGeometriesForBase(int baseIndex) {
    return List.generate(
      coreCount,
      (coreIndex) => getGeometryMetadata(encodeGeometryIndex(baseIndex, coreIndex)),
    );
  }

  /// Get geometries for a specific core
  static List<GeometryMetadata> getGeometriesForCore(int coreIndex) {
    return List.generate(
      baseCount,
      (baseIndex) => getGeometryMetadata(encodeGeometryIndex(baseIndex, coreIndex)),
    );
  }
}
