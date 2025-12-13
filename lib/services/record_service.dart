// lib/services/record_service.dart (最終修正版 - データベース専用)

import '../main.dart'; // isarグローバル変数
import '../models/record.dart';
import 'package:isar/isar.dart';

class RecordService {
  // 1. 新しい記録をデータベースに保存するメソッド
  Future<void> saveRecord(Record newRecord) async {
    try {
      await isar.writeTxn(() async {
        await isar.records.put(newRecord);
      });
    } catch (e) {
      // データベースエラーを呼び出し元に投げる
      throw Exception('データベース書き込みエラー: $e');
    }
  }

  // 2. 履歴画面用に全レコードを取得するメソッド
  Future<List<Record>> getAllRecords() async {
    return await isar.records.where().findAll();
  }
}