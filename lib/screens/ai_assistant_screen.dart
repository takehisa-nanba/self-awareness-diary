// lib/screens/ai_assistant_screen.dart

import 'package:flutter/material.dart';

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面の構造を定義
    return Column(
      children: [
        // 1. AppBar (画面上部のタイトルバー)
        AppBar(title: const Text('AIアシスト・分析'), elevation: 1),

        // 2. Body (画面本体)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // F-13: プレミアムプラン限定の指標（ダミー）
                const Text(
                  '# 自己覚知度インデックス',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '【プレミアム限定】あなたの感情パターンと行動の一致度を測定します。',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // F-9: 無料ユーザーへの価値提供と制限の提示
                const Text(
                  '💡 AIによる日次評価・月次分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '無料ユーザー様は広告視聴により、日次・月次の簡易評価をご利用いただけます。',
                  style: TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 24),

                // 課金プランへの誘導 (F-10)
                ElevatedButton(
                  onPressed: () {
                    // TODO: 課金プランの比較画面へ遷移
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // ボタンを横幅いっぱいに
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    '有料プランで無制限分析を解放する',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
