// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart'; // 日付整形用
import '../main.dart'; // isar
import '../models/diary_entry.dart'; // モデル

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DiaryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _readDiaries();
  }

  // DBから読み込み
  Future<void> _readDiaries() async {
    // isar.diaryEntrys は、Isarの自動生成コードに依存
    // Isarのバージョンによっては isar.diaryEntrys が isar.diaryEntrys になる
    final entries = await isar.diaryEntrys.where().sortByDateDesc().findAll();
    setState(() {
      _entries = entries;
    });
  }

  // スコアごとのアイコン
  String _getMoodIcon(int score) {
    switch (score) {
      case 1:
        return '😫';
      case 2:
        return '😞';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '❓';
    }
  }

  // スコアごとの色
  Color _getMoodColor(int score) {
    switch (score) {
      case 1:
        return Colors.blueGrey;
      case 2:
        return Colors.blueAccent;
      case 3:
        return Colors.green;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.pinkAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ★Scaffoldを外し、AppBarとBodyを直接返すように修正
    return Column(
      // 縦に並べるためにColumnを使用
      children: [
        AppBar(
          title: const Text('これまでの記録'),
          // 履歴/ホームはアプリの顔なので、elevationを調整すると良い
          elevation: 1,
        ),
        Expanded(
          child: _entries.isEmpty
              ? const Center(child: Text('まだ記録がありません'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    final dateStr = DateFormat(
                      'MM/dd(E) HH:mm',
                      'ja', // 'ja' は 'ja_JP' の環境依存を避けるため
                    ).format(entry.date);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        // 感情スコアのアイコン
                        leading: Text(
                          _getMoodIcon(entry.moodScore),
                          style: const TextStyle(fontSize: 32),
                        ),
                        // 日付と時刻
                        title: Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // 投稿本文の先頭を表示 (視認性向上)
                        trailing: SizedBox(
                          width: 150, // 横幅を指定
                          child: Text(
                            entry.content.isNotEmpty
                                ? entry.content.split('\n').first
                                : '(本文なし)',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        // タグリスト
                        subtitle: Wrap(
                          spacing: 4,
                          children: entry.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    // withAlphaで透明度を設定し、警告を避ける
                                    color: _getMoodColor(
                                      entry.moodScore,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getMoodColor(
                                        entry.moodScore,
                                      ).withAlpha(100),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        onTap: () {
                          // TODO: 詳細画面への遷移ロジック
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
