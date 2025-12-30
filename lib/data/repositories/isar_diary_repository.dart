// lib/data/repositories/isar_diary_repository.dart

import 'package:isar/isar.dart';
import '../../domain/models/diary_record.dart';
import '../../domain/repositories/diary_repository.dart'; // 抽象クラスのインポート
import '../../services/isar_service.dart'; // IsarService のインポート

/// Isar データベースを使用して日記データを永続化する [DiaryRepository] インターフェースの実装。
///
/// データベースとの具体的なやり取りをカプセル化し、ドメイン層からデータベースの詳細を隠蔽します。
class IsarDiaryRepository implements DiaryRepository {
  /// Isar データベースサービスへの参照。
  final IsarService _isarService;

  /// [IsarDiaryRepository] のコンストラクタ。
  IsarDiaryRepository(this._isarService);

  @override
  Future<List<DiaryRecord>> getAllRecords() {
    return _isarService.getAllRecords();
  }

  @override
  Future<DiaryRecord?> getRecord(int id) async {
    return await _isarService.isar.diaryRecords.get(id);
  }

  @override
  Future<void> saveRecord(DiaryRecord record) {
    return _isarService.saveRecord(record);
  }

  @override
  Stream<List<DiaryRecord>> watchAllRecords() {
    return _isarService.isar.diaryRecords.where().watch(fireImmediately: true);
  }

  @override
  Future<List<DiaryRecord>> getRecordsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    // startDateをその日の始まりに、endDateをその日の終わりに設定
    final startOfRange = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final endOfRange = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    return _isarService.isar.diaryRecords
        .filter()
        .recordDateBetween(startOfRange, endOfRange)
        .sortByRecordDateDesc() // 記録日時の降順でソート
        .findAll();
  }
}
