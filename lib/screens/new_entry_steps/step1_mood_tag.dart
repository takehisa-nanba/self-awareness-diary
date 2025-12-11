// lib/screens/new_entry_steps/step1_mood_tag.dart

import 'package:flutter/material.dart';

// 外部から必要なデータとコールバックを受け取るためのStatelessWidget
class Step1MoodTagScreen extends StatelessWidget {
  final Set<String> selectedTags; // 現在選択されているタグ
  final Function(String tag) onTagSelected; // タグがタップされたときの処理

  const Step1MoodTagScreen({
    super.key,
    required this.selectedTags,
    required this.onTagSelected,
  });

  static const List<String> _moodTags = [
    '楽しい',
    '落ち着いている',
    '集中',
    '達成感',
    'フラット',
    '退屈',
    'イライラ',
    '不安',
    '悲しい',
    '疲労',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1. 今の気分に合うタグを選択してください',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            '（複数選択可。最低1つ選択してください。）',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _moodTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return ActionChip(
                label: Text(tag),
                backgroundColor: isSelected
                    // ignore: deprecated_member_use
                    ? Theme.of(context).primaryColor.withAlpha(25)
                    : Colors.grey.shade100,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                onPressed: () => onTagSelected(tag), // 親ウィジェットのコールバックを呼び出す
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
