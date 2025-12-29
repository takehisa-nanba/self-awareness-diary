// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import '../../domain/models/location_setting.dart';
import '../../domain/repositories/diary_repository.dart';
import '../services/isar_service.dart';
import '../services/location_service.dart';
import 'history_provider.dart';

// サブスクリプションのティアを定義
enum SubscriptionTier { free, tier1, tier2 }

class SettingsProvider extends ChangeNotifier {
  HistoryProvider? _historyProvider;
  final IsarService _isarService;

  bool _startFromStep2 = false;
  bool get startFromStep2 => _startFromStep2;

  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  List<LocationSetting> _locations = [];
  List<LocationSetting> get locations => _locations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double? _lastLat;
  double? get lastLat => _lastLat;
  double? _lastLng;
  double? get lastLng => _lastLng;

  SettingsProvider(this._isarService, DiaryRepository diaryRepository) {
    _loadSettings();
  }

  void setHistoryProvider(HistoryProvider historyProvider) {
    _historyProvider = historyProvider;
  }

  Future<void> _loadSettings() async {
    final savedStepSetting = await _isarService.getSetting('startFromStep2');
    _startFromStep2 = savedStepSetting == 'true';

    final savedTier = await _isarService.getSetting('subscriptionTier');
    if (savedTier != null) {
      _currentTier = SubscriptionTier.values[int.tryParse(savedTier) ?? 0];
    }

    _locations = await _isarService.getLocations();
    notifyListeners();
  }

  Future<void> setStartFromStep2(bool value) async {
    _startFromStep2 = value;
    await _isarService.saveSetting('startFromStep2', value.toString());
    notifyListeners();
  }

  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    _currentTier = tier;
    await _isarService.saveSetting('subscriptionTier', tier.index.toString());
    notifyListeners();
  }

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

  Future<int> addLocation(String label, String address) async {
    final setting = LocationSetting()
      ..label = label
      ..address = address
      ..latitude = _lastLat
      ..longitude = _lastLng;

    await _isarService.saveLocation(setting);
    await _loadSettings();

    if (_lastLat != null && _lastLng != null) {
      final nearbyRecords = await _isarService.findNearbyRecords(
        _lastLat!,
        _lastLng!,
      );
      return nearbyRecords.length;
    }
    return 0;
  }

  Future<void> updatePastRecords(String label, double lat, double lng) async {
    final nearbyRecords = await _isarService.findNearbyRecords(lat, lng);
    if (nearbyRecords.isNotEmpty) {
      await _isarService.updateRecordsLocation(nearbyRecords, label);
      _historyProvider?.refreshHistory();
    }
  }

  Future<void> deleteLocation(int id) async {
    await _isarService.deleteLocation(id);
    await _loadSettings();
  }

  Future<void> updateLocation(LocationSetting location, String newLabel) async {
    location.label = newLabel;
    await _isarService.updateLocation(location);
    await _loadSettings();
  }

  // --- 新しい高レベルメソッド ---
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
