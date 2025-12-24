// lib/core/utils/color_helpers.dart

import 'package:flutter/material.dart';

/// 気分スコアに基づいて色を返す
/// - 1-3: 赤
/// - 4-6: 緑
/// - 7-10: 青
Color getMoodColor(int score) {
  if (score <= 3) return Colors.red.shade300;
  if (score <= 6) return Colors.green.shade300;
  return Colors.blue.shade300;
}

/// AIの安定性スコアに基づいて色を返す
Color getAiScoreColor(int? score) {
  if (score == null) return Colors.grey.shade400;
  if (score >= 80) return Colors.green;
  if (score >= 40) return Colors.blue;
  return Colors.orange;
}
