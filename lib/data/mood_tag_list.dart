// lib/data/mood_tag_list.dart

import 'package:flutter/material.dart';
import '../models/mood_tag.dart';

const List<MoodTag> moodTagList = [
  MoodTag(label: '幸せ', icon: Icons.sentiment_very_satisfied, color: Colors.orange),
  MoodTag(label: '穏やか', icon: Icons.sentiment_satisfied, color: Colors.green),
  MoodTag(label: 'ワクワク', icon: Icons.star, color: Colors.yellow),
  MoodTag(label: '疲れ', icon: Icons.sentiment_dissatisfied, color: Colors.blueGrey),
  MoodTag(label: 'イライラ', icon: Icons.mood_bad, color: Colors.red),
  MoodTag(label: '不安', icon: Icons.shutter_speed, color: Colors.purple),
  MoodTag(label: '悲しい', icon: Icons.sentiment_very_dissatisfied, color: Colors.blue),
  MoodTag(label: '集中', icon: Icons.psychology, color: Colors.indigo),
];