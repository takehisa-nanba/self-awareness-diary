// lib/services/isar_service.dart

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart'; // Geolocator.distanceBetween を使用
import 'package:flutter/foundation.dart';
import '../../domain/models/diary_record.dart';
import '../../domain/models/location_setting.dart';
import '../../domain/models/app_settings.dart';

/// Isar データベースの初期化、およびデータ永続化層へのアクセスを提供するサービス。
///
/// 日記レコード、場所設定、アプリケーション設定のCRUD操作を管理します。
class IsarService {
  Isar? _isar;

  /// 初期化された Isar インスタンスを返します。
  ///
  /// インスタンスがまだ初期化されていない場合は例外をスローします。
  Isar get isar {
    if (_isar == null) {
      throw Exception("IsarService: Isarが初期化されていません。先にinit()を呼び出してください。");
    }
    return _isar!;
  }

  /// Isar データベースを初期化し、必要なスキーマを登録します。
  ///
  /// アプリケーションのドキュメントディレクトリにデータベースファイルを作成します。
  Future<void> init() async {
    // 既にIsarインスタンスが存在する場合はそれを再利用
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
    debugPrint("IsarService: 初期化に成功しました。");
  }

  /// アプリケーション設定をキーと値のペアとして保存します。
  ///
  /// [key] 設定の識別子となるキー。
  /// [value] キーに対応する設定値。
  Future<void> saveSetting(String key, String value) async {
    final setting = AppSettings()
      ..key = key
      ..value = value;
    await isar.writeTxn(() async {
      await isar.collection<AppSettings>().put(setting);
    });
  }

  /// 指定されたキーに対応するアプリケーション設定の値を取得します。
  ///
  /// 設定が見つからない場合は `null` を返します。
  /// [key] 取得する設定のキー。
  Future<String?> getSetting(String key) async {
    final setting = await isar
        .collection<AppSettings>()
        .where()
        .keyEqualTo(key)
        .findFirst();
    return setting?.value;
  }

  /// 日記レコードをデータベースに保存または更新します。
  ///
  /// [record] 保存または更新する [DiaryRecord] オブジェクト。
  Future<void> saveRecord(DiaryRecord record) async {
    await isar.writeTxn(() async {
      await isar.collection<DiaryRecord>().put(record);
    });
  }

  /// Isar データベースが初期化されていることを確認します。
  ///
  /// 未初期化の場合は `init()` を呼び出して初期化を行います。
  Future<void> ensureInit() async {
    if (Isar.instanceNames.isEmpty) {
      await init();
    } else {
      _isar = Isar.getInstance()!;
    }
  }

  /// すべての日記レコードを記録日時の降順で取得します。
  Future<List<DiaryRecord>> getAllRecords() async {
    try {
      return await isar
          .collection<DiaryRecord>()
          .where()
          .sortByRecordDateDesc()
          .findAll();
    } catch (e) {
      debugPrint("IsarService: 初期化が必要です。init()を呼び出します。");
      await init(); // 再度初期化を試みる
      return await isar
          .collection<DiaryRecord>()
          .where()
          .sortByRecordDateDesc()
          .findAll();
    }
  }

  /// 指定された日付（日単位）の日記レコードを取得します。
  ///
  /// [date] 取得したい日付。
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

  /// 場所設定をデータベースに保存または更新します。
  ///
  /// [setting] 保存または更新する [LocationSetting] オブジェクト。
  Future<void> saveLocation(LocationSetting setting) async {
    await isar.writeTxn(() async {
      await isar.collection<LocationSetting>().put(setting);
    });
  }

  /// 登録されているすべての場所設定を取得します。
  Future<List<LocationSetting>> getLocations() async {
    return await isar.collection<LocationSetting>().where().findAll();
  }

  /// 指定されたIDの場所設定をデータベースから削除します。
  ///
  /// [id] 削除する場所設定のID。
  Future<void> deleteLocation(Id id) async {
    await isar.writeTxn(() async {
      await isar.collection<LocationSetting>().delete(id);
    });
  }

  /// 場所設定を更新します。
  ///
  /// [location] 更新する [LocationSetting] オブジェクト。
  Future<void> updateLocation(LocationSetting location) async {
    await isar.writeTxn(() async {
      await isar.collection<LocationSetting>().put(location);
    });
  }

  /// 指定された緯度経度から30メートル以内にある日記レコードを検索します。
  ///
  /// [lat] 検索中心の緯度。
  /// [lng] 検索中心の経度。
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
      return distance <= 30.0; // 30m以内を検索範囲とする
    }).toList();
  }

  /// 指定された日記レコードのリストの場所を新しいラベルで更新します。
  ///
  /// [records] 更新対象の日記レコードのリスト。
  /// [newLabel] 設定する新しい場所のラベル。
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

  /// 指定された場所のラベルまたは住所が既にデータベースに登録されているかを確認します。
  ///
  /// [locationLabelOrAddress] 確認する場所のラベルまたは住所。
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

/// グローバルにアクセス可能な [IsarService] のインスタンス。
/// アプリケーションの初期化時に設定されることを想定しています。
late IsarService isarService;
