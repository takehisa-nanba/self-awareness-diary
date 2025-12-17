// lib/core/write_core.dart (構造復元版)

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 
import '../services/location_weather_service.dart'; // 位置情報・天気サービス
import '../services/gemini_service.dart'; // Gemini AIサービス
import '../services/record_service.dart'; // DBサービス
import '../models/record.dart'; // Recordモデル

const _uuid = Uuid(); 

class WriteCore extends ChangeNotifier {
  bool _isLoadingAi = false;
  bool get isLoadingAi => _isLoadingAi;
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

  Future<void> nextStep() async {
      if (_currentStepIndex == 2) {
        _isLoadingAi = true;
        notifyListeners();

        try {
          // ここで GeminiService などを呼び出しているはずです
          // 例: await generateAiFeedback();
          await generateQuestion();
          // 解析が終わったら進む
          _currentStepIndex++;
        } finally {
          _isLoadingAi = false;
          notifyListeners();
        }
      } else if (_currentStepIndex < 3) {
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
  Future<void> _internalFetchLocationAndWeather() async {
    try {
      final data = await locationWeatherService.getLocationAndWeather();
      
      locationName = data['locationName'] ?? '場所不明';
      weather = data['weather'] ?? '天気不明';

      print('位置情報ロード完了: $locationName, $weather');
    } catch (e) {
      locationName = '取得失敗 (タップして再試行)';
      weather = 'エラー';
      print('位置情報取得エラー: $e');
    } finally {
      notifyListeners();
    }
  }

  // 初回ロード用
  Future<void> loadLocationAndWeather() async {
    print('--- F-2: 位置情報と天気情報の取得開始 ---');
    await _internalFetchLocationAndWeather();
  }
  
  // ★★★ タップ時の再取得ロジック ★★★
  Future<void> retryLocationAndWeather() async {
    // 状態をリセット
    locationName = "場所特定中...";
    weather = "...";
    notifyListeners();

    // 取得処理を実行
    await _internalFetchLocationAndWeather();
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

    // 1. AIによる安定度診断を実行
    // 詳細(detailController)があればそれを、なければ出来事(eventController)を対象にする
    String textToAnalyze = detailController.text.trim().isNotEmpty 
        ? detailController.text.trim() 
        : eventController.text.trim();

    int aiScore = 50; // デフォルト値
    String aiReason = "分析未実施";

    try {
      final analysis = await geminiService.analyzeStability(textToAnalyze);
      aiScore = analysis['score'] ?? 50;
      aiReason = analysis['reason'] ?? "分析に失敗しました";
      print("AI診断完了: スコア $aiScore / 理由: $aiReason");
    } catch (e) {
      print("保存時のAI診断エラー: $e");
    }

    // 2. Recordオブジェクトの作成（AIスコアを反映）
    final newRecord = Record(
      recordId: _uuid.v4(),
      recordDate: DateTime.now(),
      moodTags: selectedMoodTags.toList(),
      moodScore: moodScore.round(),
      eventText: eventController.text.trim(),
      selfAnalysis: detailController.text.trim(),
      // ★ 追加したフィールドにAIの解析結果を入れる
      aiStabilityScore: aiScore,
      aiAnalysisReason: aiReason,
      location: locationName,
      weather: weather,
    );

    try {
      await recordService.saveRecord(newRecord);
      print("データベースへの保存成功: ID=${newRecord.recordId} (AI安定度: $aiScore)");
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