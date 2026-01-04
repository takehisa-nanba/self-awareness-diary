// lib/ui/widgets/universe_canvas.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v_math;
import 'package:self_awareness_diary/providers/analysis_provider.dart';

class UniverseCanvas extends StatefulWidget {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile;
  final double timeSliderValue;
  final double warpFactor;
  final Map<String, double> indicatorAnglesRad;

  const UniverseCanvas({
    super.key,
    required this.recordCoordinates,
    required this.userProfile,
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

  final Map<DiaryRecord, DateTime> _recordEntryTimes = {};
  late AnimationController _flareAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _rotationX = ValueNotifier<double>(0.0);
    _rotationY = ValueNotifier<double>(0.0);
    _flareAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    _rotationX.dispose();
    _rotationY.dispose();
    _flareAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UniverseCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recordCoordinates != oldWidget.recordCoordinates) {
      _recordEntryTimes.clear();
    }

    final oldRecordList = oldWidget.recordCoordinates.entries.toList();
    final newRecordList = widget.recordCoordinates.entries.toList();
    final oldRecordsToShowCount =
        (oldRecordList.length * oldWidget.timeSliderValue).ceil();
    final newRecordsToShowCount =
        (newRecordList.length * widget.timeSliderValue).ceil();

    bool newRecordAppeared = false;
    if (newRecordsToShowCount > oldRecordsToShowCount) {
      for (int i = oldRecordsToShowCount; i < newRecordsToShowCount; i++) {
        if (i < newRecordList.length) {
          final record = newRecordList[i].key;
          if (!_recordEntryTimes.containsKey(record)) {
            _recordEntryTimes[record] = DateTime.now();
            newRecordAppeared = true;
          }
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

    _animationController.duration = const Duration(milliseconds: 400);
    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    _rotationX.value = 0.0;
    _rotationY.value = 0.0;
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          onDoubleTap: _animateToIdentity,
          onTapUp: (details) {
            final tempPainter = _UniversePainter(
              recordCoordinates: widget.recordCoordinates,
              userProfile: widget.userProfile,
              indicatorAnglesRad: widget.indicatorAnglesRad,
              timeSliderValue: widget.timeSliderValue,
              warpFactor: widget.warpFactor,
              rotationX: _rotationX.value,
              rotationY: _rotationY.value,
              recordEntryTimes: _recordEntryTimes,
              flareAnimationValue: 0.0,
              viewMatrix: _transformationController.value,
            );

            final tappedRecord = tempPainter._hitTestPainter(
              details.localPosition,
              size,
            );
            if (tappedRecord != null) {
              context.read<AnalysisProvider>().selectRecord(tappedRecord);
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1,
            maxScale: 10.0,
            panEnabled: false,
            onInteractionUpdate: (details) {
              if (details.pointerCount == 1) {
                _rotationY.value += details.focalPointDelta.dx * 0.01;
                _rotationX.value += details.focalPointDelta.dy * 0.01;
                _rotationX.value = _rotationX.value.clamp(
                  -math.pi / 2,
                  math.pi / 2,
                );
              } else if (details.pointerCount == 2) {
                final newTranslation = v_math.Matrix4.identity()
                  ..translateByVector3(
                    v_math.Vector3(
                      details.focalPointDelta.dx,
                      details.focalPointDelta.dy,
                      0,
                    ),
                  );
                _transformationController.value =
                    newTranslation * _transformationController.value;
              }
            },
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _rotationX,
                _rotationY,
                _flareAnimationController,
                _transformationController,
              ]),
              builder: (context, _) {
                return SizedBox.expand(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _UniversePainter(
                        recordCoordinates: widget.recordCoordinates,
                        userProfile: widget.userProfile,
                        indicatorAnglesRad: widget.indicatorAnglesRad,
                        timeSliderValue: widget.timeSliderValue,
                        warpFactor: widget.warpFactor,
                        rotationX: _rotationX.value,
                        rotationY: _rotationY.value,
                        recordEntryTimes: _recordEntryTimes,
                        flareAnimationValue: _flareAnimationController.value,
                        viewMatrix: _transformationController.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _UniversePainter extends CustomPainter {
  final Map<DiaryRecord, UniverseCoordinate> recordCoordinates;
  final UserProfile userProfile;
  final Map<String, double> indicatorAnglesRad;
  final double rotationX;
  final double rotationY;
  final double timeSliderValue;
  final double warpFactor;
  final Map<DiaryRecord, DateTime> recordEntryTimes;
  final double flareAnimationValue;
  final v_math.Matrix4 viewMatrix;

  _UniversePainter({
    required this.recordCoordinates,
    required this.userProfile,
    required this.indicatorAnglesRad,
    required this.rotationX,
    required this.rotationY,
    required this.timeSliderValue,
    required this.warpFactor,
    required this.recordEntryTimes,
    required this.flareAnimationValue,
    required this.viewMatrix,
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

    for (final entry in recordCoordinates.entries) {
      final projectedPoint = _project(entry.value, size);
      final distance = (localPoint - projectedPoint).distance;
      if (distance < 30.0 && distance < minDistance) {
        minDistance = distance;
        closestRecord = entry.key;
      }
    }
    return closestRecord;
  }

  Offset _project(UniverseCoordinate coord, Size size) {
    final rotatedOffset = coord.getProjectedOffset(size, rotationX, rotationY);
    return MatrixUtils.transformPoint(viewMatrix, rotatedOffset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. 恒星（エゴ指標）
    indicatorAnglesRad.forEach((key, angleRad) {
      final coord = UniverseCoordinate(
        x: math.cos(angleRad),
        y: math.sin(angleRad),
        z: 0.0,
      );
      final double rotatedZ = coord.getRotatedZ(rotationX, rotationY);

      // 遠近感スケール (clamp範囲を広げて奥行きを強調)
      final double perspectiveScale = (rotatedZ / 100.0 + 1.0).clamp(0.1, 2.5);
      final projectedPoint = _project(coord, size);
      final color = egoStateColors[key] ?? Colors.white;

      // ★研磨：ぼかしを完全に廃止し、不透明度のみで遠近を表現
      final paint = Paint()
        ..color = color.withValues(
          alpha: (perspectiveScale * 0.4).clamp(0.1, 0.9),
        );

      canvas.drawCircle(projectedPoint, 15.0 * perspectiveScale, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: key,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: (perspectiveScale * 0.6).clamp(0.3, 1.0),
            ),
            fontSize: (14 * perspectiveScale).clamp(8.0, 30.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        projectedPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    });

    // 2. 惑星（日記レコード）
    final recordList = recordCoordinates.entries.toList();
    final recordsToShowCount = (recordList.length * timeSliderValue).ceil();

    for (int i = 0; i < recordsToShowCount; i++) {
      final entry = recordList[i];
      final record = entry.key;
      final coordinate = entry.value;

      final double rotatedZ = coordinate.getRotatedZ(rotationX, rotationY);
      // 手前はより大きく、奥はより小さくなるよう調整
      final double perspectiveScale = (rotatedZ / 80.0 + 1.0).clamp(0.05, 3.0);

      final projectedPoint = _project(coordinate, size);
      final vectorFromCenter = projectedPoint - center;
      final warpedPosition = projectedPoint + vectorFromCenter * warpFactor;

      double currentSize = 3.5 * perspectiveScale;
      double currentOpacity = (0.7 * perspectiveScale).clamp(0.1, 1.0);

      final entryTime = recordEntryTimes[record];
      if (entryTime != null) {
        final elapsed = DateTime.now().difference(entryTime);
        final animationProgress = (elapsed.inMilliseconds / 700).clamp(
          0.0,
          1.0,
        );
        if (animationProgress < 1.0) {
          final curve = Curves.easeOutBack.transform(animationProgress);
          currentSize *= (1.0 + 2.0 * (1.0 - curve));
          currentOpacity = (0.3 + 0.7 * curve);
        } else {
          recordEntryTimes.remove(record);
        }
      }

      // ★研磨：中心の白とぼかしを排除し、ソリッドな琥珀色の星に
      final paint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: currentOpacity);

      canvas.drawCircle(warpedPosition, currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UniversePainter oldDelegate) => true;
}
