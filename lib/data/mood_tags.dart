import 'package:flutter/material.dart';

enum TagCategory {
  positive, // ポジティブ (エネルギー高・快)
  flat,     // フラット (自分軸・安定)
  negative, // ネガティブ (不快・葛藤)
}

class MoodTag {
  final String name;
  final TagCategory category;
  final bool isPremium;

  MoodTag(this.name, this.category, {this.isPremium = false});

  Color get color {
    switch (category) {
      case TagCategory.positive:
        return Colors.orange.shade600; // 前向きなエネルギー(暖色)
      case TagCategory.flat:
        return Colors.blue.shade600;   // 凪・安定の状態(青系)
      case TagCategory.negative:
        return Colors.deepPurple.shade400; // 葛藤や沈み(紫系)
    }
  }
}

// ★★★ 心理学に基づき再定義した10個のタグ ★★★
final List<MoodTag> allMoodTags = [
  // --- 無料版タグ (10個) ---
  
  // ポジティブ (4個)
  MoodTag('ワクワク', TagCategory.positive),
  MoodTag('スッキリ', TagCategory.positive),
  MoodTag('自信', TagCategory.positive),
  MoodTag('感謝', TagCategory.positive),

  // フラット (2個: 安定の状態)
  MoodTag('穏やか・安定', TagCategory.flat),
  MoodTag('集中', TagCategory.flat),

  // ネガティブ (4個)
  MoodTag('モヤモヤ', TagCategory.negative),
  MoodTag('イライラ', TagCategory.negative),
  MoodTag('ヘトヘト', TagCategory.negative),
  MoodTag('悲しい', TagCategory.negative),

  // --- 有料版タグ (F-10 / 将来の拡張用) ---
  MoodTag('達成感', TagCategory.positive, isPremium: true),
  MoodTag('誇らしい', TagCategory.positive, isPremium: true),
  MoodTag('焦り', TagCategory.negative, isPremium: true),
  MoodTag('孤独', TagCategory.negative, isPremium: true),
  MoodTag('自己嫌悪', TagCategory.negative, isPremium: true),
  MoodTag('無関心', TagCategory.flat, isPremium: true),
];

// UIで表示するタグリスト（無料版ユーザー向け）
final List<MoodTag> visibleMoodTags = allMoodTags
    .where((tag) => !tag.isPremium)
    .toList();

final int premiumTagCount = allMoodTags.where((tag) => tag.isPremium).length;