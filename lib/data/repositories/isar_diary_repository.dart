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

  Future<List<DiaryRecord>> getRecordsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _isarService.isar.diaryRecords
        .filter()
        .recordDateGreaterThan(start)
        .and()
        .recordDateLessThan(end)
        .sortByRecordDateDesc()
        .findAll();
  }
}
