import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'root_screen.dart';

/// アプリの顔：日記の「扉」を表現する画面
class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  // --- 管理用のスイッチ ---
  bool _isNavigating = false; // 画面遷移中に何度もタップされるのを防ぐ
  bool _canTap = false; // 全ての文章を読み終わるまで、扉を開けさせない「鍵」

  // --- アニメーションの司令塔 ---
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation; // 【表紙全体】を動かすための角度（0.0〜1.6）
  late Animation<double> _paperRotationAnimation; // 【中の紙】を動かすための角度（少し遅れて動く）

  @override
  void initState() {
    super.initState();

    // 1. 【時間の設計】日記がパサリと開く「質感」のために2秒（2000ミリ秒）を確保
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 2. 【表紙の動き】左端を軸にして、滑らかに（Curves.easeInOutQuart）回転
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutQuart,
      ),
    );

    // 3. 【紙の「でぃれい」演出】表紙が動き出してから「3%」遅れて（Interval 0.03）紙を動かす
    // これによって、表紙と紙の間に「厚み」という空気感が生まれます。
    _paperRotationAnimation = Tween<double>(begin: 0.0, end: 1.58).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.03, 1.0, curve: Curves.easeInOutQuart),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // 使い終わったメモリを掃除
    super.dispose();
  }

  // 文章演出の最後「準備はよろしいですか？」が書き終わったら実行
  void _onTextAnimationComplete() {
    setState(() => _canTap = true); // ここで初めて、画面タップが可能になる
  }

  // 画面がタップされた時：本をめくって「次分（次の自分）」へ進む
  void _navigateToNext() {
    if (_isNavigating || !mounted || !_canTap) return;
    _isNavigating = true;

    _animationController.forward().then((_) {
      if (!mounted) return;
      context.read<SettingsProvider>().completeFirstLaunch(); // チュートリアル終了を保存

      // ふわっと次の画面へ切り替え
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
    const paperColor = Color(0xFF5FFF5F); // 紙の緑
    const coverColor = Color(0xFF98FB98); // 表紙のミントグリーン

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GestureDetector(
        onTap: _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // --- 【レイヤー0：最背面の影】 ---
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(
                            (120 * (1 - (_rotationAnimation.value / 1.6)))
                                .round(),
                          ),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),

                // --- 【レイヤー1：紙（奥行き）】 ---
                // 表紙よりわずかに遅れて動くことで、本の中身があることを表現
                Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0005)
                    ..rotateY(_paperRotationAnimation.value),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: paperColor.withAlpha(150),
                  ),
                ),

                // --- 【レイヤー2,3,4：表紙グループ（一体化）】 ---
                // 武尚さんの「背景・装飾・文字はセットで動く」というこだわりを、一つのTransformで実現。
                Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0005)
                    ..rotateY(_rotationAnimation.value),
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      // レイヤー2：表紙の背景色
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: coverColor,
                      ),

                      // レイヤー3：装飾フレーム
                      Positioned.fill(
                        child: SvgPicture.asset(
                          'assets/images/diary_frame.svg',
                          fit: BoxFit.fill,
                        ),
                      ),

                      // レイヤー4：Min(e)Diary 文字演出
                      _CoverContent(onFinished: _onTextAnimationComplete),

                      // 武尚さん指定の位置：下から 250 の位置に点滅文字
                      if (_canTap)
                        const Positioned(
                          bottom: 250,
                          left: 0,
                          right: 0,
                          child: _TapGuidance(),
                        ),
                    ],
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

// ---------------------------------------------------------
// 【表紙のテキスト演出：ここが演出の核心です】
// ---------------------------------------------------------
class _CoverContent extends StatefulWidget {
  final VoidCallback onFinished;
  const _CoverContent({required this.onFinished});

  @override
  State<_CoverContent> createState() => _CoverContentState();
}

class _CoverContentState extends State<_CoverContent>
    with SingleTickerProviderStateMixin {
  // 文字がどこまで表示されたかを管理するスイッチ
  bool _line1Finished = false;
  bool _line2Finished = false; // タイトル開始の合図
  bool _minFinished = false; // "Min"完了

  bool _showLastPrompt = false;
  bool _showFinalReadyPrompt = false;

  // "(e)" の透明度をじわじわ変えるためのコントローラー
  late AnimationController _eFadeController;
  late Animation<double> _eOpacity;

  @override
  void initState() {
    super.initState();
    // 1.5秒かけて (e) を浮かび上がらせる
    _eFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _eOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _eFadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _eFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textGreen = Color(0xFF2E7D32); // 基本色
    final lightTextStyle = const TextStyle(color: textGreen, fontSize: 16);
    final guideStyle = const TextStyle(
      color: textGreen,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.6,
      letterSpacing: 0.5,
    );
    final finalTextStyle = const TextStyle(color: textGreen, fontSize: 16);

    const titleFontSize = 32.0;

    // 【Mind】用スタイル：極太で、 letterSpacing を 0 にして文字を密着させる。
    final mindStyle = TextStyle(
      color: const Color(0xFF1B5E20),
      fontSize: titleFontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.0,
    );

    // 【Diary】用スタイル：文字を少し細く、色も少し薄くしてバランスを取る。
    final normalDiaryStyle = TextStyle(
      color: textGreen.withAlpha(200),
      fontSize: 28.0,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.0,
    );

    return Column(
      children: [
        const Spacer(flex: 3), // 上部の余白
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 最初のキャッチコピー
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'あなたらしさは、あなたの中に。🪨',
                    textStyle: lightTextStyle,
                    speed: const Duration(milliseconds: 90),
                  ),
                ],
                isRepeatingAnimation: false,
                onFinished: () => setState(() => _line1Finished = true),
              ),
              const SizedBox(height: 8),

              // 2. 2番目のキャッチコピー
              if (_line1Finished)
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'じぶんを磨く、こころがわかる。💎',
                      textStyle: lightTextStyle,
                      speed: const Duration(milliseconds: 90),
                    ),
                  ],
                  isRepeatingAnimation: false,
                  onFinished: () {
                    // 全ての文章が終わって 0.6秒後にタイトル演出を起動
                    Future.delayed(const Duration(milliseconds: 600), () {
                      if (mounted) setState(() => _line2Finished = true);
                    });
                  },
                ),

              const SizedBox(height: 35),

              // 3. 【核心演出】Min (e) Diary
              if (_line2Finished)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // --- 「Min」を一文字ずつタイプ ---
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Min',
                          textStyle: mindStyle,
                          speed: const Duration(milliseconds: 200),
                        ),
                      ],
                      isRepeatingAnimation: false,
                      onFinished: () => setState(() => _minFinished = true),
                    ),

                    // --- 【透明な (e)】武尚さんの閃き ---
                    // 最初はオパシティ 0.0 なので見えませんが、場所だけは確保しています。
                    // これにより、Diaryがタイピングされても文字が横にズレません。
                    FadeTransition(
                      opacity: _eOpacity,
                      child: Text('(e)', style: mindStyle),
                    ),

                    // --- Diaryとの間の「少しの間隔」を 12px 固定で配置 ---
                    const SizedBox(width: 12),

                    // --- 「Diary」を一文字ずつタイプ (Minが終わったら開始) ---
                    if (_minFinished)
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Diary',
                            textStyle: normalDiaryStyle,
                            speed: const Duration(milliseconds: 150),
                          ),
                        ],
                        isRepeatingAnimation: false,
                        onFinished: () {

                          // 全ての文字が並び終わった 0.6秒後に、(e) をじわじわ宿らせる
                          Future.delayed(const Duration(milliseconds: 600), () {
                            _eFadeController.forward().then((_) {
                              // 完成の余韻として 1.2秒待ってから、次の説明文へ
                              Future.delayed(
                                const Duration(milliseconds: 1200),
                                () {
                                  if (mounted)
                                    setState(() => _showLastPrompt = true);
                                },
                              );
                            });
                          });
                        },
                      )
                    else
                      // Diaryが出るまでの間、場所が崩れないように透明なDを置いておく
                      Text(
                        'D',
                        style: normalDiaryStyle.copyWith(
                          color: Colors.transparent,
                        ),
                      ),
                  ],
                )
              else
                // タイトルが出る前の高さをあらかじめ確保（ガタつき防止）
                const SizedBox(height: titleFontSize * 1.5),

              const SizedBox(height: 40),

              // 4. 診断儀式の説明
              if (_showLastPrompt)
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      '今から、あなたの砥石の粒度を測る\n53の問いを投げ掛けますので、\nじぶんと向き合う準備をしてください。',
                      textStyle: guideStyle,
                      textAlign: TextAlign.center,
                      speed: const Duration(milliseconds: 90),
                    ),
                  ],
                  isRepeatingAnimation: false,
                  onFinished: () {
                    // 覚悟を問う前の、1.2秒の「間」
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (mounted) {
                        setState(() {
                          _showFinalReadyPrompt = true;
                        });
                      }
                    });
                  },
                ),

              const SizedBox(height: 20),

              // 5. 最後の問いかけ
              if (_showFinalReadyPrompt)
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      '準備はよろしいですか？',
                      textStyle: finalTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  isRepeatingAnimation: false,
                  onFinished: widget.onFinished, // 全演出終了の合図
                ),
            ],
          ),
        ),
        const Spacer(flex: 5), // 全体を上に押し上げるための余白
      ],
    );
  }
}

// TAP TO START：ユーザーを導く点滅文字
class _TapGuidance extends StatelessWidget {
  const _TapGuidance();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedTextKit(
        animatedTexts: [
          FadeAnimatedText(
            'TAP TO START',
            textStyle: TextStyle(
              color: const Color(0xFF2E7D32).withAlpha(150),
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        repeatForever: true,
      ),
    );
  }
}
