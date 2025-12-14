// lib/core/history_detail_core.dart

import 'package:flutter/material.dart';
import '../models/record.dart';
import '../main.dart'; // isar
import '../services/gemini_service.dart'; // AIサービス

class HistoryDetailCore with ChangeNotifier {
  // ★★★ 状態とデータ ★★★
  Record _record; // 表示・編集対象のレコード（外部から注入）
  late TextEditingController _analysisController;
  
  bool _isEditing = false;
  bool _isLoadingAi = false;
  String? _aiQuestion;

  // コンストラクタでレコードを受け取り初期化
  HistoryDetailCore({required Record record}) : _record = record {
    _analysisController = TextEditingController(
      text: _record.selfAnalysis,
    );
  }

  // ★★★ Getter (Viewが参照する状態) ★★★
  Record get record => _record;
  TextEditingController get analysisController => _analysisController;
  bool get isEditing => _isEditing;
  bool get isLoadingAi => _isLoadingAi;
  String? get aiQuestion => _aiQuestion;

  // スコアの色を取得する純粋な関数 (Coreに保持)
  Color getScoreColor() {
    if (_record.moodScore >= 8) return Colors.green.shade600;
    if (_record.moodScore >= 5) return Colors.amber.shade600;
    return Colors.red.shade600;
  }

  // ★★★ ライフサイクルとクリーンアップ ★★★
  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  // ★★★ ロジックメソッド (Setter) ★★★

  // 編集モードの切り替え
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }
  
  // ★★★ F-6: 記録の更新 (事後言語化の保存) ★★★
  // Viewからの指示を受けてデータ層の更新を行う
  Future<void> saveAnalysis() async {
    // 編集内容を反映した新しいレコードオブジェクトを作成
    final updatedRecord = _record.copyWith(
      selfAnalysis: _analysisController.text,
    );

    // Isarへの書き込み処理
    await isar.writeTxn(() async {
      await isar.records.put(updatedRecord);
    });

    // 内部のレコード状態とUIを更新
    _record = updatedRecord;
    _isEditing = false;
    notifyListeners();
  }

  // ★★★ F-7: AI言語化アシストのロジック ★★★
  Future<void> generateAiQuestion() async {
    _isLoadingAi = true;
    _aiQuestion = null;
    notifyListeners();

    try {
      // サービスを呼び出し、必要な記録データを渡す
      final question = await geminiService.generateReflectionQuestion(
        moodTags: _record.moodTags.join(', '),
        eventText: _record.eventText,
        moodScore: _record.moodScore,
        location: _record.location,
        weather: _record.weather,
      );
      
      _aiQuestion = question;
      _isLoadingAi = false;

    } catch (e) {
      _aiQuestion = "エラー: AIサービスの起動に失敗しました。";
      _isLoadingAi = false;
      debugPrint("AI Question Generation Failed: $e");
    }
    notifyListeners();
  }
}