// lib/ui/widgets/horizontal_mood_selector.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// ユーザーが水平方向にスクロールして気分のスコアを選択できるウィジェット。
///
/// 選択されたスコアは中央に表示され、視覚的に強調されます。
class HorizontalMoodSelector extends StatefulWidget {
  /// 現在選択されている気分のスコア（1から10の範囲）。
  final int currentMood;

  /// 気分のスコアが変更されたときに呼び出されるコールバック。
  final ValueChanged<int> onChanged;

  const HorizontalMoodSelector({
    super.key,
    required this.currentMood,
    required this.onChanged,
  });

  @override
  State<HorizontalMoodSelector> createState() => _HorizontalMoodSelectorState();
}

/// [HorizontalMoodSelector] の状態を管理するクラス。
///
/// スクロール位置の制御、アニメーション、デバウンス処理などを担当します。
class _HorizontalMoodSelectorState extends State<HorizontalMoodSelector> {
  late ScrollController _scrollController;
  Timer? _debounce;

  static const double _itemWidth = 80.0;
  static const double _itemMargin = 8.0;
  static const double _totalItemWidth = _itemWidth + _itemMargin;

  /// 気分スコアに基づいてグラデーションカラーを生成します。
  ///
  /// スコアが低い場合は赤に近く、高い場合は緑に近くなります。
  Color _getMoodColor(int score) {
    final double t = (score - 1) / 9; // スコア1-10を0-1に正規化

    if (t < 0.5) {
      return Color.lerp(Colors.red, Colors.yellow, t * 2) ?? Colors.red;
    } else {
      return Color.lerp(Colors.yellow, Colors.green, (t - 0.5) * 2) ??
          Colors.green;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // ウィジェットがビルドされた後に初期選択項目へスクロール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(widget.currentMood, animated: false);
    });
  }

  @override
  void didUpdateWidget(HorizontalMoodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // currentMoodが変更された場合にアニメーション付きでスクロール
    if (oldWidget.currentMood != widget.currentMood) {
      _scrollToSelected(widget.currentMood, animated: true);
    }
  }

  /// スクロールイベントを処理し、スクロール停止後に選択項目を更新します。
  void _onScroll() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      // スクロールが完全に停止した場合のみ処理
      if (!_scrollController.position.isScrollingNotifier.value) {
        final int intendedIndex = (_scrollController.offset / _totalItemWidth)
            .round();
        final int newMood = max(1, min(10, intendedIndex + 1));

        // 新しい気分が異なる場合のみコールバックを呼び出し
        if (newMood != widget.currentMood) {
          widget.onChanged(newMood);
        } else {
          // スクロールが選択項目の中央にない場合、中央に合わせる
          _scrollToSelected(widget.currentMood, animated: true);
        }
      }
    });
  }

  /// 指定された気分スコアの項目へスクロールします。
  ///
  /// [mood] スクロール先の気分スコア。
  /// [animated] スクロールをアニメーションさせるかどうか。
  void _scrollToSelected(int mood, {required bool animated}) {
    final double targetOffset = (mood - 1) * _totalItemWidth;
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOutQuart,
        );
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 選択項目を中央に配置するためのパディングを計算
        final double horizontalPadding =
            (constraints.maxWidth / 2) - (_totalItemWidth / 2);

        return SizedBox(
          height: 120,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal, // 水平スクロール
            itemCount: 10, // スコア1から10まで
            padding: EdgeInsets.symmetric(
              horizontal: max(0.0, horizontalPadding),
            ),
            itemBuilder: (context, index) {
              final score = index + 1; // 1から10のスコア
              final distance = (score - widget.currentMood).abs(); // 中央からの距離

              const double maxSize = 80.0;
              const double minSize = 20.0;
              const double jumpRate = 7.5;
              // 距離に応じてサイズを計算（中央に近いほど大きい）
              final double size = max(minSize, maxSize - distance * jumpRate);

              final Color scoreBaseColor = _getMoodColor(score);
              // 距離に応じて色を薄くする
              final Color color =
                  Color.lerp(
                    scoreBaseColor,
                    scoreBaseColor.withAlpha(0),
                    distance / 3.0,
                  ) ??
                  scoreBaseColor;
              // 距離に応じてフォントサイズを調整
              final double fontSize = max(12.0, 24.0 - distance * 3.0);
              // 中央の項目は太字
              final FontWeight fontWeight = distance == 0
                  ? FontWeight.bold
                  : FontWeight.normal;

              return GestureDetector(
                onTap: () => widget.onChanged(score), // タップでスコアを選択
                child: Container(
                  width: _totalItemWidth,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOut,
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: distance == 0
                          ? _getMoodColor(widget.currentMood).withAlpha(
                              26,
                            ) // 選択項目は背景色を薄く
                          : Colors.transparent,
                      border: Border.all(
                        color: scoreBaseColor.withAlpha(128),
                        width: 2,
                      ),
                      // 選択項目はシャドウで強調
                      boxShadow: distance == 0
                          ? [
                              BoxShadow(
                                color: _getMoodColor(
                                  widget.currentMood,
                                ).withAlpha(77),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
