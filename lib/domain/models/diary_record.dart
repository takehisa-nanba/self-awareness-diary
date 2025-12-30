// C:\Users\ramp1\Desktop\self-awareness-diary\lib\domain\models\diary_record.dart

import 'package:isar/isar.dart';
part 'diary_record.g.dart';

/// 一つの日記エントリーを表すデータモデル。
/// Isarデータベースに永続化されるオブジェクトです。
@collection
class DiaryRecord {
  /// Isarが自動で割り当てる内部ID。
  Id? isarId;

  /// レコードを一意に識別するためのID（例: UUID）。重複を許さず、更新時に置換されます。
  @Index(unique: true, replace: true)
  late String recordId;

  /// 日記が記録された正確な日時。
  late DateTime recordDate;

  /// その時の気分を表すタグのリスト。
  late List<String> moodTags;

  /// ユーザーが自己評価した気分のスコア（0-100）。
  late int moodScore;

  /// その時に起こった出来事を記述したテキスト。
  late String eventText;

  /// 出来事に対する自己分析や内省を記述したテキスト（任意）。
  String? selfAnalysis;

  /// AIが分析した心の安定度スコア（任意）。
  int? aiStabilityScore;

  /// AIによる分析の根拠や理由（任意）。
  String? aiAnalysisReason;

  /// 記録場所の地名（任意）。
  String? location;

  /// 記録時の天気（任意）。
  String? weather;

  /// 記録場所の緯度（任意）。
  double? latitude;

  /// 記録場所の経度（任意）。
  double? longitude;

  /// [DiaryRecord] のコンストラクタ。
  DiaryRecord({
    this.isarId,
    required this.recordId,
    required this.recordDate,
    required this.moodTags,
    required this.moodScore,
    required this.eventText,
    this.selfAnalysis,
    this.aiStabilityScore,
    this.aiAnalysisReason,
    this.location,
    this.weather,
    this.latitude,
    this.longitude,
  });

  /// ユーザーの気分スコアとAIの安定度スコアに大きな乖離があるかどうかを判定します。
  /// 乖離が20以上ある場合に `true` を返します。
  bool get isGapLarge {
    if (aiStabilityScore == null) return false;
    return (moodScore * 10 - aiStabilityScore!).abs() >= 20;
  }

  /// 記録日時を "HH:MM" 形式の文字列で返します。
  String get timeString =>
      "${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}";
}

/// [DiaryRecord] の分析関連ロジックをまとめた拡張。
extension DiaryRecordAnalysis on DiaryRecord {
  /// 自己分析の深さを示す「研磨度」を計算して返します (0-100)。
  /// テキストの長さと選択された気分タグの数（焦点の絞り具合）に基づいて算出されます。
  int get polishingLevel {
    if (selfAnalysis == null || selfAnalysis!.isEmpty) {
      return 0;
    }

    final textLength = selfAnalysis!.length;
    final double focusMultiplier;

    if (moodTags.length <= 2) {
      focusMultiplier = 3.0; // 焦点が絞られている
    } else if (moodTags.length == 3) {
      focusMultiplier = 1.8;
    } else {
      focusMultiplier = 1.0; // 焦点が分散
    }

    final score = textLength * 0.3 * focusMultiplier;
    return score.round().clamp(0, 100);
  }

  /// 研磨度に応じた絵文字アイコンを返します。
  String get polishingIcon {
    final level = polishingLevel;
    if (level >= 90) return '💎'; // 結晶
    if (level >= 66) return '✨'; // 洗練
    if (level >= 36) return '🌟'; // 研磨
    if (level >= 16) return '🔶'; // 粗削り
    if (level > 0) return '🔨'; // 成形
    return '🪨'; // 原石
  }

  /// 自己分析が未記入の場合に表示するメッセージを返します。
  String get polishingMessage {
    if (selfAnalysis == null || selfAnalysis!.isEmpty) {
      return '気づきの原石が眠っています';
    }
    return '';
  }
}
