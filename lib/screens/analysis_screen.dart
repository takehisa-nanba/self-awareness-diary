// lib/screens/analysis_screen.dart (分析画面の実装)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // ★★★ グラフ描画ライブラリ
import 'subscription_screen.dart'; // 課金プラン画面への導線

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // ★★★ 仮のユーザー状態 (実際はRiverpodなどで管理) ★★★
  // ここでユーザーのプランを判定し、UIを切り替えます
  final bool _isPremium = false; // 初期は無料ユーザーとして想定

  @override
  void initState() {
    super.initState();
    // TODO: 実際のユーザーサブスクリプション状態をフェッチし、_isPremiumを設定
  }

  // ★★★ ダミーのグラフデータ生成ロジック ★★★
  List<FlSpot> _getSampleChartData() {
    // 過去7日間のダミースコアを生成
    final data = [6.5, 7.0, 5.0, 4.0, 6.0, 7.5, 8.0];
    return List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getSampleChartData();

    return Scaffold(
      appBar: AppBar(title: const Text('気分分析'), elevation: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 気分の波線グラフ (無料でも提供) ---
            const Text(
              '過去7日間の気分の波',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  // グラフの詳細設定 (軸、グリッドなど) は省略
                  minY: 1,
                  maxY: 10,
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: Colors.blue.shade600,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- 2. 有料機能への誘導エリア (F-8, F-9) ---
            if (!_isPremium)
              _buildPremiumAnalysisAd(context)
            else
              _buildPremiumAnalysisContent(),
          ],
        ),
      ),
    );
  }

  // ★★★ 無料ユーザー向け広告ウィジェット (F-8/F-9への導線) ★★★
  Widget _buildPremiumAnalysisAd(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔒 プレミアム分析を解放する',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '（F-9）自己覚知度スコア、行動パターンとタグの相関性、環境トリガーの詳細分析など、深い洞察を得ることで、内省の粒度を細かくできます。',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('プランを確認する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★★★ 有料ユーザー向け分析コンテンツ (F-9: 自己覚知度提示) ★★★
  Widget _buildPremiumAnalysisContent() {
    // TODO: ここに実際のAI分析結果やレーダーチャートを表示する
    return Card(
      color: Colors.blue.shade50,
      elevation: 4,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ 自己覚知度スコア: B+',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '現在のデータに基づくと、あなたは感情のトリガー特定に高い能力を示しています。特に低スコア時の行動パターンの言語化が進んでいます。',
            ),
            SizedBox(height: 10),
            //  // レーダーチャートの表示
            Text('--- 高度なテクニカル分析レポート ---'),
            Text('・環境相関: 低気圧の日の「疲労」タグ選択率が35%増加しています。'),
            Text('・パターン特定: 「イライラ」タグは、午前中の職場でのみ発生しています。'),
          ],
        ),
      ),
    );
  }
}
