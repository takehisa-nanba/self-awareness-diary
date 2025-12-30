// lib/domain/models/diary_record.dart

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
  ///
  /// テキストの長さ、句点の数（文章の密度）、気分タグや出来事の言及、
  /// そして未来志向のキーワードの有無など、複数の要素から総合的に評価します。
  int get polishingLevel {
    if (selfAnalysis == null || selfAnalysis!.isEmpty) {
      return 0; // 自己分析がなければ0点
    }

    double score = 10; // 基礎点

    // 1. テキストの長さボーナス (最大30点)
    // テキストが長いほど、深く内省している可能性が高いと評価します。
    score += (selfAnalysis!.length * 0.2).clamp(0, 30);

    // 2. 句点（。）の数による密度ボーナス (最大15点)
    // 句点の数は、文章の構造と密度を示唆します。複数の文で構成されているほど、より整理された思考と見なします。
    final sentenceCount = '。'.allMatches(selfAnalysis!).length;
    score += (sentenceCount * 5.0).clamp(0, 15);

    // 3. 気分タグ言及ボーナス (最大20点)
    // ユーザーが選択した気分タグについて言及している場合、感情と向き合っている証拠として加点します。
    int tagMentions = 0;
    for (var tag in moodTags) {
      if (selfAnalysis!.contains(tag)) {
        tagMentions++;
      }
    }
    score += (tagMentions * 5.0).clamp(0, 20);

    // 4. 出来事言及ボーナス (最大15点)
    // 記録した「出来事」のキーワード（3文字以上）が自己分析に含まれているか評価します。
    // 出来事と内省を結びつけているほど、より深い分析と見なします。
    final eventWords = eventText
        .split(RegExp(r'\s+')) // スペースや改行で単語に分割
        .where((word) => word.length >= 3) // 3文字以上の単語を抽出
        .toSet(); // 重複を除外
    int eventWordMentions = 0;
    for (var word in eventWords) {
      if (selfAnalysis!.contains(word)) {
        eventWordMentions++;
      }
    }
    score += (eventWordMentions * 3.0).clamp(0, 15);

    // 5. 未来志向ボーナス（気分スコアが低い時のみ、最大20点）
    // 気分が落ち込んでいる時に、次への行動や感謝、学びの言葉がある場合、
    // 回復力や前向きな姿勢の表れとして大きく加点します。
    if (moodScore < 40) {
      final futureKeywords = ['次は', 'やってみる', '感謝', '学んだ', '成長'];
      for (var keyword in futureKeywords) {
        if (selfAnalysis!.contains(keyword)) {
          score += 20; // 大幅ボーナス
          break; // いずれかのキーワードが含まれていれば一度だけ加点
        }
      }
    }

    return score.round().clamp(0, 100); // 最終スコアを0-100の範囲に丸めて返す
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
