// lib/providers/write_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/diary_record.dart';
import '../../domain/repositories/diary_repository.dart';
import '../services/ad_service.dart';
import '../services/environment_coordinator.dart';
import '../services/gemini_service.dart';
import 'settings_provider.dart'; // SettingsProviderをインポート
import 'history_provider.dart'; // HistoryProviderをインポート
import 'diagnosis_provider.dart'; // DiagnosisProviderをインポート
import 'package:self_awareness_diary/providers/subscription_provider.dart'; // SubscriptionProviderとFeatureStatusをインポート
import 'package:self_awareness_diary/domain/models/subscription_tier.dart'; // SubscriptionTierをインポート

/// 日記作成プロセス全体の状態を管理するプロバイダークラス。
class WriteProvider with ChangeNotifier {
  // 依存サービス
  final EnvironmentCoordinator _environmentCoordinator;
  final GeminiService _geminiService;
  final DiaryRepository _diaryRepository;
  final AdService _adService;

  // 連携プロバイダー
  HistoryProvider? _historyProvider;
  SettingsProvider? settingsProvider; // SettingsProviderを追加
  DiagnosisProvider? _diagnosisProvider;
  SubscriptionProvider? _subscriptionProvider; // SubscriptionProviderを追加

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
    // DiagnosisProviderはupdateProvidersで渡す
  );

  /// 連携する他のプロバイダーインスタンスを更新します。
  ///
  /// [history] HistoryProviderのインスタンス。
  /// [settings] SettingsProviderのインスタンス。
  /// [diagnosis] DiagnosisProviderのインスタンス。
  /// [subscription] SubscriptionProviderのインスタンス。
  void updateProviders(
    HistoryProvider history,
    SettingsProvider settings,
    DiagnosisProvider diagnosis,
    SubscriptionProvider subscription, // SubscriptionProviderを追加
  ) {
    _historyProvider = history;
    settingsProvider = settings; // settingsProviderを更新
    _diagnosisProvider = diagnosis;
    _subscriptionProvider = subscription; // subscriptionProviderも更新
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
      final status = await _subscriptionProvider!.checkFeatureStatus(
        'weather_current',
      );
      if (status == FeatureStatus.allowed) {
        final data = await _environmentCoordinator.fetchFullData();
        tempLocation = data.location;
        tempWeather = data.weather;
        tempLat = data.latitude;
        tempLng = data.longitude;
        _subscriptionProvider!.recordUsage('weather_current'); // 利用を記録
      } else {
        // 現在の天気は常にallowedのはずだが、念のため
        tempLocation = "位置情報取得失敗";
        tempWeather = "取得失敗";
      }
    } catch (e) {
      debugPrint("識別依頼エラー: $e");
      tempLocation = "位置情報取得失敗";
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchHistoricalWeather(
    DateTime date,
    double lat,
    double lon,
  ) async {
    tempWeather = "気象情報取得中...";
    notifyListeners();

    final status = await _subscriptionProvider!.checkFeatureStatus(
      'weather_historical',
    );

    if (status == FeatureStatus.allowed) {
      try {
        final weather = await _environmentCoordinator.getHistoricalWeather(
          lat,
          lon,
          date,
        );
        tempWeather = weather;
        _subscriptionProvider!.recordUsage('weather_historical'); // 利用を記録
      } catch (e) {
        tempWeather = "取得失敗";
      } finally {
        notifyListeners();
      }
    } else if (status == FeatureStatus.needsInterstitial) {
      _adService.showInterstitialAd(() async {
        try {
          final weather = await _environmentCoordinator.getHistoricalWeather(
            lat,
            lon,
            date,
          );
          tempWeather = weather;
          _subscriptionProvider!.recordUsage('weather_historical'); // 利用を記録
        } catch (e) {
          tempWeather = "取得失敗";
        } finally {
          notifyListeners();
        }
      });
    } else {
      // forbiddenの場合など
      tempWeather = "上位プラン限定";
      notifyListeners();
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

    if (_subscriptionProvider == null) {
      debugPrint("SubscriptionProvider is not available.");
      // デフォルトの動作、またはエラー処理
      reflectionQuestion = "その出来事は、あなたにとってどんな意味がありましたか？";
      notifyListeners();
      return;
    }

    final status = await _subscriptionProvider!.checkFeatureStatus(
      'ai_write_assist',
    );

    if (status == FeatureStatus.allowed) {
      await _generateReflectionQuestion();
      _subscriptionProvider!.recordUsage('ai_write_assist'); // 利用を記録
    } else if (status == FeatureStatus.needsReward) {
      // Freeティアはリワード広告を見てから実行
      _adService.showRewardedAd(() async {
        await _generateReflectionQuestion();
        _subscriptionProvider!.recordUsage('ai_write_assist'); // 利用を記録
      });
    } else if (status == FeatureStatus.forbidden) {
      reflectionQuestion = "AIによる深掘り質問は上位プラン限定です。";
    }
    notifyListeners();
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

  Future<void> save({bool runAi = false}) async {
    isSaving = true;
    notifyListeners();

    Map<String, dynamic>? analysisResult; // Initialize to null

    // FreeティアではrunAi=trueでもAI分析を行わない
    if (_subscriptionProvider?.currentTier == SubscriptionTier.free) {
      debugPrint("FreeティアのためAI分析は実行されません。");
      runAi = false; // runAiフラグを強制的にfalseにする
    }

    // Only proceed with AI analysis logic if there's self-analysis text AND runAi is true
    if (selfAnalysisText.isNotEmpty && runAi) {
      if (_subscriptionProvider == null) {
        debugPrint("SubscriptionProvider is not available.");
        return;
      }

      final status = await _subscriptionProvider!.checkFeatureStatus(
        'ai_write_eval',
      );

      if (status == FeatureStatus.allowed) {
        debugPrint("AI Write Eval: Allowed. Performing AI analysis.");
        analysisResult = await _performAiAnalysis();
        _subscriptionProvider!.recordUsage('ai_write_eval'); // 利用を記録
      } else if (status == FeatureStatus.needsReward) {
        debugPrint(
          "AI Write Eval: Needs Reward. Showing Rewarded Ad for AI analysis.",
        );
        Completer<void> adCompleter = Completer();
        _adService.showRewardedAd(() async {
          debugPrint("Rewarded Ad shown. Performing AI analysis.");
          analysisResult = await _performAiAnalysis();
          _subscriptionProvider!.recordUsage('ai_write_eval'); // 利用を記録
          adCompleter.complete();
        });
        await adCompleter.future; // Wait for ad and analysis to complete
      } else if (status == FeatureStatus.forbidden) {
        debugPrint(
          "AI Write Eval: Forbidden. AI analysis skipped for this tier.",
        );
        // UIでメッセージ表示が必要な場合は別途実装
        analysisResult = {'score': null, 'reason': 'この機能は上位プラン限定です。'};
      } else {
        debugPrint("AI Write Eval: Unexpected status. AI analysis skipped.");
      }
    } else {
      debugPrint(
        "No self-analysis text provided or runAi is false. AI analysis skipped.",
      );
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
