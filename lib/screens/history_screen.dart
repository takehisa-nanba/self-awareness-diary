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
    final entries = await isar.diaryEntrys.where().sortByDateDesc().findAll();
    setState(() {
      _entries = entries;
    });
  }

  // スコアごとのアイコン
  String _getMoodIcon(int score) {
    switch (score) {
      case 1: return '😫';
      case 2: return '😞';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '❓';
    }
  }

  // スコアごとの色
  Color _getMoodColor(int score) {
    switch (score) {
      case 1: return Colors.blueGrey;
      case 2: return Colors.blueAccent;
      case 3: return Colors.green;
      case 4: return Colors.orange;
      case 5: return Colors.pinkAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('これまでの記録')),
      body: _entries.isEmpty
          ? const Center(child: Text('まだ記録がありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final dateStr = DateFormat('MM/dd(E) HH:mm', 'ja').format(entry.date);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Text(
                      _getMoodIcon(entry.moodScore),
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(
                      dateStr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Wrap(
                      spacing: 4,
                      children: entry.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getMoodColor(entry.moodScore).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getMoodColor(entry.moodScore).withOpacity(0.3)),
                        ),
                        child: Text(tag, style: const TextStyle(fontSize: 10)),
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}