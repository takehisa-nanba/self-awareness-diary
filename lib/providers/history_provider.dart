// lib/providers/history_provider.dart
import 'package:flutter/material.dart';
import '../../models/diary_record.dart';
import '../../services/isar_service.dart'; // Isar等のDBサービス

class HistoryProvider with ChangeNotifier {
  final IsarService _isarService = IsarService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  List<DiaryRecord> _allRecords = [];
  List<DiaryRecord> _selectedDayRecords = [];

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  List<DiaryRecord> get selectedDayRecords => _selectedDayRecords;

  HistoryProvider() {
    loadAllRecords(); // 画面が開く準備ができたらすぐに読み込む
  }

  // 初期読み込み
  Future<void> loadAllRecords() async {
    _allRecords = await _isarService.getAllRecords(); 
    
    // ★ここを追加！ そもそも何件DBにあるか確認
    debugPrint("=== DB全件チェック: ${_allRecords.length}件 ===");
    if (_allRecords.isNotEmpty) {
      debugPrint("最新レコードの日付: ${_allRecords.last.recordDate.toLocal()}");
    }
    
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

}