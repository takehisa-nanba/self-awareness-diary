import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'diagnosis_screen.dart';
import '../widgets/universe_background.dart'; // Import UniverseBackground

// 仮のホーム画面 (必要に応じて適切なウィジェットに置き換える)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Main Application Home Screen')),
    );
  }
}

/// アプリの顔：日記の「扉」を表現する画面
class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with TickerProviderStateMixin {
  // --- 管理用のスイッチ ---
  bool _isNavigating = false; // 画面遷移中に何度もタップされるのを防ぐ
  bool _canTap = false; // 全ての文章を読み終わるまで、扉を開けさせない「鍵」

  // --- アニメーションの司令塔 ---
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation; // 【表紙全体】を動かすための角度（0.0〜1.6）
  late Animation<double> _paperRotationAnimation; // 【中の紙】を動かすための角度（少し遅れて動く）

  // Warp effect animations
  late AnimationController _warpAnimationController;
  late Animation<double> _warpAnimation;

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

    // ワープアニメーションの初期化
    _warpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // 1.2秒
    );
    _warpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _warpAnimationController,
        curve: Curves.easeInExpo, // 直線的な加速
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // 使い終わったメモリを掃除
    _warpAnimationController.dispose(); // ワープアニメーションコントローラーを破棄
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

    // ワープアニメーションを開始し、完了後に画面遷移
    _warpAnimationController.forward(); // ワープアニメーション開始

    _animationController.forward().then((_) {
      if (!mounted) return;
      final settingsProvider = context.read<SettingsProvider>();

      // ナビゲーション先のウィジェットを決定
      Widget nextScreen;
      if (!settingsProvider.isDiagnosisComplete) {
        nextScreen = const DiagnosisScreen();
      } else {
        nextScreen = const HomePage(); // 仮のホーム画面 (必要に応じて適切なウィジェットに置き換える)
      }

      // ふわっと次の画面へ切り替え
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
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
    // Current theme for text and other UI elements
    final currentTheme = Theme.of(context);

    final coverColor =
        currentTheme.colorScheme.surfaceContainerHighest; // Deep purple
    final paperColor = currentTheme.colorScheme.surfaceContainer; // Deep blue

    return Scaffold(
      extendBodyBehindAppBar: true, // Make body content extend behind app bar
      body: Stack(
        children: [
          // 0. UniverseBackground at the very back
          AnimatedBuilder(
            animation: _warpAnimation,
            builder: (context, child) {
              return UniverseBackground(warpFactor: _warpAnimation.value);
            },
          ),

          // Layered content on top of UniverseBackground
          GestureDetector(
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
                        color: paperColor, // Use theme color
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
                            color: coverColor, // Use theme color
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
        ],
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
    with TickerProviderStateMixin {
  // 文字がどこまで表示されたかを管理するスイッチ
  bool _line1Finished = false;
  bool _line2Finished = false; // タイトル開始の合図
  bool _diaryFinished = false; // Diaryのタイピング完了フラグ

  bool _showLastPrompt = false;
  bool _showFinalReadyPrompt = false;

  // "(e)" の透明度と幅をじわじわ変えるためのコントローラー
  late AnimationController _eFadeController; // 幅アニメーションも兼ねる

  // 全体のタイトルタイピング進行度を制御するコントローラー
  late AnimationController _titleController;
  late Animation<double> _titleProgress;

  double _eTextWidth = 0.0; // (e)の幅計測用 (padding込み)

  @override
  void initState() {
    super.initState();
    // 1.5秒かけて (e) を浮かび上がらせる
    _eFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Min(e)Diary全体のタイピング時間
    );
    _titleProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_titleController);

    _titleProgress.addListener(() {
      if (_titleProgress.value >= 0.6 && !_diaryFinished) {
        // Diaryのタイピングが完了するタイミング (diaryEndThreshold)
        setState(() => _diaryFinished = true);
      }

      if (_diaryFinished && // Diaryが完了したら
          !_eFadeController.isAnimating &&
          _eFadeController.status != AnimationStatus.completed) {
        _eFadeController.forward(); // (e)のフェードイン開始
      }

      if (_titleProgress.value > 0.95 && !_showLastPrompt) {
        // 少し遅延させて次のプロンプトへ
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() => _showLastPrompt = true);
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Measure the width of '(e)' after the first frame
      const titleFontSize = 32.0;
      final mindStyle = TextStyle(
        color: const Color(0xFF1B5E20),
        fontSize: titleFontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.0,
      );
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: '(e)', style: mindStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      setState(() {
        _eTextWidth = textPainter.width + 8.0; // 左右のPadding 4 * 2 を加算
      });
    });
  }

  @override
  void dispose() {
    _eFadeController.dispose();
    _titleController.dispose();
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
      color: textGreen.withAlpha((255 * 0.8).round()),
      fontSize: 28.0,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.0,
    );

    List<Widget> innerColumnChildren = [
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
    ];

    // 2. 2番目のキャッチコピー
    if (_line1Finished) {
      innerColumnChildren.add(
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
              if (mounted) {
                setState(() => _line2Finished = true);
                _titleController.forward(); // タイトルタイピングアニメーションを開始
              }
            });
          },
        ),
      );
    }

    innerColumnChildren.add(const SizedBox(height: 35));

    // 3. 【核心演出】Min (e) Diary
    if (_line2Finished) {
      innerColumnChildren.add(
        AnimatedBuilder(
          animation: _titleController,
          builder: (context, child) {
            // Min
            final String minText = 'Min';
            final int minLength = minText.length;
            final double minProgressThreshold = 0.3; // Minが表示されるまでの進捗

            // (e)
            final String eText = '(e)';
            final double eStartWidthAnim = 0.6; // (e)の幅アニメーション開始
            final double eEndWidthAnim = 1.0; // (e)の幅アニメーション終了

            // Diary
            final String diaryText = 'Diary';
            final int diaryLength = diaryText.length;
            final double diaryStartThreshold = 0.3; // Diaryが表示され始める進捗
            final double diaryEndThreshold = 0.6; // Diaryの表示が完了する進捗

            // Min の表示文字数
            int currentMinChars =
                (_titleController.value / minProgressThreshold * minLength)
                    .round()
                    .clamp(0, minLength);
            String displayedMin = minText.substring(0, currentMinChars);

            // (e) の幅の進行度
            double eWidthFactor = 0.0;
            if (_titleController.value >= eStartWidthAnim) {
              eWidthFactor =
                  ((_titleController.value - eStartWidthAnim) /
                          (eEndWidthAnim - eStartWidthAnim))
                      .clamp(0.0, 1.0);
            }

            // Diary の表示文字数
            int currentDiaryChars = 0;
            if (_titleController.value > diaryStartThreshold) {
              currentDiaryChars =
                  ((_titleController.value - diaryStartThreshold) /
                          (diaryEndThreshold - diaryStartThreshold) *
                          diaryLength)
                      .round()
                      .clamp(0, diaryLength);
            }

            final String displayedD = currentDiaryChars > 0 ? 'D' : '';
            final String displayedIary = currentDiaryChars > 1
                ? diaryText.substring(1, currentDiaryChars)
                : '';

            return RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(text: displayedMin, style: mindStyle),
                  TextSpan(text: '', style: mindStyle), // n( の前のスペース
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: SizedBox(
                      width: _eTextWidth * eWidthFactor, // _eTextWidthを使用
                      child: FadeTransition(
                        opacity: _eFadeController, // _eFadeControllerで制御
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ), // ここで窮屈さを解消
                          child: Text(
                            eText,
                            style: mindStyle,
                            softWrap: false, // 絶対に改行させない
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: ' ', style: mindStyle), // ) D の間のスペース
                  TextSpan(text: displayedD, style: mindStyle),
                  TextSpan(text: displayedIary, style: normalDiaryStyle),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // タイトルが出る前の高さをあらかじめ確保（ガタつき防止）
      innerColumnChildren.add(const SizedBox(height: titleFontSize * 1.5));
    }

    innerColumnChildren.add(const SizedBox(height: 40));

    // 4. 診断儀式の説明
    if (_showLastPrompt) {
      innerColumnChildren.add(
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
      );
    }

    innerColumnChildren.add(const SizedBox(height: 20));

    // 5. 最後の問いかけ
    if (_showFinalReadyPrompt) {
      innerColumnChildren.add(
        AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              '準備はよろしいですか？',
              textStyle: finalTextStyle.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              speed: const Duration(milliseconds: 100),
            ),
          ],
          isRepeatingAnimation: false,
          onFinished: widget.onFinished, // 全演出終了の合図
        ),
      );
    }

    return Column(
      children: [
        const Spacer(flex: 3), // 上部の余白
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: innerColumnChildren,
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
              color: const Color(0xFF2E7D32).withAlpha((255 * 0.6).round()),
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
