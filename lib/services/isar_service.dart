import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/diary_record.dart';
import '../../domain/models/location_setting.dart';
import '../../domain/models/app_settings.dart';

class IsarService {
  Isar? _isar;

  Isar get isar {
    if (_isar == null) {
      throw Exception(
        "IsarService: Isar has not been initialized. Call init() first.",
      );
    }
    return _isar!;
  }

  Future<void> init() async {
    if (Isar.instanceNames.isNotEmpty) {
      _isar = Isar.getInstance()!;
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      DiaryRecordSchema,
      LocationSettingSchema,
      AppSettingsSchema,
    ], directory: dir.path);
    debugPrint("IsarService: Initialized successfully.");
  }

  Future<void> saveSetting(String key, String value) async {
    final setting = AppSettings()
      ..key = key
      ..value = value;
    await isar.writeTxn(() async {
      await isar.collection<AppSettings>().put(setting);
    });
  }

  Future<String?> getSetting(String key) async {
    final setting = await isar
        .collection<AppSettings>()
        .where()
        .keyEqualTo(key)
        .findFirst();
    return setting?.value;
  }

  Future<void> saveRecord(DiaryRecord record) async {
    await isar.writeTxn(() async {
      await isar.collection<DiaryRecord>().put(record);
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
      return await isar
          .collection<DiaryRecord>()
          .where()
          .sortByRecordDateDesc()
          .findAll();
    } catch (e) {
      debugPrint("IsarService: Initialization required, calling init().");
      await init();
      return await isar
          .collection<DiaryRecord>()
          .where()
          .sortByRecordDateDesc()
          .findAll();
    }
  }

  Future<List<DiaryRecord>> getRecordsByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return await isar
        .collection<DiaryRecord>()
        .filter()
        .recordDateGreaterThan(start)
        .and()
        .recordDateLessThan(end)
        .sortByRecordDateDesc()
        .findAll();
  }

  Future<void> saveLocation(LocationSetting setting) async {
    await isar.writeTxn(() async {
      await isar.collection<LocationSetting>().put(setting);
    });
  }

  Future<List<LocationSetting>> getLocations() async {
    return await isar.collection<LocationSetting>().where().findAll();
  }

  Future<void> deleteLocation(Id id) async {
    await isar.writeTxn(() async {
      await isar.collection<LocationSetting>().delete(id);
    });
  }

  Future<void> updateLocation(LocationSetting location) async {
    await isar.writeTxn(() async {
      await isar.collection<LocationSetting>().put(location);
    });
  }

  Future<List<DiaryRecord>> findNearbyRecords(double lat, double lng) async {
    final allRecords = await isar.collection<DiaryRecord>().where().findAll();
    return allRecords.where((record) {
      if (record.latitude == null || record.longitude == null) return false;
      double distance = Geolocator.distanceBetween(
        lat,
        lng,
        record.latitude!,
        record.longitude!,
      );
      return distance <= 30.0;
    }).toList();
  }

  Future<void> updateRecordsLocation(
    List<DiaryRecord> records,
    String newLabel,
  ) async {
    await isar.writeTxn(() async {
      for (var record in records) {
        record.location = newLabel;
        await isar.collection<DiaryRecord>().put(record);
      }
    });
  }

  /// 指定された場所のラベルまたは住所が既に登録されているかを確認します。
  Future<bool> isLocationRegistered(String locationLabelOrAddress) async {
    final count = await isar.locationSettings
        .filter()
        .labelEqualTo(locationLabelOrAddress)
        .or()
        .addressEqualTo(locationLabelOrAddress)
        .count();
    return count > 0;
  }
}

late IsarService isarService;
