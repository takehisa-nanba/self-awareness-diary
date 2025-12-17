// lib/models/record.dart

import 'package:isar/isar.dart';

part 'record.g.dart';

@collection
class Record {
  Id? isarId; // Isar用の自動インクリメントID

  @Index(unique: true, replace: true)
  late String recordId; // UUID

  late DateTime recordDate;
  late List<String> moodTags;
  late int moodScore;    // ユーザーの主観スコア (1-10)
  late String eventText; // 出来事
  String? selfAnalysis;  // 内省・詳細

  // --- ★追加フィールド: AI客観分析用 ---
  int? aiStabilityScore; // AIが算出した安定度 (0-100)
  String? aiAnalysisReason; // AIが判断した短い根拠

  // --- 既存の環境データ ---
  String? location;
  String? weather;

  // コンストラクタ
  Record({
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
  });

  // ★詳細画面での編集時に便利な copyWith メソッド
  Record copyWith({
    Id? isarId,
    String? recordId,
    DateTime? recordDate,
    List<String>? moodTags,
    int? moodScore,
    String? eventText,
    String? selfAnalysis,
    int? aiStabilityScore,
    String? aiAnalysisReason,
    String? location,
    String? weather,
  }) {
    return Record(
      isarId: isarId ?? this.isarId,
      recordId: recordId ?? this.recordId,
      recordDate: recordDate ?? this.recordDate,
      moodTags: moodTags ?? this.moodTags,
      moodScore: moodScore ?? this.moodScore,
      eventText: eventText ?? this.eventText,
      selfAnalysis: selfAnalysis ?? this.selfAnalysis,
      aiStabilityScore: aiStabilityScore ?? this.aiStabilityScore,
      aiAnalysisReason: aiAnalysisReason ?? this.aiAnalysisReason,
      location: location ?? this.location,
      weather: weather ?? this.weather,
    );
  }
}