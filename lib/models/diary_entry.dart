// lib/models/diary_entry.dart

import 'package:isar/isar.dart'; // データベースの機能を使うための宣言

// ↓この行は今は赤線（エラー）が出ても無視してください！
// 後で「裏方の職人」がこのファイル（.g.dart）を自動生成してくれます。
part 'diary_entry.g.dart';

@collection // ★「これはDBのテーブルですよ」という目印
class DiaryEntry {
  // 自動で番号を振ってくれるID
  Id id = Isar.autoIncrement;

  // 日時（検索しやすいようにインデックスを付ける）
  @Index()
  final DateTime date;
  final int moodScore;
  final String content;
  final List<String> tags;
  final String? languageDetail;

  // コンストラクタ
  DiaryEntry({
    required this.date,
    required this.moodScore,
    required this.tags,
    required this.content,
    this.languageDetail, // null許容
  });
}
