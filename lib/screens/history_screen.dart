// lib/screens/history_screen.dart (最終修正版)

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // ★★★ TableCalendarのインポート ★★★
import 'package:isar/isar.dart';
import '../main.dart'; // isarインスタンスにアクセスするため
import '../models/record.dart';
// HistoryDetailScreenのインポートが正しいか確認
import 'history_detail_screen.dart'; // ★★★ history_detail_screen.dart ファイルが存在することを前提とします ★★★

// TableCalendarの isSameDay を利用できるようにする
// import 'package:table_calendar/table_calendar.dart' があれば通常は不要
// もしエラーが出た場合、isSameDay の代わりに Dart のDateTime比較を使うか、
// TableCalendarを as でインポートしていないか確認してください。

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // カレンダーの状態管理
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 記録データを保持するリスト
  List<Record> _records = [];
  Map<DateTime, List<Record>> _recordsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchRecords();
  }

  // Isar DBからデータを取得するロジック
  Future<void> _fetchRecords() async {
    // ★★★ 修正1: Isarクエリをソートとフィルタリングで構築（sortByRecordDateDescの代替） ★★★
    final allRecords = await isar.records
        .where()
        .build()
        .findAll(); // findAllで全件取得

    // ★★★ 修正2: 取得後にDartで日付降順ソートを行う ★★★
    allRecords.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    
    // ... (Map構築ロジックはそのまま) ...
    final Map<DateTime, List<Record>> map = {};
    for (var record in allRecords) {
      final day = DateTime(
        record.recordDate.year,
        record.recordDate.month,
        record.recordDate.day,
      );
      if (map[day] == null) {
        map[day] = [];
      }
      map[day]!.add(record);
    }

    setState(() {
      _records = allRecords;
      _recordsByDay = map;
    });
  }

  // 選択した日の記録リストを返す関数 (カレンダーのドット表示に使用)
  List<Record> _getRecordsForDay(DateTime day) {
    return _recordsByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }

  // スコアに基づいた色を返す (UIの視覚化 F-5)
  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green.shade600;
    if (score >= 5) return Colors.amber.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    // 選択された日の記録リストをフィルタリング
    final List<Record> selectedDayRecords = _records.where((record) {
      if (_selectedDay == null) return true;
      // TableCalendarのisSameDayヘルパーを使用
      return isSameDay(record.recordDate, _selectedDay!);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('履歴を見る'), elevation: 1),
      body: Column(
        children: [
          // 1. カレンダーウィジェット (F-5: カレンダー機能)
          TableCalendar(
            locale: 'ja_JP',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            eventLoader: _getRecordsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  // ★★★ 修正3: Null Safety対応と型キャストはそのまま ★★★
                  final recordList = events.cast<Record>();
                  final avgScore =
                      recordList
                          .map((e) => e.moodScore)
                          .reduce((a, b) => a + b) /
                      recordList.length;
                  final markerColor = _getScoreColor(avgScore.round());

                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),

            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),

          const SizedBox(height: 8.0),

          // 2. タイムライン表示エリア (F-5: タイムライン)
          Expanded(
            child: selectedDayRecords.isEmpty
                ? Center(
                    child: Text(
                      _selectedDay != null &&
                              isSameDay(_selectedDay!, DateTime.now())
                          ? '今日の記録はありません'
                          : (_selectedDay != null
                              ? '${_selectedDay!.month}/${_selectedDay!.day} の記録はありません'
                              : '日付を選択してください'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedDayRecords.length,
                    itemBuilder: (context, index) {
                      final record = selectedDayRecords[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getScoreColor(record.moodScore),
                          child: Text(
                            record.moodScore.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(record.eventText),
                        subtitle: Text(
                          'タグ: ${record.moodTags.join(', ')} | ${record.weather} | ${record.location.split(',').first}',
                        ),
                        // ★★★ 修正2: onTapは既に修正済みなのでそのまま ★★★
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  HistoryDetailScreen(record: record),
                            ),
                          );
                          _fetchRecords(); // 詳細画面から戻ったらデータを再取得
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}