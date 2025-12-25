import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analysis_provider.dart'; // 後ほど作成するAnalysisProvider

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalysisProvider>(context, listen: false).loadMonthlyMoodData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('月別ムード分析'),
      ),
      body: SingleChildScrollView( // ここで画面全体をスクロール可能にする
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthSelector(context), 
            const SizedBox(height: 24),
            Consumer<AnalysisProvider>(
              builder: (context, consumerProvider, child) {
                if (consumerProvider.isLoading) {
                  return const SizedBox(
                    height: 250, // ローディング時もグラフと同じ高さを確保
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (consumerProvider.monthlyMoodData.isEmpty) {
                  return const SizedBox(
                    height: 250, // データなし時もグラフと同じ高さを確保
                    child: Center(child: Text('この月のデータはありません。')),
                  );
                }

                return Column(
                  children: [
                    Text(
                      '${consumerProvider.selectedYear}年 ${consumerProvider.selectedMonth}月のムード推移',
                      style: Theme.of(context).textTheme.titleMedium, // 文字を少し小さく
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox( // ここでグラフの高さを固定
                      height: 300, 
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: consumerProvider.monthlyMoodData.entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value);
                              }).toList(),
                              isCurved: true,
                              color: Theme.of(context).primaryColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Theme.of(context).primaryColor,
                                    strokeWidth: 2,
                                    strokeColor: Theme.of(context).scaffoldBackgroundColor,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context).primaryColor.withAlpha((255 * 0.3).round()),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() % 5 == 0 && value.toInt() != 0) {
                                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 8));
                                  }
                                  return const Text('');
                                },
                                reservedSize: 22,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0 || value == 2 || value == 4 || value == 6 || value == 8 || value == 10) {
                                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 8));
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
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Theme.of(context).dividerColor,
                              strokeWidth: 0.5,
                            ),
                          ),
                          minX: 1,
                          maxX: _getDaysInMonth(consumerProvider.selectedYear, consumerProvider.selectedMonth).toDouble(),
                          minY: 0,
                          maxY: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '月平均ムードスコア: ${consumerProvider.averageMoodScore.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: () => context.read<AnalysisProvider>().previousMonth(),
        ),
        GestureDetector(
          onTap: () async {
            final providerRead = context.read<AnalysisProvider>();
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(provider.selectedYear, provider.selectedMonth),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              locale: Localizations.localeOf(context),
            );
            if (!context.mounted) return;
            if (pickedDate != null) {
              providerRead.selectMonth(pickedDate.year, pickedDate.month);
            }
          },
          child: Text(
            '${provider.selectedYear}年 ${provider.selectedMonth}月',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: () => context.read<AnalysisProvider>().nextMonth(),
        ),
      ],
    );
  }

  int _getDaysInMonth(int year, int month) {
    if (month == DateTime.february) {
      final bool isLeapYear = (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const List<int> daysInMonth = <int>[31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }
}