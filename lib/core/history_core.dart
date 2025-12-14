// lib/core/history_core.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:isar/isar.dart';
import '../main.dart'; // isarインスタンスにアクセスするため
import '../models/record.dart';

class HistoryCore with ChangeNotifier {
  // ★★★ 状態管理 ★★★
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Record> _records = [];
  Map<DateTime, List<Record>> _recordsByDay = {};
  
  // 初期化 (コンストラクタ)
  HistoryCore() {
    _selectedDay = _focusedDay;
    fetchRecords();
  }

  // ★★★ Getter ★★★
  CalendarFormat get calendarFormat => _calendarFormat;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  List<Record> get allRecords => _records;
  Map<DateTime, List<Record>> get recordsByDay => _recordsByDay;

  // ★★★ データアクセスと処理ロジック ★★★

  // Isar DBからデータを取得するロジック
  Future<void> fetchRecords() async {
    final allRecords = await isar.records
        .where()
        .build()
        .findAll();

    // 取得後にDartで日付降順ソート
    allRecords.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    
    final Map<DateTime, List<Record>> map = {};
    for (var record in allRecords) {
      // 日付部分のみを取り出してキーとする
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

    _records = allRecords;
    _recordsByDay = map;
    
    notifyListeners();
  }

  // 選択した日の記録リストを返す関数 (カレンダーのドット表示に使用)
  List<Record> getRecordsForDay(DateTime day) {
    // 日付部分のみをキーとして使用
    return _recordsByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }

  // スコアに基づいた色を返す (UIの視覚化ロジック)
  Color getScoreColor(int score) {
    if (score >= 8) return Colors.green.shade600;
    if (score >= 5) return Colors.amber.shade600;
    return Colors.red.shade600;
  }
  
  // ★★★ UIイベントハンドリング ★★★
  
  // 日付選択時のロジック
  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    notifyListeners();
  }

  // カレンダーフォーマット変更時のロジック
  void setCalendarFormat(CalendarFormat format) {
     if (_calendarFormat != format) {
       _calendarFormat = format;
       notifyListeners();
     }
  }

  // カレンダーページ変更時のロジック
  void setFocusedDay(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }
}