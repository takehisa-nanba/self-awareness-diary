// lib/providers/history_provider.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/diary_record.dart';
import '../../domain/repositories/diary_repository.dart';

class HistoryProvider with ChangeNotifier {
  final DiaryRepository _diaryRepository;

  HistoryProvider(this._diaryRepository) {
    _initialize();
  }

  // --- 内部状態 ---
  List<DiaryRecord> _allRecords = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<DiaryRecord> _selectedDayRecords = []; // 選択された日のレコードリスト

  // --- UIへの公開ゲッター ---
  List<DiaryRecord> get allRecords => _allRecords;
  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;
  CalendarFormat get calendarFormat => _calendarFormat;
  List<DiaryRecord> get selectedDayRecords => _selectedDayRecords;

  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  Future<void> _initialize() async {
    await loadAllRecords();
  }

  // 初期読み込み
  Future<void> loadAllRecords() async {
    // DBから全件取得
    _allRecords = await _diaryRepository.getAllRecords();

    debugPrint("=== DB全件チェック: ${_allRecords.length}件 ===");

    _filterRecords();
    notifyListeners();
  }

  // 日付が選択された時のロジック
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    _filterRecords();
    notifyListeners();
  }

  // 特定の日付にジャンプする
  void jumpToDate(DateTime date) {
    _selectedDay = date;
    _focusedDay = date;
    _filterRecords();
    notifyListeners();
  }

  // カレンダーに表示するイベント（ドット）を返す
  List<DiaryRecord> getEventsForDay(DateTime day) {
    final d = day.toLocal();
    return _allRecords.where((record) {
      final r = record.recordDate.toLocal();
      return r.year == d.year && r.month == d.month && r.day == d.day;
    }).toList();
  }

  // 選択された日のデータだけを抽出するロジック
  // lib/providers/history_provider.dart

  void _filterRecords() {
    // 選択された日をローカル時間に変換
    final s = _selectedDay.toLocal();

    _selectedDayRecords = _allRecords.where((record) {
      // 保存されたデータもローカル時間に変換して比較
      final r = record.recordDate.toLocal();

      return r.year == s.year && r.month == s.month && r.day == s.day;
    }).toList();

    debugPrint(
      "【判定終了】選択日(Local): ${_selectedDay.toLocal()} / 表示対象: ${_selectedDayRecords.length}件",
    );
  }

  Future<void> refreshHistory() async {
    // Isarから最新のデータを取ってきて、リストを更新する
    _allRecords = await _diaryRepository.getAllRecords();
    _filterRecords();
    notifyListeners(); // ← これが「画面を書き換えろ！」という合図です
  }
}
