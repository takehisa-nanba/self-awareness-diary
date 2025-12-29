import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/diary_record.dart';
import 'history_provider.dart';
import '../services/environment_coordinator.dart';
import '../services/gemini_service.dart';
import '../../domain/repositories/diary_repository.dart'; // DiaryRepositoryをインポート

class WriteProvider with ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // 履歴スタッフ
  HistoryProvider? _historyProvider;

  final EnvironmentCoordinator _environmentCoordinator;
  final GeminiService _geminiService;
  final DiaryRepository _diaryRepository;

  // 入力データ
  int moodScore = 5;
  List<String> selectedTags = [];
  String eventText = "";
  String selfAnalysisText = "";
  String reflectionQuestion = "";

  // 位置・天気データ
  String? tempLocation;
  String? tempWeather;
  double? tempLat;
  double? tempLng;

  bool isGenerating = false;
  bool isSaving = false;

  WriteProvider(
    this._environmentCoordinator,
    this._geminiService,
    this._diaryRepository,
  );

  // UI更新用（履歴Providerとの連携）
  void update(HistoryProvider history) {
    _historyProvider = history;
    notifyListeners();
  }

  // 環境データの取得（店長への依頼）
  Future<void> fetchEnvironmentData() async {
    // UIに「取得中」と表示するのは、まだデータが何もない初回のみ
    if (tempLocation == null) {
      tempLocation = "位置情報取得中...";
      notifyListeners();
    }

    // 常に店長（Coordinator）に問い合わせる。キャッシュ管理は店長の責任。
    try {
      final data = await _environmentCoordinator.fetchFullData();

      // 取得したデータでUIを更新
      tempLocation = data.location;
      tempWeather = data.weather;
      tempLat = data.latitude;
      tempLng = data.longitude;
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
      reflectionQuestion = await _geminiService.generateReflectionQuestion(
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

      // 自己分析があればAI分析を実行
      if (selfAnalysisText.length >= 5) {
        try {
          final analysis = await _geminiService.analyzeStability(
            selfAnalysisText,
          );
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
        latitude: tempLat,
        longitude: tempLng,
      );

      // DiaryRepositoryに保存
      await _diaryRepository.saveRecord(record);
      debugPrint("日記保存完了: ${record.recordId}");

      // 履歴画面をリフレッシュ
      _historyProvider?.refreshHistory();

      _reset();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // 入力リセット（場所・天気・座標はあえて残す）
  void _reset() {
    _currentStep = 0;
    moodScore = 5;
    selectedTags = [];
    eventText = "";
    selfAnalysisText = "";
    reflectionQuestion = "";
    notifyListeners();
    debugPrint("WriteProvider：入力内容はリセット（場所情報はCoordinatorのキャッシュに依存）");
  }

  void notify() {
    notifyListeners();
  }
}
