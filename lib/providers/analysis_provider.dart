// lib/providers/analysis_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/analysis_report.dart';
import '../domain/repositories/diary_repository.dart';
import '../services/gemini_service.dart';
import '../domain/mappers/ai_report_to_prompt_mapper.dart';

/// 分析グラフに表示するデータの種類を定義する列挙型。
enum AnalysisDataType { mood, pressure, temperature, polishing }

/// 分析画面の状態管理を行うプロバイダー。
///
/// 日付範囲の指定、日記データの集計、分析レポートの生成、
/// およびAIによる洞察の取得といった機能を提供します。
class AnalysisProvider extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final GeminiService _geminiService;

  // --- 状態 ---
  /// 現在グラフに表示すべきデータの種類の集合。
  final Set<AnalysisDataType> activeDataTypes = {AnalysisDataType.mood};

  /// [AnalysisProvider] のコンストラクタ。
  ///
  /// 依存関係を受け取り、初期の日付範囲（過去7日間）を設定します。
  AnalysisProvider(this._diaryRepository, this._geminiService) {
    // 初期表示として過去7日間で設定
    final now = DateTime.now();
    // 日付を正規化
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final startOfPeriod = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final initialRange = DateTimeRange(start: startOfPeriod, end: endOfToday);
    changeDateRange(initialRange);
  }

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  AnalysisReport? _report;
  bool _isLoading = false;

  // AI洞察用の状態
  bool _isAiLoading = false;
  List<String> _aiInsights = [];

  /// 現在選択されている分析対象の日付範囲。
  DateTimeRange get dateRange => _dateRange;

  /// 生成された分析レポート。
  AnalysisReport? get report => _report;

  /// 日記データの読み込み中かどうかを示すフラグ。
  bool get isLoading => _isLoading;

  /// AIが洞察を生成中かどうかを示すフラグ。
  bool get isAiLoading => _isAiLoading;

  /// AIによって生成された洞察のリスト。
  List<String> get aiInsights => _aiInsights;

  /// 分析対象の新しい日付範囲を設定し、データの再集計とAIの洞察取得を行います。
  Future<void> changeDateRange(DateTimeRange newRange) async {
    _dateRange = newRange;
    _isLoading = true;
    _isAiLoading = true; // AIの読み込みも開始
    _aiInsights = []; // 古い洞察をクリア
    notifyListeners();

    final records = await _diaryRepository.getRecordsInDateRange(
      newRange.start,
      newRange.end,
    );

    _report = AnalysisReport(records: records, dateRange: newRange);
    _isLoading = false;
    notifyListeners();

    // データ分析後にAIの洞察を取得
    await fetchAiInsights();
  }

  /// 現在の分析レポートを基に、AIによる洞-察を非同期で取得します。
  Future<void> fetchAiInsights() async {
    if (_report == null) {
      _isAiLoading = false;
      notifyListeners();
      return;
    }

    final summary = AiReportToPromptMapper.toPrompt(_report!); // 新しいマッパーを使用
    final insights = await _geminiService.generateAnalysisInsights(summary);
    _aiInsights = insights;
    _isAiLoading = false;
    notifyListeners();
  }

  /// グラフに表示するデータタイプを切り替えます。
  void toggleDataType(AnalysisDataType dataType) {
    if (activeDataTypes.contains(dataType)) {
      // moodは常に必要なので削除しない
      if (dataType != AnalysisDataType.mood) {
        activeDataTypes.remove(dataType);
      }
    } else {
      activeDataTypes.add(dataType);
    }
    notifyListeners();
  }
}
