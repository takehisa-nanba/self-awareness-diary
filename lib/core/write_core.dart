// lib/core/write_core.dart (修正版)

import 'package:flutter/material.dart';
import 'dart:developer';
import '../services/gemini_service.dart'; // ★★★ 追加 ★★★

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
  double moodScore = 5.0; // デフォルトは5
  TextEditingController eventController = TextEditingController();
  TextEditingController detailController = TextEditingController();

  // AIからの内省の質問を格納するフィールド ★★★ 追加 ★★★
  String _reflectionQuestion = '';
  String get reflectionQuestion => _reflectionQuestion;
  bool _isGeneratingQuestion = false;
  bool get isGeneratingQuestion => _isGeneratingQuestion;

  // 環境データ (ダミー値)
  String locationName = '東京駅';
  String weather = '晴れ';

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
    // 実際にはAPIからの取得完了をチェックする
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
        // ステップ3では必須入力なし (保存はいつでも可能)
        return true; 
      default:
        return false;
    }
  }

  void nextStep() async {
    if (!isStepValid()) return;

    if (_currentStepIndex == 2) {
      // ステップ2から3に遷移する際、AIに質問生成を依頼する
      await generateQuestion(); // ★★★ AI呼び出し ★★★
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
  // AI連携メソッド ★★★ 追加 ★★★
  // ------------------------------------
  
  Future<void> generateQuestion() async {
    // 出来事の入力がない場合は実行しない
    if (eventController.text.trim().isEmpty) return; 

    _isGeneratingQuestion = true;
    _reflectionQuestion = 'AIコーチが質問を考えています...'; // 処理中のメッセージ
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
    // F-8: ローカルDBへの保存ロジック (TODO: 後続タスクで実装)
    log("--- 記録を保存 ---");
    log("タグ: ${selectedMoodTags.join(', ')}");
    log("スコア: $moodScore");
    log("出来事: ${eventController.text}");
    log("内省: ${detailController.text}");
    log("質問: $_reflectionQuestion");
  }

  void resetEntry() {
    _currentStepIndex = 1;
    selectedMoodTags.clear();
    moodScore = 5.0;
    eventController.clear();
    detailController.clear();
    _reflectionQuestion = ''; // 質問もリセット
    _isGeneratingQuestion = false;
    notifyListeners();
  }
}