// lib/data/mood_tag_list.dart

import 'package:flutter/material.dart';
import '../domain/models/mood_tag.dart';
import '../domain/models/subscription_tier.dart'; // SubscriptionTier の定義のため

/// アプリケーションで利用可能なすべての気分タグの定義済みリスト。
///
/// 各 [MoodTag] は、ラベル、アイコン、色、および関連するサブスクリプションティア
/// ([SubscriptionTier.free], [SubscriptionTier.tier1], [SubscriptionTier.tier2]) を持ちます。
const List<MoodTag> allMoodTags = [
  // --- 無料プラン (15個) ---
  MoodTag(
    label: 'うれしい',
    icon: Icons.sentiment_very_satisfied,
    color: Colors.amber,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'わくわく',
    icon: Icons.star,
    color: Colors.orange,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'ほっとする',
    icon: Icons.sentiment_satisfied,
    color: Colors.lightGreen,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'ありがとう',
    icon: Icons.volunteer_activism,
    color: Colors.pink,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'すっきり',
    icon: Icons.cleaning_services,
    color: Colors.lightBlue,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'いつも通り',
    icon: Icons.sentiment_neutral,
    color: Colors.blueGrey,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'つかれた',
    icon: Icons.battery_charging_full,
    color: Colors.grey,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'だるい',
    icon: Icons.sick,
    color: Color(0xFF90A4AE), // 独自のカラー定義
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'かなしい',
    icon: Icons.sentiment_very_dissatisfied,
    color: Colors.blue,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'イライラ',
    icon: Icons.mood_bad,
    color: Colors.red,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'そわそわ',
    icon: Icons.motion_photos_on,
    color: Colors.purple,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'モヤモヤ',
    icon: Icons.cloud,
    color: Colors.indigo,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'いやだな',
    icon: Icons.thumb_down,
    color: Colors.brown,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'びっくり',
    icon: Icons.lightbulb,
    color: Colors.yellow,
    tier: SubscriptionTier.free,
  ),
  MoodTag(
    label: 'あれ？',
    icon: Icons.help_outline,
    color: Colors.deepOrange,
    tier: SubscriptionTier.free,
  ),

  // --- Tier 1 追加分 (15個) ---
  MoodTag(
    label: '誇らしい',
    icon: Icons.emoji_events,
    color: Colors.orangeAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: '愛おしい',
    icon: Icons.favorite,
    color: Colors.pinkAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'つながり',
    icon: Icons.people,
    color: Colors.teal,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: '没頭',
    icon: Icons.psychology,
    color: Colors.indigoAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'やる気',
    icon: Icons.auto_awesome,
    color: Colors.lightGreenAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'パンク気味',
    icon: Icons.battery_alert,
    color: Colors.redAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'ドキドキ（緊張）',
    icon: Icons.heart_broken,
    color: Colors.purpleAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'あせり',
    icon: Icons.speed,
    color: Colors.deepOrangeAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: '申し訳ない',
    icon: Icons.sentiment_dissatisfied,
    color: Color(0xFFBCAAA4),
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: '情けない',
    icon: Icons.sentiment_very_dissatisfied,
    color: Color(0xFFB0BEC5),
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'ショック',
    icon: Icons.flash_on,
    color: Colors.deepPurpleAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'のびのび',
    icon: Icons.self_improvement,
    color: Colors.cyan,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'がんばり時',
    icon: Icons.fitness_center,
    color: Colors.amberAccent,
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'あわただしい',
    icon: Icons.moped,
    color: Color(0xFF78909C),
    tier: SubscriptionTier.tier1,
  ),
  MoodTag(
    label: 'つまらない',
    icon: Icons.hourglass_empty,
    color: Color(0xFF455A64),
    tier: SubscriptionTier.tier1,
  ),

  // --- Tier 2 追加分 (20個) ---
  MoodTag(
    label: '最高！',
    icon: Icons.emoji_emotions,
    color: Color(0xFFF9A825),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: '満たされる',
    icon: Icons.ac_unit,
    color: Color(0xFF64B5F6),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'しみじみ感動',
    icon: Icons.auto_awesome,
    color: Color(0xFFFF8A65),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'なつかしい',
    icon: Icons.history,
    color: Color(0xFFBCAAA4),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: '静かな一人',
    icon: Icons.person,
    color: Color(0xFF7986CB),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'ふざけたい',
    icon: Icons.tag_faces,
    color: Color(0xFFDCE775),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: '演じている',
    icon: Icons.theater_comedy,
    color: Color(0xFF757575),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: '切ない',
    icon: Icons.favorite_border,
    color: Color(0xFFF06292),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'どんより',
    icon: Icons.cloud_off,
    color: Color(0xFF78909C),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'からっぽ',
    icon: Icons.circle_outlined,
    color: Color(0xFFBDBDBD),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'ポツンと',
    icon: Icons.person_off,
    color: Color(0xFF90CAF9),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'まっすぐ',
    icon: Icons.straighten,
    color: Color(0xFF66BB6A),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: '見通しが立った',
    icon: Icons.map,
    color: Color(0xFFFFCA28),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'ゆれる',
    icon: Icons.alt_route,
    color: Color(0xFFBA68C8),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'もう無理',
    icon: Icons.error_outline,
    color: Color(0xFFE53935),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'びくびく',
    icon: Icons.sentiment_dissatisfied,
    color: Color(0xFFFFCCBC),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: '冷めている',
    icon: Icons.sentiment_neutral,
    color: Color(0xFFCFD8DC),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'わかる',
    icon: Icons.diversity_3,
    color: Color(0xFF80CBC4),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'つい',
    icon: Icons.rocket_launch,
    color: Color(0xFFF8BBD0),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: 'せわしない',
    icon: Icons.timer,
    color: Color(0xFF8D6E63),
    tier: SubscriptionTier.tier2,
  ),
  MoodTag(
    label: '違和感',
    icon: Icons.warning_amber,
    color: Colors.deepOrange,
    tier: SubscriptionTier.tier2,
  ),
];
