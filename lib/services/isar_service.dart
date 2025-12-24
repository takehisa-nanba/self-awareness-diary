import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/diary_record.dart';
import '../models/location_setting.dart';
import '../models/app_settings.dart'; // AppSettingsモデルをインポート

class IsarService {
  Isar? _isar;

  Isar get isar {
    if (_isar == null) {
      throw Exception("IsarStaff: まだ準備ができていないのに呼ばれました。init()を先に完了させてください。");
    }
    return _isar!;
  }

  Future<void> init() async {
    if (Isar.instanceNames.isNotEmpty) {
      _isar = Isar.getInstance()!;
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [DiaryRecordSchema, LocationSettingSchema, AppSettingsSchema], // AppSettingsSchemaを追加
      directory: dir.path,
    );
    debugPrint("DBスタッフ：準備完了しました。");
  }

  // --- AppSettings関連のメソッドを追加 ---

  // 設定を保存する
  Future<void> saveSetting(String key, String value) async {
    final setting = AppSettings()..key = key..value = value;
    await isar.writeTxn(() async {
      await isar.appSettings.put(setting);
    });
  }

  // 設定を取得する
  Future<String?> getSetting(String key) async {
    final setting = await isar.appSettings.where().keyEqualTo(key).findFirst();
    return setting?.value;
  }

  // ------------------------------------


  Future<void> saveRecord(DiaryRecord record) async {
    await isar.writeTxn(() async {
      await isar.diaryRecords.put(record);
    });
  }

  Future<void> ensureInit() async {
    if (Isar.instanceNames.isEmpty) {
      await init();
    } else {
      _isar = Isar.getInstance()!;
    }
  }

  Future<List<DiaryRecord>> getAllRecords() async {
    try {
      return await isar.diaryRecords.where().sortByRecordDateDesc().findAll();
    } catch (e) {
      debugPrint("IsarService: 未初期化のため init を実行します");
      await init();
      return await isar.diaryRecords.where().sortByRecordDateDesc().findAll();
    }
  }

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

  Future<void> saveLocation(LocationSetting setting) async {
    await isar.writeTxn(() async {
      await isar.locationSettings.put(setting);
    });
  }

  Future<List<LocationSetting>> getLocations() async {
    return await isar.locationSettings.where().findAll();
  }

  Future<void> deleteLocation(Id id) async {
    await isar.writeTxn(() async {
      await isar.locationSettings.delete(id);
    });
  }

  // 登録地点の更新
  Future<void> updateLocation(LocationSetting location) async {
    await isar.writeTxn(() async {
      await isar.locationSettings.put(location);
    });
  }

  Future<List<DiaryRecord>> findNearbyRecords(double lat, double lng) async {
  final allRecords = await isar.diaryRecords.where().findAll();
    return allRecords.where((record) {
      if (record.latitude == null || record.longitude == null) return false;
      double distance = Geolocator.distanceBetween(lat, lng, record.latitude!, record.longitude!);
      return distance <= 30.0;
    }).toList();
  }

  Future<void> updateRecordsLocation(List<DiaryRecord> records, String newLabel) async {
    await isar.writeTxn(() async {
      for (var record in records) {
        record.location = newLabel;
        await isar.diaryRecords.put(record);
      }
    });
  }

}

late IsarService isarService;