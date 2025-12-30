// lib/providers/history_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/diary_record.dart';
import '../../domain/repositories/diary_repository.dart';

/// 履歴画面のデータと状態を管理するプロバイダークラス。
///
/// 日記レコードの読み込み、日付選択、カレンダー表示形式の制御、
/// および選択された日の記録のフィルタリングなどを担当します。
class HistoryProvider with ChangeNotifier {
  final DiaryRepository _diaryRepository;

  /// [HistoryProvider] のコンストラクタ。
  ///
  /// 依存する [DiaryRepository] を受け取り、初期化処理を行います。
  HistoryProvider(this._diaryRepository) {
    _initialize();
  }

  // --- 内部状態 ---
  /// すべての日記レコードのリスト。
  List<DiaryRecord> _allRecords = [];

  /// カレンダーで現在選択されている日付。
  DateTime _selectedDay = DateTime.now();

  /// カレンダーで現在フォーカスされている日付。
  DateTime _focusedDay = DateTime.now();

  /// カレンダーの表示形式（月、週など）。
  CalendarFormat _calendarFormat = CalendarFormat.month;

  /// 選択された日付の日記レコードのリスト。
  List<DiaryRecord> _selectedDayRecords = [];

  // --- UI公開ゲッター ---
  /// すべての日記レコードのリストを返します。
  List<DiaryRecord> get allRecords => _allRecords;

  /// カレンダーで現在選択されている日付を返します。
  DateTime get selectedDay => _selectedDay;

  /// カレンダーで現在フォーカスされている日付を返します。
  DateTime get focusedDay => _focusedDay;

  /// カレンダーの現在の表示形式を返します。
  CalendarFormat get calendarFormat => _calendarFormat;

  /// 選択された日付の日記レコードのリストを返します。
  List<DiaryRecord> get selectedDayRecords => _selectedDayRecords;

  /// カレンダーの表示形式を設定し、UIを更新します。
  ///
  /// [format] 設定する新しいカレンダーの表示形式。
  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  /// プロバイダの初期化処理。
  ///
  /// すべての日記レコードの読み込みを開始します。
  Future<void> _initialize() async {
    await loadAllRecords();
  }

  /// データベースからすべてのレコードを読み込み、状態を更新します。
  Future<void> loadAllRecords() async {
    _allRecords = await _diaryRepository.getAllRecords();
    debugPrint("=== DB全件チェック: ${_allRecords.length}件 ===");
    _filterRecords(); // 全レコード読み込み後に選択日のレコードをフィルタリング
    notifyListeners();
  }

  /// カレンダーの日付が選択されたときに呼び出される処理。
  ///
  /// [selectedDay] ユーザーが選択した日付。
  /// [focusedDay] 現在フォーカスされている日付（通常は選択された日付）。
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    _filterRecords(); // 選択日が変わったのでレコードを再フィルタリング
    notifyListeners();
  }

  /// 特定の日付にカレンダーの表示と選択を移動させます。
  ///
  /// [date] 移動先の特定の日付。
  void jumpToDate(DateTime date) {
    _selectedDay = date;
    _focusedDay = date;
    _filterRecords();
    notifyListeners();
  }

  /// カレンダーにイベント（記録のある日）として表示するためのデータを返します。
  ///
  /// [day] イベントの有無を確認する対象の日。
  List<DiaryRecord> getEventsForDay(DateTime day) {
    final d = day.toLocal(); // ローカルタイムに変換
    return _allRecords.where((record) {
      final r = record.recordDate.toLocal(); // ローカルタイムに変換
      return r.year == d.year && r.month == d.month && r.day == d.day;
    }).toList();
  }

  /// `_allRecords` から `_selectedDay` に一致するレコードをフィルタリングし、
  /// `_selectedDayRecords` を更新します。
  void _filterRecords() {
    final s = _selectedDay.toLocal(); // 選択日をローカルタイムに変換
    _selectedDayRecords = _allRecords.where((record) {
      final r = record.recordDate.toLocal(); // レコードの日付をローカルタイムに変換
      return r.year == s.year && r.month == s.month && r.day == s.day;
    }).toList();

    debugPrint(
      "【判定終了】選択日(Local): ${_selectedDay.toLocal()} / 表示対象: ${_selectedDayRecords.length}件",
    );
  }

  /// データベースから最新の履歴データを再読み込みし、UIを更新します。
  Future<void> refreshHistory() async {
    _allRecords = await _diaryRepository.getAllRecords();
    _filterRecords();
    notifyListeners();
  }
}
