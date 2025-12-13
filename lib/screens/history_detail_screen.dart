// lib/screens/history_detail_screen.dart (新規作成)

import 'package:flutter/material.dart';
import '../models/record.dart';
import '../main.dart';
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
  bool _isLoadingAi = false;
  String? _aiQuestion; // AIが提示する質問

  @override
  void initState() {
    super.initState();
    // 既存の自己分析データでコントローラーを初期化
    _analysisController = TextEditingController(
      text: widget.record.selfAnalysis,
    );
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  // ★★★ F-6: 記録の更新 (事後言語化の保存) ★★★
  Future<void> _saveAnalysis() async {
    final updatedRecord = widget.record.copyWith(
      selfAnalysis: _analysisController.text,
    );

    await isar.writeTxn(() async {
      // IsarIdを使って、既存のレコードを更新 (putメソッドは既存IDがあれば更新)
      await isar.records.put(updatedRecord);
    });

    setState(() {
      _isEditing = false;
      // 画面上のrecordオブジェクトを更新（重要）
      // widget.record.selfAnalysis = _analysisController.text; // (finalなので不可)
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('自己分析を更新しました。')));
    }
  }

  // ★★★ F-7: AI言語化アシストのロジック (ダミー) ★★★
  Future<void> _generateAiQuestion() async {
    setState(() {
      _isLoadingAi = true;
      _aiQuestion = null;
    });

    try {
      // サービスを呼び出し、必要な記録データを渡す
      final question = await geminiService.generateReflectionQuestion(
        moodTags: widget.record.moodTags.join(', '),
        eventText: widget.record.eventText,
        moodScore: widget.record.moodScore,
        location: widget.record.location,
        weather: widget.record.weather,
      );
      
      setState(() {
        _aiQuestion = question;
        _isLoadingAi = false;
      });

    } catch (e) {
      setState(() {
        _aiQuestion = "エラー: AIサービスの起動に失敗しました。";
        _isLoadingAi = false;
      });
      debugPrint("AI Question Generation Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // スコアの色を取得するHelper (ここでは仮に簡易的なロジックを使用)
    Color scoreColor() {
      if (widget.record.moodScore >= 8) return Colors.green.shade600;
      if (widget.record.moodScore >= 5) return Colors.amber.shade600;
      return Colors.red.shade600;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('記録の詳細と内省'),
        backgroundColor: scoreColor(),
        actions: [
          // 編集ボタン
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          // 保存ボタン
          if (_isEditing)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveAnalysis),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 記録概要 ---
            ListTile(
              leading: Icon(Icons.calendar_today, color: scoreColor()),
              title: Text(
                '${widget.record.recordDate.month}/${widget.record.recordDate.day} ${widget.record.recordDate.hour}:${widget.record.recordDate.minute}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'スコア: ${widget.record.moodScore}/10 | タグ: ${widget.record.moodTags.join(', ')}',
              ),
            ),

            // --- 外部環境情報 (F-2) ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.record.location,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.cloud, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.record.weather,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(),

            // --- 出来事 (クイック入力) ---
            const Text(
              '【出来事】',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(widget.record.eventText),
            const SizedBox(height: 20),

            // --- 自己分析 / 言語化 (F-6) ---
            const Text(
              '【自己分析/言語化】',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // AIアシストボタン (F-7)
            if (!_isEditing)
              OutlinedButton.icon(
                onPressed: _isLoadingAi ? null : _generateAiQuestion,
                icon: _isLoadingAi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology_alt),
                label: Text(
                  _isLoadingAi ? 'AIが質問を作成中...' : 'AI言語化アシストを依頼 (質問形式)',
                ),
              ),

            // AIからの質問表示エリア
            if (_aiQuestion != null)
              Card(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'AIの質問: ${_aiQuestion!}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),

            // 分析入力フィールド
            TextField(
              controller: _analysisController,
              enabled: _isEditing,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: _isEditing
                    ? 'なぜそう感じたか、感情のトリガー、自分の行動パターンなどを記述しましょう。'
                    : '未入力',
                border: _isEditing
                    ? const OutlineInputBorder()
                    : InputBorder.none,
                fillColor: _isEditing
                    ? Colors.grey.shade100
                    : Colors.transparent,
                filled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
