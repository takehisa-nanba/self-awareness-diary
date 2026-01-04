// lib/providers/write_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/use_cases/save_diary_entry_use_case.dart';

import '../services/ad_service.dart';
import '../services/environment_coordinator.dart';
import '../services/gemini_service.dart';
import 'settings_provider.dart';
import 'history_provider.dart';
import 'package:self_awareness_diary/providers/subscription_provider.dart';

/// 日記作成プロセス全体の状態を管理するプロバイダークラス。
class WriteProvider with ChangeNotifier {
  // 依存サービスとUse Case (Nullable)
  EnvironmentCoordinator? _environmentCoordinator;
  GeminiService? _geminiService;
  AdService? _adService;
  SaveDiaryEntryUseCase? _saveDiaryEntryUseCase;

  // 連携プロバイダー (Nullable)
  HistoryProvider? _historyProvider;
  SettingsProvider? settingsProvider;
  SubscriptionProvider? _subscriptionProvider;

  // 状態フラグ
  int _currentStep = 0;
  int get currentStep => _currentStep;
  int? isarId;
  bool isHistoricalFlow = false;
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
  DateTime? _historicalDate;

  /// コンストラクタは空にする
  WriteProvider();

  /// 連携する他のプロバイダーやサービス、Use Caseのインスタンスを更新します。
  void updateProviders({
    required HistoryProvider history,
    required SettingsProvider settings,
    required SubscriptionProvider subscription,
    required EnvironmentCoordinator environmentCoordinator,
    required GeminiService geminiService,
    required AdService adService,
    required SaveDiaryEntryUseCase saveDiaryEntryUseCase,
  }) {
    _historyProvider = history;
    settingsProvider = settings;
    _subscriptionProvider = subscription;
    _environmentCoordinator = environmentCoordinator;
    _geminiService = geminiService;
    _adService = adService;
    _saveDiaryEntryUseCase = saveDiaryEntryUseCase;
    // Note: ここではnotifyListeners()は不要な場合が多い
  }

  void initForEdit(DiaryRecord record) {
    _reset();
    isHistoricalFlow = true;
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

  void initForHistorical(DateTime date, String location, double lat, double lon) {
    _reset();
    isHistoricalFlow = true;
    _historicalDate = date;
    tempLocation = location;
    tempLat = lat;
    tempLng = lon;
    _fetchHistoricalWeather(date, lat, lon);
    notifyListeners();
  }

  Future<void> fetchCurrentEnvironmentData() async {
    if (_subscriptionProvider == null || _environmentCoordinator == null) return;
    if (tempLocation == null) {
      tempLocation = "位置情報取得中...";
      notifyListeners();
    }
    try {
      final status = await _subscriptionProvider!.checkFeatureStatus('weather_current');
      if (status == FeatureStatus.allowed) {
        final data = await _environmentCoordinator!.fetchFullData();
        tempLocation = data.location;
        tempWeather = data.weather;
        tempLat = data.latitude;
        tempLng = data.longitude;
        _subscriptionProvider!.recordUsage('weather_current');
      } else {
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

  Future<void> _fetchHistoricalWeather(DateTime date, double lat, double lon) async {
    if (_subscriptionProvider == null || _environmentCoordinator == null || _adService == null) return;

    tempWeather = "気象情報取得中...";
    notifyListeners();

    final status = await _subscriptionProvider!.checkFeatureStatus('weather_historical');

    if (status == FeatureStatus.allowed) {
      try {
        final weather = await _environmentCoordinator!.getHistoricalWeather(lat, lon, date);
        tempWeather = weather;
        _subscriptionProvider!.recordUsage('weather_historical');
      } catch (e) {
        tempWeather = "取得失敗";
      } finally {
        notifyListeners();
      }
    } else if (status == FeatureStatus.needsInterstitial) {
      _adService!.showInterstitialAd(() async {
        try {
          final weather = await _environmentCoordinator!.getHistoricalWeather(lat, lon, date);
          tempWeather = weather;
          _subscriptionProvider!.recordUsage('weather_historical');
        } catch (e) {
          tempWeather = "取得失敗";
        } finally {
          notifyListeners();
        }
      });
    } else {
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
    if (eventText.isEmpty || _subscriptionProvider == null || _adService == null) return;

    final status = await _subscriptionProvider!.checkFeatureStatus('ai_write_assist');

    if (status == FeatureStatus.allowed) {
      await _generateReflectionQuestion();
      _subscriptionProvider!.recordUsage('ai_write_assist');
    } else if (status == FeatureStatus.needsReward) {
      _adService!.showRewardedAd(() async {
        await _generateReflectionQuestion();
        _subscriptionProvider!.recordUsage('ai_write_assist');
      });
    } else if (status == FeatureStatus.forbidden) {
      reflectionQuestion = "AIによる深掘り質問は上位プラン限定です。";
    }
    notifyListeners();
  }

  Future<void> _generateReflectionQuestion() async {
    if (_geminiService == null) return;
    isGenerating = true;
    notifyListeners();
    try {
      reflectionQuestion = await _geminiService!.generateReflectionQuestion(
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

  Future<void> save({bool runAi = false}) async {
    if (_saveDiaryEntryUseCase == null || _historyProvider == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final params = SaveDiaryEntryParams(
        runAi: runAi,
        selfAnalysisText: selfAnalysisText,
        isarId: isarId,
        isHistoricalFlow: isHistoricalFlow,
        historicalDate: _historicalDate,
        moodTags: selectedTags,
        moodScore: moodScore,
        eventText: eventText,
        location: tempLocation,
        weather: tempWeather,
        latitude: tempLat,
        longitude: tempLng,
      );
      await _saveDiaryEntryUseCase!.execute(params);

      _historyProvider!.refreshHistory();
      _reset();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _reset() {
    _currentStep = 0;
    isarId = null;
    isHistoricalFlow = false;
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
