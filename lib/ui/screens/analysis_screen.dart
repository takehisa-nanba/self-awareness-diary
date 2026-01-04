import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              Padding(
                padding: const EdgeInsets.only(bottom: 280.0),
                child: Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    final warpFactor =
                        (settingsProvider.currentTier == SubscriptionTier.free)
                        ? 0.0
                        : 0.05; // 動きを認識しやすいように値を調整
                    return UniverseCanvas(
                      recordCoordinates: provider.visibleRecordCoordinates,
                      userProfile: report.userProfile,
                      indicatorAnglesRad: provider.indicatorAnglesRad,
                      timeSliderValue: provider.timeSliderValue,
                      warpFactor: warpFactor,
                    );
                  },
                ),
              ),

              // 霧エフェクト
              if (provider.isCloudy) _buildFogEffect(),

              // 操作UIとAI解説
              _buildOverlayContent(context, provider),
            ],
          );
        },
      ),
    );
  }

  /// 霧（曇り）のエフェクトとメッセージ
  Widget _buildFogEffect() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Container(
          color: Colors.black.withAlpha((255 * 0.4).round()),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              '宇宙が曇ってしまっていて鮮明に読み取れませんでした。\nあと少し、どんな小さなことでも良いので、私に教えてくれませんか？',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha((255 * 0.8).round()),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 宇宙図の上に重ねるUIコンテンツを構築します。
  Widget _buildOverlayContent(BuildContext context, AnalysisProvider provider) {
    return Stack(
      children: [
        Column(
          children: [
            const Spacer(), // 上部の余白
            // AI解説セクション
            _buildInterpretationCard(context, provider),
            // 操作パネル
            _buildControlPanel(context, provider),
          ],
        ),
        // 選択された星の詳細カード
        _buildSelectedRecordCard(context),
      ],
    );
  }

  /// 選択された星（日記レコード）の詳細を表示するカード
  Widget _buildSelectedRecordCard(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, child) {
        final record = provider.selectedRecord;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: record == null
              ? const SizedBox.shrink()
              : Positioned.fill(
                  child: GestureDetector(
                    onTap: () => provider.selectRecord(null), // 背景タップで閉じる
                    child: Container(
                      color: Colors.black.withAlpha(100),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {}, // カード自身へのタップは伝播させない
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 8.0,
                                sigmaY: 8.0,
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(100),
                                  ),
                                ),
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
                                    const Divider(
                                      color: Colors.white54,
                                      height: 20,
                                    ),
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
                                            .map(
                                              (tag) => Chip(
                                                label: Text(tag),
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondaryContainer
                                                        .withAlpha(150),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                    ),
                                              ),
                                            )
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
                                    SizedBox(
                                      height: 80, // スクロールエリアの高さ
                                      child: SingleChildScrollView(
                                        child: Text(
                                          record.eventText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      color: Colors.white54,
                                      height: 24,
                                    ),
                                    // AI解説セクション
                                    GestureDetector(
                                      onTap: () {
                                        if (!provider.isExplanationLoading &&
                                            provider.selectedRecordExplanation ==
                                                null) {
                                          provider.explainSelectedRecord();
                                        }
                                      },
                                      child: AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        child: provider.isExplanationLoading
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              )
                                            : (provider.selectedRecordExplanation !=
                                                      null
                                                  ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          '星の物語',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          provider
                                                              .selectedRecordExplanation!,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                height: 1.5,
                                                              ),
                                                        ),
                                                      ],
                                                    )
                                                  : Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withAlpha(50),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.auto_awesome,
                                                            size: 16,
                                                            color: Colors.white,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'AIにこの星の物語を聞く',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                      ),
                                    ),
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

  /// AIによる解説を表示するグラスモフィズム風カード
  Widget _buildInterpretationCard(
    BuildContext context,
    AnalysisProvider provider,
  ) {
    return Consumer<SettingsProvider>( // SettingsProviderも購読
      builder: (context, settingsProvider, child) {
        // Tier2ユーザーでない場合は表示しない
        if (settingsProvider.currentTier != SubscriptionTier.tier2) {
          return provider.universeInterpretation != null
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withAlpha(100),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    'AIによる宇宙図の解説はTier2プランでご利用いただけます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              provider.toggleInterpretationVisibility();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withAlpha(100),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AIによる宇宙図の解説',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            provider.isInterpretationVisible
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: provider.isInterpretationVisible
                            ? Column(
                                key: const ValueKey('interpretation_content'),
                                children: [
                                  const Divider(color: Colors.white54, height: 20),
                                  SingleChildScrollView(
                                    // スクロール可能なテキストエリア
                                    child: Text(
                                      provider.universeInterpretation!,
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(key: ValueKey('empty_content')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 画面下部の操作パネル
  Widget _buildControlPanel(BuildContext context, AnalysisProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      color: Colors.black.withAlpha((255 * 0.6).round()),
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
              value: provider.timeSliderValue,
              onChanged: (value) {
                context.read<AnalysisProvider>().onTimeSliderChanged(value);
              },
            ),
            const SizedBox(height: 8),
            // 全体のAI解説表示ボタン
            if (provider.universeInterpretation != null &&
                !provider.isInterpretationVisible)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('AIに宇宙図を解説してもらう'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(100)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: () => provider.showInterpretation(),
                ),
              ),
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
}

/// メインのAnalysisScreenはStackの背景として機能
class AnalysisScreenWrapper extends StatelessWidget {
  const AnalysisScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(children: [UniverseBackground(), AnalysisScreen()]);
  }
}
