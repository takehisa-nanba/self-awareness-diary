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

  /// 指定された回転角度に基づいて3D座標を回転させ、回転後のZ座標を計算します。
  /// このメソッドは、遠近感の計算に使用されます。
  double getRotatedZ(double rotationX, double rotationY) {
    // 宇宙空間のスケールを合わせる
    const double spaceScale = 150.0;
    final double currentX = x * spaceScale;
    final double currentY = y * spaceScale;
    final double currentZ = z * spaceScale;

    // Y軸（水平）回転
    final rotatedZAfterY = currentZ * cos(rotationY) - currentX * sin(rotationY);

    // X軸（垂直）回転
    final finalZ = rotatedZAfterY * cos(rotationX) - currentY * sin(rotationX);
    
    return finalZ;
  }

  /// 3D座標を回転させ、2Dスクリーンに投影したOffsetを計算します。
  Offset getProjectedOffset(Size size, double rotationX, double rotationY) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    const double spaceScale = 150.0;
    final double currentX = x * spaceScale;
    final double currentY = y * spaceScale;
    final double currentZ = z * spaceScale;

    // Y軸回転
    final rotatedX = currentX * cos(rotationY) + currentZ * sin(rotationY);
    final rotatedZAfterY = currentZ * cos(rotationY) - currentX * sin(rotationY);

    // X軸回転
    final rotatedY = currentY * cos(rotationX) + rotatedZAfterY * sin(rotationX);
    final finalZ = rotatedZAfterY * cos(rotationX) - currentY * sin(rotationX);

    // 透視投影
    const double focalLength = 200.0;
    final double perspectiveFactor = focalLength / (focalLength + finalZ);

    final double projectedX = rotatedX * perspectiveFactor;
    final double projectedY = rotatedY * perspectiveFactor;

    return Offset(centerX + projectedX, centerY + projectedY);
  }
}