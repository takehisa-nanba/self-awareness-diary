// lib/core/write_core.dart (エラー解消後の最終全文)

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';
import '../models/record.dart';
import '../services/location_weather_service.dart'; 

// UIの更新を通知し、ロジックを保持するコアクラス
class WriteCore with ChangeNotifier {
  
  static const List<String> stepTitles = [
    '記録の新規作成',
    'スコア評価／出来事入力',
    '気分の詳細入力',
  ];

  // ステップ管理 (1-based)
  int _currentStepIndex = 1;
  int get currentStepIndex => _currentStepIndex;
  
  // ロケーションと天気情報
  Position? _currentLocation;
  String _locationName = '位置情報取得中...';
  String _weather = '天気情報取得中...';

  String get locationName => _locationName;
  String get weather => _weather;
  Position? get currentLocation => _currentLocation;
  
  // フォーム入力データ
  final Set<String> _selectedMoodTags = {}; 
  int _moodScore = 5;
  TextEditingController eventController = TextEditingController();
  TextEditingController detailController = TextEditingController();

  Set<String> get selectedMoodTags => _selectedMoodTags;
  int get moodScore => _moodScore;
  
  // サービス
  final LocationWeatherService _locationWeatherService = LocationWeatherService();

  WriteCore() {
    _loadLocationAndWeather();
  }

  String get currentStepTitle {
    return stepTitles[_currentStepIndex - 1];
  }

  // ------------------------------------
  // Location and Weather
  // ------------------------------------

  Future<void> _loadLocationAndWeather() async {
    try {
      // ★★★ 修正: getLocationAndWeather を呼び出し、結果を Map から取得 ★★★
      final result = await _locationWeatherService.getLocationAndWeather();
      
      _locationName = result['location'] ?? '不明';
      _weather = result['weather'] ?? '不明';
      
      // Position オブジェクトの有無で「準備完了」を判断するための暫定措置
      if (_locationName != '取得エラー' && _locationName != '権限なし') {
          _currentLocation = Position(
              latitude: 0, 
              longitude: 0, 
              timestamp: DateTime.now(), // ★★★ 修正2: null ではなく DateTime.now() を渡す ★★★
              accuracy: 0, 
              altitude: 0, 
              heading: 0, 
              speed: 0, 
              speedAccuracy: 0, 
              altitudeAccuracy: 0, 
              headingAccuracy: 0
          );
      } else {
          _currentLocation = null;
      }
      // ★★★ 修正ここまで ★★★

    } catch (e) {
      _locationName = '取得失敗 ($e)';
      _weather = '取得失敗';
      _currentLocation = null;
    }
    notifyListeners();
  }

  bool isLocationAndWeatherReady() {
    return _currentLocation != null;
  }

  // ------------------------------------
  // Form Logic
  // ------------------------------------

  void toggleMoodTag(String tag) {
    if (_selectedMoodTags.contains(tag)) {
      _selectedMoodTags.remove(tag);
    } else {
      _selectedMoodTags.add(tag);
    }
    notifyListeners();
  }

  void setMoodScore(double score) {
    _moodScore = score.round();
    notifyListeners();
  }
  
  void notifyUiUpdate() {
    notifyListeners();
  }
  
  bool isStepValid() {
    if (_currentStepIndex == 1) {
      return _selectedMoodTags.isNotEmpty;
    }
    if (_currentStepIndex == 2) {
      return eventController.text.trim().isNotEmpty;
    }
    return true;
  }

  void nextStep() {
    if (_currentStepIndex < 3 && isStepValid()) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 1) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  // ------------------------------------
  // Save Logic
  // ------------------------------------
  
  Future<void> saveRecordOnly() async {
    final newRecord = Record(
      // ★★★ 修正: 必須のString型 recordId に一意な文字列を割り当てる ★★★
      recordId: DateTime.now().microsecondsSinceEpoch.toString(), 
      moodScore: _moodScore,
      moodTags: _selectedMoodTags.toList(),
      eventText: eventController.text.trim(),
      recordDate: DateTime.now(),
      location: _locationName,
      weather: _weather,
      selfAnalysis: detailController.text.trim(),
    );
    
    await isar.writeTxn(() async {
      await isar.records.put(newRecord);
    });
  }

  void resetEntry() {
    _currentStepIndex = 1;
    _selectedMoodTags.clear();
    _moodScore = 5;
    eventController.clear();
    detailController.clear();
    _loadLocationAndWeather(); 
    notifyListeners();
  }
}