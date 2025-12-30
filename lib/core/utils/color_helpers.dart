// lib/core/utils/color_helpers.dart

import 'package:flutter/material.dart';

/// 気分スコアに基づいて色を返します。
///
/// スコアの範囲に応じて異なる色の濃淡を返します。
/// - 3以下の場合は赤系の色
/// - 6以下の場合は緑系の色
/// - それ以上の場合は青系の色
/// [score] 気分スコア。
Color getMoodColor(int score) {
  if (score <= 3) return Colors.red.shade300;
  if (score <= 6) return Colors.green.shade300;
  return Colors.blue.shade300;
}

/// AIの安定性スコアに基づいて色を返します。
///
/// スコアの範囲に応じて異なる色を返します。
/// - 80以上の場合は緑
/// - 40以上の場合は青
/// - それ以下の場合はオレンジ
/// [score] AIの安定性スコア (null の可能性あり)。
Color getAiScoreColor(int? score) {
  if (score == null) return Colors.grey.shade400; // スコアがない場合はグレー
  if (score >= 80) return Colors.green;
  if (score >= 40) return Colors.blue;
  return Colors.orange;
}
