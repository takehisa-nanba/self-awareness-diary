// lib/providers/settings_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import '../../domain/models/location_setting.dart';
import '../../domain/repositories/diary_repository.dart'; // IsarDiaryRepositoryの参照のため
import '../services/isar_service.dart';
import '../services/location_service.dart'; // グローバルなlocationServiceを使用
import 'history_provider.dart';

/// アプリケーションのサブスクリプションの階層を定義する列挙型。
///
/// - [free]: 無料プラン。
/// - [tier1]: Tier 1 プラン。
/// - [tier2]: Tier 2 プラン（最も機能が充実）。
enum SubscriptionTier { free, tier1, tier2 }

/// アプリケーションの設定（初回起動フラグ、日記の開始ステップ、
/// サブスクリプションティア、登録済み場所など）を管理するプロバイダークラス。
///
/// 設定の永続化と取得、および関連するUIの状態更新を行います。
class SettingsProvider extends ChangeNotifier {
  /// [HistoryProvider] のインスタンスへの参照。
  /// 場所の更新後に履歴をリフレッシュするために使用されます。
  HistoryProvider? _historyProvider;

  /// Isar データベースサービスへの参照。
  /// 設定や場所の情報を永続化・取得するために使用されます。
  final IsarService _isarService;

  /// 日記の記録をステップ2（出来事の入力）から開始するかどうかを示すフラグ。
  bool _startFromStep2 = false;
  bool get startFromStep2 => _startFromStep2;

  /// 現在のユーザーのサブスクリプションティア。
  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  /// ユーザーが登録した場所のリスト。
  List<LocationSetting> _locations = [];
  List<LocationSetting> get locations => _locations;

  /// 位置情報取得中かどうかを示すフラグ。
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 最後に取得された緯度。場所登録時に使用されます。
  double? _lastLat;
  double? get lastLat => _lastLat;

  /// 最後に取得された経度。場所登録時に使用されます。
  double? _lastLng;
  double? get lastLng => _lastLng;

  // --- 初回起動判定 ---
  /// アプリが初回起動かどうかを示すフラグ。
  bool isFirstLaunch = true;
  // ---------------------

  /// [SettingsProvider] のコンストラクタ。
  ///
  /// IsarサービスとDiaryリポジトリを受け取り、保存されている設定を読み込みます。
  SettingsProvider(this._isarService, DiaryRepository diaryRepository) {
    _loadSettings();
  }

  /// [HistoryProvider] のインスタンスを設定します。
  ///
  /// [MultiProvider] の `update` メソッドで呼び出されることを想定しています。
  void setHistoryProvider(HistoryProvider historyProvider) {
    _historyProvider = historyProvider;
  }

  /// データベースからすべての設定（初回起動フラグ、開始ステップ、ティア、場所）を非同期で読み込みます。
  Future<void> _loadSettings() async {
    // isFirstLaunchフラグの読み込み
    final firstLaunchFlag = await _isarService.getSetting('isFirstLaunch');
    if (firstLaunchFlag == 'false') {
      isFirstLaunch = false;
    }

    // `startFromStep2` 設定の読み込み
    final savedStepSetting = await _isarService.getSetting('startFromStep2');
    _startFromStep2 = savedStepSetting == 'true';

    // サブスクリプションティアの読み込み
    final savedTier = await _isarService.getSetting('subscriptionTier');
    if (savedTier != null) {
      _currentTier = SubscriptionTier.values[int.tryParse(savedTier) ?? 0];
    }

    // 登録場所の読み込み
    _locations = await _isarService.getLocations();
    notifyListeners();
  }

  /// アプリの初回起動プロセスが完了したことをマークし、その状態を永続化します。
  Future<void> completeFirstLaunch() async {
    isFirstLaunch = false;
    await _isarService.saveSetting('isFirstLaunch', 'false');
    notifyListeners();
  }

  /// 初回起動フラグをリセットします（主に開発者向けのデバッグ機能）。
  Future<void> resetFirstLaunchFlag() async {
    isFirstLaunch = true;
    await _isarService.saveSetting('isFirstLaunch', 'true');
    notifyListeners();
  }

  /// 日記をステップ2から開始する設定を更新し、永続化します。
  ///
  /// [value] 新しい設定値。
  Future<void> setStartFromStep2(bool value) async {
    _startFromStep2 = value;
    await _isarService.saveSetting('startFromStep2', value.toString());
    notifyListeners();
  }

  /// 現在のユーザーのサブスクリプションティアを更新し、永続化します。
  ///
  /// [tier] 新しいサブスクリプションティア。
  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    _currentTier = tier;
    await _isarService.saveSetting('subscriptionTier', tier.index.toString());
    notifyListeners();
  }

  /// 現在の位置情報を取得し、その場所の住所を返します。
  ///
  /// 取得中は `_isLoading` フラグを `true` に設定し、UIにローディング状態を通知します。
  Future<String?> getCurrentLocationAddress() async {
    _isLoading = true;
    notifyListeners();

    final pos = await locationService.getCurrentPosition();
    if (pos != null) {
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
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

  /// 新しい場所を登録します。
  ///
  /// 登録後、近くの既存レコードを更新するかどうかを判断するための件数を返します。
  /// [label] 場所のラベル。
  /// [address] 場所の住所。
  Future<int> addLocation(String label, String address) async {
    final setting = LocationSetting()
      ..label = label
      ..address = address
      ..latitude = _lastLat
      ..longitude = _lastLng;

    await _isarService.saveLocation(setting);
    await _loadSettings(); // locationsリストを更新

    if (_lastLat != null && _lastLng != null) {
      final nearbyRecords = await _isarService.findNearbyRecords(
        _lastLat!,
        _lastLng!,
      );
      return nearbyRecords.length;
    }
    return 0;
  }

  /// 指定された緯度経度に近い過去の日記レコードの場所を更新します。
  ///
  /// [label] 新しい場所のラベル。
  /// [lat] 緯度。
  /// [lng] 経度。
  Future<void> updatePastRecords(String label, double lat, double lng) async {
    final nearbyRecords = await _isarService.findNearbyRecords(lat, lng);
    if (nearbyRecords.isNotEmpty) {
      await _isarService.updateRecordsLocation(nearbyRecords, label);
      _historyProvider?.refreshHistory(); // 履歴画面をリフレッシュ
    }
  }

  /// 指定されたIDの場所を削除します。
  ///
  /// [id] 削除する場所のID。
  Future<void> deleteLocation(int id) async {
    await _isarService.deleteLocation(id);
    await _loadSettings(); // locationsリストを更新
  }

  /// 既存の場所のラベルを更新します。
  ///
  /// [location] 更新する場所のオブジェクト。
  /// [newLabel] 新しいラベル。
  Future<void> updateLocation(LocationSetting location, String newLabel) async {
    location.label = newLabel;
    await _isarService.updateLocation(location);
    await _loadSettings(); // locationsリストを更新
  }

  // 新しい高レベルメソッド
  /// 新しい場所を登録し、オプションで過去の関連レコードも更新します。
  Future<void> addNewLocationAndUpdateRecords({
    required String label,
    required String address,
    required double? lat,
    required double? lng,
    required bool updatePast,
  }) async {
    // 1. 新しい場所を登録
    final setting = LocationSetting()
      ..label = label
      ..address = address
      ..latitude = lat
      ..longitude = lng;
    await _isarService.saveLocation(setting);
    await _loadSettings(); // locationsリストを更新

    // 2. 過去の記録を更新（オプション）
    if (updatePast && lat != null && lng != null) {
      await updatePastRecords(label, lat, lng);
    }
  }
}
