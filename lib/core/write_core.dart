// lib/core/write_core.dart (構造復元版)

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 
import '../services/location_weather_service.dart'; // 位置情報・天気サービス
import '../services/gemini_service.dart'; // Gemini AIサービス
import '../services/record_service.dart'; // DBサービス
import '../models/record.dart'; // Recordモデル

const _uuid = Uuid(); 

class WriteCore extends ChangeNotifier {
  // ステップ管理
  int _currentStepIndex = 1;
  int get currentStepIndex => _currentStepIndex;

  static const List<String> stepTitles = [
    '感情の記録',
    '出来事の記録',
    '内省と保存',
  ];

  String get currentStepTitle => stepTitles[_currentStepIndex - 1];

  // データフィールド
  Set<String> selectedMoodTags = {};
  double moodScore = 5.0; 
  TextEditingController eventController = TextEditingController();
  TextEditingController detailController = TextEditingController();

  // AIからの内省の質問を格納するフィールド
  String _reflectionQuestion = '';
  String get reflectionQuestion => _reflectionQuestion;
  bool _isGeneratingQuestion = false;
  bool get isGeneratingQuestion => _isGeneratingQuestion;

  // 環境データ (位置情報・天気)
  String latitude = '0.0';
  String longitude = '0.0';
  String locationName = '場所不明';
  String weather = '天気不明';
  
  // initCoreでリアルタイムデータをロード
  WriteCore() {
    loadLocationAndWeather(); // ★★★ 追記: コア初期化時に位置情報をロード ★★★
  }

  // ------------------------------------
  // メソッド
  // ------------------------------------

  void toggleMoodTag(String tag) {
    if (selectedMoodTags.contains(tag)) {
      selectedMoodTags.remove(tag);
    } else {
      selectedMoodTags.add(tag);
    }
    notifyListeners();
  }

  void setMoodScore(double score) {
    moodScore = score;
    notifyListeners();
  }

  void notifyUiUpdate() {
    notifyListeners();
  }

  bool isLocationAndWeatherReady() {
    return locationName.isNotEmpty && weather.isNotEmpty;
  }
  
  // ------------------------------------
  // 画面遷移ロジック
  // ------------------------------------

  bool isStepValid() {
    switch (_currentStepIndex) {
      case 1:
        return selectedMoodTags.isNotEmpty;
      case 2:
        return eventController.text.trim().isNotEmpty && moodScore >= 1;
      case 3:
        return true; 
      default:
        return false;
    }
  }

  void nextStep() async {
    if (!isStepValid()) return;

    if (_currentStepIndex == 2) {
      await generateQuestion(); 
    }

    if (_currentStepIndex < stepTitles.length) {
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
  // 位置情報・天気取得ロジック
  // ------------------------------------
  Future<void> loadLocationAndWeather() async {
    print('--- F-2: 位置情報と天気情報の取得開始 ---');
    try {
      final data = await locationWeatherService.getLocationAndWeather();
      
      locationName = data['locationName'] ?? '場所不明';
      weather = data['weather'] ?? '天気不明';

      print('位置情報ロード完了: $locationName, $weather');
      notifyListeners(); // UIの更新を通知
    } catch (e) {
      print('位置情報ロード中に予期せぬエラー: $e');
    }
  }

  // ------------------------------------
  // AI連携メソッド
  // ------------------------------------
  
  Future<void> generateQuestion() async {
    if (eventController.text.trim().isEmpty) return; 

    _isGeneratingQuestion = true;
    _reflectionQuestion = 'AIコーチが質問を考えています...'; 
    notifyListeners();

    try {
      final question = await geminiService.generateReflectionQuestion(
        moodTags: selectedMoodTags.join(', '),
        eventText: eventController.text.trim(),
        moodScore: moodScore.round(),
        location: locationName,
        weather: weather,
      );
      
      _reflectionQuestion = question;
      
    } catch (e) {
      _reflectionQuestion = "質問生成中にエラーが発生しました。ネットワークまたはAPIキーを確認してください。";
    } finally {
      _isGeneratingQuestion = false;
      notifyListeners();
    }
  }

  // ------------------------------------
  // 保存・リセットロジック
  // ------------------------------------

  Future<void> saveRecordOnly() async {
    print("--- 記録のDB保存開始 ---"); 
    
    // 1. Recordオブジェクトの作成
    final newRecord = Record(
      recordId: _uuid.v4(), // 一意のIDを生成
      recordDate: DateTime.now(), // 現在日時
      moodTags: selectedMoodTags.toList(), // tagリスト
      moodScore: moodScore.round(), // スコアを整数に変換
      eventText: eventController.text.trim(), // 出来事テキスト
      selfAnalysis: detailController.text.trim(), // 内省テキスト
      location: locationName,     // 場所名
      weather: weather,           // 天気情報
    );

    try {
      // 2. データベースサービスを呼び出す
      await recordService.saveRecord(newRecord); 
      
      print("データベースへの保存成功: ID=${newRecord.recordId}");
      
      // 3. 保存完了後、フォームをリセット
      resetEntry();
      
    } catch (e) {
      print("データベース保存エラー: $e");
    }
  }

  void resetEntry() {
    _currentStepIndex = 1;
    selectedMoodTags.clear();
    moodScore = 5.0;
    eventController.clear();
    detailController.clear();
    _reflectionQuestion = ''; 
    _isGeneratingQuestion = false;
    notifyListeners();
  }
}