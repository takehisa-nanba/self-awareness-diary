// lib/providers/location_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import '../../domain/models/location_setting.dart';
import '../services/isar_service.dart'; // Isarデータベース操作のため
import '../services/location_service.dart'; // 位置情報取得サービスのため
import 'history_provider.dart'; // 履歴更新のため

/// アプリケーションの場所設定（登録済み場所）を管理するプロバイダークラス。
///
/// 場所の追加、削除、更新、および現在地の取得などのロジックを担当します。
class LocationProvider extends ChangeNotifier {
  final IsarService _isarService; // IsarServiceのインスタンス
  HistoryProvider? _historyProvider; // HistoryProviderへの参照

  List<LocationSetting> _locations = []; // 登録済み場所のリスト
  List<LocationSetting> get locations => _locations;

  bool _isLoading = false; // 位置情報取得中かどうかを示すフラグ
  bool get isLoading => _isLoading;

  double? _lastLat; // 最後に取得された緯度
  double? get lastLat => _lastLat;

  double? _lastLng; // 最後に取得された経度
  double? get lastLng => _lastLng;

  /// [LocationProvider] のコンストラクタ。
  ///
  /// IsarServiceを受け取り、初期化時に登録済み場所を読み込みます。
  LocationProvider(this._isarService) {
    loadLocations(); // 初期化時に場所データを読み込む
  }

  /// HistoryProviderのインスタンスを設定します。
  ///
  /// [MultiProvider] の `update` メソッドで呼び出されることを想定しています。
  void setHistoryProvider(HistoryProvider historyProvider) {
    _historyProvider = historyProvider;
  }

  /// 登録済み場所のリストをデータベースから読み込み、UIを更新します。
  Future<void> loadLocations() async {
    _locations = await _isarService.getLocations();
    notifyListeners();
  }

  /// 現在の位置情報を取得し、その場所の住所を返します。
  ///
  /// 取得中は `_isLoading` フラグを `true` に設定し、UIにローディング状態を通知します。
  Future<String?> getCurrentLocationAddress() async {
    _isLoading = true;
    notifyListeners();

    final pos = await locationService.getCurrentPosition(); // 現在位置を取得
    if (pos != null) {
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      // 緯度経度から住所を取得
      final address = await locationService.getAddressFromLatLng(
        _lastLat!,
        _lastLng!,
      );
      _isLoading = false;
      notifyListeners();
      return address;
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// 指定された緯度経度に近い過去の日記レコードの場所を更新します。
  ///
  /// [label] 新しい場所のラベル。
  /// [lat] 緯度。
  /// [lng] 経度。
  Future<void> updatePastRecords(String label, double lat, double lng) async {
    // 近くの記録を検索
    final nearbyRecords = await _isarService.findNearbyRecords(lat, lng);
    if (nearbyRecords.isNotEmpty) {
      // 検索された記録の場所を更新
      await _isarService.updateRecordsLocation(nearbyRecords, label);
      _historyProvider?.refreshHistory(); // 履歴画面をリフレッシュ
    }
  }

  /// 指定されたIDの場所を削除します。
  ///
  /// [id] 削除する場所のID。
  Future<void> deleteLocation(int id) async {
    await _isarService.deleteLocation(id); // データベースから場所を削除
    await loadLocations(); // locationsリストを再読み込みしてUIを更新
  }

  /// 既存の場所のラベルを更新します。
  ///
  /// [location] 更新する場所のオブジェクト。
  /// [newLabel] 新しいラベル。
  Future<void> updateLocation(LocationSetting location, String newLabel) async {
    location.label = newLabel; // ラベルを更新
    await _isarService.updateLocation(location); // データベースの場所情報を更新
    await loadLocations(); // locationsリストを再読み込みしてUIを更新
  }

  /// 新しい場所を登録し、オプションで過去の関連レコードも更新します。
  Future<void> addNewLocationAndUpdateRecords({
    required String label,
    required String address,
    required double? lat,
    required double? lng,
    required bool updatePast,
  }) async {
    // 1. 新しい場所設定オブジェクトを作成
    final setting = LocationSetting()
      ..label = label
      ..address = address
      ..latitude = lat
      ..longitude = lng;
    await _isarService.saveLocation(setting); // データベースに場所を保存
    await loadLocations(); // locationsリストを再読み込みしてUIを更新

    // 2. 過去の記録を更新（オプション）
    if (updatePast && lat != null && lng != null) {
      await updatePastRecords(label, lat, lng);
    }
  }
}
