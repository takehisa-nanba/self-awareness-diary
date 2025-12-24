// lib/providers/history_provider.dart
import 'package:flutter/material.dart';
import '../../models/diary_record.dart';
import '../../services/isar_service.dart'; // Isar等のDBサービス

class HistoryProvider with ChangeNotifier {
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  List<DiaryRecord> _allRecords = [];
  List<DiaryRecord> _selectedDayRecords = [];

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  List<DiaryRecord> get selectedDayRecords => _selectedDayRecords;

  HistoryProvider() {
    // コンストラクタで直接呼ばず、初期化完了を待つメソッドを呼ぶ
    _initialize();
  }

  Future<void> _initialize() async {
    // main.dart の init() が終わるのを待つための安全策
    // もし isarService.isar が未初期化なら、一瞬待機する
    try {
      await isarService.init(); 
      await loadAllRecords();
    } catch (e) {
      debugPrint("HistoryProvider初期化エラー: $e");
    }
  }

  // 初期読み込み
  Future<void> loadAllRecords() async {
    // DBから全件取得
    _allRecords = await isarService.getAllRecords(); 
    
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

  // 選択された日のデータだけを抽出するロジック
  // lib/providers/history_provider.dart

  void _filterRecords() {
    if (_selectedDay == null) {
      _selectedDayRecords = _allRecords;
    } else {
      // 選択された日をローカル時間に変換
      final s = _selectedDay!.toLocal();
      
      _selectedDayRecords = _allRecords.where((record) {
        // 保存されたデータもローカル時間に変換して比較
        final r = record.recordDate.toLocal();
        
        return r.year == s.year && 
               r.month == s.month && 
               r.day == s.day;
      }).toList();
    }
    debugPrint("【判定終了】選択日(Local): ${_selectedDay?.toLocal()} / 表示対象: ${_selectedDayRecords.length}件");
  }

  Future<void> refreshHistory() async {
  // Isarから最新のデータを取ってきて、リストを更新する
  _allRecords = await isarService.getAllRecords(); 
  _filterRecords();
  notifyListeners(); // ← これが「画面を書き換えろ！」という合図です
  }
  
}