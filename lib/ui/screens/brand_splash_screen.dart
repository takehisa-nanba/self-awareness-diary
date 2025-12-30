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
      end: 3.14159, // πラジアン (180度) まで回転
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
            // 90度 (π/2) を境に表裏を切り替える
            final isFrontVisible = angle < (3.14159 / 2);
            final isBackVisible = angle >= (3.14159 / 2);

            return Stack(
              children: [
                // 背景の装飾 (static frame)
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/diary_frame.svg',
                    fit: BoxFit.fill,
                  ),
                ),

                // ページの積層 (Page thickness - 2 layers behind the main page)
                // Layer 1 (most behind)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 4.0,
                      top: 4.0,
                    ), // わずかに左下へずらす
                    color: const Color(0xFFFFF9E3), // アンティークな紙のアイボリー
                  ),
                ),
                // Layer 2
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 2.0,
                      top: 2.0,
                    ), // わずかに左下へずらす
                    color: const Color(0xFFFFF9E3), // アンティークな紙のアイボリー
                  ),
                ),

                // 回転するメインページ
                Center(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // パース (3D効果)
                      ..rotateY(angle), // Y軸を中心に回転
                    alignment: Alignment.centerLeft, // 左端を軸に回転
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8, // 画面幅の80%
                      height:
                          MediaQuery.of(context).size.height * 0.8, // 画面高さの80%
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E3), // メインページの色
                        boxShadow: [
                          BoxShadow(
                            // 影の濃さが角度に応じて変化
                            color: Colors.black.withAlpha(
                              (255 * 0.5 * (angle / (3.14159 / 2)).clamp(0.0, 1.0)).round(),
                            ),
                            offset: const Offset(-5, 0), // 左側（背表紙側）に影
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // ページの表側
                          if (isFrontVisible)
                            const _SplashScreenContent(isFront: true),

                          // ページの裏側
                          if (isBackVisible)
                            Transform(
                              transform: Matrix4.identity()
                                ..rotateY(3.14159), // 180度回転させて裏側を表示
                              alignment: Alignment.center,
                              child: const _SplashScreenContent(isFront: false),
                            ),
                        ],
                      ),
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
  final bool isFront;
  const _SplashScreenContent({required this.isFront});

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF2E7D32); // 深い緑

    return Container(
      color: const Color(0xFFFFF9E3), // 背景色をアイボリーに統一
      // 裏面には薄い枠線を追加して質感を与える
      decoration: isFront
          ? null
          : BoxDecoration(
              border: Border.all(
                color: Colors.grey.withAlpha((255 * 0.3).round()), // 薄いグレーの枠線
                width: 2.0,
              ),
            ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFront) ...[
              // 表側にのみメインのキャッチコピーを表示
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
            ] else ...[
              // 裏面には簡潔なテキストと枠線を表示
              Text(
                '新しいページへ',
                style: TextStyle(
                  fontSize: 20,
                  color: textColor.withAlpha((255 * 0.5).round()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
