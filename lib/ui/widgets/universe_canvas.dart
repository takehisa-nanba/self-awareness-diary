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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _rotationX = ValueNotifier<double>(0.0);
    _rotationY = ValueNotifier<double>(0.0);
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
                    final painter = _UniversePainter(
                      recordCoordinates: widget.recordCoordinates,
                      userProfile: widget.userProfile,
                      indicatorAnglesRad: widget.indicatorAnglesRad,
                      timeSliderValue: widget.timeSliderValue,
                      warpFactor: widget.warpFactor,
                      rotationX: rotationX,
                      rotationY: rotationY,
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

  _UniversePainter({
    required this.recordCoordinates,
    required this.userProfile, // UserProfileを追加
    required this.indicatorAnglesRad,
    required this.rotationX,
    required this.rotationY,
    required this.timeSliderValue,
    required this.warpFactor,
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
      final paint = Paint()
        ..color = color.withAlpha(200)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(projectedPoint, 12.0, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: key,
          style: const TextStyle(
            color: Colors.white,
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
      final projectedPoint = entry.value.getProjectedOffset(
        size,
        rotationX,
        rotationY,
      );

      final vectorFromCenter = projectedPoint - center;
      final warpedPosition = projectedPoint + vectorFromCenter * warpFactor;

      final paint = Paint()..color = Colors.amberAccent.withAlpha(220);
      canvas.drawCircle(warpedPosition, 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UniversePainter oldDelegate) {
    return oldDelegate.recordCoordinates != recordCoordinates ||
        oldDelegate.userProfile != userProfile || // UserProfileの変更もトリガー
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.timeSliderValue != timeSliderValue ||
        oldDelegate.warpFactor != warpFactor;
  }
}
