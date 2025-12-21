// lib/providers/write_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_record.dart';
import '../services/environment_coordinator.dart';
import '../services/isar_service.dart';
import '../services/gemini_service.dart';

class WriteProvider with ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // 入力データ
  int moodScore = 5;
  List<String> selectedTags = [];
  String eventText = "";
  String selfAnalysisText = "";
  String reflectionQuestion = "";
  String? tempLocation;
  String? tempWeather;
  
  bool isGenerating = false;
  bool isSaving = false;

  // UI更新用
  void update() => notifyListeners();

  Future<void> fetchEnvironmentData() async {
    // すでに取得済みなら何もしない
    if (tempLocation != null && tempLocation != "位置情報取得中...") return;

    try {
      tempLocation = "位置情報取得中...";
      notifyListeners();

      // 店長に一括依頼（待ち処理は店長が中でやってくれる）
      final data = await environmentCoordinator.fetchFullData();
      
      tempLocation = data.location;
      tempWeather = data.weather;
      
    } catch (e) {
      debugPrint("識別依頼エラー: $e");
      tempLocation = "位置情報取得失敗";
    } finally {
      notifyListeners();
    }
  }

  // ステップ制御
  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // Geminiによる深掘り質問の生成
  Future<void> prepareReflection() async {
    if (eventText.isEmpty) return;
    
    isGenerating = true;
    notifyListeners();
    
    try {
      reflectionQuestion = await geminiService.generateReflectionQuestion(
        eventText: eventText,
        tags: selectedTags.join(', '),
      );
    } catch (e) {
      reflectionQuestion = "その出来事は、あなたにとってどんな意味がありましたか？";
      debugPrint("Gemini Error: $e");
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  // 保存処理
  Future<void> save() async {
    isSaving = true;
    notifyListeners();

    try {
      int? aiScore;
      String? aiReason;

      // 自己分析が入力されていればAI分析を実行
      if (selfAnalysisText.length >= 5) {
        try {
          final analysis = await geminiService.analyzeStability(selfAnalysisText);
          aiScore = analysis['score'];
          aiReason = analysis['reason'];
        } catch (e) {
          debugPrint("AI Analysis Error: $e");
        }
      }

      // DiaryRecordモデルの作成
      final record = DiaryRecord(
        recordId: const Uuid().v4(),
        recordDate: DateTime.now(),
        moodTags: List.from(selectedTags),
        moodScore: moodScore,
        eventText: eventText,
        selfAnalysis: selfAnalysisText,
        aiStabilityScore: aiScore,
        aiAnalysisReason: aiReason,
        location: tempLocation,
        weather: tempWeather,
      );

      // Isarに保存
      await isarService.saveRecord(record);
      
      _reset();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
  
  void _reset() {
    _currentStep = 0;
    moodScore = 5;
    selectedTags = [];
    eventText = "";
    selfAnalysisText = "";
    reflectionQuestion = "";
    notifyListeners();
  }
}