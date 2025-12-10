// lib/screens/mood_selector_screen.dart

import 'package:flutter/material.dart';
import 'tag_selection_screen.dart'; // 次の画面へのリンク

class MoodSelectorScreen extends StatefulWidget {
  const MoodSelectorScreen({super.key});

  @override
  State<MoodSelectorScreen> createState() => _MoodSelectorScreenState();
}

class _MoodSelectorScreenState extends State<MoodSelectorScreen> {
  int _currentMood = 3; // デフォルトは「普通」

  // 気分データ
  final List<Map<String, dynamic>> _moodOptions = [
    {'score': 1, 'icon': '😫', 'label': '最悪', 'color': Colors.blueGrey},
    {'score': 2, 'icon': '😞', 'label': '悪い', 'color': Colors.blueAccent},
    {'score': 3, 'icon': '😐', 'label': '普通', 'color': Colors.green},
    {'score': 4, 'icon': '🙂', 'label': '良い', 'color': Colors.orange},
    {'score': 5, 'icon': '😄', 'label': '最高', 'color': Colors.pinkAccent},
  ];

  // ▼▼▼ ここから下が抜けていた可能性が高い部分です ▼▼▼
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今の気分は？')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 顔アイコンリスト
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moodOptions.map((option) {
                final isSelected = _currentMood == option['score'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentMood = option['score']);
                  },
                  child: Column(
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.4 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(option['icon'], style: const TextStyle(fontSize: 45)),
                      ),
                      const SizedBox(height: 10),
                      if (isSelected)
                        Text(option['label'],
                            style: TextStyle(
                                color: option['color'], fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 50),
            
            // 次へボタン
            ElevatedButton.icon(
              onPressed: () {
                // 次の画面（タグ選択）へ移動し、選んだスコアを渡す
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TagSelectionScreen(moodScore: _currentMood),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('深掘りする'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            ),
          ],
        ),
      ),
    );
  }
}