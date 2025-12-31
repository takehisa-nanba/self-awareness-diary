// lib/ui/screens/brand_splash_screen.dart

import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'root_screen.dart';

class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isNavigating = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _paperRotationAnimation; // 紙の層専用のアニメーション

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 重厚感のある速度
    );
    // 表紙が左へ「手前に」開くアニメーション
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutQuart,
      ),
    );
    // 紙の層用のアニメーション（表紙より少し遅れて開始）
    _paperRotationAnimation = Tween<double>(begin: 0.0, end: 1.58).animate(
      // 少し角度を浅くする
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.03,
          1.0,
          curve: Curves.easeInOutQuart,
        ), // 3%遅らせて開始
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // テキストアニメーションが完了した後に呼ばれるメソッド
  void _onTextAnimationComplete() {
    // 1秒待ってから本を開くアニメーションを開始
    Timer(const Duration(seconds: 1), () {
      _navigateToHome();
    });
  }

  // ホーム画面へ遷移するメソッド
  void _navigateToHome() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    _animationController.forward().then((_) {
      if (!mounted) return;
      context.read<SettingsProvider>().completeFirstLaunch();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const RootScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const paperColor = Color(0xFF5FFF5F); // 淡い緑色
    const coverColor = Color(0xFF98FB98); // 固定のミントグリーン

    // スプラッシュ画面のUI
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedBuilder(
        animation: _animationController, // animationControllerをリッスン
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 本全体の影（アニメーションで薄くなるように変更）
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(
                          (150 * (1 - (_rotationAnimation.value / 1.6)))
                              .round(),
                        ),
                        blurRadius: 40,
                        offset: const Offset(10, 10),
                      ),
                    ],
                  ),
                ),
              ),
              // 紙の層を回転させるTransform
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_paperRotationAnimation.value),
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    _buildPaperLayer(context, paperColor, 6, 0.6),
                    _buildPaperLayer(context, paperColor, 3, 0.8),
                  ],
                ),
              ),

              // 表紙を回転させるTransform
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_rotationAnimation.value),
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    // 表紙本体（BoxShadowを削除）
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(color: coverColor),
                      child: _CoverContent(
                        onFinished: _onTextAnimationComplete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 元のシンプルな実装に戻す
  Widget _buildPaperLayer(
    BuildContext context,
    Color color,
    double offset,
    double opacity,
  ) {
    return Positioned.fill(
      left: offset,
      top: offset / 2,
      bottom: offset / 2,
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha((255 * opacity).round()),
          border: Border(
            right: BorderSide(
              color: Color.fromARGB(255, 95, 255, 95).withAlpha(30),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// 表紙のコンテンツウィジェット
class _CoverContent extends StatefulWidget {
  final VoidCallback onFinished;
  const _CoverContent({required this.onFinished});

  @override
  State<_CoverContent> createState() => _CoverContentState();
}

class _CoverContentState extends State<_CoverContent> {
  bool _line1Finished = false;
  bool _line2Finished = false;

  @override
  Widget build(BuildContext context) {
    final lightTextStyle = TextStyle(
      color: const Color(0xFF2E7D32), // 濃い緑色
      fontSize: 16,
    );
    // タイトルのスタイルを定義（フォントサイズを28に変更）
    final titleStyle = TextStyle(
      color: const Color(0xFF2E7D32), // 濃い緑色
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/diary_frame.svg',
            fit: BoxFit.fill,
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1行目のテキスト
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'あなたらしさは、あなたの中に。🪨',
                    textStyle: lightTextStyle,
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                isRepeatingAnimation: false,
                onFinished: () {
                  setState(() {
                    _line1Finished = true;
                  });
                },
              ),
              const SizedBox(height: 12),
              // 2行目のテキスト（1行目が終わったら表示）
              if (_line1Finished)
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'じぶんを磨く、こころがわかる。💎',
                      textStyle: lightTextStyle,
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  isRepeatingAnimation: false,
                  onFinished: () {
                    // 2行目が終わったら次のアニメーションフラグを立てる
                    setState(() {
                      _line2Finished = true;
                    });
                  },
                )
              else
                // プレースホルダー（高さを維持するため）
                Text('', style: lightTextStyle),

              const SizedBox(height: 60),
              // タイトル（2行目が終わったらアニメーション開始）
              if (_line2Finished)
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      '「じぶんを磨く日記帳」',
                      textStyle: titleStyle,
                      speed: const Duration(milliseconds: 120),
                    ),
                  ],
                  isRepeatingAnimation: false,
                  onFinished: () {
                    // 最後のテキストアニメーションが終わったら全体の完了コールバックを呼ぶ
                    widget.onFinished();
                  },
                )
              else
                // プレースホルダー
                Text('', style: titleStyle),
            ],
          ),
        ),
      ],
    );
  }
}
