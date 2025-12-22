import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_record.dart';
import 'history_provider.dart';
import '../services/environment_coordinator.dart';
import '../services/isar_service.dart';
import '../services/gemini_service.dart';

// WidgetsBindingObserver をミックスインしてアプリの開閉を監視
class WriteProvider with ChangeNotifier, WidgetsBindingObserver {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // 履歴スタッフ
  HistoryProvider? _historyProvider;

  // --- 20分ルール用の設定 ---
  DateTime? _lastPausedTime; 
  static const int _refreshThresholdMinutes = 20;

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

  // コンストラクタ：監視員としての登録
  WriteProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  // UI更新用（履歴Providerとの連携）
  void update(HistoryProvider history) {
    _historyProvider = history;
    notifyListeners();
  }

  // アプリの状態変化を検知
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // アプリが裏に回った時間を記録
      _lastPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // アプリに戻ってきた時に鮮度をチェック
      _checkLocationFreshness();
    }
  }

  // 20分経過判定ロジック
  void _checkLocationFreshness() {
    if (_lastPausedTime == null) return;

    final diff = DateTime.now().difference(_lastPausedTime!);
    
    if (diff.inMinutes >= _refreshThresholdMinutes) {
      debugPrint("WriteProvider：$_refreshThresholdMinutes分以上経過したため情報をリセットします");
      tempLocation = null;
      tempWeather = null;
      tempLat = null;
      tempLng = null;
      
      // 自動で最新情報を取得しにいく
      fetchEnvironmentData();
    } else {
      debugPrint("WriteProvider：20分以内のため情報を維持します（経過: ${diff.inMinutes}分）");
    }
  }

  // 環境データの取得（店長への依頼）
  Future<void> fetchEnvironmentData() async {
    // すでに取得済みなら何もしない
    if (tempLocation != null && tempLocation != "位置情報取得中...") return;

    try {
      tempLocation = "位置情報取得中...";
      notifyListeners();

      // 店長に一括依頼
      final data = await environmentCoordinator.fetchFullData();
      
      tempLocation = data.location;
      tempWeather = data.weather;
      // 店長から受け取った座標もしっかり保持
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

      // 自己分析があればAI分析を実行
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
        latitude: tempLat,  
        longitude: tempLng,
      );

      // Isarに保存
      await isarService.saveRecord(record);
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
    debugPrint("WriteProvider：入力内容はリセット（場所情報は30分維持モード）");
  }

  // 解放時に監視を解除
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void notify() {
    notifyListeners();
  }

}