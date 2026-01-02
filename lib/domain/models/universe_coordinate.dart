// lib/domain/models/universe_coordinate.dart

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
}
