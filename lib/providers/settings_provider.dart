// lib/providers/settings_provider.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/diary_record.dart';
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
  final DiaryRepository _diaryRepository;

  bool _startFromStep2 = false;
  bool get startFromStep2 => _startFromStep2;

  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  List<LocationSetting> _locations = [];
  List<LocationSetting> get locations => _locations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentTestRecordCount = 0;
  int get currentTestRecordCount => _currentTestRecordCount;

  int _totalTestRecordCount = 0;
  int get totalTestRecordCount => _totalTestRecordCount;

  double? _lastLat;
  double? get lastLat => _lastLat;
  double? _lastLng;
  double? get lastLng => _lastLng;

  SettingsProvider(this._isarService, this._diaryRepository) {
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
      final address = await locationService.getAddressFromLatLng(_lastLat!, _lastLng!);
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
      final nearbyRecords = await _isarService.findNearbyRecords(_lastLat!, _lastLng!);
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

  // --- 開発者向け機能 ---
  Future<void> addTestRecords() async {
    debugPrint("addTestRecords: メソッド開始");
    _isLoading = true;
    _currentTestRecordCount = 0; // リセット
    _totalTestRecordCount = 0; // リセット
    notifyListeners();

    try {
      final random = Random();
      final now = DateTime.now();
      const tags = ['仕事', '人間関係', '自己成長', '健康', '趣味', '家族'];
      const int totalDays = 50;
      const int recordsPerDay = 10;
      _totalTestRecordCount = totalDays * recordsPerDay; // 500件

      debugPrint("addTestRecords: 生成するレコード数 = $_totalTestRecordCount");

      for (int i = 0; i < _totalTestRecordCount; i++) {
        final dayOffset = random.nextInt(totalDays);
        final date = now.subtract(Duration(days: dayOffset, hours: random.nextInt(24), minutes: random.nextInt(60)));
        final moodScore = random.nextInt(10) + 1;
        final selfAnalysis = random.nextDouble() > 0.7 ? 'これはテスト用の自己分析です。No.${i + 1}' : ''; // 30%の確率で自己分析を記入

        final record = DiaryRecord(
          recordId: const Uuid().v4(),
          recordDate: date,
          moodTags: (List<String>.from(tags)..shuffle()).take(random.nextInt(3) + 1).toList(),
          moodScore: moodScore,
          eventText: 'テストイベント ${i + 1}',
          selfAnalysis: selfAnalysis,
          location: 'テスト地点',
          weather: '晴れ',
        );
        debugPrint("addTestRecords: レコード生成中 (${i + 1}/$_totalTestRecordCount) - Date: ${record.recordDate.toIso8601String().substring(0, 10)}, Mood: ${record.moodScore}, SelfAnalysisEmpty: ${record.selfAnalysis?.isEmpty ?? true}");

        await _diaryRepository.saveRecord(record);
        _currentTestRecordCount = i + 1; // 進行状況を更新
        notifyListeners(); // UIを更新
        debugPrint("addTestRecords: レコード保存完了 (${i + 1}/$_totalTestRecordCount)");
      }
      _historyProvider?.refreshHistory();
      final targetDate = now.subtract(const Duration(days: 25)); // 過去25日前に移動
      _historyProvider?.jumpToDate(targetDate); // HistoryProviderのジャンプメソッドを呼び出す
      debugPrint("addTestRecords: HistoryProviderリフレッシュ完了");
    } catch (e) {
      debugPrint("addTestRecords: エラー発生 - $e");
    } finally {
      _isLoading = false;
      _currentTestRecordCount = 0; // 完了したらリセット
      _totalTestRecordCount = 0; // 完了したらリセット
      notifyListeners();
      debugPrint("addTestRecords: メソッド終了 (finally)");
    }
  }
}

  