// lib/data/mood_tag_list.dart

import 'package:flutter/material.dart';
import '../domain/models/mood_tag.dart';

// 無料版のムードタグ (15個)
const List<MoodTag> freeMoodTagList = [
  MoodTag(label: 'うれしい', icon: Icons.sentiment_very_satisfied, color: Colors.amber),
  MoodTag(label: 'ほっとする', icon: Icons.sentiment_satisfied, color: Colors.lightGreen),
  MoodTag(label: 'わくわく', icon: Icons.star, color: Colors.orange),
  MoodTag(label: 'ありがとう', icon: Icons.volunteer_activism, color: Colors.pink),
  MoodTag(label: 'いつも通り', icon: Icons.sentiment_neutral, color: Colors.blueGrey),
  MoodTag(label: 'だるい', icon: Icons.sick, color: Colors.grey),
  MoodTag(label: 'かなしい', icon: Icons.sentiment_very_dissatisfied, color: Colors.blue),
  MoodTag(label: 'イライラ', icon: Icons.mood_bad, color: Colors.red),
  MoodTag(label: 'そわそわ', icon: Icons.motion_photos_on, color: Colors.purple),
  MoodTag(label: 'いやだな', icon: Icons.thumb_down, color: Colors.brown),
  MoodTag(label: 'びっくり', icon: Icons.lightbulb, color: Colors.yellow),
  MoodTag(label: 'モヤモヤ', icon: Icons.cloud, color: Colors.indigo),
  MoodTag(label: 'つまらない', icon: Icons.hourglass_empty, color: Color(0xFF455A64)), // blueGrey.shade700
  MoodTag(label: '安心した', icon: Icons.check_circle, color: Colors.green),
  MoodTag(label: '違和感', icon: Icons.warning_amber, color: Colors.deepOrange),
];

// Tier 1版のムードタグ (追加15個、合計30個)
const List<MoodTag> tier1MoodTagList = [
  ...freeMoodTagList,
  MoodTag(label: '誇らしい', icon: Icons.emoji_events, color: Colors.orangeAccent),
  MoodTag(label: '愛おしい', icon: Icons.favorite, color: Colors.pinkAccent),
  MoodTag(label: 'つながり', icon: Icons.people, color: Colors.teal),
  MoodTag(label: '没頭', icon: Icons.psychology, color: Colors.indigoAccent),
  MoodTag(label: 'やる気', icon: Icons.auto_awesome, color: Colors.lightGreenAccent),
  MoodTag(label: 'パンク気味', icon: Icons.battery_alert, color: Colors.redAccent),
  MoodTag(label: 'ドキドキ（緊張）', icon: Icons.heart_broken, color: Colors.purpleAccent),
  MoodTag(label: 'あせり', icon: Icons.speed, color: Colors.deepOrangeAccent),
  MoodTag(label: '申し訳ない', icon: Icons.sentiment_dissatisfied, color: Color(0xFFBCAAA4)), // brown.shade300
  MoodTag(label: '情けない', icon: Icons.sentiment_very_dissatisfied, color: Color(0xFFB0BEC5)), // blueGrey.shade300
  MoodTag(label: 'ショック', icon: Icons.flash_on, color: Colors.deepPurpleAccent),
  MoodTag(label: 'のびのび', icon: Icons.self_improvement, color: Colors.cyan),
  MoodTag(label: 'ラッキー', icon: Icons.thumb_up, color: Colors.greenAccent),
  MoodTag(label: 'スッキリ', icon: Icons.cleaning_services, color: Colors.lightBlue),
  MoodTag(label: 'がんばり時', icon: Icons.fitness_center, color: Colors.amberAccent),
];

// Tier 2版のムードタグ (追加20個、合計50個)
const List<MoodTag> tier2MoodTagList = [
  ...tier1MoodTagList,
  MoodTag(label: '最高！', icon: Icons.emoji_emotions, color: Color(0xFFF9A825)), // yellow.shade800
  MoodTag(label: '満たされる', icon: Icons.ac_unit, color: Color(0xFF64B5F6)), // blue.shade300
  MoodTag(label: 'しみじみ感動', icon: Icons.auto_awesome, color: Color(0xFFFF8A65)), // deepOrange.shade300
  MoodTag(label: 'さっぱり', icon: Icons.water_drop, color: Color(0xFF81D4FA)), // lightBlue.shade300
  MoodTag(label: 'なつかしい', icon: Icons.history, color: Color(0xFFBCAAA4)), // brown.shade300
  MoodTag(label: '静かな一人', icon: Icons.self_improvement, color: Color(0xFF7986CB)), // indigo.shade300
  MoodTag(label: 'ふざけたい', icon: Icons.tag_faces, color: Color(0xFFDCE775)), // lime.shade300
  MoodTag(label: '演じている', icon: Icons.theater_comedy, color: Color(0xFF757575)), // grey.shade600
  MoodTag(label: '切ない', icon: Icons.heart_broken, color: Color(0xFFF06292)), // pink.shade300, and fixed icon
  MoodTag(label: 'どんより', icon: Icons.cloud_off, color: Color(0xFF78909C)), // blueGrey.shade600
  MoodTag(label: 'からっぽ', icon: Icons.circle_outlined, color: Color(0xFFBDBDBD)), // grey.shade400
  MoodTag(label: 'ポツンと', icon: Icons.person_off, color: Color(0xFF90CAF9)), // blue.shade200
  MoodTag(label: 'まっすぐ（誠実）', icon: Icons.straighten, color: Color(0xFF66BB6A)), // green.shade600
  MoodTag(label: '光が見える', icon: Icons.light_mode, color: Color(0xFFFFCA28)), // amber.shade600
  MoodTag(label: 'ゆれる（葛藤）', icon: Icons.alt_route, color: Color(0xFFBA68C8)), // purple.shade300
  MoodTag(label: 'もう無理', icon: Icons.error_outline, color: Color(0xFFE53935)), // red.shade600
  MoodTag(label: 'びくびく', icon: Icons.sentiment_dissatisfied, color: Color(0xFFFFCCBC)), // deepOrange.shade100
  MoodTag(label: '冷めている', icon: Icons.sentiment_neutral, color: Color(0xFFCFD8DC)), // blueGrey.shade200
  MoodTag(label: 'わかる（共感）', icon: Icons.diversity_3, color: Color(0xFF80CBC4)), // teal.shade200
  MoodTag(label: 'つい（衝動）', icon: Icons.rocket_launch, color: Color(0xFFF8BBD0)), // pink.shade100
];
