// lib/providers/write_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/diary_record.dart';
import '../../domain/repositories/diary_repository.dart';
import '../services/ad_service.dart';
import '../services/environment_coordinator.dart';
import '../services/gemini_service.dart';
import 'history_provider.dart';
import 'settings_provider.dart';
import 'diagnosis_provider.dart'; // DiagnosisProviderをインポート

/// 日記作成プロセス全体の状態を管理するプロバイダークラス。
class WriteProvider with ChangeNotifier {
  // 依存サービス
  final EnvironmentCoordinator _environmentCoordinator;
  final GeminiService _geminiService;
  final DiaryRepository _diaryRepository;
  final AdService _adService;

  // 連携プロバイダー
  HistoryProvider? _historyProvider;
  SettingsProvider? _settingsProvider;
  DiagnosisProvider? _diagnosisProvider; // DiagnosisProviderを追加

  // 状態フラグ
  int _currentStep = 0;
  int get currentStep => _currentStep;
  int? isarId;
  bool isHistoricalFlow = false; // 過去の記録/編集フローかどうかのフラグ
  bool isGenerating = false;
  bool isSaving = false;

  // 入力データ
  int moodScore = 5;
  List<String> selectedTags = [];
  String eventText = "";
  String selfAnalysisText = "";
  String reflectionQuestion = "";

  // 環境データ
  String? tempLocation;
  String? tempWeather;
  double? tempLat;
  double? tempLng;
  DateTime? _historicalDate; // 過去記録時の日付

  WriteProvider(
    this._environmentCoordinator,
    this._geminiService,
    this._diaryRepository,
    this._adService,
    this._diagnosisProvider, // コンストラクタ引数に追加
  );

  /// 連携する他のプロバイダーインスタンスを更新します。
  ///
  /// [history] HistoryProviderのインスタンス。
  /// [settings] SettingsProviderのインスタンス。
  /// [diagnosis] DiagnosisProviderのインスタンス。
  void updateProviders(
    HistoryProvider history,
    SettingsProvider settings,
    DiagnosisProvider diagnosis,
  ) {
    _historyProvider = history;
    _settingsProvider = settings;
    _diagnosisProvider = diagnosis; // diagnosisProviderも更新
    notifyListeners();
  }

  void initForEdit(DiaryRecord record) {
    _reset();
    isHistoricalFlow = true; // 編集も過去のフローと見なす
    _currentStep = 2;
    isarId = record.isarId;
    moodScore = record.moodScore;
    selectedTags = List.from(record.moodTags);
    eventText = record.eventText;
    selfAnalysisText = record.selfAnalysis ?? "";
    tempLocation = record.location;
    tempWeather = record.weather;
    tempLat = record.latitude;
    tempLng = record.longitude;
    _historicalDate = record.recordDate;
    reflectionQuestion = "";
    notifyListeners();
  }

  void initForHistorical(
    DateTime date,
    String location,
    double lat,
    double lon,
  ) {
    _reset();
    isHistoricalFlow = true;
    _historicalDate = date;
    tempLocation = location;
    tempLat = lat;
    tempLng = lon;

    // 広告表示後に過去の天気を取得
    _fetchHistoricalWeather(date, lat, lon);
    notifyListeners();
  }

  Future<void> fetchCurrentEnvironmentData() async {
    if (tempLocation == null) {
      tempLocation = "位置情報取得中...";
      notifyListeners();
    }
    try {
      final data = await _environmentCoordinator.fetchFullData();
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

  void _fetchHistoricalWeather(DateTime date, double lat, double lon) {
    tempWeather = "気象情報取得中...";
    notifyListeners();

    // 無料ユーザーの場合、インタースティシャル広告を表示
    if (_settingsProvider?.currentTier == SubscriptionTier.free) {
      _adService.showInterstitialAd(() async {
        try {
          final weather = await _environmentCoordinator.getHistoricalWeather(
            lat,
            lon,
            date,
          );
          tempWeather = weather;
        } catch (e) {
          tempWeather = "取得失敗";
        } finally {
          notifyListeners();
        }
      });
    } else {
      // 有料ユーザーは広告なし
      _environmentCoordinator
          .getHistoricalWeather(lat, lon, date)
          .then((weather) {
            tempWeather = weather;
          })
          .catchError((_) {
            tempWeather = "取得失敗";
          })
          .whenComplete(notifyListeners);
    }
  }

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

  Future<void> prepareReflection() async {
    if (eventText.isEmpty) return;

    // 無料ユーザーはリワード広告を見てから実行
    if (_settingsProvider?.currentTier == SubscriptionTier.free) {
      _adService.showRewardedAd(_generateReflectionQuestion);
    } else {
      await _generateReflectionQuestion();
    }
  }

  /// AIによる深掘り質問を生成するプライベートメソッド。
  Future<void> _generateReflectionQuestion() async {
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

  /// AI安定度分析を実行し、結果を返すプライベートメソッド。
  ///
  /// UserProfileをDiagnosisProviderから取得し、GeminiService.analyzeStabilityに渡します。
  Future<Map<String, dynamic>?> _performAiAnalysis() async {
    try {
      // DiagnosisProviderからUserProfileを取得
      final userProfile = _diagnosisProvider?.userProfile;

      final analysis = await _geminiService.analyzeStability(
        selfAnalysisText,
        userProfile, // UserProfileを渡す
      );
      return {'score': analysis['score'], 'reason': analysis['reason']};
    } catch (e) {
      debugPrint("AI Analysis Error: $e");
      return null;
    }
  }

  Future<void> save() async {
    isSaving = true;
    notifyListeners();

    Map<String, dynamic>? analysisResult; // Initialize to null

    // Only proceed with AI analysis logic if there's self-analysis text
    if (selfAnalysisText.isNotEmpty) {
      // Ensure settingsProvider is initialized
      if (_settingsProvider == null) {
        debugPrint(
          "SettingsProvider is not initialized. Cannot perform AI analysis.",
        );
      } else {
        final currentTier = _settingsProvider!.currentTier;

        // Tier 2: Automatic analysis
        if (currentTier == SubscriptionTier.tier2) {
          debugPrint("Tier 2: Performing automatic AI analysis.");
          analysisResult = await _performAiAnalysis();
        }
        // Free Tier: Analysis is triggered by Rewarded Ad
        else if (currentTier == SubscriptionTier.free) {
          debugPrint("Free Tier: Showing Rewarded Ad for AI analysis.");
          Completer<void> adCompleter = Completer();
          _adService.showRewardedAd(() async {
            debugPrint("Rewarded Ad shown. Performing AI analysis.");
            analysisResult = await _performAiAnalysis();
            adCompleter.complete();
          });
          await adCompleter.future; // Wait for ad and analysis to complete
        }
        // Other tiers (e.g., Tier 1): No automatic analysis, as per requirement.
        // analysisResult remains null.
        else {
          debugPrint(
            "Tier ${currentTier.toString()} does not support automatic AI analysis. Analysis skipped.",
          );
        }
      }
    } else {
      debugPrint("No self-analysis text provided. AI analysis skipped.");
    }

    try {
      final record = DiaryRecord(
        isarId: isarId,
        recordId: isarId != null
            ? (await _diaryRepository.getRecordByIsarId(isarId!))!.recordId
            : const Uuid().v4(),
        recordDate: isHistoricalFlow ? _historicalDate! : DateTime.now(),
        moodTags: List.from(selectedTags),
        moodScore: moodScore,
        eventText: eventText,
        selfAnalysis: selfAnalysisText,
        aiStabilityScore:
            analysisResult?['score'], // Will be null if no analysis performed
        aiAnalysisReason:
            analysisResult?['reason'], // Will be null if no analysis performed
        location: tempLocation,
        weather: tempWeather,
        latitude: tempLat,
        longitude: tempLng,
      );

      await _diaryRepository.saveRecord(record);
      debugPrint("日記${isarId == null ? '保存' : '更新'}完了: ${record.recordId}");

      _historyProvider?.refreshHistory();
      _reset();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _reset() {
    _currentStep = 0;
    isarId = null;
    isHistoricalFlow = false; // フラグをリセット
    moodScore = 5;
    selectedTags = [];
    eventText = "";
    selfAnalysisText = "";
    reflectionQuestion = "";
    tempLocation = null;
    tempWeather = null;
    tempLat = null;
    tempLng = null;
    _historicalDate = null;
    notifyListeners();
    debugPrint("WriteProvider：入力内容はリセットされました。");
  }

  void notify() {
    notifyListeners();
  }
}
