/**
 * Audio → Visual Modulation System
 *
 * Maps real-time audio analysis to visual parameters:
 * - Bass Energy (20-250 Hz) → 4D Rotation Speed
 * - Mid Energy (250-2000 Hz) → Tessellation Density
 * - High Energy (2000-8000 Hz) → Vertex Brightness
 * - Spectral Centroid → Hue Shift
 * - RMS Amplitude → Glow Intensity
 * - Stereo Width → RGB Split Amount
 *
 * A Paul Phillips Manifestation
 */

import 'dart:typed_data';
import 'dart:math' as math;
import '../providers/audio_provider.dart';
import '../providers/visual_provider.dart';
import '../models/mapping_preset.dart';
import '../audio/audio_analyzer.dart';

class AudioToVisualModulator {
  final AudioProvider audioProvider;
  final VisualProvider visualProvider;

  // Audio analyzer
  final AudioAnalyzer analyzer = AudioAnalyzer();

  // Mapping configuration
  Map<String, ParameterMapping> _mappings = {};

  AudioToVisualModulator({
    required this.audioProvider,
    required this.visualProvider,
  }) {
    _initializeDefaultMappings();
  }

  void _initializeDefaultMappings() {
    _mappings = {
      // ========== CORE VISUAL PARAMETERS ==========
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

      // ========== 3D ROTATION MODULATION (NEW!) ==========
      // Bass drives XY rotation intensity
      'bassEnergy_to_rotationXY': ParameterMapping(
        sourceParam: 'bassEnergy',
        targetParam: 'rotationModXY',
        minRange: 0.0,
        maxRange: 0.5, // Add up to 0.5 radians per frame
        curve: MappingCurve.exponential,
      ),
      // Mid drives XZ rotation intensity
      'midEnergy_to_rotationXZ': ParameterMapping(
        sourceParam: 'midEnergy',
        targetParam: 'rotationModXZ',
        minRange: 0.0,
        maxRange: 0.4,
        curve: MappingCurve.linear,
      ),
      // High drives YZ rotation intensity
      'highEnergy_to_rotationYZ': ParameterMapping(
        sourceParam: 'highEnergy',
        targetParam: 'rotationModYZ',
        minRange: 0.0,
        maxRange: 0.3,
        curve: MappingCurve.linear,
      ),

      // ========== 4D ROTATION MODULATION ==========
      // RMS (overall energy) drives 4D rotations
      'rms_to_rotationXW': ParameterMapping(
        sourceParam: 'rms',
        targetParam: 'rotationModXW',
        minRange: 0.0,
        maxRange: 0.3,
        curve: MappingCurve.exponential,
      ),
      'rms_to_rotationYW': ParameterMapping(
        sourceParam: 'rms',
        targetParam: 'rotationModYW',
        minRange: 0.0,
        maxRange: 0.25,
        curve: MappingCurve.exponential,
      ),
      // Bass also affects ZW for that deep rumble feel
      'bassEnergy_to_rotationZW': ParameterMapping(
        sourceParam: 'bassEnergy',
        targetParam: 'rotationModZW',
        minRange: 0.0,
        maxRange: 0.2,
        curve: MappingCurve.exponential,
      ),
    };
  }

  // Normalization constants for audio features
  // These approximate maximum expected values to normalize to 0-1 range
  static const double _bassNormalize = 2.0;      // Bass energy can be quite high
  static const double _midNormalize = 1.5;       // Mid energy moderate
  static const double _highNormalize = 1.0;      // High energy lower
  static const double _centroidNormalize = 8000.0; // Max frequency we care about
  static const double _rmsNormalize = 0.5;       // Typical max RMS for synth

  // Smoothing for audio reactivity (prevents jitter)
  double _smoothedBass = 0.0;
  double _smoothedMid = 0.0;
  double _smoothedHigh = 0.0;
  double _smoothedCentroid = 0.0;
  double _smoothedRms = 0.0;
  static const double _smoothingFactor = 0.3; // Lower = smoother, higher = more reactive

  /// Main update function called at 60 FPS
  void updateFromAudio(Float32List audioBuffer) {
    // Perform FFT analysis
    final fftData = analyzer.computeFFT(audioBuffer);

    // Extract and NORMALIZE audio features to 0-1 range
    final rawBass = analyzer.getBandEnergy(fftData, 20.0, 250.0);
    final rawMid = analyzer.getBandEnergy(fftData, 250.0, 2000.0);
    final rawHigh = analyzer.getBandEnergy(fftData, 2000.0, 8000.0);
    final rawCentroid = analyzer.computeSpectralCentroid(fftData);
    final rawRms = analyzer.computeRMS(audioBuffer);

    // Normalize to 0-1 range
    final normBass = (rawBass / _bassNormalize).clamp(0.0, 1.0);
    final normMid = (rawMid / _midNormalize).clamp(0.0, 1.0);
    final normHigh = (rawHigh / _highNormalize).clamp(0.0, 1.0);
    final normCentroid = (rawCentroid / _centroidNormalize).clamp(0.0, 1.0);
    final normRms = (rawRms / _rmsNormalize).clamp(0.0, 1.0);

    // Apply smoothing to prevent jitter
    _smoothedBass = _smoothedBass * (1 - _smoothingFactor) + normBass * _smoothingFactor;
    _smoothedMid = _smoothedMid * (1 - _smoothingFactor) + normMid * _smoothingFactor;
    _smoothedHigh = _smoothedHigh * (1 - _smoothingFactor) + normHigh * _smoothingFactor;
    _smoothedCentroid = _smoothedCentroid * (1 - _smoothingFactor) + normCentroid * _smoothingFactor;
    _smoothedRms = _smoothedRms * (1 - _smoothingFactor) + normRms * _smoothingFactor;

    // Build normalized features map
    final features = {
      'bassEnergy': _smoothedBass,
      'midEnergy': _smoothedMid,
      'highEnergy': _smoothedHigh,
      'spectralCentroid': _smoothedCentroid,
      'rms': _smoothedRms,
      'stereoWidth': 0.5, // Placeholder - requires stereo buffer
    };

    // Apply each mapping
    _mappings.forEach((key, mapping) {
      final sourceValue = features[mapping.sourceParam] ?? 0.0;
      final mappedValue = mapping.map(sourceValue);

      // Update corresponding visual parameter
      _updateVisualParameter(mapping.targetParam, mappedValue);
    });
  }

  void _updateVisualParameter(String paramName, double value) {
    switch (paramName) {
      // Core visual parameters
      case 'rotationSpeed':
        visualProvider.setRotationSpeed(value);
        break;
      case 'tessellationDensity':
        visualProvider.setTessellationDensity(value.round());
        break;
      case 'vertexBrightness':
        visualProvider.setVertexBrightness(value);
        break;
      case 'hueShift':
        visualProvider.setHueShift(value);
        break;
      case 'glowIntensity':
        visualProvider.setGlowIntensity(value);
        break;
      case 'rgbSplitAmount':
        visualProvider.setRGBSplitAmount(value);
        break;

      // 3D rotation modulation (additive to current rotation)
      case 'rotationModXY':
        final currentXY = visualProvider.rotationXY;
        visualProvider.setRotationXY(currentXY + value * 0.016); // ~60fps, so scale by frame time
        break;
      case 'rotationModXZ':
        final currentXZ = visualProvider.rotationXZ;
        visualProvider.setRotationXZ(currentXZ + value * 0.016);
        break;
      case 'rotationModYZ':
        final currentYZ = visualProvider.rotationYZ;
        visualProvider.setRotationYZ(currentYZ + value * 0.016);
        break;

      // 4D rotation modulation (additive to current rotation)
      case 'rotationModXW':
        final currentXW = visualProvider.rotationXW;
        visualProvider.setRotationXW(currentXW + value * 0.016);
        break;
      case 'rotationModYW':
        final currentYW = visualProvider.rotationYW;
        visualProvider.setRotationYW(currentYW + value * 0.016);
        break;
      case 'rotationModZW':
        final currentZW = visualProvider.rotationZW;
        visualProvider.setRotationZW(currentZW + value * 0.016);
        break;
    }
  }

  void applyPreset(MappingPreset preset) {
    _mappings = preset.audioToVisualMappings;
  }

  Map<String, ParameterMapping> exportMappings() {
    return Map.from(_mappings);
  }
}

/// Parameter mapping configuration
class ParameterMapping {
  final String sourceParam;
  final String targetParam;
  final double minRange;
  final double maxRange;
  final MappingCurve curve;

  ParameterMapping({
    required this.sourceParam,
    required this.targetParam,
    required this.minRange,
    required this.maxRange,
    required this.curve,
  });

  /// Map source value (0-1) to target range using specified curve
  double map(double sourceValue) {
    // Clamp input to 0-1
    final normalized = sourceValue.clamp(0.0, 1.0);

    // Apply curve
    double curved;
    switch (curve) {
      case MappingCurve.linear:
        curved = normalized;
        break;
      case MappingCurve.exponential:
        curved = math.pow(normalized, 2.0).toDouble();
        break;
      case MappingCurve.logarithmic:
        curved = math.log(1.0 + normalized * (math.e - 1.0)) / math.log(math.e);
        break;
      case MappingCurve.sinusoidal:
        curved = (math.sin(normalized * math.pi - math.pi / 2) + 1.0) / 2.0;
        break;
    }

    // Scale to target range
    return minRange + (curved * (maxRange - minRange));
  }
}

enum MappingCurve {
  linear,
  exponential,
  logarithmic,
  sinusoidal,
}
