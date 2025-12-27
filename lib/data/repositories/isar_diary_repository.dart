import 'package:isar/isar.dart';
import '../../domain/models/diary_record.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../services/isar_service.dart';

class IsarDiaryRepository implements DiaryRepository {
  final IsarService _isarService;

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
  Future<List<DiaryRecord>> getRecordsInDateRange(DateTime startDate, DateTime endDate) {
    // startDateをその日の始まりに、endDateをその日の終わりに設定する
    final startOfRange = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfRange = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    return _isarService.isar.diaryRecords
        .filter()
        .recordDateBetween(startOfRange, endOfRange) // 開始日と終了日を両方とも含める
        .sortByRecordDateDesc()
        .findAll();
  }
}
