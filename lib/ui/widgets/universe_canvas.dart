// lib/ui/widgets/universe_canvas.dart

import 'package:flutter/material.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart';
import 'dart:math';

/// 宇宙図を描画するためのカスタムペインター。
/// エゴグラムの各要素を「恒星」、日記の記録を「惑星」に見立てて描画します。
class UniverseCanvas extends StatefulWidget {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile;
  final double timeSliderValue; // 4次元目の時間軸スライダーの値 (0.0 - 1.0)

  const UniverseCanvas({
    super.key,
    required this.recordCoordinates,
    required this.userProfile,
    this.timeSliderValue = 1.0,
  });

  @override
  State<UniverseCanvas> createState() => _UniverseCanvasState();
}

class _UniverseCanvasState extends State<UniverseCanvas> {
  // 視点に関する状態
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        // ドラッグに応じて視点を変更
        setState(() {
          _rotationY += details.delta.dx * 0.01;
          _rotationX += details.delta.dy * 0.01;
          // 回転を制限することも可能
          _rotationX = _rotationX.clamp(-pi / 2, pi / 2);
        });
      },
      child: CustomPaint(
        painter: _UniversePainter(
          recordCoordinates: widget.recordCoordinates,
          userProfile: widget.userProfile,
          rotationX: _rotationX,
          rotationY: _rotationY,
          timeSliderValue: widget.timeSliderValue,
        ),
        child: Container(),
      ),
    );
  }
}

class _UniversePainter extends CustomPainter {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile;
  final double rotationX;
  final double rotationY;
  final double timeSliderValue; // 時間スライダーの値

  _UniversePainter({
    required this.recordCoordinates,
    required this.userProfile,
    required this.rotationX,
    required this.rotationY,
    required this.timeSliderValue,
  });

  // エゴグラムの各要素の表示名と色
  static const Map<String, Color> egoStateColors = {
    'CP': Colors.red,
    'NP': Colors.green,
    'A': Colors.blue,
    'FC': Colors.purple,
    'AC': Colors.orange,
  };

  // 各エゴグラム要素の角度 (deg) - UserProfileのcalculateUniversePositionと同期
  static const Map<String, double> egoStateAngles = {
    'CP': 90, // 規律 (真上)
    'NP': 18, // 慈愛
    'A': 306, // 論理
    'FC': 234, // 自由
    'AC': 162, // 順応
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double baseRadius = 100.0; // 恒星の配置半径
    const double maxZScale = 150.0; // Z軸方向のスケール係数

    // 恒星（エゴグラムの5要素）を描画
    egoStateAngles.forEach((key, angleDeg) {
      final angleRad = angleDeg * (pi / 180.0);
      // X, Y座標は円周上に配置
      final x3d = baseRadius * cos(angleRad);
      final y3d = baseRadius * sin(angleRad);
      const z3d = 0.0; // 恒星はZ=0の平面に描画

      // 3D回転を適用
      final rotatedX = x3d * cos(rotationY) - z3d * sin(rotationY);
      final rotatedY =
          y3d * cos(rotationX) -
          (x3d * sin(rotationY) + z3d * cos(rotationY)) * sin(rotationX);
      final rotatedZ =
          y3d * sin(rotationX) +
          (x3d * sin(rotationY) + z3d * cos(rotationY)) * cos(rotationX);

      // 簡易的な透視投影
      final perspectiveScale = 1 - (rotatedZ / maxZScale); // Zが大きいほど小さく、遠くに
      final projectedX = center.dx + rotatedX * perspectiveScale;
      final projectedY = center.dy + rotatedY * perspectiveScale;

      final color = egoStateColors[key] ?? Colors.white;
      final paint = Paint()
        ..color = color
            .withAlpha((255 * perspectiveScale.clamp(0.2, 1.0)).toInt())
            .withBlue(200)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          perspectiveScale * 5,
        ); // 光の表現
      final starRadius = 10.0 * perspectiveScale.clamp(0.5, 1.5); // Zに応じてサイズ変更

      canvas.drawCircle(Offset(projectedX, projectedY), starRadius, paint);

      // ラベルを描画
      final textPainter = TextPainter(
        text: TextSpan(
          text: key,
          style: TextStyle(
            color: Colors.white.withAlpha(
              (255 * perspectiveScale.clamp(0.5, 1.0)).toInt(),
            ),
            fontSize: 10 * perspectiveScale.clamp(0.8, 1.2),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          projectedX - textPainter.width / 2,
          projectedY - textPainter.height / 2,
        ),
      );
    });

    // 日記の星（惑星）を描画
    final recordList = recordCoordinates.entries.toList();
    final recordsToShowCount = (recordList.length * timeSliderValue).ceil();

    for (int i = 0; i < recordsToShowCount; i++) {
      final entry = recordList[i];
      // final record = entry.key; // Removed unused variable
      final coord = entry.value;

      // UniverseCoordinateの範囲 (-1.0 to 1.0) を画面座標に変換
      final x3d = coord.x * (size.width / 4); // 画面の1/4を最大半径とする
      final y3d = coord.y * (size.height / 4);
      final z3d = coord.z * maxZScale; // Zは0-1なのでmaxZScaleをかける

      // 3D回転を適用
      final rotatedX = x3d * cos(rotationY) - z3d * sin(rotationY);
      final rotatedY =
          y3d * cos(rotationX) -
          (x3d * sin(rotationY) + z3d * cos(rotationY)) * sin(rotationX);
      final rotatedZ =
          y3d * sin(rotationX) +
          (x3d * sin(rotationY) + z3d * cos(rotationY)) * cos(rotationX);

      // 簡易的な透視投影
      final perspectiveScale = 1 - (rotatedZ / maxZScale);
      final projectedX = center.dx + rotatedX * perspectiveScale;
      final projectedY = center.dy + rotatedY * perspectiveScale;

      final paint = Paint()
        ..color = Colors.amberAccent.withAlpha(
          (255 * perspectiveScale.clamp(0.1, 0.8)).toInt(),
        );
      final recordRadius = 2.0 * perspectiveScale.clamp(0.5, 1.5); // Zに応じてサイズ変更

      canvas.drawCircle(Offset(projectedX, projectedY), recordRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UniversePainter oldDelegate) {
    return oldDelegate.recordCoordinates != recordCoordinates ||
        oldDelegate.userProfile != userProfile ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.timeSliderValue != timeSliderValue;
  }
}
