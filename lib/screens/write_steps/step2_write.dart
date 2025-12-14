// lib/screens/write_steps/step2_write.dart

import 'package:flutter/material.dart';

class Step2WriteScreen extends StatelessWidget {
  final double moodScore;
  final TextEditingController eventController;
  final void Function(int) onScoreChanged;
  final VoidCallback onContentChanged;

  const Step2WriteScreen({
    super.key,
    required this.moodScore,
    required this.eventController,
    required this.onScoreChanged,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 気分スコアの入力
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '【気分スコア】現在の気分は？',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              
              // ★★★ 修正1: Slider を再導入 ★★★
              Slider(
                value: moodScore,
                min: 1,
                max: 10,
                divisions: 9,
                label: moodScore.round().toString(),
                onChanged: (double value) {
                  onScoreChanged(value.round());
                },
              ),

              // ★★★ 修正2: 中央のスコア表示を再導入 ★★★
              Center(
                child: Text(
                  'スコア: ${moodScore.round()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 30),

        // 2. 出来事の入力
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RichTextに置き換え、アスタリスクを赤くする
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: const <TextSpan>[
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                      text: '【出来事】何をしましたか？',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: eventController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '例：友人とのランチ、新しいタスクの開始、休憩など',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12.0),
                ),
                onChanged: (_) => onContentChanged(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}