// lib/domain/repositories/diary_repository.dart

import '../models/diary_record.dart';

/// 日記データの永続化に関する操作を定義する抽象クラス（インターフェース）。
///
/// このインターフェースを実装することで、データベースへの依存を分離し、
/// テストや将来的なデータソースの変更が容易になります。
abstract class DiaryRepository {
  /// 新しい日記レコードを保存または更新します。
  Future<void> saveRecord(DiaryRecord record);

  /// 保存されているすべての日記レコードを取得します。
  Future<List<DiaryRecord>> getAllRecords();

  /// 指定されたIDに一致する日記レコードを1件取得します。
  Future<DiaryRecord?> getRecord(int id);

  /// 指定されたIsar IDに一致する日記レコードを1件取得します。
  /// 指定されたIsar IDに一致する日記レコードを1件取得します。
  Future<DiaryRecord?> getRecordByIsarId(int isarId);

  /// 指定された開始日から終了日までの範囲に含まれる日記レコードを取得します。
  Future<List<DiaryRecord>> getRecordsInDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// すべての日記レコードの変更を監視するストリームを返します。
  ///
  /// データが追加、更新、削除された際に、新しいリストをストリームに流します。
  Stream<List<DiaryRecord>> watchAllRecords();
}
