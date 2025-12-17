// lib/screens/history_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/record.dart';
import '../main.dart'; // isarインスタンス取得用
import '../services/gemini_service.dart';

class HistoryDetailScreen extends StatefulWidget {
  final Record record;
  const HistoryDetailScreen({super.key, required this.record});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late TextEditingController _analysisController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _analysisController = TextEditingController(text: widget.record.selfAnalysis);
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.initState();
    super.dispose(); // 忘れずに親のdisposeも呼ぶ
  }

  // 保存処理
  Future<void> _saveAnalysis() async {
    // 1. ローディング表示（AI解析中）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AIが再分析しています...'), duration: Duration(seconds: 1)),
    );

    // 2. 書き換えた文章で AI 安定度を再測定
    final analysisResult = await geminiService.analyzeStability(_analysisController.text);

    // 3. レコードを更新
    final updatedRecord = widget.record.copyWith(
      selfAnalysis: _analysisController.text,
      aiStabilityScore: analysisResult['score'] ?? 50, // ★ AIスコアを更新
      aiAnalysisReason: analysisResult['reason'] ?? "再分析に失敗しました", // ★ 理由を更新
    );

    // 4. 保存
    await isar.writeTxn(() async {
      await isar.records.put(updatedRecord);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内省とAIスコアを更新しました')),
      );
      setState(() => _isEditing = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    // ズレの計算
    final int userScore = widget.record.moodScore * 10;
    final int aiScore = widget.record.aiStabilityScore ?? 0;
    final int diff = (userScore - aiScore).abs();
    final bool hasGap = widget.record.aiStabilityScore != null && diff >= 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text('記録の詳細'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveAnalysis();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. メタ認知インサイト・カード（主観 vs 客観）
            _buildInsightCard(userScore, aiScore, hasGap),

            const SizedBox(height: 20),

            // 2. 基本情報セクション
            _buildSectionTitle(Icons.event, "基本情報"),
            _buildInfoTile("日時", "${widget.record.recordDate.month}/${widget.record.recordDate.day} ${widget.record.recordDate.hour}:${widget.record.recordDate.minute}"),
            _buildInfoTile("場所/天気", "${widget.record.location?.split(',').first ?? '不明'} / ${widget.record.weather?.split('/').first ?? '不明'}"),
            _buildInfoTile("感情タグ", widget.record.moodTags.join(', ')),

            const SizedBox(height: 20),

            // 3. 出来事セクション
            _buildSectionTitle(Icons.notes, "その時の出来事"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(widget.record.eventText, style: const TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 20),

            // 4. 内省・詳細セクション
            _buildSectionTitle(Icons.psychology, "振り返り・自己分析"),
            TextField(
              controller: _analysisController,
              enabled: _isEditing,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "ここをタップして、後から気づいたことを書き足せます...",
                border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                filled: _isEditing,
                fillColor: Colors.blue.shade50.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // インサイトカードの構築
  Widget _buildInsightCard(int userScore, int aiScore, bool hasGap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("自己認識のズレ（メタ認知）", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreIndicator("あなたの気分", userScore, Colors.orange),
                Icon(hasGap ? Icons.compare_arrows : Icons.sync, color: hasGap ? Colors.red : Colors.green, size: 30),
                _buildScoreIndicator("AIの安定度", aiScore, Colors.blue),
              ],
            ),
            if (widget.record.aiAnalysisReason != null) ...[
              const Divider(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.record.aiAnalysisReason!,
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text("$score%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}