import 'package:flutter/material.dart';
import '../models/diary_record.dart';
import '../services/isar_service.dart';

class HistoryProvider with ChangeNotifier {
  List<DiaryRecord> _records = [];
  List<DiaryRecord> get records => _records;

  HistoryProvider() {
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    _records = await isarService.getAllRecords();
    notifyListeners();
  }

  Future<void> loadRecords() async {
    _records = await isarService.getAllRecords();
    notifyListeners(); // 画面を更新！
  } 
  Future<void> deleteRecord(int id) async {
    await isarService.deleteRecord(id);
    await fetchRecords();
  }
}