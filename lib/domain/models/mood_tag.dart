// lib/domain/models/mood_tag.dart

import 'package:flutter/material.dart';
import '../../providers/settings_provider.dart'; // SubscriptionTierの定義をインポート

class MoodTag {
  final String label;
  final IconData icon;
  final Color color;
  final SubscriptionTier tier; // どのプランに属するかを追加

  const MoodTag({
    required this.label,
    required this.icon,
    required this.color,
    required this.tier, // 必須プロパティにする
  });
}
