// lib/providers/analysis_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:self_awareness_diary/domain/mappers/cosmic_map_to_prompt_mapper.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/providers/settings_provider.dart';
import '../domain/models/analysis_report.dart';
import '../domain/repositories/diary_repository.dart';
import '../services/gemini_service.dart';
import '../domain/mappers/ai_report_to_prompt_mapper.dart';
import 'diagnosis_provider.dart';

/// 分析グラフに表示するデータの種類を定義する列挙型。
enum AnalysisDataType { mood, pressure, temperature, polishing }

/// 分析画面の状態管理を行うプロバイダー。
class AnalysisProvider extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final GeminiService _geminiService;
  SettingsProvider? _settingsProvider;
  DiagnosisProvider? _diagnosisProvider;

  // --- 状態 ---
  final Set<AnalysisDataType> activeDataTypes = {AnalysisDataType.mood};
  DateTimeRange _dateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
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
  bool _isInterpretationVisible = false; // ★追加
  Map<DiaryRecord, UniverseCoordinate> _visibleRecordCoordinates = {};
  DiaryRecord? _selectedRecord;
  String? _selectedRecordExplanation;
  bool _isExplanationLoading = false;

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
  bool get isInterpretationVisible => _isInterpretationVisible; // ★追加
  DiaryRecord? get selectedRecord => _selectedRecord;
  String? get selectedRecordExplanation => _selectedRecordExplanation;
  bool get isExplanationLoading => _isExplanationLoading;

  AnalysisProvider(this._diaryRepository, this._geminiService) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final startOfPeriod = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final initialRange = DateTimeRange(start: startOfPeriod, end: endOfToday);
    changeDateRange(initialRange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
  }

  void updateDiagnosisProvider(DiagnosisProvider diagnosis) {
    _diagnosisProvider = diagnosis;
  }

  /// ユーザーがタップした星（日記レコード）を選択状態にする。
  /// [record]がnullの場合、選択を解除する。
  void selectRecord(DiaryRecord? record) {
    if (_selectedRecord != record) {
      _selectedRecord = record;
      _selectedRecordExplanation = null; // 選択が変更されたら解説をクリア
      _isExplanationLoading = false;
      hideInterpretation(); // ★追加: 星選択時/選択解除時は全体の解説を隠す
      notifyListeners();
    }
  }

  /// 選択された星（日記）の位置についてAIに解説を求める。
  Future<void> explainSelectedRecord() async {
    if (_selectedRecord == null || _report == null) return;

    _isExplanationLoading = true;
    _selectedRecordExplanation = null;
    notifyListeners();

    try {
      final coordinate = _report!.recordCoordinates[_selectedRecord!];
      if (coordinate == null) {
        throw Exception('Coordinate not found for the selected record.');
      }

      final explanation = await _geminiService.explainRecordPosition(
        record: _selectedRecord!,
        userProfile: _report!.userProfile,
        coordinate: coordinate,
      );
      _selectedRecordExplanation = explanation;
    } catch (e) {
      _selectedRecordExplanation = 'AIとの通信中にエラーが発生しました。';
    } finally {
      _isExplanationLoading = false;
      notifyListeners();
    }
  }

  /// 全体のAI解説を表示する。
  void showInterpretation() {
    if (_universeInterpretation != null) {
      _isInterpretationVisible = true;
      notifyListeners();
    }
  }

  /// 全体のAI解説を非表示にする。
  void hideInterpretation() {
    _isInterpretationVisible = false;
    notifyListeners();
  }

  /// 時間スライダーの値が変更されたときに呼び出される。
  void onTimeSliderChanged(double value) {
    _timeSliderValue = value;
    _isCloudy = false;
    _universeInterpretation = null;
    hideInterpretation(); // ★追加
    selectRecord(null); // スライダー操作時は選択を解除
    
    // スライダー操作中は表示する星をリアルタイムで更新
    _updateVisibleCoordinates();
    
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _triggerInterpretation();
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
      final startIndex =
          (_timeSliderValue * (totalDays - windowSize)).floor();
      final startDate =
          _report!.dateRange.start.add(Duration(days: startIndex));
      final endDate = startDate.add(Duration(days: windowSize));

      final visibleEntries = allCoordinates.where((entry) {
        final recordDate = entry.key.recordDate;
        return recordDate.isAfter(startDate) && recordDate.isBefore(endDate);
      });
      _visibleRecordCoordinates = Map.fromEntries(visibleEntries);
    }
    debugPrint(
        '[AnalysisProvider] _updateVisibleCoordinates: Tier: ${_settingsProvider?.currentTier}, Visible records: ${_visibleRecordCoordinates.length}');
    notifyListeners();
  }

  /// スライダー操作のデバウンス後に実行される処理。
  Future<void> _triggerInterpretation() async {
    if (_report == null) return;

    debugPrint(
        '[AnalysisProvider] _triggerInterpretation START: Tier: ${_settingsProvider?.currentTier}, Visible records: ${_visibleRecordCoordinates.length}');

    _isInterpreting = true;
    _isCloudy = false;
    _universeInterpretation = null;
    notifyListeners();

    // データ密度のチェック
    if (_visibleRecordCoordinates.length < 3) {
      _isCloudy = true;
      _isInterpreting = false;
      notifyListeners();
      return;
    }

    if (_settingsProvider?.currentTier == SubscriptionTier.free) {
      _universeInterpretation = 'この機能は上位プランでご利用いただけます。';
      _isInterpreting = false;
      notifyListeners();
      return;
    }
    
    try {
      final tempReport = AnalysisReport(
        records: _visibleRecordCoordinates.keys.toList(),
        dateRange: _report!.dateRange, // 期間は全体のまま
        userProfile: _report!.userProfile,
      );
      final promptSummary = CosmicMapToPromptMapper.toPrompt(tempReport);
      final interpretation = await _geminiService.interpretCosmicMap(promptSummary);
      _universeInterpretation = interpretation;
    } catch (e) {
      _universeInterpretation = 'AIとの通信に失敗しました。';
    } finally {
      _isInterpreting = false;
      notifyListeners();
    }
  }

  Future<DiaryRecord> performManualAnalysis(DiaryRecord record) async {
    if (record.selfAnalysis == null || record.selfAnalysis!.isEmpty) {
      throw Exception("分析対象のテキストがありません。");
    }
    final userProfile = _diagnosisProvider?.userProfile;
    final analysisResult = await _geminiService.analyzeStability(
      record.selfAnalysis!,
      userProfile,
    );
    final updatedRecord = record.copyWith(
      aiStabilityScore: analysisResult['score'],
      aiAnalysisReason: analysisResult['reason'],
    );
    await _diaryRepository.saveRecord(updatedRecord);
    await _settingsProvider?.recordManualAnalysis();
    notifyListeners();
    return updatedRecord;
  }

  Future<void> changeDateRange(DateTimeRange newRange) async {
    _dateRange = newRange;
    _isLoading = true;
    _isAiLoading = true;
    _isCosmicMapAiLoading = true;
    _aiInsights = [];
    _cosmicMapInsights = [];
    _universeInterpretation = null;
    _isCloudy = false;
    notifyListeners();

    final records = await _diaryRepository.getRecordsInDateRange(
      newRange.start,
      newRange.end,
    );
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
    );
    _visibleRecordCoordinates = _report!.recordCoordinates; // 全体を初期表示
    _isLoading = false;
    
    // スライダーの初期化と最初の解説をトリガー
    onTimeSliderChanged(1.0); 

    notifyListeners();

    // チャート用の洞察は引き続き全体から生成
    await fetchAiInsights();
    await fetchCosmicMapInsights();
  }

  Future<void> fetchAiInsights() async {
    if (_report == null) {
      _isAiLoading = false;
      notifyListeners();
      return;
    }
    final summary = AiReportToPromptMapper.toPrompt(_report!);
    try {
      final insights = await _geminiService.generateAnalysisInsights(summary);
      _aiInsights = insights;
    } catch (e) {
      _aiInsights = ['チャートの分析中にエラーが発生しました。'];
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCosmicMapInsights() async {
    if (_report == null) {
      _isCosmicMapAiLoading = false;
      notifyListeners();
      return;
    }
    final summary = CosmicMapToPromptMapper.toPrompt(_report!);
    try {
      final insights = await _geminiService.generateCosmicMapInsights(summary);
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
