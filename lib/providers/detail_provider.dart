import 'package:flutter/material.dart';
import '../../domain/models/diary_record.dart';
import '../../services/isar_service.dart';
import '../../core/utils/color_helpers.dart'; // color_helpersをインポート

class DetailProvider with ChangeNotifier {
  final DiaryRecord record;
  DetailProvider(this.record);

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
    // Isarに上書き保存
    await isarService.saveRecord(record);
    _isEditing = false;
    notifyListeners();
  }

  // --- 場所の登録状態判定 ---
  // IsarServiceに問い合わせて、未登録なら true を返す
  Future<bool> isLocationUnregistered() async {
    if (record.location == null || record.location!.isEmpty) return false;
    // サービス層に問い合わせて、結果の真偽を逆にする
    final isRegistered = await isarService.isLocationRegistered(
      record.location!,
    );
    return !isRegistered;
  }

  // --- 場所の名前更新処理 ---
  Future<void> updateLocationName(String newLabel) async {
    // 1. メモリ上のデータを更新
    record.location = newLabel;

    // 2. DB（Isar）を更新（上書き保存）
    await isarService.saveRecord(record);

    // 3. 画面に「データが変わったよ！」と通知して再描画
    notifyListeners();

    debugPrint("DetailProvider: 場所の名前を「$newLabel」に更新しました。");
  }

  // --- 既存の表示ロジック ---
  Color get scoreColor {
    return getAiScoreColor(record.aiStabilityScore); // 共通関数を呼び出す
  }

  String get environmentInfo =>
      "${record.weather ?? '不明'} / ${record.location ?? '位置情報なし'}";

  bool get hasAnalysis => record.aiStabilityScore != null;
}
