import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight 3D vector.
class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  static const Vector3 zero = Vector3(0, 0, 0);

  Vector3 operator +(Vector3 o) => Vector3(x + o.x, y + o.y, z + o.z);
  Vector3 operator -(Vector3 o) => Vector3(x - o.x, y - o.y, z - o.z);
  Vector3 operator *(double s) => Vector3(x * s, y * s, z * s);
  Vector3 operator /(double s) => Vector3(x / s, y / s, z / s);

  double dot(Vector3 o) => x * o.x + y * o.y + z * o.z;

  Vector3 cross(Vector3 o) => Vector3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  double get length => math.sqrt(x * x + y * y + z * z);

  Vector3 normalized() {
    final len = length;
    if (len < 1e-9) return const Vector3(0, 1, 0);
    return this / len;
  }

  Vector3 copyWith({double? x, double? y, double? z}) =>
      Vector3(x ?? this.x, y ?? this.y, z ?? this.z);
}

/// Projected 2D point with depth for z-sorting.
class Offset3D {
  final Offset screen;
  final double depth;
  final bool isVisible;

  const Offset3D(this.screen, this.depth, [this.isVisible = true]);
}

/// 3D Orbit Camera with spherical yaw/pitch coordinates, perspective projection, and lighting.
class SimCamera3D {
  double yaw;
  double pitch;
  double distance;
  Vector3 target;
  double fov;

  // Cached initial values for quick reset
  final double _initialYaw;
  final double _initialPitch;
  final double _initialDistance;
  final Vector3 _initialTarget;

  SimCamera3D({
    this.yaw = 0.75, // ~43 degrees
    this.pitch = 0.52, // ~30 degrees
    this.distance = 250.0,
    this.target = const Vector3(0, 0, 0),
    this.fov = 60.0 * (math.pi / 180.0),
  })  : _initialYaw = yaw,
        _initialPitch = pitch,
        _initialDistance = distance,
        _initialTarget = target;

  void reset() {
    yaw = _initialYaw;
    pitch = _initialPitch;
    distance = _initialDistance;
    target = _initialTarget;
  }

  void orbit(double deltaYaw, double deltaPitch) {
    yaw += deltaYaw;
    pitch = (pitch + deltaPitch).clamp(-1.45, 1.45); // Clamp pitch to prevent gimbal flip
  }

  void zoom(double factor) {
    distance = (distance * factor).clamp(20.0, 3000.0);
  }

  void pan(double deltaX, double deltaY) {
    // Camera basis vectors
    final cosYaw = math.cos(yaw);
    final sinYaw = math.sin(yaw);

    final right = Vector3(-sinYaw, 0, cosYaw);
    final up = Vector3(0, 1, 0);

    final panSpeed = distance * 0.002;
    target = target + (right * (-deltaX * panSpeed)) + (up * (deltaY * panSpeed));
  }

  /// Calculates eye position in world space
  Vector3 get eye {
    final cosPitch = math.cos(pitch);
    final sinPitch = math.sin(pitch);
    final cosYaw = math.cos(yaw);
    final sinYaw = math.sin(yaw);

    final eyeX = target.x + distance * cosPitch * sinYaw;
    final eyeY = target.y + distance * sinPitch;
    final eyeZ = target.z + distance * cosPitch * cosYaw;

    return Vector3(eyeX, eyeY, eyeZ);
  }

  /// Projects a 3D point in world coordinates to screen viewport coordinates.
  Offset3D? project(double x, double y, double z, Size viewport) {
    return projectVector(Vector3(x, y, z), viewport);
  }

  /// Projects a Vector3 point into 2D screen coordinates with depth.
  Offset3D? projectVector(Vector3 worldPoint, Size viewport) {
    final currentEye = eye;

    // View coordinate system
    final forward = (target - currentEye).normalized();
    final upWorld = const Vector3(0, 1, 0);
    final right = forward.cross(upWorld).normalized();
    final trueUp = right.cross(forward).normalized();

    // Transform point to camera view space
    final d = worldPoint - currentEye;
    final viewX = d.dot(right);
    final viewY = d.dot(trueUp);
    final viewZ = d.dot(forward);

    // Near plane clipping
    if (viewZ <= 2.0) {
      return null;
    }

    // Isotropic perspective projection centered on viewport
    final refDimension = math.min(viewport.width, viewport.height);
    final focalLength = refDimension / (2.0 * math.tan(fov * 0.5));

    final screenX = viewport.width * 0.5 + (viewX / viewZ) * focalLength;
    final screenY = viewport.height * 0.5 - (viewY / viewZ) * focalLength;

    return Offset3D(Offset(screenX, screenY), viewZ, true);
  }

  /// Directional Blinn-Phong shading with specular highlights and ambient light.
  Color calculateLighting(
    Vector3 normal,
    Color baseColor, {
    Vector3 lightDir = const Vector3(0.5, 0.8, 0.3),
    double ambient = 0.35,
    double diffuse = 0.65,
    double specular = 0.25,
    double shininess = 32.0,
    Vector3? worldPos,
  }) {
    final l = lightDir.normalized();
    final n = normal.normalized();
    final nDotL = math.max(0.0, n.dot(l));
    var intensity = ambient + diffuse * nDotL;

    if (worldPos != null && nDotL > 0) {
      final v = (eye - worldPos).normalized();
      final h = (l + v).normalized();
      final nDotH = math.max(0.0, n.dot(h));
      final spec = math.pow(nDotH, shininess).toDouble() * specular;
      intensity = (intensity + spec).clamp(0.0, 1.0);
    } else {
      intensity = intensity.clamp(0.0, 1.0);
    }

    final a = (baseColor.a * 255.0).round().clamp(0, 255);
    final r = ((baseColor.r * 255.0).round() * intensity).toInt().clamp(0, 255);
    final g = ((baseColor.g * 255.0).round() * intensity).toInt().clamp(0, 255);
    final b = ((baseColor.b * 255.0).round() * intensity).toInt().clamp(0, 255);
    return Color.fromARGB(a, r, g, b);
  }
}
