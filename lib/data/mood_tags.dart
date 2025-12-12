// lib/data/mood_tags.dart

import 'package:flutter/material.dart';

// ★★★ タグの分類と色分けの定義 ★★★
enum TagCategory {
  positive, // ポジティブ (緑系)
  flat, // フラット (黄色系)
  negative, // ネガティブ (赤系)
}

// タグのデータ構造
class MoodTag {
  final String name;
  final TagCategory category;
  final bool isPremium;

  MoodTag(this.name, this.category, {this.isPremium = false});

  // 分類に基づいて色を返すgetter
  Color get color {
    switch (category) {
      case TagCategory.positive:
        return Colors.green.shade600; // ポジティブは濃い緑
      case TagCategory.flat:
        return Colors.amber.shade600; // フラットは濃いアンバー（黄色系）
      case TagCategory.negative:
        return Colors.red.shade600; // ネガティブは濃い赤
    }
  }
}

// ★★★ 最終決定したタグリスト（無料版10個 + 有料版） ★★★
final List<MoodTag> allMoodTags = [
  // --- 無料版タグ (10個) ---
  // ポジティブ (3個)
  MoodTag('楽しい', TagCategory.positive),
  MoodTag('集中', TagCategory.positive),
  MoodTag('落ち着いている', TagCategory.positive),

  // フラット (3個)
  MoodTag('ニュートラル', TagCategory.flat),
  MoodTag('退屈', TagCategory.flat),
  MoodTag('眠い', TagCategory.flat),

  // ネガティブ (4個)
  MoodTag('不安', TagCategory.negative),
  MoodTag('イライラ', TagCategory.negative),
  MoodTag('疲労', TagCategory.negative),
  MoodTag('悲しい', TagCategory.negative),

  // --- 有料版タグ (F-10 / 差別化のため非表示で導線を作る) ---
  MoodTag('感謝', TagCategory.positive, isPremium: true),
  MoodTag('達成感', TagCategory.positive, isPremium: true),
  MoodTag('焦り', TagCategory.negative, isPremium: true),
  MoodTag('孤独', TagCategory.negative, isPremium: true),
  MoodTag('自己嫌悪', TagCategory.negative, isPremium: true),
  MoodTag('無関心', TagCategory.flat, isPremium: true),
  // ... (合計30〜50個になるまでタグを追加することを想定)
];

// UIで表示するタグリスト（無料版ユーザー向け）
final List<MoodTag> visibleMoodTags = allMoodTags
    .where((tag) => !tag.isPremium)
    .toList();

// 有料タグの総数
final int premiumTagCount = allMoodTags.where((tag) => tag.isPremium).length;
