import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:synther_vib34d_holographic/providers/tilt_sensor_provider.dart';

void main() {
  test(
    'TiltSensorProvider processes accelerometer input and respects dead zone',
    () async {
      final controller = StreamController<AccelerometerEvent>();

      final provider = TiltSensorProvider(
        enableSensors: true,
        accelerometerStreamOverride: controller.stream,
        autoCalibrate: false,
      );

      provider.enable();

      controller.add(
        AccelerometerEvent(
            5.0, -5.0, 0.0, DateTime.fromMillisecondsSinceEpoch(0)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.tiltPosition.dx, closeTo(0.0526, 0.001));
      expect(provider.tiltPosition.dy, closeTo(-0.0526, 0.001));

      controller.add(
        AccelerometerEvent(
            0.5, 0.5, 0.0, DateTime.fromMillisecondsSinceEpoch(50)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.tiltPosition.dx, closeTo(0.0421, 0.01));
      expect(provider.tiltPosition.dy, closeTo(-0.0105, 0.02));

      provider.disable();
      expect(provider.tiltPosition, const Offset(0, 0));

      await controller.close();
      provider.dispose();
    },
  );
}
