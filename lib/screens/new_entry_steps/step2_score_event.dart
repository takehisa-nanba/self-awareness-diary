// lib/screens/new_entry_steps/step2_score_event.dart (修正後)

import 'package:flutter/material.dart';

class Step2ScoreEventScreen extends StatelessWidget {
  final int moodScore;
  final Function(int) onScoreChanged;
  final TextEditingController eventController;
  final VoidCallback onContentChanged;

  const Step2ScoreEventScreen({
    super.key,
    required this.moodScore,
    required this.onScoreChanged,
    required this.eventController,
    required this.onContentChanged,
  });

  // ★★★ 修正箇所1: スコアに基づく色を取得 (赤 → 黄 → 緑のグラデーション) ★★★
  Color _getScoreColor(int score) {
    // スコアを1から10の間に固定
    final clampedScore = score.clamp(1, 10);

    if (clampedScore <= 5) {
      // 1 (赤) から 5 (黄色) へのグラデーション
      final t = (clampedScore - 1) / 4.0; // tは0.0から1.0に変化
      // DarkRedからAmberへ補間
      return Color.lerp(Colors.red.shade700, Colors.amber.shade700, t)!;
    } else {
      // 6 (黄色) から 10 (緑) へのグラデーション
      // 5と6の間にギャップが生じないよう、補間開始を調整
      final t = (clampedScore - 5) / 5.0; // tは0.0から1.0に変化
      // AmberからGreenへ補間
      return Color.lerp(Colors.amber.shade700, Colors.green.shade700, t)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color displayColor = moodScore > 0
        ? _getScoreColor(moodScore)
        : Colors.grey;

    // スコアボタンのサイズ定義
    const unselectedSize = 30.0;
    const selectedSize = 45.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2-1. スコア評価 (10段階)
          const Text(
            'Step 2-1. 今の気分を10段階で評価してください',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Center(
            // ★★★ 修正箇所2: WrapからRowに変更し、1行表示にする ★★★
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (index) {
                final score = index + 1;
                final isSelected = score == moodScore;

                return GestureDetector(
                  onTap: () => onScoreChanged(score),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    // ★★★ 修正箇所3: サイズを調整して1行に収める ★★★
                    height: isSelected ? selectedSize : unselectedSize,
                    width: isSelected ? selectedSize : unselectedSize,

                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getScoreColor(score)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _getScoreColor(score).withAlpha(153),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      score.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: isSelected ? 18 : 14, // フォントサイズも調整
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              moodScore > 0 ? '評価スコア: $moodScore / 10' : 'スコアを選択してください',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 2-2. 出来事入力
          const Text(
            'Step 2-2. 感情を引き起こした出来事を簡潔に',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (_) => onContentChanged(),
            controller: eventController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例：〇〇プロジェクトが完了した など',
            ),
          ),
        ],
      ),
    );
  }
}
