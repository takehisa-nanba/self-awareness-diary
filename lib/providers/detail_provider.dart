// lib/providers/detail_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import '../../domain/models/diary_record.dart';
import '../../services/isar_service.dart'; // isarService にアクセスするため
import '../../core/utils/color_helpers.dart'; // getAiScoreColor 関数を使用
import '../../services/gemini_service.dart';
import 'settings_provider.dart';

/// 日記レコードの詳細画面のデータと状態を管理するプロバイダークラス。
///
/// レコードの編集、自己分析の更新、AI分析の実行、
/// 場所の登録状態判定などを担当します。
class DetailProvider with ChangeNotifier {
  /// 現在表示または編集している日記レコード。
  final DiaryRecord record;

  /// Gemini AIサービス。心の安定度分析などに使用。
  final GeminiService _geminiService;

  /// 設定プロバイダー。サブスクリプションティアの確認などに使用。
  final SettingsProvider _settingsProvider;

  /// [DetailProvider] のコンストラクタ。
  DetailProvider(this.record, this._geminiService, this._settingsProvider);

  // 編集モードの管理
  /// 自己分析の編集モードに入っているかどうかを示すフラグ。
  bool _isEditing = false;
  bool get isEditing => _isEditing;

  /// 編集モードの状態を切り替えます。
  void toggleEdit() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  /// 自己分析のテキストを更新し、その変更を永続化します。
  ///
  /// Tier 2ユーザーの場合、更新された自己分析に基づいてAIによる心の安定度分析を再度実行し、
  /// その結果もレコードに保存します。
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
        // エラーが発生してもUIの更新は止めないが、AI分析結果はクリア
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
    _isEditing = false; // 編集モードを終了
    notifyListeners();
  }

  /// 現在のレコードに記録されている場所が、ユーザーの登録地点としてまだ登録されていないかどうかを判定します。
  ///
  /// レコードに場所が記録されていない場合や、既に登録されている場合は `false` を返します。
  Future<bool> isLocationUnregistered() async {
    if (record.location == null || record.location!.isEmpty) return false;
    final isRegistered = await isarService.isLocationRegistered(
      record.location!,
    );
    return !isRegistered;
  }

  /// レコードの場所名を更新し、その変更を永続化します。
  ///
  /// [newLabel] 新しい場所のラベル。
  Future<void> updateLocationName(String newLabel) async {
    record.location = newLabel;
    await isarService.saveRecord(record);
    notifyListeners();
    debugPrint("DetailProvider: 場所の名前を「$newLabel」に更新しました。");
  }

  // 既存の表示ロジック
  /// AI分析スコアに基づいて、UIに表示するための適切な色を返します。
  Color get scoreColor {
    return getAiScoreColor(record.aiStabilityScore);
  }

  /// 天気情報と場所情報を組み合わせた環境情報文字列を返します。
  String get environmentInfo =>
      "${record.weather ?? '不明'} / ${record.timeString} / ${record.location ?? '位置情報なし'}";

  /// AI分析結果が存在するかどうかを返します。
  bool get hasAnalysis => record.aiStabilityScore != null;
}
