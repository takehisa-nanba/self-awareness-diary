// lib/ui/widgets/universe_canvas.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart'; // UserProfileをインポート
import 'dart:math' as math; // Rename dart:math to math
import 'package:vector_math/vector_math_64.dart'
    as v_math; // Use vector_math_64 with a prefix

import 'package:self_awareness_diary/providers/analysis_provider.dart';

class UniverseCanvas extends StatefulWidget {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile; // UserProfileを追加
  final double timeSliderValue;
  final double warpFactor;
  final Map<String, double> indicatorAnglesRad;

  const UniverseCanvas({
    super.key,
    required this.recordCoordinates,
    required this.userProfile, // UserProfileを追加
    required this.indicatorAnglesRad,
    this.timeSliderValue = 1.0,
    this.warpFactor = 0.0,
  });

  @override
  State<UniverseCanvas> createState() => _UniverseCanvasState();
}

class _UniverseCanvasState extends State<UniverseCanvas>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;

  late ValueNotifier<double> _rotationX;
  late ValueNotifier<double> _rotationY;

  // 記憶の誕生エフェクト用
  final Map<DiaryRecord, DateTime> _recordEntryTimes = {};
  late AnimationController _flareAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _rotationX = ValueNotifier<double>(0.0);
    _rotationY = ValueNotifier<double>(0.0);
    // 追加：フレア演出用コントローラーの初期化
    _flareAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // didUpdateWidgetと合わせて700ms
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    _rotationX.dispose();
    _rotationY.dispose();
    _flareAnimationController.dispose(); // 追加
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UniverseCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // recordCoordinatesの参照が変わった場合、またはリストの中身が大きく変わった場合は、
    // エントリ時間をリセットして再評価する。
    // 具体的なレコードの追加・削除は recordCoordinates の変更として扱われる。
    if (widget.recordCoordinates != oldWidget.recordCoordinates) {
      _recordEntryTimes.clear();
    }

    final oldRecordList = oldWidget.recordCoordinates.entries.toList();
    final newRecordList = widget.recordCoordinates.entries.toList();

    // timeSliderValue が後退した場合に、表示済みのエントリ時間をクリアしないように注意
    // timeSliderValue が増加した場合に、新しく表示されるレコードを検出
    final oldRecordsToShowCount =
        (oldRecordList.length * oldWidget.timeSliderValue).ceil();
    final newRecordsToShowCount =
        (newRecordList.length * widget.timeSliderValue).ceil();

    bool newRecordAppeared = false;
    // timeSliderValue が進んだ時のみ新しいレコードを検出
    if (newRecordsToShowCount > oldRecordsToShowCount) {
      for (int i = oldRecordsToShowCount; i < newRecordsToShowCount; i++) {
        if (i < newRecordList.length) {
          final record = newRecordList[i].key;
          // 新しく表示範囲に入ったレコードの場合のみエントリ時間を記録
          if (!_recordEntryTimes.containsKey(record)) {
            _recordEntryTimes[record] = DateTime.now();
            newRecordAppeared = true;
          }
        }
      }
    }

    // timeSliderValue が減少した場合は、表示範囲外になったレコードのエントリ時間をクリア
    if (newRecordsToShowCount < oldRecordsToShowCount) {
      for (int i = newRecordsToShowCount; i < oldRecordsToShowCount; i++) {
        if (i < newRecordList.length) {
          final record = newRecordList[i].key;
          _recordEntryTimes.remove(record);
        }
      }
    }

    if (newRecordAppeared) {
      _flareAnimationController.forward(from: 0.0);
    }
  }

  void _animateToIdentity() {
    final animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: v_math.Matrix4.identity(),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.duration = const Duration(milliseconds: 300);
    animation.addListener(() {
      _transformationController.value = animation.value;
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // Get the matrix from InteractiveViewer
        final interactiveViewMatrix = _transformationController.value;

        // Create a matrix for the current rotation
        final size = context.size!;
        final center = Offset(size.width / 2, size.height / 2);
        final rotationMatrix = v_math.Matrix4.identity()
          ..translateByVector3(v_math.Vector3(center.dx, center.dy, 0))
          ..rotateX(_rotationX.value)
          ..rotateY(_rotationY.value)
          ..translateByVector3(v_math.Vector3(-center.dx, -center.dy, 0));

        // Combine all transformations
        final fullTransform = interactiveViewMatrix * rotationMatrix;

        final invertedFullTransform = Matrix4.inverted(fullTransform);
        final tappedPoint = MatrixUtils.transformPoint(
          invertedFullTransform,
          details.localPosition,
        );

        // Create a temporary painter for hit testing
        final tempPainter = _UniversePainter(
          recordCoordinates: widget.recordCoordinates,
          userProfile: widget.userProfile,
          indicatorAnglesRad: widget.indicatorAnglesRad,
          timeSliderValue: widget.timeSliderValue,
          warpFactor: widget.warpFactor,
          rotationX: _rotationX.value,
          rotationY: _rotationY.value,
          recordEntryTimes: _recordEntryTimes, // Pass the map
          flareAnimationValue:
              0.0, // Hit testing doesn't need actual flare animation
        );

        final tappedRecord = tempPainter._hitTestPainter(tappedPoint, size);
        if (tappedRecord != null) {
          context.read<AnalysisProvider>().selectRecord(tappedRecord);
        }
      },
      // 回転は1本指でのみ (InteractiveViewerがパン・ズームを処理するため、それ以外の1本指ドラッグを回転に使う)
      onScaleUpdate: (details) {
        if (details.pointerCount == 1 &&
            _transformationController.value.getMaxScaleOnAxis() <= 1.05) {
          _rotationY.value += details.focalPointDelta.dx * 0.01;
          _rotationX.value += details.focalPointDelta.dy * 0.01;
          _rotationX.value = _rotationX.value.clamp(-math.pi / 2, math.pi / 2);
        }
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        onInteractionEnd: (details) {
          // スケールが初期値に近づいたらアニメーションで戻す
          if (_transformationController.value.getMaxScaleOnAxis() < 1.05) {
            _animateToIdentity();
          }
        },
        child: ValueListenableBuilder<double>(
          valueListenable: _rotationX,
          builder: (context, rotationX, _) {
            return ValueListenableBuilder<double>(
              valueListenable: _rotationY,
              builder: (context, rotationY, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    final center = Offset(size.width / 2, size.height / 2);
                    return AnimatedBuilder(
                      animation: _flareAnimationController,
                      builder: (context, child) {
                        final painter = _UniversePainter(
                          recordCoordinates: widget.recordCoordinates,
                          userProfile: widget.userProfile,
                          indicatorAnglesRad: widget.indicatorAnglesRad,
                          timeSliderValue: widget.timeSliderValue,
                          warpFactor: widget.warpFactor,
                          rotationX: rotationX,
                          rotationY: rotationY,
                          recordEntryTimes: _recordEntryTimes, // Pass the map
                          flareAnimationValue: _flareAnimationController
                              .value, // Pass the animation value
                        );
                        return Transform(
                          // Apply rotation to the CustomPaint child
                          transform: v_math.Matrix4.identity()
                            ..translateByVector3(
                              v_math.Vector3(center.dx, center.dy, 0),
                            )
                            ..rotateX(rotationX)
                            ..rotateY(rotationY)
                            ..translateByVector3(
                              v_math.Vector3(-center.dx, -center.dy, 0),
                            ),
                          alignment: FractionalOffset.center,
                          child: RepaintBoundary(
                            child: CustomPaint(painter: painter, size: size),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UniversePainter extends CustomPainter {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile; // UserProfileを追加
  final Map<String, double> indicatorAnglesRad;
  final double rotationX;
  final double rotationY;
  final double timeSliderValue;
  final double warpFactor;
  final Map<DiaryRecord, DateTime> recordEntryTimes; // エントランスアニメーション用
  final double flareAnimationValue; // フレアアニメーションの現在の値

  _UniversePainter({
    required this.recordCoordinates,
    required this.userProfile, // UserProfileを追加
    required this.indicatorAnglesRad,
    required this.rotationX,
    required this.rotationY,
    required this.timeSliderValue,
    required this.warpFactor,
    required this.recordEntryTimes, // エントランスアニメーション用
    required this.flareAnimationValue, // フレアアニメーションの現在の値
  });

  static const Map<String, Color> egoStateColors = {
    'CP': Colors.red,
    'NP': Colors.green,
    'A': Colors.blue,
    'FC': Colors.purple,
    'AC': Colors.orange,
  };

  DiaryRecord? _hitTestPainter(Offset localPoint, Size size) {
    double minDistance = double.infinity;
    DiaryRecord? closestRecord;

    // 恒星のヒットテスト（今回は惑星のみに絞る）
    // indicatorAnglesRad.forEach((key, angleRad) {
    //   final coord = UniverseCoordinate(x: cos(angleRad), y: sin(angleRad), z: 0);
    //   final projectedPoint = coord.getProjectedOffset(size, rotationX, rotationY);
    //   const double tapRadius = 25.0;
    //   final distance = (localPoint - projectedPoint).distance;
    //   if (distance < tapRadius && distance < minDistance) {
    //     minDistance = distance;
    //     closestRecord = ... // 恒星のタップはRecordではないので別の方法を考える
    //   }
    // });

    // 惑星のヒットテスト
    for (final entry in recordCoordinates.entries) {
      final projectedPoint = entry.value.getProjectedOffset(
        size,
        rotationX,
        rotationY,
      );
      const double tapRadius = 25.0; // タップ半径
      final distance = (localPoint - projectedPoint).distance;
      if (distance < tapRadius && distance < minDistance) {
        minDistance = distance;
        closestRecord = entry.key;
      }
    }
    return closestRecord;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 一時的なperspectiveScale (後でZ値に基づいて計算する)
    const double perspectiveScale = 1.0;

    // 恒星
    indicatorAnglesRad.forEach((key, angleRad) {
      // UserProfileの値をUniverseCoordinateのx, y, zに適切にマッピングして使用する
      // 今回は恒星なのでZは0。x,yは円周上の位置とする
      final coord = UniverseCoordinate(
        x: math.cos(angleRad) * (size.width / 4),
        y: math.sin(angleRad) * (size.height / 4),
        z: 0,
      );
      final projectedPoint = coord.getProjectedOffset(
        size,
        rotationX,
        rotationY,
      );

      final color = egoStateColors[key] ?? Colors.white;
      final double perspectiveScale =
          1.0; // Placeholder for now, to be calculated based on depth
      final paint = Paint()
        ..color = color.withValues(alpha: perspectiveScale.clamp(0.2, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(projectedPoint, 12.0, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: key,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: perspectiveScale.clamp(0.5, 1.0),
            ),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        projectedPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    });

    // 惑星
    final recordList = recordCoordinates.entries.toList();
    final recordsToShowCount = (recordList.length * timeSliderValue).ceil();
    for (int i = 0; i < recordsToShowCount; i++) {
      final entry = recordList[i];
      final record = entry.key; // 現在のレコード
      final projectedPoint = entry.value.getProjectedOffset(
        size,
        rotationX,
        rotationY,
      );

      final vectorFromCenter = projectedPoint - center;
      final warpedPosition = projectedPoint + vectorFromCenter * warpFactor;

      double currentSize = 2.5; // 基本サイズ
      double currentOpacity = 0.8; // 基本透明度 (220/255)

      // エントランスアニメーションの適用
      final entryTime = recordEntryTimes[record];
      if (entryTime != null) {
        final elapsed = DateTime.now().difference(entryTime);
        final animationDuration = const Duration(milliseconds: 700);
        final animationProgress =
            elapsed.inMilliseconds / animationDuration.inMilliseconds;

        if (animationProgress >= 0 && animationProgress <= 1.0) {
          // オーバーシュートするカーブ
          final curve = Curves.easeOutCubic; // Flare curve
          final curvedValue = curve.transform(animationProgress);

          // サイズのオーバーシュート (例: 1.0 -> 1.5 -> 1.0)
          currentSize = 2.5 * (1.0 + 0.5 * (1 - curvedValue));
          // 透明度のオーバーシュート (例: 0.8 -> 1.0 -> 0.8) と perspectiveScale の適用
          currentOpacity =
              (0.8 + 0.2 * (1 - curvedValue)) *
              perspectiveScale.clamp(0.1, 0.8);
        } else if (animationProgress > 1.0) {
          // アニメーション終了後は通常のサイズと透明度 (perspectiveScale を適用)
          currentOpacity = 0.8 * perspectiveScale.clamp(0.1, 0.8);
          recordEntryTimes.remove(record); // アニメーション終了済みとして削除
        }
      } else {
        // エントリ時間がない場合 (アニメーションが終了しているか、最初から表示されている場合)
        currentOpacity = 0.8 * perspectiveScale.clamp(0.1, 0.8);
      }

      final baseColor = Colors.amberAccent;
      final paint = Paint()
        ..color = baseColor.withValues(
          alpha: currentOpacity,
          // RGB値はそのまま
        );
      canvas.drawCircle(warpedPosition, currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UniversePainter oldDelegate) {
    return oldDelegate.recordCoordinates != recordCoordinates ||
        oldDelegate.userProfile != userProfile || // UserProfileの変更もトリガー
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.timeSliderValue != timeSliderValue ||
        oldDelegate.warpFactor != warpFactor ||
        oldDelegate.recordEntryTimes != recordEntryTimes || // エントランスアニメーション用
        oldDelegate.flareAnimationValue != flareAnimationValue; // フレアアニメーション用
  }
}
