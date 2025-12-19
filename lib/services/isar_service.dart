import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diary_record.dart';

class IsarService {
  static late Isar _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([DiaryRecordSchema], directory: dir.path);
  }

  Isar get db => _isar;

  Future<List<DiaryRecord>> getAllRecords() async =>
      await _isar.diaryRecords.where().sortByRecordDateDesc().findAll();

  Future<void> saveRecord(DiaryRecord record) async =>
      await _isar.writeTxn(() async => await _isar.diaryRecords.put(record));

  Future<void> deleteRecord(int id) async =>
      await _isar.writeTxn(() async => await _isar.diaryRecords.delete(id));
}
final isarService = IsarService();