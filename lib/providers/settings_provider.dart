// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import '../models/location_setting.dart';
import '../services/isar_service.dart';
import '../services/location_service.dart';

class SettingsProvider extends ChangeNotifier {
  // --- 追加：サブスクリプション状態 ---
  bool _isPremium = false; // 初期値は無料ユーザー
  bool get isPremium => _isPremium;

  // テスト用：サブスク状態を切り替えるメソッド（デバッグ時や設定画面で使用）
  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners();
  }
  // ------------------------------
  List<LocationSetting> _locations = [];
  List<LocationSetting> get locations => _locations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  // 設定の読み込み
  Future<void> _loadSettings() async {
    _locations = await isarService.getLocations();
    notifyListeners();
  }

  // 保存用の座標を保持する変数
  double? _lastLat;
  double? _lastLng;

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

  Future<void> addLocation(String label, String address) async {
    final setting = LocationSetting()
      ..label = label
      ..address = address
      ..latitude = _lastLat    // 保持していた座標を保存
      ..longitude = _lastLng;
    
    await isarService.saveLocation(setting);
    await _loadSettings();
  }

  // 場所の削除
  Future<void> deleteLocation(int id) async {
    await isarService.deleteLocation(id);
    await _loadSettings();
  }
}