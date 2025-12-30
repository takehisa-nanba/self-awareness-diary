import 'package:flutter/material.dart';
import '../../domain/models/diary_record.dart';
import '../../services/isar_service.dart';
import '../../core/utils/color_helpers.dart';
import '../../services/gemini_service.dart';
import 'settings_provider.dart';

class DetailProvider with ChangeNotifier {
  final DiaryRecord record;
  final GeminiService _geminiService;
  final SettingsProvider _settingsProvider;

  DetailProvider(this.record, this._geminiService, this._settingsProvider);

  // --- 編集モードの管理 ---
  bool _isEditing = false;
  bool get isEditing => _isEditing;

  void toggleEdit() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  // --- 保存処理 ---
  Future<void> updateSelfAnalysis(String newText) async {
    record.selfAnalysis = newText;

    // Tier 2ユーザーで、かつ自己分析が5文字以上の場合のみAI分析を実行
    if (_settingsProvider.currentTier == SubscriptionTier.tier2 &&
        newText.length >= 5) {
      try {
        final analysis = await _geminiService.analyzeStability(newText);
        record.aiStabilityScore = analysis['score'];
        record.aiAnalysisReason = analysis['reason'];
      } catch (e) {
        debugPrint("AI Analysis Error on update: $e");
        // エラーでもUIの更新は止めない
        record.aiStabilityScore = null;
        record.aiAnalysisReason = "AI分析中にエラーが発生しました。";
      }
    } else {
      // 条件を満たさない場合はAI分析結果をクリア
      record.aiStabilityScore = null;
      record.aiAnalysisReason = null;
    }

    // Isarに上書き保存
    await isarService.saveRecord(record);
    _isEditing = false;
    notifyListeners();
  }

  // --- 場所の登録状態判定 ---
  Future<bool> isLocationUnregistered() async {
    if (record.location == null || record.location!.isEmpty) return false;
    final isRegistered = await isarService.isLocationRegistered(
      record.location!,
    );
    return !isRegistered;
  }

  // --- 場所の名前更新処理 ---
  Future<void> updateLocationName(String newLabel) async {
    record.location = newLabel;
    await isarService.saveRecord(record);
    notifyListeners();
    debugPrint("DetailProvider: 場所の名前を「$newLabel」に更新しました。");
  }

  // --- 既存の表示ロジック ---
  Color get scoreColor {
    return getAiScoreColor(record.aiStabilityScore);
  }

  String get environmentInfo =>
      "${record.weather ?? '不明'} / ${record.location ?? '位置情報なし'}";

  bool get hasAnalysis => record.aiStabilityScore != null;
}
