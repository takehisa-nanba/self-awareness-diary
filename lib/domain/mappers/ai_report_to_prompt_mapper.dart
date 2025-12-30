// lib/domain/mappers/ai_report_to_prompt_mapper.dart

import 'package:intl/intl.dart';
import '../models/analysis_report.dart';
import '../models/diary_record.dart';

/// [AnalysisReport] オブジェクトを Gemini AI のプロンプトとして使用できる形式の
/// 文字列に変換する役割を持つユーティリティクラス。
///
/// AI が日記の傾向やユーザーの感情を理解し、洞察を生成するための
/// 要約されたデータを提供します。
class AiReportToPromptMapper {
  /// [AnalysisReport] オブジェクトを受け取り、その内容を要約したプロンプト文字列を生成します。
  ///
  /// 生成されるプロンプトには、分析期間、平均気分スコア、気分タグの分布、
  /// 時間別/日別の気分スコア、そして最高・最低スコアの日に関する情報が含まれます。
  /// [report] プロンプト生成の基となる [AnalysisReport] オブジェクト。
  /// 戻り値: AI プロンプトとして適した形式の文字列。
  static String toPrompt(AnalysisReport report) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final summary = StringBuffer();

    summary.writeln(
      '分析期間: ${dateFormat.format(report.dateRange.start)} - ${dateFormat.format(report.dateRange.end)}',
    );
    summary.writeln('平均気分スコア: ${report.averageMoodScore.toStringAsFixed(1)}');

    summary.writeln('\n最も多かった気分タグ TOP5:');
    if (report.moodTagDistribution.isEmpty) {
      summary.writeln('- データなし');
    } else {
      report.moodTagDistribution.entries.take(5).forEach((entry) {
        summary.writeln('- ${entry.key}: ${entry.value}回');
      });
    }

    if (report.isSingleDay) {
      summary.writeln('\n時間毎の平均気分スコア（0時-23時）:');
      final hourlyScores = report.hourlyMoodScores.entries
          .map((e) => '${e.key}時:${e.value.toStringAsFixed(1)}')
          .join(', ');
      summary.writeln(hourlyScores.isNotEmpty ? hourlyScores : '- データなし');
    } else {
      summary.writeln('\n日毎の平均気分スコア:');
      final dailyScores = report.dailyMoodScores.entries
          .map(
            (e) => '${dateFormat.format(e.key)}:${e.value.toStringAsFixed(1)}',
          )
          .join(', ');
      summary.writeln(dailyScores.isNotEmpty ? dailyScores : '- データなし');
    }

    // 最高・最低スコアの日の情報を追加
    final lowestScoreRecord = report.lowestScoreRecord;
    final highestScoreRecord = report.highestScoreRecord;

    if (lowestScoreRecord != null) {
      summary.writeln('\n期間中の最低スコアの日:');
      summary.writeln(
        '- 日時: ${dateFormat.format(lowestScoreRecord.recordDate)}',
      );
      summary.writeln('- スコア: ${lowestScoreRecord.moodScore}');
      summary.writeln('- タグ: ${lowestScoreRecord.moodTags.join(', ')}');
      summary.writeln('- 出来事: ${lowestScoreRecord.eventText}');
    }

    if (highestScoreRecord != null) {
      summary.writeln('\n期間中の最高スコアの日:');
      summary.writeln(
        '- 日時: ${dateFormat.format(highestScoreRecord.recordDate)}',
      );
      summary.writeln('- スコア: ${highestScoreRecord.moodScore}');
      summary.writeln('- タグ: ${highestScoreRecord.moodTags.join(', ')}');
      summary.writeln('- 出来事: ${highestScoreRecord.eventText}');
    }

    return summary.toString();
  }
}
