// lib/domain/models/cosmic_observation.dart

import 'package:self_awareness_diary/domain/models/diary_record.dart';

/// 日記レコードの数値データを宇宙の物理パラメータとして解釈するモデル。
///
/// DiaryRecord の `moodScore` や `polishingLevel` などの値を基に、
/// 輝き、距離、深度といった宇宙的な表現に変換します。
class CosmicObservation {
  final DiaryRecord record;

  // 宇宙の物理パラメータ
  final double brightness; // 輝き (例: moodScoreから)
  final double distance; // 距離 (例: polishingLevelから)
  final double depth; // 深度 (例: 記録の長さ、詳細度から)

  CosmicObservation({required this.record})
    : brightness = _calculateBrightness(record),
      distance = _calculateDistance(record),
      depth = _calculateDepth(record);

  /// moodScore を輝きに変換するロジック。
  /// moodScore は 0-100 の範囲と仮定。
  /// 輝きも 0.0-1.0 の範囲で表現。
  static double _calculateBrightness(DiaryRecord record) {
    // 例: moodScoreが高いほど明るい
    return record.moodScore / 100.0;
  }

  /// polishingLevel を距離に変換するロジック。
  /// polishingLevel は 0-100 の範囲と仮定。
  /// 距離は逆相関で、研磨度が高いほど近い（より深く観測されている）と解釈。
  static double _calculateDistance(DiaryRecord record) {
    // 例: polishingLevelが高いほど距離が短い (0.0-1.0で、0.0が最も近い)
    return 1.0 - (record.polishingLevel / 100.0);
  }

  /// 記録の長さを深度に変換するロジック。
  /// eventTextとselfAnalysisの長さの合計を基に。
  static double _calculateDepth(DiaryRecord record) {
    final totalLength =
        (record.eventText.length + (record.selfAnalysis?.length ?? 0));
    // 例: 長いほど深度が深い (最大長を仮定して正規化)
    // 仮の最大長を500文字とする
    final maxLength = 500;
    return (totalLength / maxLength).clamp(0.0, 1.0);
  }

  // 必要に応じて、他の派生プロパティやメソッドを追加
}
