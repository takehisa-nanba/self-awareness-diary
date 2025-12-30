// lib/ui/screens/brand_splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SvgPictureのためにインポート
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'root_screen.dart';

/// ブランドスプラッシュスクリーンを表示するステートフルウィジェット。

/// アプリ起動時にアニメーションと共にキャッチコピーとアプリ名を表示します。

class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

/// [BrandSplashScreen] の状態を管理するクラス。

/// テキストアニメーション、自動画面遷移などのロジックを実装します。

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isNavigating = false;

  // アニメーション用コントローラーとTween

  late AnimationController _animationController;

  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 1500), // ページをめくるアニメーション時間
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 3.14159,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  /// [RootScreen] へ画面遷移を実行します。

  /// 多重遷移を防ぐためのフラグ管理も行います。

  void _navigateToHome() {
    if (_isNavigating || !mounted) return;

    _isNavigating = true;

    context.read<SettingsProvider>().completeFirstLaunch();

    // アニメーションを開始

    _animationController.forward().then((_) {
      if (!mounted) return;

      context.read<SettingsProvider>().completeFirstLaunch();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToHome,

      child: Scaffold(
        backgroundColor: const Color(0xFF98FB98), // ミントグリーン

        body: AnimatedBuilder(
          animation: _rotationAnimation,

          builder: (context, child) {
            final angle = _rotationAnimation.value;

            final isFrontVisible = angle < 1.5708; // 90度まで

            final isBackVisible = angle >= 1.5708; // 90度以降

            return Stack(
              children: [
                // 背景の装飾

                // SVGをアセットファイルから読み込むように変更
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/diary_frame.svg',

                    fit: BoxFit.fill, // 画面全体に広げる
                  ),
                ),

                // 回転するコンテンツ
                Center(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // パース
                      ..rotateY(angle),

                    alignment: Alignment.centerLeft,

                    child: Stack(
                      children: [
                        // ページの表側
                        if (isFrontVisible) const _SplashScreenContent(),

                        // ページの裏側（厚み）
                        if (isBackVisible)
                          Transform(
                            transform: Matrix4.identity()
                              ..rotateY(3.14159), // 180度回転させて裏側を表示

                            alignment: Alignment.center,

                            child: Container(
                              color: const Color(0xFF88D488), // ミントグリーンより少し濃い色

                              width: double.infinity,

                              height: double.infinity,

                              child:
                                  const _SplashScreenContent(), // 裏面もコンテンツを表示
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 画面遷移アニメーション中に表示するための静的なスプラッシュスクリーンコンテンツ。

class _SplashScreenContent extends StatelessWidget {
  const _SplashScreenContent();

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF2E7D32); // 深い緑

    return Container(
      color: const Color(0xFF98FB98), // 背景色

      child: Stack(
        children: [
          // SVGをアセットファイルから読み込むように変更
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/diary_frame.svg',

              fit: BoxFit.fill, // 画面全体に広げる
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Text(
                  'あなたらしさは、あなたの中に。🪨',

                  style: const TextStyle(fontSize: 16, color: textColor),
                ),

                const SizedBox(height: 16),

                Text(
                  'じぶんを磨く、こころがわかる。💎',

                  style: const TextStyle(fontSize: 16, color: textColor),
                ),

                const SizedBox(height: 40),

                Text(
                  '「じぶんを磨く日記帳」',

                  style: const TextStyle(
                    fontSize: 28,

                    fontWeight: FontWeight.bold,

                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
