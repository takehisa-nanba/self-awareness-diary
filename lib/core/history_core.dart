// lib/core/history_core.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> selectSpecificDate(BuildContext context) async {
    DateTime tempDate = _focusedDay;

    // 1. 年を選択するダイアログを表示
    final int? selectedYear = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('年を選択'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              selectedDate: tempDate,
              onChanged: (DateTime dateTime) {
                Navigator.pop(context, dateTime.year);
              },
            ),
          ),
        );
      },
    );

    if (selectedYear == null) return;

    // 2. 月を選択するダイアログを表示
    if (context.mounted) {
      final int? selectedMonth = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('$selectedYear年 - 月を選択'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3列で表示
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  return InkWell(
                    onTap: () => Navigator.pop(context, month),
                    child: Center(
                      child: Text(
                        '$month月',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedMonth != null) {
        // 3. 状態を更新
        _focusedDay = DateTime(selectedYear, selectedMonth, 1);
        _selectedDay = _focusedDay;
        _calendarFormat = CalendarFormat.month;
        
        notifyListeners();
      }
    }
  }
  void toggleCalendarFormat() {
    if (kDebugMode) {
      print('Current Format: $_calendarFormat');
    }
    
    // ★★★ 修正箇所: twoWeeksをスキップするロジックに変更 ★★★
    if (_calendarFormat == CalendarFormat.month) {
      _calendarFormat = CalendarFormat.week;
    } else if (_calendarFormat == CalendarFormat.week) {
      // 週表示の次を月表示に戻すことで、2weeks表示をスキップ
      _calendarFormat = CalendarFormat.month;
    } 
    // CalendarFormat.twoWeeks の場合は、意図的にこの分岐に入らないようにします
    // これで、月表示 <-> 週表示 のトグルになります。

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

  // 記録削除ロジック
  Future<void> deleteRecord(int id) async {
    await isar.writeTxn(() async {
      await isar.records.delete(id); // IDを指定して削除
    });
    
    // 削除後、一覧を再読み込みして画面を更新
    await fetchRecords();
  }
}