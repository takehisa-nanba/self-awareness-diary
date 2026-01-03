// lib/ui/screens/analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/analysis_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/universe_background.dart';
import '../widgets/universe_canvas.dart';
import 'chart_analysis_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  double _timeSliderValue = 1.0;
  bool _isInsightsExpanded = false; // AI解説パネルの開閉状態

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '分析',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.report == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = provider.report;
          if (report == null || report.recordCoordinates.isEmpty) {
            return const Center(
              child: Text(
                '分析データがありません。',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Stack(
            children: [
              // 宇宙図キャンバス
              Padding(
                // 下部のUIと重ならないようにパディングを追加
                padding: const EdgeInsets.only(bottom: 200.0),
                child: UniverseCanvas(
                  recordCoordinates: report.recordCoordinates,
                  userProfile: report.userProfile,
                  timeSliderValue: _timeSliderValue,
                ),
              ),
              // 操作UIとAI解説を重ねて表示
              _buildOverlayContent(context, provider),
            ],
          );
        },
      ),
    );
  }

  /// 宇宙図の上に重ねるUIコンテンツを構築します。
  Widget _buildOverlayContent(BuildContext context, AnalysisProvider provider) {
    return Column(
      children: [
        const Spacer(), // 上部の余白
        // AI解説セクション
        _buildAiInsightsSection(context, provider),
        // 操作パネル
        _buildControlPanel(context),
      ],
    );
  }

  /// AIの洞察を表示する開閉式のセクション
  Widget _buildAiInsightsSection(
    BuildContext context,
    AnalysisProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (settings.currentTier != SubscriptionTier.tier2) {
            return _buildUpgradePlaceholder(context);
          }
          return Card(
            color: Colors.black.withAlpha(191),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withAlpha(51)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Colors.yellow),
                  title: const Text(
                    'AIによる宇宙図の解説',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(
                    _isInsightsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onTap: () {
                    setState(() {
                      _isInsightsExpanded = !_isInsightsExpanded;
                    });
                  },
                ),
                // 開閉するコンテンツ部分
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  child: Visibility(
                    visible: _isInsightsExpanded,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: _buildCosmicMapInsightsList(context, provider),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 宇宙図用AI洞察のリスト
  Widget _buildCosmicMapInsightsList(
    BuildContext context,
    AnalysisProvider provider,
  ) {
    return Consumer<AnalysisProvider>(
      builder: (context, analysisProvider, child) {
        if (analysisProvider.isCosmicMapAiLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (analysisProvider.cosmicMapInsights.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '解説を生成できませんでした。',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: Column(
            children: analysisProvider.cosmicMapInsights
                .map(
                  (insight) => ListTile(
                    leading: const Icon(
                      Icons.star_outline,
                      color: Colors.purpleAccent,
                    ),
                    title: Text(
                      insight,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  /// 画面下部の操作パネル
  Widget _buildControlPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      color: Colors.black.withAlpha(153),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '時間軸 (4次元目)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Slider(
              value: _timeSliderValue,
              onChanged: (double value) {
                setState(() {
                  _timeSliderValue = value;
                });
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('詳細チャート分析'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChartAnalysisScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// アップグレードを促すUI
  Widget _buildUpgradePlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: Colors.yellow, size: 32),
          const SizedBox(height: 8),
          Text(
            'AIによる高度な分析',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'アップグレードすると、AIがあなたの記録を分析し、パーソナライズされた洞察を提供します。',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {
              // TODO: 課金画面への遷移を実装
            },
            child: const Text('プランを確認する'),
          ),
        ],
      ),
    );
  }
}

/// メインのAnalysisScreenはStackの背景として機能
class AnalysisScreenWrapper extends StatelessWidget {
  const AnalysisScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(children: [UniverseBackground(), AnalysisScreen()]);
  }
}
