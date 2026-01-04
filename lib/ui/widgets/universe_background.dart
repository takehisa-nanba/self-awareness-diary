// lib/ui/widgets/universe_background.dart
import 'dart:math';

import 'package:flutter/material.dart';

class UniverseBackground extends StatefulWidget {
  final double warpFactor;
  const UniverseBackground({super.key, this.warpFactor = 0.0});

  @override
  State<UniverseBackground> createState() => _UniverseBackgroundState();
}

class _UniverseBackgroundState extends State<UniverseBackground>
    with TickerProviderStateMixin {
  late List<Offset> _starPositions;
  late List<double> _starSizes;
  late AnimationController _twinkleController;
  late Animation<double> _twinkleAnimation;

  static const int _numberOfStars = 200;

  @override
  void initState() {
    super.initState();

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 10,
      ), // Adjust duration for desired twinkle speed
    )..repeat(reverse: true);

    _twinkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_twinkleController);

    // 星の位置、サイズをランダムに初期化
    _starPositions = List.generate(
      _numberOfStars,
      (index) => Offset(
        Random().nextDouble(),
        Random().nextDouble(),
      ), // 0.0-1.0の範囲でランダムな位置
    );
    _starSizes = List.generate(
      _numberOfStars,
      (index) => Random().nextDouble() * 2 + 1, // 1px-3pxのサイズ
    );
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 最背面: 深海グラデーション
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF000511), // ほぼ黒に近い深淵
                Color(0xFF0B1026), // 深い紺
                Color(0xFF1A1B41), // 深みのある紫
              ],
            ),
          ),
        ),

        // 中層: 静的な星間ガス (Nebula)
        CustomPaint(size: Size.infinite, painter: _NebulaPainter()),

        // 最前面: 瞬く星々 (Stars)
        AnimatedBuilder(
          animation: _twinkleAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _StarsPainter(
                starPositions: _starPositions,
                starSizes: _starSizes,
                twinkleValue: _twinkleAnimation.value,
                warpFactor: widget.warpFactor,
              ),
            );
          },
        ),
      ],
    );
  }
}

// 星間ガスを描画するCustomPainter
class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // 複数のRadialGradientを重ねて雲のような表現に
    paint.shader =
        RadialGradient(
          colors: [
            const Color(0xFF4FD1C5).withAlpha((255 * 0.08).round()), // ミントグリーン
            const Color(0xFF1A1B41).withAlpha((255 * 0.08).round()), // バイオレット
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.2, size.height * 0.3),
            radius: size.width * 0.7,
          ),
        );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.shader =
        RadialGradient(
          colors: [
            const Color(0xFF1A1B41).withAlpha((255 * 0.08).round()), // バイオレット
            const Color(0xFF4FD1C5).withAlpha((255 * 0.08).round()), // ミントグリーン
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.8, size.height * 0.7),
            radius: size.width * 0.6,
          ),
        );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // アニメーションはSlideTransitionで制御するため、自身は再描画不要
}

// 星を描画するCustomPainter
class _StarsPainter extends CustomPainter {
  final List<Offset> starPositions;
  final List<double> starSizes;
  final double twinkleValue; // 瞬きの現在の値 (0.0-1.0)
  final double warpFactor;

  // 各星の瞬きを非同期にするためのシード値
  final List<double> _twinkleSeeds;
  static const double _twinkleFrequency = 2 * pi; // 瞬きの頻度 (sin関数の周期)

  _StarsPainter({
    required this.starPositions,
    required this.starSizes,
    required this.twinkleValue,
    this.warpFactor = 0.0,
  }) : _twinkleSeeds = List.generate(
         starPositions.length,
         (index) =>
             Random(index).nextDouble() * _twinkleFrequency, // 各星に異なるシードを与える
       );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    for (int i = 0; i < starPositions.length; i++) {
      Offset originalPosition = Offset(
        starPositions[i].dx * size.width,
        starPositions[i].dy * size.height,
      );

      // Calculate vector from center
      Offset vectorFromCenter = Offset(
        originalPosition.dx - centerX,
        originalPosition.dy - centerY,
      );

      // Apply warp effect: move stars radially outwards
      Offset warpedPosition = Offset(
        originalPosition.dx + vectorFromCenter.dx * warpFactor,
        originalPosition.dy + vectorFromCenter.dy * warpFactor,
      );

      final starSize = starSizes[i];

      // 瞬きを計算: sin関数で周期的な透明度変化を作成
      // 0.2から0.7の範囲で透明度を変化させる
      final double twinkle =
          (sin(twinkleValue * _twinkleFrequency + _twinkleSeeds[i]) + 1) /
          2; // 0.0-1.0
      final double opacity = 0.2 + (twinkle * 0.5); // 0.2-0.7

      paint.color = Colors.white.withAlpha((255 * opacity).round());
      canvas.drawCircle(warpedPosition, starSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    // twinkleValueが変わったときにのみ再描画
    return oldDelegate.twinkleValue != twinkleValue ||
        oldDelegate.starPositions != starPositions ||
        oldDelegate.starSizes != starSizes ||
        oldDelegate.warpFactor != warpFactor;
  }
}
