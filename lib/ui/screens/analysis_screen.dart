import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../domain/models/analysis_report.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/custom_date_range_picker_dialog.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateRangeSelector(context),
          const SizedBox(height: 24),
          Consumer<AnalysisProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final report = provider.report;
              if (report == null ||
                  (report.isSingleDay
                      ? report.hourlyMoodScores.isEmpty
                      : report.dailyMoodScores.isEmpty)) {
                return const SizedBox(
                  height: 400,
                  child: Center(child: Text('この期間のデータはありません。')),
                );
              }

              return Column(
                children: [
                  _buildSectionTitle(context, 'ムード推移'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: report.isSingleDay
                        ? _buildHourlyMoodTrendChart(context, report)
                        : _buildMoodTrendChart(context, report),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '平均スコア: ${report.averageMoodScore.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'ムードの分布'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildMoodDistributionChart(context, report),
                  ),

                  const SizedBox(height: 40),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) {
                      if (settings.currentTier != SubscriptionTier.tier2) {
                        return _buildUpgradePlaceholder(context);
                      }
                      // Tier 2ユーザーのみAI洞察を表示
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionTitle(context, 'AIによる洞察'),
                          const SizedBox(height: 16),
                          _buildAiInsights(context, provider),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 80), // FABのための余白
        ],
      ),
    );
  }

  Widget _buildUpgradePlaceholder(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.tertiaryContainer.withAlpha((255 * 0.5).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 32,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'AIによる高度な分析',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'アップグレードすると、AIがあなたの記録を分析し、パーソナライズされた洞察を提供します。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                // TODO: 課金画面への遷移を実装
              },
              child: const Text('プランを確認する'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsights(BuildContext context, AnalysisProvider provider) {
    if (provider.isAiLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.aiInsights.isEmpty) {
      return const Center(child: Text('AIからの洞察はありません。'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.aiInsights.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final insight = provider.aiInsights[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd', 'ja_JP');
    final start = dateFormat.format(provider.dateRange.start);
    final end = dateFormat.format(provider.dateRange.end);

    return InkWell(
      onTap: () async {
        // HistoryProviderから全レコードを取得してイベントとして渡す
        final historyProvider = context.read<HistoryProvider>();
        final events = historyProvider.allRecords;

        final newRange = await showDialog<DateTimeRange>(
          context: context,
          builder: (context) => CustomDateRangePickerDialog(
            initialDateRange: provider.dateRange,
            events: events,
          ),
        );
        if (!context.mounted) return;
        if (newRange != null) {
          context.read<AnalysisProvider>().changeDateRange(newRange);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 8),
            Text('$start - $end', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  LineTouchData _getLineTouchData(BuildContext context, AnalysisReport report, bool isHourly) {
    return LineTouchData(
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((spotIndex) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: Theme.of(context).primaryColor,
              strokeWidth: 2,
            ),
            FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Theme.of(context).primaryColor,
                  strokeColor: Theme.of(context).cardColor,
                  strokeWidth: 2,
                );
              },
            ),
          );
        }).toList();
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => Theme.of(context).colorScheme.secondaryContainer,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final String title;
            if (isHourly) {
              title = '${spot.x.toInt()}時';
            } else {
              final date = report.dateRange.start.add(Duration(days: spot.x.toInt()));
              title = DateFormat('M/d').format(date);
            }
            return LineTooltipItem(
              '$title\n',
              TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'スコア: ${spot.y.toStringAsFixed(1)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }
  
  Widget _buildMoodTrendChart(BuildContext context, AnalysisReport report) {
    debugPrint('--- Trend Chart Build Start ---');
    debugPrint('Date Range: ${report.dateRange.start} - ${report.dateRange.end}');
    
    final spots = report.dailyMoodScores.entries.map((entry) {
      final daysFromStart = entry.key.difference(report.dateRange.start).inDays;
      return FlSpot(daysFromStart.toDouble(), entry.value);
    }).toList();

    final durationDays = report.dateRange.duration.inDays;
    final bottomLabelInterval = durationDays > 7 ? 7 : 1;
    final maxX = durationDays.toDouble() + 0.1;

    debugPrint('Duration Days: $durationDays, MaxX: $maxX');
    debugPrint('Daily Mood Scores Map: ${report.dailyMoodScores}');
    debugPrint('Generated Spots: ${spots.map((s) => '(${s.x}, ${s.y})').join(', ')}');
    debugPrint('--- Trend Chart Build End ---');

    return LineChart(
      LineChartData(
        lineTouchData: _getLineTouchData(context, report, false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withAlpha(50),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // X軸の最大値（終端）はfl_chartに任せるか、描画しない
                if (value == meta.max) {
                  return const Text('');
                }
                final day = value.toInt();
                if (day % bottomLabelInterval == 0) {
                  final date = report.dateRange.start.add(Duration(days: day));
                  return Text(DateFormat('M/d').format(date), style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 2 == 0) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withAlpha(128),
            strokeWidth: 0.5,
          ),
        ),
        minX: 0,
        maxX: durationDays.toDouble() + 0.1,
        minY: 0,
        maxY: 10,
      ),
    );
  }
  
  Widget _buildHourlyMoodTrendChart(BuildContext context, AnalysisReport report) {
    final spots = report.hourlyMoodScores.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return LineChart(
      LineChartData(
        lineTouchData: _getLineTouchData(context, report, true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withAlpha(50),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 6 == 0) {
                  return Text('${value.toInt()}時', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 2 == 0) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withAlpha(128),
            strokeWidth: 0.5,
          ),
        ),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: 10,
      ),
    );
  }
  
  Widget _buildMoodDistributionChart(BuildContext context, AnalysisReport report) {
    final distribution = report.moodTagDistribution;
    final primaryColor = Theme.of(context).primaryColor;

    final topItems = distribution.entries.take(5).toList();
    if (topItems.isEmpty) return const Center(child: Text('データがありません'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: max(5, (topItems.first.value * 1.2).toDouble()),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (spot) => Theme.of(context).colorScheme.secondaryContainer,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${topItems[groupIndex].key}\n',
                TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: '${topItems[groupIndex].value} 回',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < topItems.length) {
                  return Text(
                    topItems[index].key,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  );
                }
                return const Text('');
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: topItems.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value.toDouble(),
                color: primaryColor.withAlpha((255 * (0.6 + (index * 0.08))).toInt()),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}