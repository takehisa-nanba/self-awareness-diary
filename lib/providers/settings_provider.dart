// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import '../models/location_setting.dart';
import '../services/isar_service.dart';
import '../services/location_service.dart';
import 'history_provider.dart';

class SettingsProvider extends ChangeNotifier {
  HistoryProvider? _historyProvider;

  bool _startFromStep2 = false;
  bool get startFromStep2 => _startFromStep2;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  List<LocationSetting> _locations = [];
  List<LocationSetting> get locations => _locations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }
  
  void setHistoryProvider(HistoryProvider historyProvider) {
    _historyProvider = historyProvider;
  }

  Future<void> _loadSettings() async {
    final savedStepSetting = await isarService.getSetting('startFromStep2');
    _startFromStep2 = savedStepSetting == 'true';
    _locations = await isarService.getLocations();
    notifyListeners();
  }

  Future<void> setStartFromStep2(bool value) async {
    _startFromStep2 = value;
    await isarService.saveSetting('startFromStep2', value.toString());
    notifyListeners();
  }

  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners();
  }

  double? _lastLat;
  double? get lastLat => _lastLat;
  double? _lastLng;
  double? get lastLng => _lastLng;

  Future<String?> getCurrentLocationAddress() async {
    _isLoading = true;
    notifyListeners();
    
    final pos = await locationService.getCurrentPosition();
    if (pos != null) {
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      final address = await locationService.getAddressFromLatLng(_lastLat!, _lastLng!);
      _isLoading = false;
      notifyListeners();
      return address;
    }
    
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // 場所の追加と、近くの日記の件数を返す
  Future<int> addLocation(String label, String address) async {
    final setting = LocationSetting()
      ..label = label
      ..address = address
      ..latitude = _lastLat
      ..longitude = _lastLng;
    
    await isarService.saveLocation(setting);
    await _loadSettings();

    if (_lastLat != null && _lastLng != null) {
      final nearbyRecords = await isarService.findNearbyRecords(_lastLat!, _lastLng!);
      return nearbyRecords.length;
    }
    return 0;
  }

  // 過去の日記を更新する
  Future<void> updatePastRecords(String label, double lat, double lng) async {
    final nearbyRecords = await isarService.findNearbyRecords(lat, lng);
    if (nearbyRecords.isNotEmpty) {
      await isarService.updateRecordsLocation(nearbyRecords, label);
      _historyProvider?.refreshHistory();
    }
  }

    Future<void> deleteLocation(int id) async {

      await isarService.deleteLocation(id);

      await _loadSettings();

    }

  

    // 場所のラベルを更新する

    Future<void> updateLocation(LocationSetting location, String newLabel) async {

      location.label = newLabel;

      await isarService.updateLocation(location);

      await _loadSettings();

    }

  }

  