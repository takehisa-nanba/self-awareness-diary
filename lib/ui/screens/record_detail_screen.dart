// lib/ui/screens/record_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/diary_record.dart';
import '../../providers/detail_provider.dart';

class RecordDetailScreen extends StatelessWidget {
  final DiaryRecord record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    // この画面専用のProviderを生成して配る
    return ChangeNotifierProvider(
      create: (_) => DetailProvider(record),
      child: Scaffold(
        appBar: AppBar(title: const Text('記録の詳細')),
        body: const _DetailBody(),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetailProvider>();
    final record = provider.record;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 環境情報
          Text(provider.environmentInfo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          
          const _SectionTitle("起きたこと"),
          const SizedBox(height: 8),
          Text(record.eventText, style: const TextStyle(fontSize: 18)),
          
          const SizedBox(height: 32),
          
          const _SectionTitle("AI分析結果"),
          const SizedBox(height: 12),
          _AIAnalysisCard(provider: provider), // 修正：部品を呼び出す
        ],
      ),
    );
  }
}

// 内部部品1：セクションタイトル
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }
}

// 内部部品2：AI分析カード (表示に専念)
class _AIAnalysisCard extends StatelessWidget {
  final DetailProvider provider;
  const _AIAnalysisCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final record = provider.record;
    final color = provider.scoreColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("感情の安定度", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                provider.hasAnalysis ? "${record.aiStabilityScore}%" : "--%",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.aiAnalysisReason ?? "分析データはありません",
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}