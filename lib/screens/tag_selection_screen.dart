import 'package:flutter/material.dart';
import 'package:isar/isar.dart'; // DBを使うための道具
import '../main.dart'; // isar変数をもらう
import '../models/diary_entry.dart'; // データの設計図

class TagSelectionScreen extends StatefulWidget {
  final int moodScore;
  const TagSelectionScreen({super.key, required this.moodScore});

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  final Set<String> _selectedTags = {};

  // 感情に応じたタグ候補（ロジック）
  List<String> get _tagCandidates {
    if (widget.moodScore >= 4) {
      return [
        '🏆 達成感・成長',
        '🤝 つながり・感謝',
        '🛌 安らぎ・回復',
        '🎨 没頭',
        '🛡️ 安心',
        '🍽️ 快楽',
      ];
    } else if (widget.moodScore <= 2) {
      return ['💔 孤独', '😡 自尊心', '😰 不安', '🔋 疲れ', '⛓️ 不自由', '🌫️ 混乱'];
    } else {
      return ['💼 仕事', '💬 人間関係', '🏥 健康', '💰 お金', '🎮 趣味', '☕ 休憩'];
    }
  }

  // ★データベースに保存する関数
  Future<void> _saveDiary() async {
    // 1. データを作る
    final newEntry = DiaryEntry(
      date: DateTime.now(), // 今の時間
      moodScore: widget.moodScore,
      tags: _selectedTags.toList(), // セットをリストに変換
      content: '', // 本文は一旦空で
    );

    // 2. 金庫に入れて鍵をかける（保存）
    await isar.writeTxn(() async {
      await isar.diaryEntrys.put(newEntry);
    });

    // 3. ユーザーに報告
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ 日記を保存しました！')));
      // 最初の画面に戻る
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('その感情の正体は？')),
      body: SingleChildScrollView(
        // 画面が小さくてもスクロール可能に
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              '何がその気分を作りましたか？\n(複数選択可)',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // タグ一覧
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _tagCandidates.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(
                      () => val
                          ? _selectedTags.add(tag)
                          : _selectedTags.remove(tag),
                    );
                  },
                  selectedColor: Colors.indigo.shade100,
                  checkmarkColor: Colors.indigo,
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // ★ここに保存ボタンがあります！
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  if (_selectedTags.isEmpty) {
                    // タグがない時に警告を出す
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ 理由を1つ以上選んでください'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  _saveDiary(); // 保存処理へ
                },
                icon: const Icon(Icons.check),
                label: const Text(
                  'これで記録する',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
