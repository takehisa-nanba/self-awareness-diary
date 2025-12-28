import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/models/analysis_report.dart';
import '../domain/repositories/diary_repository.dart';
import '../services/gemini_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final GeminiService _geminiService;

  AnalysisProvider(this._diaryRepository, this._geminiService) {
    // 初期表示として過去7日間で設定
    final now = DateTime.now();
    // 日付を正規化
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final startOfPeriod = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    
    final initialRange = DateTimeRange(
      start: startOfPeriod,
      end: endOfToday,
    );
    changeDateRange(initialRange);
  }

  DateTimeRange _dateRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
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

    final summary = _formatReportForSummary(_report!);
    final insights = await _geminiService.generateAnalysisInsights(summary);
    _aiInsights = insights;
    _isAiLoading = false;
    notifyListeners();
  }

  String _formatReportForSummary(AnalysisReport report) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final summary = StringBuffer();

    summary.writeln('分析期間: ${dateFormat.format(report.dateRange.start)} - ${dateFormat.format(report.dateRange.end)}');
    summary.writeln('平均気分スコア: ${report.averageMoodScore.toStringAsFixed(1)}');
    
    summary.writeln('\n最も多かった気分タグ TOP5:');
    if (report.moodTagDistribution.isEmpty) {
      summary.writeln('- データなし');
    } else {
      report.moodTagDistribution.entries.take(5).forEach((entry) {
        summary.writeln('- ${entry.key}: ${entry.value}回');
      });
    }

    if (report.isSingleDay) {
      summary.writeln('\n時間毎の平均気分スコア（0時-23時）:');
      final hourlyScores = report.hourlyMoodScores.entries.map((e) => '${e.key}時:${e.value.toStringAsFixed(1)}').join(', ');
      summary.writeln(hourlyScores.isNotEmpty ? hourlyScores : '- データなし');
    } else {
       summary.writeln('\n日毎の平均気分スコア:');
       final dailyScores = report.dailyMoodScores.entries.map((e) => '${dateFormat.format(e.key)}:${e.value.toStringAsFixed(1)}').join(', ');
       summary.writeln(dailyScores.isNotEmpty ? dailyScores : '- データなし');
    }

    // 最高・最低スコアの日の情報を追加
    final allRecords = report.records;
    if (allRecords.isNotEmpty) {
      allRecords.sort((a, b) => a.moodScore.compareTo(b.moodScore));
      final lowestScoreRecord = allRecords.first;
      final highestScoreRecord = allRecords.last;

      summary.writeln('\n期間中の最低スコアの日:');
      summary.writeln('- 日時: ${dateFormat.format(lowestScoreRecord.recordDate)}');
      summary.writeln('- スコア: ${lowestScoreRecord.moodScore}');
      summary.writeln('- タグ: ${lowestScoreRecord.moodTags.join(', ')}');
      summary.writeln('- 出来事: ${lowestScoreRecord.eventText}');

      summary.writeln('\n期間中の最高スコアの日:');
      summary.writeln('- 日時: ${dateFormat.format(highestScoreRecord.recordDate)}');
      summary.writeln('- スコア: ${highestScoreRecord.moodScore}');
      summary.writeln('- タグ: ${highestScoreRecord.moodTags.join(', ')}');
      summary.writeln('- 出来事: ${highestScoreRecord.eventText}');
    }

    return summary.toString();
  }
}
