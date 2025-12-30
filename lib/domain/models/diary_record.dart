// lib/models/diary_record.dart
import 'package:isar/isar.dart';
part 'diary_record.g.dart';

@collection
class DiaryRecord {
  Id? isarId;
  @Index(unique: true, replace: true)
  late String recordId;
  late DateTime recordDate;
  late List<String> moodTags;
  late int moodScore;
  late String eventText;
  String? selfAnalysis;
  int? aiStabilityScore;
  String? aiAnalysisReason;
  String? location;
  String? weather;
  double? latitude;
  double? longitude;

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

  bool get isGapLarge {
    if (aiStabilityScore == null) return false;
    return (moodScore * 10 - aiStabilityScore!).abs() >= 20;
  }

  String get timeString =>
      "${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}";
}

extension DiaryRecordAnalysis on DiaryRecord {
  /// 自己分析の深さを示す研磨度 (0-100)
  int get polishingLevel {
    if (selfAnalysis == null || selfAnalysis!.isEmpty) {
      return 0;
    }

    final textLength = selfAnalysis!.length;
    final double focusMultiplier;

    if (moodTags.length <= 2) {
      focusMultiplier = 3.0;
    } else if (moodTags.length == 3) {
      focusMultiplier = 1.8;
    } else {
      focusMultiplier = 1.0;
    }

    final score = textLength * 0.3 * focusMultiplier;
    return score.round().clamp(0, 100);
  }

  /// 研磨度に応じたアイコン
  String get polishingIcon {
    final level = polishingLevel;
    if (level >= 90) return '💎';
    if (level >= 50) return '✨';
    if (level > 0) return '⚒️';
    return '🪨';
  }

  /// 自己分析が未記入の場合のメッセージ
  String get polishingMessage {
    if (selfAnalysis == null || selfAnalysis!.isEmpty) {
      return '気づきの原石が眠っています';
    }
    return '';
  }
}
