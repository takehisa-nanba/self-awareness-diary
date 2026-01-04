// lib/providers/analysis_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:self_awareness_diary/domain/use_cases/get_universe_interpretation_use_case.dart';
import 'package:self_awareness_diary/domain/mappers/cosmic_map_to_prompt_mapper.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/providers/settings_provider.dart';
import '../domain/models/analysis_report.dart';
import '../domain/repositories/diary_repository.dart';
import '../services/gemini_service.dart';
import '../domain/mappers/ai_report_to_prompt_mapper.dart';
import 'diagnosis_provider.dart';
import 'package:self_awareness_diary/providers/subscription_provider.dart';

/// 分析グラフに表示するデータの種類を定義する列挙型。
enum AnalysisDataType { mood, pressure, temperature, polishing }

/// 分析画面の状態管理を行うプロバイダー。
class AnalysisProvider extends ChangeNotifier {
  // 依存サービスとUse Case (Nullable)
  DiaryRepository? _diaryRepository;
  GeminiService? _geminiService;
  GetUniverseInterpretationUseCase? _getUniverseInterpretationUseCase;

  // 連携プロバイダー (Nullable)
  SettingsProvider? _settingsProvider;
  DiagnosisProvider? _diagnosisProvider;
  SubscriptionProvider? _subscriptionProvider;

  // --- 状態 ---
  final Set<AnalysisDataType> activeDataTypes = {AnalysisDataType.mood};
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  AnalysisReport? _report;
  bool _isLoading = false;

  // チャート用AIの状態
  bool _isAiLoading = false;
  List<String> _aiInsights = [];

  // 宇宙図用の状態
  bool _isCosmicMapAiLoading = false;
  List<String> _cosmicMapInsights = [];

  // 動的フィードバック用の状態
  Timer? _debounce;
  double _timeSliderValue = 1.0;
  bool _isCloudy = false;
  bool _isInterpreting = false;
  String? _universeInterpretation;
  bool _isInterpretationVisible = false;
  Map<DiaryRecord, UniverseCoordinate> _visibleRecordCoordinates = {};
  DiaryRecord? _selectedRecord;
  String? _selectedRecordExplanation;
  bool _isExplanationLoading = false;
  FeatureStatus _interpretationStatus = FeatureStatus.forbidden;

  // --- ゲッター ---
  DateTimeRange get dateRange => _dateRange;
  AnalysisReport? get report => _report;
  bool get isLoading => _isLoading;
  bool get isAiLoading => _isAiLoading;
  List<String> get aiInsights => _aiInsights;
  bool get isCosmicMapAiLoading => _isCosmicMapAiLoading;
  List<String> get cosmicMapInsights => _cosmicMapInsights;
  double get timeSliderValue => _timeSliderValue;
  bool get isCloudy => _isCloudy;
  bool get isInterpreting => _isInterpreting;
  String? get universeInterpretation => _universeInterpretation;
  Map<DiaryRecord, UniverseCoordinate> get visibleRecordCoordinates => _visibleRecordCoordinates;
  Map<String, double> get indicatorAnglesRad => _report?.indicatorAnglesRad ?? {};
  bool get isInterpretationVisible => _isInterpretationVisible;
  DiaryRecord? get selectedRecord => _selectedRecord;
  String? get selectedRecordExplanation => _selectedRecordExplanation;
  bool get isExplanationLoading => _isExplanationLoading;
  FeatureStatus get interpretationStatus => _interpretationStatus;

  /// コンストラクタは空にする
  AnalysisProvider() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final startOfPeriod = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    _dateRange = DateTimeRange(start: startOfPeriod, end: endOfToday);
    // 初期データのロードはupdateProviders後に行う
  }

  /// 連携する他のプロバイダーやサービス、Use Caseのインスタンスを更新します。
  void updateProviders({
    required DiaryRepository diaryRepository,
    required GeminiService geminiService,
    required GetUniverseInterpretationUseCase getUniverseInterpretationUseCase,
    required SettingsProvider settings,
    required DiagnosisProvider diagnosis,
    required SubscriptionProvider subscription,
  }) {
    bool needsInitialization = _diaryRepository == null;
    _diaryRepository = diaryRepository;
    _geminiService = geminiService;
    _getUniverseInterpretationUseCase = getUniverseInterpretationUseCase;
    _settingsProvider = settings;
    _diagnosisProvider = diagnosis;
    _subscriptionProvider = subscription;

    if (needsInitialization) {
      changeDateRange(_dateRange);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void selectRecord(DiaryRecord? record) {
    if (_selectedRecord != record) {
      _selectedRecord = record;
      _selectedRecordExplanation = null;
      _isExplanationLoading = false;
      hideInterpretation();
      notifyListeners();
    }
  }

  Future<void> explainSelectedRecord() async {
    if (_selectedRecord == null || _report == null || _subscriptionProvider == null || _geminiService == null) return;

    _isExplanationLoading = true;
    _selectedRecordExplanation = null;
    notifyListeners();

    final status = await _subscriptionProvider!.checkFeatureStatus('record_insight');

    try {
      if (status == FeatureStatus.allowed || status == FeatureStatus.needsReward) {
        final coordinate = _report!.recordCoordinates[_selectedRecord!];
        if (coordinate == null) {
          throw Exception('Coordinate not found for the selected record.');
        }

        final explanation = await _geminiService!.explainRecordPosition(
          record: _selectedRecord!,
          userProfile: _report!.userProfile,
          coordinate: coordinate,
        );
        _selectedRecordExplanation = explanation;

        if (status == FeatureStatus.allowed) {
          _subscriptionProvider!.recordUsage('record_insight');
        }
      } else if (status == FeatureStatus.forbidden) {
        _selectedRecordExplanation = 'この機能は上位プランでご利用いただけます。';
      }
    } catch (e) {
      _selectedRecordExplanation = 'AIとの通信中にエラーが発生しました。';
    } finally {
      _isExplanationLoading = false;
      notifyListeners();
    }
  }

  void showInterpretation() {
    if (_universeInterpretation != null) {
      _isInterpretationVisible = true;
      notifyListeners();
    }
  }

  void hideInterpretation() {
    _isInterpretationVisible = false;
    notifyListeners();
  }

  void toggleInterpretationVisibility() {
    _isInterpretationVisible = !_isInterpretationVisible;
    notifyListeners();
  }

  void onTimeSliderChanged(double value) {
    _timeSliderValue = value;
    _isCloudy = false;
    _universeInterpretation = null;
    hideInterpretation();
    selectRecord(null);

    _updateVisibleCoordinates();

    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      triggerInterpretation();
    });
  }

  void _updateVisibleCoordinates() {
    if (_report == null) return;

    final allCoordinates = _report!.recordCoordinates.entries.toList();
    allCoordinates.sort((a, b) => a.key.recordDate.compareTo(b.key.recordDate));

    final totalDays = _report!.dateRange.duration.inDays;
    if (totalDays <= 7) {
      _visibleRecordCoordinates = _report!.recordCoordinates;
    } else {
      final windowSize = 7;
      final startIndex = (_timeSliderValue * (totalDays - windowSize)).floor();
      final startDate = _report!.dateRange.start.add(Duration(days: startIndex));
      final endDate = startDate.add(Duration(days: windowSize));

      final visibleEntries = allCoordinates.where((entry) {
        final recordDate = entry.key.recordDate;
        return recordDate.isAfter(startDate) && recordDate.isBefore(endDate);
      });
      _visibleRecordCoordinates = Map.fromEntries(visibleEntries);
    }
    debugPrint(
      '[AnalysisProvider] _updateVisibleCoordinates: Tier: ${_settingsProvider?.currentTier}, Visible records: ${_visibleRecordCoordinates.length}',
    );
    notifyListeners();
  }

  Future<void> triggerInterpretation() async {
    if (_report == null || _getUniverseInterpretationUseCase == null) return;

    _isInterpreting = true;
    _isCloudy = false;
    _universeInterpretation = null;
    notifyListeners();

    final params = GetUniverseInterpretationParams(
      report: _report!,
      visibleRecordCoordinates: _visibleRecordCoordinates,
    );

    final result = await _getUniverseInterpretationUseCase!.execute(params);

    if (result.status == FeatureStatus.notEnoughData) {
      _isCloudy = true;
    } else {
      _universeInterpretation = result.interpretation;
    }
    
    _interpretationStatus = result.status;
    _isInterpreting = false;
    notifyListeners();
  }

  Future<void> runFreeInterpretation(bool isMonthly) async {
    if (_subscriptionProvider == null) return;

    _isInterpreting = true;
    notifyListeners();

    try {
      final featureKey = isMonthly ? 'ai_interpretation_monthly' : 'ai_interpretation';
      await _subscriptionProvider!.recordUsage(featureKey);
      await triggerInterpretation();
    } catch (e) {
      debugPrint('【エラー】無料枠での解析実行に失敗しました: $e');
      rethrow;
    } finally {
      _isInterpreting = false;
      notifyListeners();
    }
  }

  Future<DiaryRecord> performManualAnalysis(DiaryRecord record) async {
    if (_geminiService == null || _diaryRepository == null) {
      throw Exception("Provider not fully initialized");
    }
    if (record.selfAnalysis == null || record.selfAnalysis!.isEmpty) {
      throw Exception("分析対象のテキストがありません。");
    }
    final userProfile = _diagnosisProvider?.userProfile;
    final analysisResult = await _geminiService!.analyzeStability(
      record.selfAnalysis!,
      userProfile,
    );
    final updatedRecord = record.copyWith(
      aiStabilityScore: analysisResult['score'],
      aiAnalysisReason: analysisResult['reason'],
    );
    await _diaryRepository!.saveRecord(updatedRecord);
    await _settingsProvider?.recordManualAnalysis();
    notifyListeners();
    return updatedRecord;
  }

  Future<void> changeDateRange(DateTimeRange newRange) async {
    if (_diaryRepository == null || _geminiService == null) return;

    _dateRange = newRange;
    _isLoading = true;
    _isAiLoading = true;
    _isCosmicMapAiLoading = true;
    _aiInsights = [];
    _cosmicMapInsights = [];
    _universeInterpretation = null;
    _isCloudy = false;
    notifyListeners();

    final records = await _diaryRepository!.getRecordsInDateRange(newRange.start, newRange.end);
    final currentUserProfile = _diagnosisProvider?.userProfile;

    if (currentUserProfile == null) {
      _report = null;
      _isLoading = false;
      _isAiLoading = false;
      _isCosmicMapAiLoading = false;
      notifyListeners();
      return;
    }

    _report = AnalysisReport(
      records: records,
      dateRange: newRange,
      userProfile: currentUserProfile,
      geminiService: _geminiService!,
    );
    _visibleRecordCoordinates = _report!.recordCoordinates;
    _isLoading = false;

    onTimeSliderChanged(1.0);

    notifyListeners();

    await fetchAiInsights();
    await fetchCosmicMapInsights();
  }

  Future<void> fetchAiInsights() async {
    if (_report == null || _geminiService == null) {
      _isAiLoading = false;
      notifyListeners();
      return;
    }
    final summary = AiReportToPromptMapper.toPrompt(_report!);
    try {
      final insights = await _geminiService!.generateAnalysisInsights(summary);
      _aiInsights = insights;
    } catch (e) {
      _aiInsights = ['チャートの分析中にエラーが発生しました。'];
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCosmicMapInsights() async {
    if (_report == null || _geminiService == null) {
      _isCosmicMapAiLoading = false;
      notifyListeners();
      return;
    }
    final summary = CosmicMapToPromptMapper.toPrompt(_report!);
    try {
      final insights = await _geminiService!.generateCosmicMapInsights(summary);
      _cosmicMapInsights = insights;
    } catch (e) {
      _cosmicMapInsights = ['宇宙図の解説生成中にエラーが発生しました。'];
    } finally {
      _isCosmicMapAiLoading = false;
      notifyListeners();
    }
  }

  void toggleDataType(AnalysisDataType dataType) {
    if (activeDataTypes.contains(dataType)) {
      if (dataType != AnalysisDataType.mood) {
        activeDataTypes.remove(dataType);
      }
    } else {
      activeDataTypes.add(dataType);
    }
    notifyListeners();
  }
}
