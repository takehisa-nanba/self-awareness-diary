// lib/ui/screens/chart_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../domain/models/analysis_report.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/custom_date_range_picker_dialog.dart';

/// 分析チャート専用の画面ウィジェット。
class ChartAnalysisScreen extends StatelessWidget {
  const ChartAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final report = provider.report;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('チャート分析'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSelector(context),
            const SizedBox(height: 16),
            _buildDataTypeSelector(context),
            const SizedBox(height: 24),

            if (provider.isLoading)
              const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (report == null ||
                (report.isSingleDay
                    ? report.hourlyMoodScores.isEmpty
                    : report.dailyMoodScores.isEmpty))
              const SizedBox(
                height: 400,
                child: Center(child: Text('この期間のデータはありません。')),
              )
            else
              Column(
                children: [
                  _buildSectionTitle(context, 'ムード推移'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildLayeredMoodTrendChart(
                      context,
                      report,
                      provider.activeDataTypes,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '平均スコア: ${report.averageMoodScore.toStringAsFixed(1)}',
                      style: theme.textTheme.bodySmall,
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
                  _buildSectionTitle(context, '研磨の軌跡'),
                  const SizedBox(height: 16),
                  _buildPolishingTrajectory(context, report),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, '自分と環境'),
                  const SizedBox(height: 16),
                  _buildEnvironmentCorrelation(context, report),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, '感情の癖'),
                  const SizedBox(height: 16),
                  _buildEmotionalHabits(context, report),
                  const SizedBox(height: 80),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final dateFormat = DateFormat('yyyy/MM/dd', 'ja_JP');
    final start = dateFormat.format(provider.dateRange.start);
    final end = dateFormat.format(provider.dateRange.end);

    return Center(
      child: InkWell(
        onTap: () async {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                '$start - $end',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTypeSelector(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final activeTypes = provider.activeDataTypes;

    return Center(
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: AnalysisDataType.values.map((type) {
          return FilterChip(
            label: Text(_getDataTypeLabel(type)),
            selected: activeTypes.contains(type),
            onSelected: (bool selected) {
              provider.toggleDataType(type);
            },
          );
        }).toList(),
      ),
    );
  }

  String _getDataTypeLabel(AnalysisDataType type) {
    switch (type) {
      case AnalysisDataType.mood:
        return '気分';
      case AnalysisDataType.pressure:
        return '気圧';
      case AnalysisDataType.temperature:
        return '気温';
      case AnalysisDataType.polishing:
        return '研磨度';
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  LineTouchData _getLineTouchData(
    BuildContext context,
    AnalysisReport report,
    bool isHourly,
  ) {
    final theme = Theme.of(context);
    return LineTouchData(
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(color: theme.primaryColor, strokeWidth: 2),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: theme.primaryColor,
                      strokeColor: theme.cardColor,
                      strokeWidth: 2,
                    );
                  },
                ),
              );
            }).toList();
          },
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => theme.colorScheme.secondaryContainer,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final String title;
            if (isHourly) {
              title = '${spot.x.toInt()}時';
            } else {
              final date = report.dateRange.start.add(
                Duration(days: spot.x.toInt()),
              );
              title = DateFormat('M/d').format(date);
            }
            return LineTooltipItem(
              '$title\n',
              TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: 'スコア: ${spot.y.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  double _safeScale(double value, double min, double max) {
    if (max == min) return 5.0;
    return ((value - min) / (max - min)) * 10;
  }

  Widget _buildLayeredMoodTrendChart(
    BuildContext context,
    AnalysisReport report,
    Set<AnalysisDataType> activeTypes,
  ) {
    final theme = Theme.of(context);
    final bool isHourly = report.isSingleDay;
    final List<LineChartBarData> lineBarsData = [];

    final moodData = isHourly
        ? report.hourlyMoodScores
        : report.dailyMoodScores;
    final pressureData = isHourly
        ? report.hourlyPressureScores
        : report.pressureData;
    final tempData = isHourly
        ? report.hourlyTemperatureScores
        : report.temperatureData;
    final polishingData = isHourly
        ? report.hourlyPolishingLevelData
        : report.polishingLevelData;

    final pressureValues = pressureData.values
        .where((v) => v > 0)
        .map((e) => e.toDouble());
    final tempValues = tempData.values
        .where((v) => v > 0)
        .map((e) => e.toDouble());
    final polishingValues = polishingData.values
        .where((v) => v > 0)
        .map((e) => e.toDouble());

    final minPressure = pressureValues.isNotEmpty
        ? pressureValues.reduce(min)
        : 0.0;
    final maxPressure = pressureValues.isNotEmpty
        ? pressureValues.reduce(max)
        : 1.0;
    final minTemp = tempValues.isNotEmpty ? tempValues.reduce(min) : 0.0;
    final maxTemp = tempValues.isNotEmpty ? tempValues.reduce(max) : 1.0;
    final minPolishing = polishingValues.isNotEmpty
        ? polishingValues.reduce(min)
        : 0.0;
    final maxPolishing = polishingValues.isNotEmpty
        ? polishingValues.reduce(max)
        : 1.0;

    if (activeTypes.contains(AnalysisDataType.mood)) {
      final spots = moodData.entries.map((entry) {
        final double x = isHourly
            ? (entry.key as int).toDouble()
            : (entry.key as DateTime)
                  .difference(report.dateRange.start)
                  .inDays
                  .toDouble();
        return FlSpot(x, entry.value.toDouble());
      }).toList();
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: theme.primaryColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: theme.primaryColor.withAlpha(80),
          ),
        ),
      );
    }

    if (activeTypes.contains(AnalysisDataType.pressure)) {
      final spots = pressureData.entries.map((entry) {
        final double x = isHourly
            ? (entry.key as int).toDouble()
            : (entry.key as DateTime)
                  .difference(report.dateRange.start)
                  .inDays
                  .toDouble();
        return FlSpot(
          x,
          _safeScale(entry.value.toDouble(), minPressure, maxPressure),
        );
      }).toList();
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.orange.withAlpha(150),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
      );
    }

    if (activeTypes.contains(AnalysisDataType.temperature)) {
      final spots = tempData.entries.map((entry) {
        final double x = isHourly
            ? (entry.key as int).toDouble()
            : (entry.key as DateTime)
                  .difference(report.dateRange.start)
                  .inDays
                  .toDouble();
        return FlSpot(x, _safeScale(entry.value.toDouble(), minTemp, maxTemp));
      }).toList();
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.redAccent.withAlpha(150),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
      );
    }

    if (activeTypes.contains(AnalysisDataType.polishing)) {
      final spots = polishingData.entries.map((entry) {
        final double x = isHourly
            ? (entry.key as int).toDouble()
            : (entry.key as DateTime)
                  .difference(report.dateRange.start)
                  .inDays
                  .toDouble();
        return FlSpot(
          x,
          _safeScale(entry.value.toDouble(), minPolishing, maxPolishing),
        );
      }).toList();
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.purple.withAlpha(150),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
      );
    }

    final double duration = isHourly
        ? 23
        : report.dateRange.duration.inDays.toDouble();
    final double bottomLabelInterval = isHourly ? 6 : (duration > 7 ? 7 : 1);

    return LineChart(
      LineChartData(
        lineTouchData: _getLineTouchData(context, report, isHourly),
        lineBarsData: lineBarsData,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const Text('');
                final day = value.toInt();
                if (day % bottomLabelInterval == 0) {
                  final String text = isHourly
                      ? '$day時'
                      : DateFormat('M/d').format(
                          report.dateRange.start.add(Duration(days: day)),
                        );
                  return Text(
                    text,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface,
                    ),
                  );
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
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withAlpha(128),
            strokeWidth: 0.5,
          ),
        ),
        minX: 0,
        maxX: duration + 0.1,
        minY: 0,
        maxY: 10,
      ),
    );
  }

  Widget _buildMoodDistributionChart(
    BuildContext context,
    AnalysisReport report,
  ) {
    final theme = Theme.of(context);
    final distribution = report.moodTagDistribution;
    final primaryColor = theme.primaryColor;

    final topItems = distribution.entries.take(5).toList();
    if (topItems.isEmpty) return const Center(child: Text('データがありません'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: max(5, (topItems.first.value * 1.2).toDouble()),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (spot) => theme.colorScheme.secondaryContainer,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${topItems[groupIndex].key}\n',
                TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '${topItems[groupIndex].value} 回',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
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
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }
                return const Text('');
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                color: primaryColor.withAlpha(
                  (255 * (0.6 + (index * 0.08))).toInt(),
                ),
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

  Widget _buildPolishingTrajectory(
    BuildContext context,
    AnalysisReport report,
  ) {
    final theme = Theme.of(context);
    final distribution = report.polishingDistribution;
    final sortedKeys = distribution.keys.toList()
      ..sort((a, b) {
        const order = ['🪨', '🔨', '🔶', '🌟', '✨', '💎'];
        return order.indexOf(a).compareTo(order.indexOf(b));
      });

    if (distribution.isEmpty) {
      return const Center(child: Text('データがありません。'));
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: sortedKeys.map((icon) {
            final count = distribution[icon]!;
            return Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text('$count 回', style: theme.textTheme.bodySmall),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnvironmentCorrelation(
    BuildContext context,
    AnalysisReport report,
  ) {
    final theme = Theme.of(context);
    final correlation = report.weatherCorrelation;
    if (correlation.isEmpty) {
      return const Center(child: Text('天気の記録があるデータが不足しています。'));
    }

    final sortedEntries = correlation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final overallAverage = report.averageMoodScore;

    return Column(
      children: sortedEntries.map((entry) {
        final difference = entry.value - overallAverage;
        final color = difference >= 0
            ? Colors.green.shade700
            : Colors.red.shade700;
        final sign = difference >= 0 ? '+' : '';

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          child: ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '平均より $sign${difference.toStringAsFixed(1)} ポイント',
              style: TextStyle(color: color),
            ),
            trailing: Text(
              '平均 ${entry.value.toStringAsFixed(1)}',
              style: theme.textTheme.titleMedium,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmotionalHabits(BuildContext context, AnalysisReport report) {
    final theme = Theme.of(context);
    final pairs = report.tagPairs;
    if (pairs.isEmpty) {
      return const Center(child: Text('感情の組み合わせデータがありません。'));
    }

    final topPairs = pairs.entries.take(5);

    return Column(
      children: topPairs.map((pair) {
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          child: ListTile(
            leading: const Icon(Icons.link),
            title: Text(
              pair.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '${pair.value} 回',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
