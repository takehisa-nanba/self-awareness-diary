// lib/ui/widgets/universe_canvas.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart';
import 'dart:math';

import 'package:self_awareness_diary/providers/analysis_provider.dart';

/// 宇宙図を描画するためのカスタムペインター。
/// エゴグラムの各要素を「恒星」、日記の記録を「惑星」に見立てて描画します。
class UniverseCanvas extends StatefulWidget {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile;
  final double timeSliderValue; // 4次元目の時間軸スライダーの値 (0.0 - 1.0)
  final double warpFactor; // ワープエフェクトの強さ
  final Map<String, double> indicatorAnglesRad; // ラジアン角のマップ

  const UniverseCanvas({
    super.key,
    required this.recordCoordinates,
    required this.userProfile,
    required this.indicatorAnglesRad,
    this.timeSliderValue = 1.0,
    this.warpFactor = 0.0, // デフォルトは0
  });

  @override
  State<UniverseCanvas> createState() => _UniverseCanvasState();
}

class _UniverseCanvasState extends State<UniverseCanvas> with SingleTickerProviderStateMixin {
  // 視点に関する状態
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  // 拡大縮小とパンに関する状態
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // アニメーション用
  late AnimationController _animationController;
  Animation<Offset>? _offsetAnimation;
  Animation<double>? _scaleAnimation;

  // タップ判定のためのPainterへの参照
  late _UniversePainter _painter;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        setState(() {
          _offset = _offsetAnimation?.value ?? _offset;
          _scale = _scaleAnimation?.value ?? _scale;
        });
      });
    _painter = _createPainter();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UniverseCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _painter = _createPainter();
  }

  _UniversePainter _createPainter() {
    return _UniversePainter(
      recordCoordinates: widget.recordCoordinates,
      userProfile: widget.userProfile,
      indicatorAnglesRad: widget.indicatorAnglesRad,
      rotationX: _rotationX,
      rotationY: _rotationY,
      scale: _scale,
      offset: _offset,
      timeSliderValue: widget.timeSliderValue,
      warpFactor: widget.warpFactor,
    );
  }

  @override
  Widget build(BuildContext context) {
    _painter = _createPainter();

    return GestureDetector(
      onScaleStart: (details) {
        _animationController.stop();
      },
      onScaleUpdate: (details) {
        if (details.pointerCount > 1) { // 2本指以上はズーム
          setState(() {
            // TODO: ズーム中心を考慮したオフセット計算が必要だが、一旦パンで調整可能とする
            final newScale = _scale * details.scale;
            _scale = max(1.0, newScale);
          });
        } else { // 1本指はパン or 回転
            if (_scale > 1.01) { // わずかなスケール変動を無視
              setState(() {
                // 拡大中はパン
                _offset += details.focalPointDelta;
              });
            } else {
              // 拡大していない場合は視点回転
              setState(() {
                _rotationY += details.focalPointDelta.dx * 0.01;
                _rotationX += details.focalPointDelta.dy * 0.01;
                _rotationX = _rotationX.clamp(-pi / 2, pi / 2);
              });
            }
        }
      },
      onScaleEnd: (details) {
        // スケールが1.1未満ならアニメーションで元に戻す
        if (_scale < 1.1) {
          _offsetAnimation = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
          );
          _scaleAnimation = Tween<double>(begin: _scale, end: 1.0).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
          );
          _animationController.forward(from: 0.0);
        }
      },
      onTapUp: (details) {
        // タップ座標をPainterの座標系に変換
        final tappedPoint = (details.localPosition - _offset) / _scale;
        
        final tappedRecord = _painter.hitTestRecord(tappedPoint);
        if (tappedRecord != null) {
          context.read<AnalysisProvider>().selectRecord(tappedRecord);
        }
      },
      child: CustomPaint(
        painter: _painter,
        child: Container(),
      ),
    );
  }
}

// タップされた星の情報を保持するクラス
class TappableRecord {
  final Rect area;
  final DiaryRecord record;

  TappableRecord({required this.area, required this.record});
}

class _UniversePainter extends CustomPainter {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile;
  final Map<String, double> indicatorAnglesRad;
  final double rotationX;
  final double rotationY;
  final double scale;
  final Offset offset;
  final double timeSliderValue;
  final double warpFactor;

  // タップ可能な領域のリスト
  final List<TappableRecord> tappableRecords = [];

  _UniversePainter({
    required this.recordCoordinates,
    required this.userProfile,
    required this.indicatorAnglesRad,
    required this.rotationX,
    required this.rotationY,
    required this.scale,
    required this.offset,
    required this.timeSliderValue,
    required this.warpFactor,
  });

  // エゴグラムの各要素の表示名と色
  static const Map<String, Color> egoStateColors = {
    'CP': Colors.red,
    'NP': Colors.green,
    'A': Colors.blue,
    'FC': Colors.purple,
    'AC': Colors.orange,
  };

  /// タップ位置がどの星にヒットしたかをテストする
  DiaryRecord? hitTestRecord(Offset position) {
    for (final tappable in tappableRecords) {
      if (tappable.area.contains(position)) {
        return tappable.record;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 毎回の描画前にクリア
    tappableRecords.clear();

    final center = Offset(size.width / 2, size.height / 2);

    // 実際の描画処理を行う内部関数
    void paintUniverse(Canvas canvas, Size size) {
      const double baseRadius = 100.0;
      const double maxZScale = 150.0;

      // 恒星（エゴグラムの5要素）を描画
      indicatorAnglesRad.forEach((key, angleRad) {
        final x3d = baseRadius * cos(angleRad);
        final y3d = baseRadius * sin(angleRad);
        const z3d = 0.0;
        final rotatedX = x3d * cos(rotationY) - z3d * sin(rotationY);
        final rotatedY = y3d * cos(rotationX) - (x3d * sin(rotationY) + z3d * cos(rotationY)) * sin(rotationX);
        final rotatedZ = y3d * sin(rotationX) + (x3d * sin(rotationY) + z3d * cos(rotationY)) * cos(rotationX);
        final perspectiveScale = 1 - (rotatedZ / maxZScale);
        final projectedX = center.dx + rotatedX * perspectiveScale;
        final projectedY = center.dy + rotatedY * perspectiveScale;
        final color = egoStateColors[key] ?? Colors.white;
        final paint = Paint()
          ..color = color.withAlpha((255 * perspectiveScale.clamp(0.2, 1.0)).round()).withBlue(200)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, perspectiveScale * 5);
        final starRadius = 10.0 * perspectiveScale.clamp(0.5, 1.5);
        canvas.drawCircle(Offset(projectedX, projectedY), starRadius, paint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: key,
            style: TextStyle(
              color: Colors.white.withAlpha((255 * perspectiveScale.clamp(0.5, 1.0)).round()),
              fontSize: 10 * perspectiveScale.clamp(0.8, 1.2),
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(projectedX - textPainter.width / 2, projectedY - textPainter.height / 2));
      });

      // 日記の星（惑星）を描画
      final recordList = recordCoordinates.entries.toList();
      final recordsToShowCount = (recordList.length * timeSliderValue).ceil();

      for (int i = 0; i < recordsToShowCount; i++) {
        final entry = recordList[i];
        final record = entry.key;
        final coord = entry.value;

        final x3d = coord.x * (size.width / 4);
        final y3d = coord.y * (size.height / 4);
        final z3d = coord.z * maxZScale;
        final rotatedX = x3d * cos(rotationY) - z3d * sin(rotationY);
        final rotatedY = y3d * cos(rotationX) - (x3d * sin(rotationY) + z3d * cos(rotationY)) * sin(rotationX);
        final rotatedZ = y3d * sin(rotationX) + (x3d * sin(rotationY) + z3d * cos(rotationY)) * cos(rotationX);
        final perspectiveScale = 1 - (rotatedZ / maxZScale);
        final projectedX = center.dx + rotatedX * perspectiveScale;
        final projectedY = center.dy + rotatedY * perspectiveScale;
        final vectorFromCenter = Offset(projectedX - center.dx, projectedY - center.dy);
        final warpedPosition = Offset(
          projectedX + vectorFromCenter.dx * warpFactor,
          projectedY + vectorFromCenter.dy * warpFactor,
        );
        final paint = Paint()..color = Colors.amberAccent.withAlpha((255 * perspectiveScale.clamp(0.1, 0.8)).round());
        final recordRadius = 2.0 * perspectiveScale.clamp(0.5, 1.5);

        // タップ領域を計算してリストに追加
        final tappableArea = Rect.fromCircle(center: warpedPosition, radius: recordRadius + 8.0); // 少し領域を広げる
        tappableRecords.add(TappableRecord(area: tappableArea, record: record));

        canvas.drawCircle(warpedPosition, recordRadius, paint);
      }
    }

    // --- 描画の実行 ---
    // オフセットとスケールを適用したクリッピング領域を作成
    final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(clipRect);

    canvas.save();
    // キャンバス全体を変換
    final transformCenter = Offset(size.width / 2, size.height / 2);
    final matrix = Matrix4.identity()
      ..translate(transformCenter.dx, transformCenter.dy)
      ..scale(scale)
      ..translate(-transformCenter.dx, -transformCenter.dy)
      ..translate(offset.dx, offset.dy);

    canvas.transform(matrix.storage);
    
    paintUniverse(canvas, size);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UniversePainter oldDelegate) {
    return oldDelegate.recordCoordinates != recordCoordinates ||
        oldDelegate.userProfile != userProfile ||
        oldDelegate.indicatorAnglesRad != indicatorAnglesRad ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.timeSliderValue != timeSliderValue ||
        oldDelegate.warpFactor != warpFactor;
  }
}
