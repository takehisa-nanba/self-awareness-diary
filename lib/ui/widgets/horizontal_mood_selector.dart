// lib/ui/widgets/horizontal_mood_selector.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class HorizontalMoodSelector extends StatefulWidget {
  final int currentMood;
  final ValueChanged<int> onChanged;

  const HorizontalMoodSelector({
    super.key,
    required this.currentMood,
    required this.onChanged,
  });

  @override
  State<HorizontalMoodSelector> createState() => _HorizontalMoodSelectorState();
}

class _HorizontalMoodSelectorState extends State<HorizontalMoodSelector> {
  late ScrollController _scrollController;
  Timer? _debounce;

  static const double _itemWidth = 80.0; // アイテム自体の幅
  static const double _itemMargin = 8.0; // 左右のマージンの合計
  static const double _totalItemWidth = _itemWidth + _itemMargin; // 1アイテムが占める合計幅

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // 初期のスクロール位置を設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(widget.currentMood, animated: false);
    });
  }

  @override
  void didUpdateWidget(HorizontalMoodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMood != widget.currentMood) {
      // 外部から値が変更された場合にスナップさせる
      _scrollToSelected(widget.currentMood, animated: true);
    }
  }
  
  void _onScroll() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      if (!_scrollController.position.isScrollingNotifier.value) {
        final int intendedIndex = (_scrollController.offset / _totalItemWidth).round();
        final int newMood = max(1, min(10, intendedIndex + 1));
        
        if (newMood != widget.currentMood) {
          widget.onChanged(newMood);
        } else {
          _scrollToSelected(widget.currentMood, animated: true);
        }
      }
    });
  }

  void _scrollToSelected(int mood, {required bool animated}) {
    final double targetOffset = (mood - 1) * _totalItemWidth;
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 50), // ズレ防止のため短い時間を設定
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
        final double horizontalPadding = (constraints.maxWidth / 2) - (_totalItemWidth / 2);
        
        final Color primaryColor = Theme.of(context).colorScheme.primary;
        final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

        return SizedBox(
          height: 120, // 高さを少し増やす
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemBuilder: (context, index) {
              final score = index + 1;
              final distance = (score - widget.currentMood).abs();

              const double maxSize = 80.0; // 最大サイズ
              const double minSize = 20.0; // 最小サイズ 
              const double jumpRate = 7.5; // サイズ変化の速さ調整用
              final double size = max(minSize, maxSize - distance * jumpRate);

              final Color color = Color.lerp(primaryColor, onSurfaceColor.withAlpha(153), distance / 5.0) ?? onSurfaceColor;
              final double fontSize = max(12.0, 24.0 - distance * 3.0);
              final FontWeight fontWeight = distance == 0 ? FontWeight.bold : FontWeight.normal;

              return GestureDetector(
                onTap: () => widget.onChanged(score),
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
                      color: distance == 0 ? primaryColor.withAlpha(26) : Colors.transparent,
                      border: Border.all(color: color.withAlpha(128), width: 2),
                      boxShadow: distance == 0 ? [
                        BoxShadow(
                          color: primaryColor.withAlpha(77),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ] : [],
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
