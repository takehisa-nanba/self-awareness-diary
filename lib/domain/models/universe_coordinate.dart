// lib/domain/models/universe_coordinate.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// 3D空間における宇宙座標を表すイミュータブルなクラス。
class UniverseCoordinate {
  /// X座標 (-1.0 から 1.0)
  final double x;

  /// Y座標 (-1.0 から 1.0)
  final double y;

  /// Z座標（深度, 0.0 から 1.0）
  final double z;

  const UniverseCoordinate({required this.x, required this.y, required this.z});

  @override
  String toString() {
    return 'UniverseCoordinate(x: $x, y: $y, z: $z)';
  }

  /// 3D座標を回転させ、2Dスクリーンに投影したOffsetを計算します。
  Offset getProjectedOffset(Size size, double rotationX, double rotationY) {
    const double maxZScale = 150.0;
    final center = Offset(size.width / 2, size.height / 2);

    // painterの計算と合わせる
    final x3d = x * (size.width / 4);
    final y3d = y * (size.height / 4);
    final z3d = z * maxZScale;

    // 3D回転
    final rotatedX = x3d * cos(rotationY) - z3d * sin(rotationY);
    final rotatedY =
        y3d * cos(rotationX) -
        (x3d * sin(rotationY) + z3d * cos(rotationY)) * sin(rotationX);
    final rotatedZ =
        y3d * sin(rotationX) +
        (x3d * sin(rotationY) + z3d * cos(rotationY)) * cos(rotationX);

    // 透視投影
    final perspectiveScale = 1 - (rotatedZ / maxZScale);
    return Offset(
      center.dx + rotatedX * perspectiveScale,
      center.dy + rotatedY * perspectiveScale,
    );
  }
}
