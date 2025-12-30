// lib/domain/models/mood_tag.dart

import 'package:flutter/material.dart';
import '../../providers/settings_provider.dart'; // SubscriptionTierの定義をインポート

/// 気分タグの情報を定義するデータモデルクラス。
///
/// 各タグは、表示ラベル、アイコン、色、および関連するサブスクリプションティアを保持します。
class MoodTag {
  /// 気分タグの表示ラベル（例：「うれしい」、「かなしい」）。
  final String label;

  /// 気分タグに関連付けられたアイコン。
  final IconData icon;

  /// 気分タグに関連付けられた色。
  final Color color;

  /// この気分タグが利用可能になるサブスクリプションティア。
  final SubscriptionTier tier;

  /// [MoodTag] のコンストラクタ。
  const MoodTag({
    required this.label,
    required this.icon,
    required this.color,
    required this.tier, // 必須プロパティにする
  });
}
