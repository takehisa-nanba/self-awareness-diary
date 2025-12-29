import 'package:flutter/material.dart';
import '../domain/models/analysis_report.dart';
import '../domain/repositories/diary_repository.dart';
import '../services/gemini_service.dart';
import '../domain/mappers/ai_report_to_prompt_mapper.dart'; // Add this import

class AnalysisProvider extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final GeminiService _geminiService;

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

  DateTimeRange get dateRange => _dateRange;
  AnalysisReport? get report => _report;
  bool get isLoading => _isLoading;
  bool get isAiLoading => _isAiLoading;
  List<String> get aiInsights => _aiInsights;

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

  Future<void> fetchAiInsights() async {
    if (_report == null) {
      _isAiLoading = false;
      notifyListeners();
      return;
    }

    final summary = AiReportToPromptMapper.toPrompt(
      _report!,
    ); // Use the new mapper
    final insights = await _geminiService.generateAnalysisInsights(summary);
    _aiInsights = insights;
    _isAiLoading = false;
    notifyListeners();
  }
}
