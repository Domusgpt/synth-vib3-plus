/**
 * Tilt Sensor Provider
 *
 * Integrates device accelerometer/gyroscope for tilt-based control
 * of the orb controller and other performance parameters.
 *
 * Features:
 * - Real-time accelerometer data processing
 * - Smoothing and filtering to reduce jitter
 * - Calibration system for different device orientations
 * - Configurable sensitivity and dead zones
 * - Auto-calibrate on startup
 *
 * A Paul Phillips Manifestation
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TiltSensorProvider with ChangeNotifier {
  // Raw sensor data
  double _rawX = 0.0;
  double _rawY = 0.0;
  double _rawZ = 0.0;

  // Filtered/smoothed data
  double _filteredX = 0.0;
  double _filteredY = 0.0;

  // Calibration offsets
  double _calibrationX = 0.0;
  double _calibrationY = 0.0;

  // Configuration
  double _sensitivity = 1.0; // 0.5 to 2.0
  double _deadZone = 0.05; // 0 to 0.2
  bool _isEnabled = false;
  bool _isCalibrating = false;

  // Smoothing parameters (low-pass filter)
  final double _smoothingFactor = 0.2; // 0.1 (smooth) to 1.0 (responsive)

  // Sensor stream subscription
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Calibration samples
  final List<double> _calibrationSamplesX = [];
  final List<double> _calibrationSamplesY = [];
  static const int _calibrationSampleCount = 30;

  TiltSensorProvider() {
    _initializeSensor();
  }

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isCalibrating => _isCalibrating;
  double get sensitivity => _sensitivity;
  double get deadZone => _deadZone;

  /// Get normalized tilt position (-1.0 to 1.0)
  Offset get tiltPosition => Offset(
        _applyDeadZone(_filteredX),
        _applyDeadZone(_filteredY),
      );

  /// Get raw accelerometer values (for debugging)
  Map<String, double> get rawAccelerometer => {
        'x': _rawX,
        'y': _rawY,
        'z': _rawZ,
      };

  void _initializeSensor() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 16), // ~60 Hz
    ).listen(_handleAccelerometerEvent);

    // Auto-calibrate on startup
    Future.delayed(const Duration(milliseconds: 500), () {
      calibrate();
    });
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_isEnabled && !_isCalibrating) return;

    // Store raw values
    _rawX = event.x;
    _rawY = event.y;
    _rawZ = event.z;

    if (_isCalibrating) {
      _collectCalibrationSample(event);
      return;
    }

    // Apply calibration offsets
    final calibratedX = _rawX - _calibrationX;
    final calibratedY = _rawY - _calibrationY;

    // Normalize to -1.0 to 1.0 range
    // Typical accelerometer range is -10 to 10 m/s²
    final normalizedX = (calibratedX / 10.0).clamp(-1.0, 1.0);
    final normalizedY = (calibratedY / 10.0).clamp(-1.0, 1.0);

    // Apply sensitivity
    final sensitiveX = normalizedX * _sensitivity;
    final sensitiveY = normalizedY * _sensitivity;

    // Apply low-pass filter (smooth out jitter)
    _filteredX = _filteredX * (1.0 - _smoothingFactor) + sensitiveX * _smoothingFactor;
    _filteredY = _filteredY * (1.0 - _smoothingFactor) + sensitiveY * _smoothingFactor;

    notifyListeners();
  }

  void _collectCalibrationSample(AccelerometerEvent event) {
    _calibrationSamplesX.add(event.x);
    _calibrationSamplesY.add(event.y);

    if (_calibrationSamplesX.length >= _calibrationSampleCount) {
      _finalizeCalibration();
    }
  }

  void _finalizeCalibration() {
    // Calculate average of samples
    _calibrationX = _calibrationSamplesX.reduce((a, b) => a + b) / _calibrationSamplesX.length;
    _calibrationY = _calibrationSamplesY.reduce((a, b) => a + b) / _calibrationSamplesY.length;

    // Clear samples
    _calibrationSamplesX.clear();
    _calibrationSamplesY.clear();

    _isCalibrating = false;

    debugPrint('🎯 Tilt calibration complete: X=$_calibrationX, Y=$_calibrationY');
    notifyListeners();
  }

  double _applyDeadZone(double value) {
    // Apply dead zone to eliminate drift when device is stationary
    if (value.abs() < _deadZone) {
      return 0.0;
    }

    // Scale the remaining range to maintain full -1.0 to 1.0 output
    final sign = value.sign;
    final magnitude = (value.abs() - _deadZone) / (1.0 - _deadZone);
    return sign * magnitude.clamp(0.0, 1.0);
  }

  // Public methods
  void enable() {
    _isEnabled = true;
    debugPrint('🎛️ Tilt sensor enabled');
    notifyListeners();
  }

  void disable() {
    _isEnabled = false;
    // Reset to center
    _filteredX = 0.0;
    _filteredY = 0.0;
    debugPrint('🎛️ Tilt sensor disabled');
    notifyListeners();
  }

  void toggle() {
    if (_isEnabled) {
      disable();
    } else {
      enable();
    }
  }

  void calibrate() {
    if (_isCalibrating) return;

    _isCalibrating = true;
    _calibrationSamplesX.clear();
    _calibrationSamplesY.clear();

    debugPrint('🎯 Starting tilt calibration (hold device steady)...');
    notifyListeners();

    // Auto-stop calibration after timeout
    Future.delayed(const Duration(seconds: 2), () {
      if (_isCalibrating) {
        _finalizeCalibration();
      }
    });
  }

  void setSensitivity(double value) {
    _sensitivity = value.clamp(0.5, 2.0);
    debugPrint('🎛️ Tilt sensitivity: $_sensitivity');
    notifyListeners();
  }

  void setDeadZone(double value) {
    _deadZone = value.clamp(0.0, 0.2);
    debugPrint('🎛️ Tilt dead zone: $_deadZone');
    notifyListeners();
  }

  /// Get orientation-aware tilt position
  /// Handles landscape left/right and portrait orientations
  Offset getTiltPositionForOrientation(Orientation orientation) {
    // In landscape, swap and flip axes as needed
    if (orientation == Orientation.landscape) {
      // Landscape: X becomes Y, Y becomes -X
      return Offset(
        _applyDeadZone(-_filteredY),
        _applyDeadZone(_filteredX),
      );
    } else {
      // Portrait: Use as-is
      return Offset(
        _applyDeadZone(_filteredX),
        _applyDeadZone(_filteredY),
      );
    }
  }

  /// Check if device is roughly level (for auto-calibration prompts)
  bool get isDeviceLevel {
    // Device is level if Z acceleration is close to -9.8 m/s² (gravity)
    // and X/Y accelerations are near zero
    return (_rawZ.abs() - 9.8).abs() < 2.0 &&
           _rawX.abs() < 2.0 &&
           _rawY.abs() < 2.0;
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}
