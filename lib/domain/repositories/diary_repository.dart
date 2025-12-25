import '../models/diary_record.dart';

abstract class DiaryRepository {
  Future<void> saveRecord(DiaryRecord record);

  Future<List<DiaryRecord>> getAllRecords();

  Future<DiaryRecord?> getRecord(int id);

  Stream<List<DiaryRecord>> watchAllRecords();
}
