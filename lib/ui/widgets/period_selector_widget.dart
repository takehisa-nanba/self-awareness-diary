// lib/ui/widgets/period_selector_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analysis_provider.dart';

/// 分析画面で使われる期間選択用の共通ウィジェット。
///
/// ToggleButtonsを使用して、定義済みの期間（全期間, 1か月, 1週間, 当日）を
/// 素早く選択する機能を提供します。
class PeriodSelectorWidget extends StatelessWidget {
  const PeriodSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final analysisProvider = context.watch<AnalysisProvider>();
    final currentRange = analysisProvider.dateRange;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); // 今日の終わり
    final oneWeekAgoStart = now.subtract(const Duration(days: 6));
    final oneMonthAgoStart = DateTime(now.year, now.month - 1, now.day);
    final allTimeStart = DateTime(2000, 1, 1);

    const periodOptions = ['全期間', '1か月', '1週間', '当日'];
    
    final List<bool> isSelected = [
      _isSameRange(currentRange, allTimeStart, todayEnd), // 全期間
      _isSameRange(currentRange, oneMonthAgoStart, todayEnd), // 1か月
      _isSameRange(currentRange, oneWeekAgoStart, todayEnd), // 1週間
      _isSameRange(currentRange, todayStart, todayEnd), // 当日
    ];

    return Padding(
      padding: const EdgeInsets.only(top: kToolbarHeight + 4.0, bottom: 4.0),
      child: Center(
        child: ToggleButtons(
          isSelected: isSelected,
          onPressed: (int index) {
            _applyPeriodFilter(context, periodOptions[index]);
          },
          borderRadius: BorderRadius.circular(8.0),
          selectedBorderColor: Theme.of(context).colorScheme.primary,
          selectedColor: Colors.white,
          fillColor: Theme.of(context).colorScheme.primary.withAlpha(204),
          color: Colors.white70,
          borderColor: Colors.white54,
          children: periodOptions.map((period) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(period, style: const TextStyle(fontWeight: FontWeight.bold)),
          )).toList(),
        ),
      ),
    );
  }

  /// 選択された期間文字列に基づいてAnalysisProviderのdateRangeを更新します。
  void _applyPeriodFilter(BuildContext context, String period) {
    final provider = context.read<AnalysisProvider>();
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (period) {
      case '全期間':
        startDate = DateTime(2000, 1, 1);
        break;
      case '1か月':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '1週間':
        startDate = now.subtract(const Duration(days: 6));
        break;
      case '当日':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      default:
        return;
    }
    provider.changeDateRange(DateTimeRange(start: startDate, end: endDate));
  }
  
  /// 2つのDateTimeRangeが（日付レベルで）同じかどうかを判定します。
  bool _isSameRange(DateTimeRange range1, DateTime compareStart, DateTime compareEnd) {
    return DateUtils.isSameDay(range1.start, compareStart) &&
           DateUtils.isSameDay(range1.end, compareEnd);
  }
}
