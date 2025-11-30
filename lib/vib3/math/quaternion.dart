// Quaternion Mathematics for 4D Rotations
//
// Ported from vib34d-vib3plus SDK
// Provides quaternion operations for XR spatial computing
//
// A Paul Phillips Manifestation
//
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' as vm;

/// Euler angles representation
class EulerAngles {
  final double roll;
  final double pitch;
  final double yaw;

  const EulerAngles({
    required this.roll,
    required this.pitch,
    required this.yaw,
  });

  /// Convert to degrees
  EulerAngles toDegrees() {
    return EulerAngles(
      roll: roll * 180.0 / math.pi,
      pitch: pitch * 180.0 / math.pi,
      yaw: yaw * 180.0 / math.pi,
    );
  }

  @override
  String toString() => 'EulerAngles(roll: $roll, pitch: $pitch, yaw: $yaw)';
}

/// Quaternion utility class for 4D rotations
class Quaternion {
  final double x;
  final double y;
  final double z;
  final double w;

  const Quaternion(this.x, this.y, this.z, this.w);

  /// Identity quaternion
  factory Quaternion.identity() => const Quaternion(0, 0, 0, 1);

  /// From axis and angle
  factory Quaternion.axisAngle(vm.Vector3 axis, double angle) {
    final halfAngle = angle / 2.0;
    final s = math.sin(halfAngle);
    final normalized = axis.normalized();

    return Quaternion(
      normalized.x * s,
      normalized.y * s,
      normalized.z * s,
      math.cos(halfAngle),
    );
  }

  /// From Euler angles
  factory Quaternion.euler(double roll, double pitch, double yaw) {
    final cy = math.cos(yaw * 0.5);
    final sy = math.sin(yaw * 0.5);
    final cp = math.cos(pitch * 0.5);
    final sp = math.sin(pitch * 0.5);
    final cr = math.cos(roll * 0.5);
    final sr = math.sin(roll * 0.5);

    return Quaternion(
      sr * cp * cy - cr * sp * sy,
      cr * sp * cy + sr * cp * sy,
      cr * cp * sy - sr * sp * cy,
      cr * cp * cy + sr * sp * sy,
    );
  }

  /// Quaternion length
  double get length => math.sqrt(x * x + y * y + z * z + w * w);

  /// Normalize quaternion
  Quaternion normalize() {
    final len = length;

    // Handle null case and zero-length quaternions
    if (len == 0.0) {
      return Quaternion.identity();
    }

    return Quaternion(x / len, y / len, z / len, w / len);
  }

  /// Conjugate (inverse rotation)
  Quaternion conjugate() {
    return Quaternion(-x, -y, -z, w);
  }

  /// Quaternion multiplication
  Quaternion multiply(Quaternion other) {
    return Quaternion(
      w * other.x + x * other.w + y * other.z - z * other.y,
      w * other.y - x * other.z + y * other.w + z * other.x,
      w * other.z + x * other.y - y * other.x + z * other.w,
      w * other.w - x * other.x - y * other.y - z * other.z,
    );
  }

  /// Convert to Euler angles (roll, pitch, yaw)
  EulerAngles toEuler() {
    // Roll (x-axis rotation)
    final sinrCosp = 2.0 * (w * x + y * z);
    final cosrCosp = 1.0 - 2.0 * (x * x + y * y);
    final roll = math.atan2(sinrCosp, cosrCosp);

    // Pitch (y-axis rotation)
    final sinp = 2.0 * (w * y - z * x);
    final pitch = sinp.abs() >= 1
        ? (sinp >= 0 ? math.pi / 2 : -math.pi / 2) // Gimbal lock
        : math.asin(sinp);

    // Yaw (z-axis rotation)
    final sinyCosp = 2.0 * (w * z + x * y);
    final cosyCosp = 1.0 - 2.0 * (y * y + z * z);
    final yaw = math.atan2(sinyCosp, cosyCosp);

    return EulerAngles(roll: roll, pitch: pitch, yaw: yaw);
  }

  /// Linear interpolation
  Quaternion lerp(Quaternion other, double t) {
    final t1 = 1.0 - t;
    return Quaternion(
      x * t1 + other.x * t,
      y * t1 + other.y * t,
      z * t1 + other.z * t,
      w * t1 + other.w * t,
    ).normalize();
  }

  /// Spherical linear interpolation (maintains constant angular velocity)
  Quaternion slerp(Quaternion other, double t) {
    // Compute dot product
    var dot = x * other.x + y * other.y + z * other.z + w * other.w;

    // If negative dot, negate other to take shorter path
    var q2 = other;
    if (dot < 0.0) {
      dot = -dot;
      q2 = Quaternion(-other.x, -other.y, -other.z, -other.w);
    }

    // If very close, use linear interpolation
    if (dot > 0.9995) {
      return lerp(q2, t);
    }

    // Calculate angle and sin values
    final theta = math.acos(dot);
    final sinTheta = math.sin(theta);
    final t1 = math.sin((1.0 - t) * theta) / sinTheta;
    final t2 = math.sin(t * theta) / sinTheta;

    return Quaternion(
      x * t1 + q2.x * t2,
      y * t1 + q2.y * t2,
      z * t1 + q2.z * t2,
      w * t1 + q2.w * t2,
    );
  }

  /// Calculate angular velocity (degrees per second)
  double angularVelocity(Quaternion previous, double deltaTime) {
    if (deltaTime <= 0.0) return 0.0;

    final diff = previous.conjugate().multiply(this);
    final angle = 2.0 * math.acos(diff.w.clamp(-1.0, 1.0));

    return (angle * 180.0 / math.pi) / deltaTime;
  }

  /// Rotate a 3D vector
  vm.Vector3 rotateVector(vm.Vector3 v) {
    final qv = Quaternion(v.x, v.y, v.z, 0);
    final result = multiply(qv).multiply(conjugate());
    return vm.Vector3(result.x, result.y, result.z);
  }

  @override
  String toString() => 'Quaternion($x, $y, $z, $w)';

  @override
  bool operator ==(Object other) {
    if (other is! Quaternion) return false;
    return x == other.x && y == other.y && z == other.z && w == other.w;
  }

  @override
  int get hashCode => Object.hash(x, y, z, w);
}
