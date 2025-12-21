import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/diary_record.dart';
import '../models/location_setting.dart';

class IsarService {
  // staticを外し、このインスタンス専用の変数にします
  late Isar isar;

  // 初期化メソッド
  Future<void> init() async {
    if (Isar.instanceNames.isNotEmpty) {
      isar = Isar.getInstance()!;
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [DiaryRecordSchema, LocationSettingSchema],
      directory: dir.path,
    );
    debugPrint("DBスタッフ：準備完了しました。");
  }


  // 記録の保存
  Future<void> saveRecord(DiaryRecord record) async {
    await isar.writeTxn(() async {
      await isar.diaryRecords.put(record);
    });
  }

  // 記録の取得（全件）
  Future<List<DiaryRecord>> getAllRecords() async {
    return await isar.diaryRecords.where().sortByRecordDateDesc().findAll();
  }

  // 特定の日の記録を取得
  Future<List<DiaryRecord>> getRecordsByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return await isar.diaryRecords
        .filter()
        .recordDateGreaterThan(start)
        .and()
        .recordDateLessThan(end)
        .sortByRecordDateDesc()
        .findAll();
  }

  // 登録地点の保存
  Future<void> saveLocation(LocationSetting setting) async {
    await isar.writeTxn(() async {
      await isar.locationSettings.put(setting);
    });
  }

  // 登録地点の取得
  Future<List<LocationSetting>> getLocations() async {
    return await isar.locationSettings.where().findAll();
  }

  // 登録地点の削除
  Future<void> deleteLocation(Id id) async {
    await isar.writeTxn(() async {
      await isar.locationSettings.delete(id);
    });
  }
}

// グローバルインスタンス
late IsarService isarService;