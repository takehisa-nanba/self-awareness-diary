// lib/services/record_service.dart

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/record.dart';

class RecordService {
  // Isarインスタンスの非同期管理
  late Future<Isar> _isarFuture;

  RecordService() {
    _isarFuture = _openIsar();
  }

  // データベースの初期化とオープン（シングルトンインスタンス管理）
  Future<Isar> _openIsar() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      
      return Isar.open(
        [RecordSchema], // 定義したスキーマを指定
        directory: dir.path,
        inspector: true, 
      );
    }
    // 既に開いている場合はそのインスタンスを返す
    return Isar.getInstance()!;
  }

  // 1. 新しい記録をデータベースに保存するメソッド
  Future<void> saveRecord(Record newRecord) async {
    final isar = await _isarFuture;
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
    final isar = await _isarFuture;
    return await isar.records.where().sortByRecordDateDesc().findAll();
  }
}

// サービスをどこからでも呼び出せるように、シングルトンとして公開
final recordService = RecordService();