// lib/models/record.dart (isarId修正後の最終版)

import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';

part 'record.g.dart';

// 記録データモデル (最終確定版)
@collection
@immutable // 不変性を宣言
class Record {
  // ★★★ 修正箇所1: isarIdをfinalかつNullableにする ★★★
  // DB保存時はnullで渡され、保存後にIsarが値を割り当てる
  final Id? isarId;

  @Index(unique: true)
  final String recordId;

  final DateTime recordDate;
  final List<String> moodTags;
  final int moodScore;
  final String eventText;

  // 外部データ
  final String location;
  final String weather;

  // 事後言語化
  final String selfAnalysis;

  // コンストラクタ (修正2: isarIdをコンストラクタに追加)
  Record({
    this.isarId, // 修正2: 追加
    required this.recordId,
    required this.recordDate,
    required this.moodTags,
    required this.moodScore,
    required this.eventText,
    required this.location,
    required this.weather,
    this.selfAnalysis = '',
  });

  // copyWithメソッド (修正3: isarIdをcopyの対象に追加)
  Record copyWith({
    Id? isarId, // 修正3: 追加
    String? recordId,
    DateTime? recordDate,
    List<String>? moodTags,
    int? moodScore,
    String? eventText,
    String? location,
    String? weather,
    String? selfAnalysis,
  }) {
    return Record(
      isarId: isarId ?? this.isarId, // 修正3: 追加
      recordId: recordId ?? this.recordId,
      recordDate: recordDate ?? this.recordDate,
      moodTags: moodTags ?? this.moodTags,
      moodScore: moodScore ?? this.moodScore,
      eventText: eventText ?? this.eventText,
      location: location ?? this.location,
      weather: weather ?? this.weather,
      selfAnalysis: selfAnalysis ?? this.selfAnalysis,
    );
  }
}
