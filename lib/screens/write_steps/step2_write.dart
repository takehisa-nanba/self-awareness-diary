// lib/screens/write_steps/step2_write.dart (最新版)

import 'package:flutter/material.dart';

class Step2WriteScreen extends StatelessWidget {
  final int moodScore;
  final TextEditingController eventController;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onContentChanged;

  const Step2WriteScreen({
    super.key,
    required this.moodScore,
    required this.eventController,
    required this.onScoreChanged,
    required this.onContentChanged,
  });

  // ★★★ 1. スコアに基づいて背景色を計算するロジック ★★★
  Color _getScoreColor(int score) {
    // 範囲を1から10に固定
    final clampedScore = score.clamp(1, 10);

    // スコア5（アンバー）を基準に、赤と緑に分ける
    if (clampedScore <= 5) {
      // 1 (濃赤) から 5 (濃アンバー) へのグラデーション
      final t = (clampedScore - 1) / 4.0;
      return Color.lerp(Colors.red.shade700, Colors.amber.shade700, t)!;
    } else {
      // 6 (濃アンバー) から 10 (濃緑) へのグラデーション
      // tは0.0 (スコア6) から 1.0 (スコア10) に変化
      final t = (clampedScore - 5) / 5.0;
      // 濃アンバーと濃緑の間で補間する
      return Color.lerp(Colors.amber.shade700, Colors.green.shade700, t)!;
    }
  }

  // ★★★ 2. スコアに基づいて文字色を決定するロジック（コントラスト確保） ★★★
  Color _getTextColor(int score) {
    // スコア 4〜7 の中間色（濃い黄色/アンバー）は黒文字で見やすくする
    if (score >= 4 && score <= 7) {
      return Colors.black;
    }
    // それ以外（濃赤、濃緑）は白文字にする
    return Colors.white;
  }

  // ★★★ 3. スコアに基づいて感情ワードを返すロジック ★★★
  String _getMoodWord(int score) {
    if (score >= 9) return '[最高] / [歓喜]';
    if (score >= 7) return '[満足] / [良好]';
    if (score == 6) return '[ニュートラル] / [普通]';
    if (score == 5) return '【モヤっとする】 / [曖昧]'; // 要件に合わせた最重要ポイント
    if (score >= 3) return '[不調] / [不安]';
    return '[最悪] / [絶望]';
  }

  @override
  Widget build(BuildContext context) {
    // 選択されたスコアに基づいて色と文字色を決定
    final displayColor = _getScoreColor(moodScore);
    final displayTextColor = _getTextColor(moodScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           // 気分スコア表示エリア
          Card(
            color: displayColor, // ★★★ 色をスコアと連動 ★★★
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              child: Column(
                children: [
                  Text(
                    '今の気分スコアを選択してください',
                    style: TextStyle(
                      fontSize: 16,
                      color: displayTextColor, // ★★★ 文字色をスコアと連動 ★★★
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$moodScore / 10',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: displayTextColor, // ★★★ 文字色をスコアと連動 ★★★
                    ),
                  ),
                  Text(
                    _getMoodWord(moodScore), // ★★★ 感情ワードを表示 ★★★
                    style: TextStyle(
                      fontSize: 18,
                      color: displayTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

         // 2. スコア選択ボタンエリア
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: List.generate(10, (index) {
              final score = index + 1;
              return RawMaterialButton(
                onPressed: () => onScoreChanged(score),
                elevation: 2.0,
                fillColor: _getScoreColor(score), // 各ボタンも色を付ける
                padding: const EdgeInsets.all(12.0),
                shape: const CircleBorder(),
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                child: Text(
                  score.toString(),
                  style: TextStyle(
                    color: _getTextColor(score),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 30),

          // 出来事入力セクション
          const Text(
            '【出来事】何がトリガーでしたか？',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: eventController,
            onChanged: (text) => onContentChanged(),
            maxLines: 1,
            decoration: const InputDecoration(
              hintText: '例: プロジェクトの締め切りが近づいている。上司に褒められた。',
              border: OutlineInputBorder(),
            ),
          ),

          // 3. 出来事の入力エリア
        ],
      ),
    );
  }
}
