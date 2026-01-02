// lib/ui/screens/analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // グラフ描画ライブラリ
import 'package:intl/intl.dart'; // 日付フォーマットのため
import 'dart:math'; // max関数を使うため
import '../../domain/models/analysis_report.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/history_provider.dart'; // カレンダーイベント読み込みのため
import '../../providers/settings_provider.dart';
import '../widgets/custom_date_range_picker_dialog.dart'; // カスタム日付範囲ピッカー
import '../widgets/universe_background.dart'; // Import UniverseBackground
import '../widgets/universe_canvas.dart'; // Import UniverseCanvas

/// 日記データの分析結果を表示する画面ウィジェット。
///
/// ユーザーは日付範囲を選択し、その期間の気分推移グラフ、気分分布グラフ、
/// およびAIによる洞察（Tier 2ユーザーのみ）を視覚的に確認できます。
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

enum ViewMode { chart, cosmicMap }

class _AnalysisScreenState extends State<AnalysisScreen> {
  ViewMode _viewMode = ViewMode.chart; // デフォルトはチャートビュー
  double _timeSliderValue = 1.0; // 4次元目の時間スライダーの値

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Use Stack to layer background and content
      children: [
        const UniverseBackground(), // Background as the first layer
        Scaffold(
          backgroundColor: Colors.transparent, // Make Scaffold transparent
          extendBodyBehindAppBar:
              true, // Allow background to extend behind AppBar
          appBar: AppBar(
            title: const Text('分析レポート'), // AppBarのタイトルを追加
            backgroundColor: Colors.transparent, // AppBarも透過
            elevation: 0, // AppBarの影をなくす
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateRangeSelector(context),
                const SizedBox(height: 16),
                _buildDataTypeSelector(context),
                const SizedBox(height: 16),

                // ViewMode Toggle
                Center(
                  child: SegmentedButton<ViewMode>(
                    segments: const <ButtonSegment<ViewMode>>[
                      ButtonSegment<ViewMode>(
                        value: ViewMode.chart,
                        label: Text('チャート'),
                        icon: Icon(Icons.bar_chart),
                      ),
                      ButtonSegment<ViewMode>(
                        value: ViewMode.cosmicMap,
                        label: Text('宇宙図'),
                        icon: Icon(Icons.travel_explore),
                      ),
                    ],
                    selected: <ViewMode>{_viewMode},
                    onSelectionChanged: (Set<ViewMode> newSelection) {
                      setState(() {
                        _viewMode = newSelection.first;
                      });
                    },
                  ),
                ),
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

                    // Display either Chart or Cosmic Map based on _viewMode
                    if (_viewMode == ViewMode.cosmicMap) {
                      return Column(
                        children: [
                          SizedBox(
                            height: 500, // Adjust height as needed
                            child: UniverseCanvas(
                              recordCoordinates: report.recordCoordinates,
                              userProfile: report.userProfile,
                              timeSliderValue: _timeSliderValue,
                            ),
                          ),
                          // Time Slider for Cosmic Map
                          Slider(
                            value: _timeSliderValue,
                            min: 0.0,
                            max: 1.0,
                            divisions: 100,
                            label: (_timeSliderValue * 100).round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _timeSliderValue = value;
                              });
                            },
                          ),
                        ],
                      );
                    } else {
                      // Existing Chart View
                      return Column(
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
                          const SizedBox(height: 40),
                          Consumer<SettingsProvider>(
                            builder: (context, settings, child) {
                              if (settings.currentTier !=
                                  SubscriptionTier.tier2) {
                                return _buildUpgradePlaceholder(context);
                              }
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
                    }
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// AI分析機能が利用できない場合に表示されるアップグレード促進用のプレースホルダー。
  Widget _buildUpgradePlaceholder(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.tertiaryContainer.withAlpha((255 * 0.5).toInt()),
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

            /// プラン確認ボタン（TODO: 課金画面への遷移を実装）。
            FilledButton.tonal(
              onPressed: () {
                // TODO: 課金画面への遷移を実装
              },
              child: const Text('プランを確認する'),
            ),
          ],
        ),
      ),
    );
  }

  /// AIによる洞察を表示するウィジェット。
  ///
  /// AIが洞察を生成中の場合はローディング表示を行い、
  /// 洞察がない場合はメッセージを表示します。
  Widget _buildAiInsights(BuildContext context, AnalysisProvider provider) {
    if (provider.isAiLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.aiInsights.isEmpty) {
      return const Center(child: Text('AIからの洞察はありません。'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // ListView自体のスクロールを無効化
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

  /// 各分析セクションのタイトルを表示するための再利用可能なウィジェット。
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  /// ユーザーが分析対象の日付範囲を選択するためのウィジェット。
  ///
  /// タップするとカスタム日付範囲ピッカーダイアログが表示されます。
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
            Text(
              '$start - $end',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// データタイプ選択のためのFilterChip群を構築するウィジェット。
  Widget _buildDataTypeSelector(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final activeTypes = provider.activeDataTypes;

    return Wrap(
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
    );
  }

  /// AnalysisDataTypeのラベルを取得するヘルパーメソッド。
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

  /// 折れ線グラフのタッチ（ツールチップ）データ設定を返します。
  ///
  /// [context] ビルドコンテキスト。
  /// [report] 分析レポート。
  /// [isHourly] 時間ごとのグラフかどうか。
  LineTouchData _getLineTouchData(
    BuildContext context,
    AnalysisReport report,
    bool isHourly,
  ) {
    return LineTouchData(
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(color: Theme.of(context).primaryColor, strokeWidth: 2),
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
        getTooltipColor: (spot) =>
            Theme.of(context).colorScheme.secondaryContainer,
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
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: 'スコア: ${spot.y.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  /// データを0-10の範囲に安全に正規化するヘルパー関数
  double _safeScale(double value, double min, double max) {
    if (max == min) return 5.0; // 範囲が0の場合は中央値を返す
    return ((value - min) / (max - min)) * 10;
  }

  /// 選択されたデータタイプに基づいてレイヤー化された気分推移グラフを構築します。
  Widget _buildLayeredMoodTrendChart(
    BuildContext context,
    AnalysisReport report,
    Set<AnalysisDataType> activeTypes,
  ) {
    final bool isHourly = report.isSingleDay;
    final List<LineChartBarData> lineBarsData = [];

    // --- データセットの準備 ---
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

    // --- 正規化のための最小・最大値計算 ---
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

    // --- LineChartBarDataの生成 ---

    // 1. Mood (主軸)
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
          color: Theme.of(context).primaryColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).primaryColor.withAlpha(80),
          ),
        ),
      );
    }

    // 2. Pressure (副データ)
    if (activeTypes.contains(AnalysisDataType.pressure)) {
      final spots = pressureData.entries.map((entry) {
        final double x;
        if (isHourly) {
          x = (entry.key as int).toDouble();
        } else {
          x = (entry.key as DateTime)
              .difference(report.dateRange.start)
              .inDays
              .toDouble();
        }
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

    // 3. Temperature (副データ)
    if (activeTypes.contains(AnalysisDataType.temperature)) {
      final spots = tempData.entries.map((entry) {
        final double x;
        if (isHourly) {
          x = (entry.key as int).toDouble();
        } else {
          x = (entry.key as DateTime)
              .difference(report.dateRange.start)
              .inDays
              .toDouble();
        }
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

    // 4. Polishing (副データ)
    if (activeTypes.contains(AnalysisDataType.polishing)) {
      final spots = polishingData.entries.map((entry) {
        final double x;
        if (isHourly) {
          x = (entry.key as int).toDouble();
        } else {
          x = (entry.key as DateTime)
              .difference(report.dateRange.start)
              .inDays
              .toDouble();
        }
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

    // --- グラフのX軸設定 ---
    final double duration = isHourly
        ? 23
        : report.dateRange.duration.inDays.toDouble();
    final double bottomLabelInterval = isHourly ? 6 : (duration > 7 ? 7 : 1);

    // --- グラフウィジェットの構築 ---
    return LineChart(
      LineChartData(
        lineTouchData: _getLineTouchData(context, report, isHourly), // タッチデータ
        lineBarsData: lineBarsData,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const Text(''); // 最後のラベルは表示しない
                final day = value.toInt();
                if (day % bottomLabelInterval == 0) {
                  final String text = isHourly
                      ? '$day時'
                      : DateFormat('M/d').format(
                          report.dateRange.start.add(Duration(days: day)),
                        );
                  return Text(
                    text,
                    style: const TextStyle(fontSize: 10),
                  ); // ラベルスタイル
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
                    style: const TextStyle(fontSize: 10), // ラベルスタイル
                  );
                }
                return const Text(''); // 奇数は表示しない
              },
              reservedSize: 28,
            ),
          ),
          // 右と上のタイトルは非表示
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false), // 枠線非表示
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
        maxX: duration + 0.1,
        minY: 0,
        maxY: 10,
      ),
    );
  }

  /// 気分タグの分布を示す棒グラフを構築します。
  Widget _buildMoodDistributionChart(
    BuildContext context,
    AnalysisReport report,
  ) {
    final distribution = report.moodTagDistribution;
    final primaryColor = Theme.of(context).primaryColor;

    final topItems = distribution.entries.take(5).toList(); // トップ5のタグを表示
    if (topItems.isEmpty) return const Center(child: Text('データがありません'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: max(5, (topItems.first.value * 1.2).toDouble()), // Y軸の最大値を調整
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (spot) =>
                Theme.of(context).colorScheme.secondaryContainer,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${topItems[groupIndex].key}\n',
                TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '${topItems[groupIndex].value} 回',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                    style: const TextStyle(fontSize: 10),
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
        gridData: const FlGridData(show: false), // グリッド線を非表示
        barGroups: topItems.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value.toDouble(),
                color: primaryColor.withAlpha(
                  (255 * (0.6 + (index * 0.08))).toInt(), // タグごとに色を微妙に変化
                ),
                width: 16, // 棒の幅
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
      color: Theme.of(context).colorScheme.surfaceContainer,
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
                Text('$count 回', style: Theme.of(context).textTheme.bodySmall),
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
    final correlation = report.weatherCorrelation;
    if (correlation.isEmpty) {
      return const Center(child: Text('天気の記録があるデータが不足しています。'));
    }

    // スコアの差が大きい順にソート
    final sortedEntries = correlation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 平均との差を計算
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
          color: Theme.of(context).colorScheme.surfaceContainer,
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmotionalHabits(BuildContext context, AnalysisReport report) {
    final pairs = report.tagPairs;
    if (pairs.isEmpty) {
      return const Center(child: Text('感情の組み合わせデータがありません。'));
    }

    // 上位5件に絞る
    final topPairs = pairs.entries.take(5);

    return Column(
      children: topPairs.map((pair) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: ListTile(
            leading: const Icon(Icons.link),
            title: Text(
              pair.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '${pair.value} 回',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
