import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/analysis_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import 'package:self_awareness_diary/domain/models/subscription_tier.dart';

import '../widgets/universe_background.dart';
import '../widgets/universe_canvas.dart';
import 'chart_analysis_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isPanelOpen = false; // 解析パネルの開閉状態
  final DraggableScrollableController _draggableScrollableController =
      DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '宇宙図分布',
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
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  final warpFactor =
                      (settingsProvider.currentTier == SubscriptionTier.free)
                      ? 0.0
                      : 0.05;
                  return UniverseCanvas(
                    recordCoordinates: provider.visibleRecordCoordinates,
                    userProfile: report.userProfile,
                    indicatorAnglesRad: provider.indicatorAnglesRad,
                    timeSliderValue: provider.timeSliderValue,
                    warpFactor: warpFactor,
                  );
                },
              ),

              // 霧エフェクト
              if (provider.isCloudy) _buildFogEffect(),

              // 選択された星の詳細カード (最前面)
              _buildSelectedRecordCard(context),

              // フローティング解析パネル
              _buildFloatingAnalysisPanel(context, provider),
            ],
          );
        },
      ),
      floatingActionButton: _isPanelOpen
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isPanelOpen = true;
                });
                _draggableScrollableController.animateTo(
                  0.5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.psychology_alt),
            ),
    );
  }

  Widget _buildFogEffect() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Container(
          color: Colors.black.withAlpha((255 * 0.4).round()),
          alignment: Alignment.center,
          child: const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              '宇宙が曇ってしまっていて鮮明に読み取れませんでした。\nあと少し、どんな小さなことでも良いので、私に教えてくれませんか？',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedRecordCard(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, child) {
        final record = provider.selectedRecord;
        if (record == null) return const SizedBox.shrink();

        return Positioned.fill(
          child: GestureDetector(
            onTap: () => provider.selectRecord(null),
            child: Container(
              color: Colors.black54,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                        ),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'yyyy年M月d日 HH:mm',
                                    ).format(record.recordDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        provider.selectRecord(null),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white54),
                              if (record.moodTags.isNotEmpty) ...[
                                const Text(
                                  '気分タグ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: record.moodTags
                                      .map((tag) => Chip(label: Text(tag)))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                              const Text(
                                '出来事',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                record.eventText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const Divider(color: Colors.white54, height: 32),
                              _buildStarStorySection(provider),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarStorySection(AnalysisProvider provider) {
    if (provider.isExplanationLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (provider.selectedRecordExplanation != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '星の物語',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            provider.selectedRecordExplanation!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      );
    }
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AIにこの星の物語を聞く'),
        onPressed: () => provider.explainSelectedRecord(),
      ),
    );
  }

  Widget _buildFloatingAnalysisPanel(
    BuildContext context,
    AnalysisProvider analysisProvider,
  ) {
    return DraggableScrollableSheet(
      controller: _draggableScrollableController,
      initialChildSize: _isPanelOpen ? 0.5 : 0.0,
      minChildSize: 0.0,
      maxChildSize: 0.9,
      expand: true,
      snap: true,
      builder: (BuildContext context, ScrollController scrollController) {
        if (!_isPanelOpen) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24.0),
                ),
                border: Border.all(color: Colors.white.withAlpha(100)),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white54,
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                          _buildTimeSlider(context, analysisProvider),
                          const SizedBox(height: 16),
                          _buildInterpretationSection(
                            context,
                            analysisProvider,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailChartButton(context),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _draggableScrollableController.animateTo(
                          0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                        setState(() => _isPanelOpen = false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSlider(BuildContext context, AnalysisProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '時間軸 (4次元目)',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Slider(
          value: provider.timeSliderValue,
          onChanged: (value) =>
              context.read<AnalysisProvider>().onTimeSliderChanged(value),
        ),
      ],
    );
  }

  Widget _buildInterpretationSection(
    BuildContext context,
    AnalysisProvider analysisProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AIによる宇宙図の解説',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInterpretButton(context, analysisProvider),
        const SizedBox(height: 16),
        if (analysisProvider.isInterpreting)
          const Center(child: CircularProgressIndicator())
        else if (analysisProvider.universeInterpretation != null)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.white.withAlpha(50)),
            ),
            child: Text(
              analysisProvider.universeInterpretation!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInterpretButton(
    BuildContext context,
    AnalysisProvider analysisProvider,
  ) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final currentTier = subscriptionProvider.currentTier;
    final featureStatus = analysisProvider.interpretationStatus;

    String buttonText = 'AIに宇宙図を解釈してもらう';
    bool isDisabled = analysisProvider.isInterpreting;
    VoidCallback? onPressed;

    if (analysisProvider.visibleRecordCoordinates.length < 3) {
      buttonText = 'データが少なすぎて解釈できません';
      isDisabled = true;
    } else {
      switch (featureStatus) {
        case FeatureStatus.allowed:
          onPressed = () => analysisProvider.triggerInterpretation();
          break;
        case FeatureStatus.needsReward:
          buttonText = '宇宙を解釈 (週次無料枠を解放)';
          onPressed = () => _handleAdFlow(
            context,
            analysisProvider,
            '週に一度の宇宙の助言',
            '動画広告を見て、今週分のAI解説を生成しますか？',
            false,
          );
          break;
        case FeatureStatus.needsRewardMonthly:
          buttonText = '宇宙を解釈 (月間ボーナスを使用)';
          onPressed = () => _handleAdFlow(
            context,
            analysisProvider,
            '貴重な月間ボーナス',
            '今週分は終了しました。貴重な「今月のボーナス枠(1/1)」を消費して、宇宙の深淵を読み解きますか？',
            true,
          );
          break;
        case FeatureStatus.forbidden:
          buttonText = '今月分の解析枠を使い切りました';
          isDisabled = true;
          break;
        default:
          onPressed = () => analysisProvider.triggerInterpretation();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentTier == SubscriptionTier.free)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FutureBuilder<List<int>>(
              future: Future.wait([
                subscriptionProvider.getWeeklyInterpretationCount(),
                subscriptionProvider.getMonthlyInterpretationCount(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return Text(
                  '今週の残り: ${1 - snapshot.data![0]}回 / 今月のボーナス: ${1 - snapshot.data![1]}回',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                );
              },
            ),
          ),
        ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: Text(buttonText),
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAdFlow(
    BuildContext context,
    AnalysisProvider provider,
    String title,
    String message,
    bool isMonthly,
  ) async {
    final bool confirm = await _showConfirmationDialog(context, title, message);
    if (confirm) {
      // 広告視聴完了後に解析を実行
      await provider.runFreeInterpretation(isMonthly);
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('広告を見て解釈する'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDetailChartButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.bar_chart),
      label: const Text('詳細チャート分析'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChartAnalysisScreen()),
      ),
    );
  }
}

class AnalysisScreenWrapper extends StatelessWidget {
  const AnalysisScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return const Stack(children: [UniverseBackground(), AnalysisScreen()]);
  }
}
