// lib/providers/detail_provider.dart
import 'package:flutter/material.dart';
import '../../models/diary_record.dart';

class DetailProvider with ChangeNotifier {
  final DiaryRecord record;
  DetailProvider(this.record);

  // 表示ロジック：スコアに応じた色を判定
  Color get scoreColor {
    final score = record.aiStabilityScore ?? 0;
    if (score >= 80) return Colors.green;
    if (score >= 40) return Colors.blue;
    return Colors.orange;
  }

  // 表示ロジック：場所と天気を一行にまとめる
  String get environmentInfo => 
      "${record.weather ?? '不明'} / ${record.location ?? '位置情報なし'}";

  // 表示ロジック：分析データの有無
  bool get hasAnalysis => record.aiStabilityScore != null;
}