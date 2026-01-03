// lib/domain/mappers/cosmic_map_to_prompt_mapper.dart

import '../models/analysis_report.dart';
import 'package:intl/intl.dart';

/// 宇宙図の分析レポートをAIのプロンプト形式に変換するマッパー。
class CosmicMapToPromptMapper {
  /// [AnalysisReport] を受け取り、AIが宇宙図を解説するためのプロンプト文字列を生成します。
  static String toPrompt(AnalysisReport report) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy年M月d日');

    buffer.writeln('ユーザープロファイル:');
    buffer.writeln('- CP(批判的な親): ${report.userProfile.cp}');
    buffer.writeln('- NP(養育的な親): ${report.userProfile.np}');
    buffer.writeln('- A(大人): ${report.userProfile.a}');
    buffer.writeln('- FC(自由な子供): ${report.userProfile.fc}');
    buffer.writeln('- AC(適応した子供): ${report.userProfile.ac}');
    buffer.writeln(
      '- 現在の研磨度: ${report.userProfile.currentGritLevel?.toStringAsFixed(2)}',
    );
    buffer.writeln();

    buffer.writeln(
      '期間: ${dateFormat.format(report.dateRange.start)} - ${dateFormat.format(report.dateRange.end)}',
    );
    buffer.writeln();

    buffer.writeln('星（日記レコード）のリスト:');
    for (final entry in report.recordCoordinates.entries) {
      final record = entry.key;
      final coord = entry.value;
      buffer.writeln(
        '- 日付: ${dateFormat.format(record.recordDate)}, '
        '座標: (x=${coord.x.toStringAsFixed(2)}, y=${coord.y.toStringAsFixed(2)}, z=${coord.z.toStringAsFixed(2)}), '
        'ムード色(明るさ): ${record.moodScore}, '
        'エネルギー(星のサイズ): ${record.eventText.length}, '
        'タグ: [${record.moodTags.join(', ')}]',
      );
    }

    return buffer.toString();
  }
}
