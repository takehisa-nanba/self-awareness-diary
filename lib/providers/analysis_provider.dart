import 'package:flutter/material.dart';
import '../../domain/models/analysis_report.dart';
import '../../domain/repositories/diary_repository.dart';

class AnalysisProvider with ChangeNotifier {
  final DiaryRepository _diaryRepository;

  AnalysisProvider(this._diaryRepository) {
    // 初期期間を過去30日間に設定し、時刻コンポーネントを正規化
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final defaultStart = startOfDay.subtract(const Duration(days: 29)); // 30日前の00:00:00
    final defaultEnd = endOfDay; // 現在日の23:59:59.999

    _dateRange = DateTimeRange(start: defaultStart, end: defaultEnd);
    loadAnalysisData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late DateTimeRange _dateRange;
  DateTimeRange get dateRange => _dateRange;
  
  AnalysisReport? _report;
  AnalysisReport? get report => _report;


  Future<void> loadAnalysisData() async {
    _isLoading = true;
    notifyListeners();

    final records = await _diaryRepository.getRecordsInDateRange(_dateRange.start, _dateRange.end);
    debugPrint('[AnalysisProvider] 期間 [${_dateRange.start.toLocal().toString().substring(0,10)} - ${_dateRange.end.toLocal().toString().substring(0,10)}] のレコードを ${records.length} 件取得しました。');
    _report = AnalysisReport(records: records, dateRange: _dateRange);
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> changeDateRange(DateTimeRange newRange) async {
    _dateRange = newRange;
    await loadAnalysisData();
  }
}

