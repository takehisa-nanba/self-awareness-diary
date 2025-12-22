import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
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

  // すべてのメソッドの冒頭にこれを入れると、より安全です
  Future<void> ensureInit() async {
    if (Isar.instanceNames.isEmpty) {
      await init();
    } else {
      isar = Isar.getInstance()!;
    }
  }

  // 例：全件取得を安全にする
  Future<List<DiaryRecord>> getAllRecords() async {
    // isar が late 初期化されているかチェック。未完了なら init を呼ぶ
    try {
      return await isar.diaryRecords.where().sortByRecordDateDesc().findAll();
    } catch (e) {
      debugPrint("IsarService: 未初期化のため init を実行します");
      await init();
      return await isar.diaryRecords.where().sortByRecordDateDesc().findAll();
    }
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

  // 近くの記録を探す
  Future<List<DiaryRecord>> findNearbyRecords(double lat, double lng) async {
  final allRecords = await isar.diaryRecords.where().findAll();
    return allRecords.where((record) {
      if (record.latitude == null || record.longitude == null) return false;
      double distance = Geolocator.distanceBetween(lat, lng, record.latitude!, record.longitude!);
      return distance <= 30.0;
    }).toList();
  }

  // 複数の記録の位置情報を一括更新
  Future<void> updateRecordsLocation(List<DiaryRecord> records, String newLabel) async {
    await isar.writeTxn(() async {
      for (var record in records) {
        record.location = newLabel;
        await isar.diaryRecords.put(record);
      }
    });
  }

}

// late を外し、即座にインスタンス化する（中身のisarはinitで初期化される）
late IsarService isarService;