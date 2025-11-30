// 4D Rotation Mathematics
//
// Implements all six 4D rotation planes:
// - XY, XZ, YZ (ordinary 3D-like rotations)
// - XW, YW, ZW (rotations into the 4th dimension)
//
// Ported from vib34d-vib3plus PolychoraSystem.js
//
// A Paul Phillips Manifestation
//
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' as vm;

/// 4D rotation matrix builder
class Rotation4D {
  /// Rotate in XY plane (like rotating in 2D)
  static vm.Matrix4 rotateXY(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    return vm.Matrix4(
      c, -s, 0, 0,
      s,  c, 0, 0,
      0,  0, 1, 0,
      0,  0, 0, 1,
    );
  }

  /// Rotate in XZ plane
  static vm.Matrix4 rotateXZ(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    return vm.Matrix4(
      c,  0, -s, 0,
      0,  1,  0, 0,
      s,  0,  c, 0,
      0,  0,  0, 1,
    );
  }

  /// Rotate in YZ plane
  static vm.Matrix4 rotateYZ(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    return vm.Matrix4(
      1,  0,  0, 0,
      0,  c, -s, 0,
      0,  s,  c, 0,
      0,  0,  0, 1,
    );
  }

  /// Rotate in XW plane (into 4th dimension)
  static vm.Matrix4 rotateXW(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    return vm.Matrix4(
      c,  0, 0, -s,
      0,  1, 0,  0,
      0,  0, 1,  0,
      s,  0, 0,  c,
    );
  }

  /// Rotate in YW plane (into 4th dimension)
  static vm.Matrix4 rotateYW(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    return vm.Matrix4(
      1,  0,  0, 0,
      0,  c,  0, -s,
      0,  0,  1, 0,
      0,  s,  0, c,
    );
  }

  /// Rotate in ZW plane (into 4th dimension)
  static vm.Matrix4 rotateZW(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);

    return vm.Matrix4(
      1, 0,  0,  0,
      0, 1,  0,  0,
      0, 0,  c, -s,
      0, 0,  s,  c,
    );
  }

  /// Apply complete 6D rotation (all six planes)
  /// Order matters: XY -> XZ -> YZ -> XW -> YW -> ZW
  static vm.Matrix4 apply6DRotation({
    double xy = 0.0,
    double xz = 0.0,
    double yz = 0.0,
    double xw = 0.0,
    double yw = 0.0,
    double zw = 0.0,
  }) {
    var result = vm.Matrix4.identity();

    // Apply rotations in mathematically correct order
    if (xy != 0.0) result = rotateXY(xy) * result;
    if (xz != 0.0) result = rotateXZ(xz) * result;
    if (yz != 0.0) result = rotateYZ(yz) * result;
    if (xw != 0.0) result = rotateXW(xw) * result;
    if (yw != 0.0) result = rotateYW(yw) * result;
    if (zw != 0.0) result = rotateZW(zw) * result;

    return result;
  }

  /// Rotate a 4D vector
  static vm.Vector4 rotateVector(vm.Vector4 v, vm.Matrix4 rotation) {
    return rotation.transform(v);
  }

  /// Rotate multiple 4D vectors
  static List<vm.Vector4> rotateVertices(List<vm.Vector4> vertices, vm.Matrix4 rotation) {
    return vertices.map((v) => rotation.transform(v)).toList();
  }

  /// Project 4D to 3D (stereographic projection)
  static vm.Vector3 project4Dto3D(vm.Vector4 v, {double distance = 2.0}) {
    final w = 1.0 / (distance - v.w);
    return vm.Vector3(v.x * w, v.y * w, v.z * w);
  }

  /// Project 4D to 2D (perspective projection)
  static vm.Vector2 project4Dto2D(vm.Vector4 v, {double distance = 2.0}) {
    final w = 1.0 / (distance - v.w);
    return vm.Vector2(v.x * w, v.y * w);
  }

  /// Project 3D to 2D (standard perspective)
  static vm.Vector2 project3Dto2D(vm.Vector3 v, {double distance = 4.0}) {
    final z = 1.0 / (distance - v.z);
    return vm.Vector2(v.x * z, v.y * z);
  }
}
