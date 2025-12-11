// lib/models/record.dart

import 'package:isar/isar.dart';

part 'record.g.dart'; // Isarに自動生成を依頼するファイル名

// 記録データモデル (最終確定版)
@collection
class Record {
  // IsarのID（主キー）
  Id isarId = Isar.autoIncrement;

  // 記録の一意な識別子 (Isarでの検索を高速化)
  @Index(unique: true)
  final String recordId;

  // 記録日時
  final DateTime recordDate;

  // 気分タグのリスト (Step 1)
  final List<String> moodTags;

  // 気分スコア (1〜10) (Step 2)
  final int moodScore;

  // 出来事の記述 (Step 2)
  final String eventText;

  // ★★★ 外部データ（自動取得）★★★
  final String location;
  final String weather;

  // 自己分析/言語化（事後入力 - Step 3のデータ）
  final String selfAnalysis;

  // コンストラクタ
  Record({
    required this.recordId,
    required this.recordDate,
    required this.moodTags,
    required this.moodScore,
    required this.eventText,
    required this.location,
    required this.weather,
    this.selfAnalysis = '',
  });
}
