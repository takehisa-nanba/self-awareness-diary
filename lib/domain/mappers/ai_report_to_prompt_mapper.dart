import 'package:intl/intl.dart';
import '../models/analysis_report.dart';
import '../models/diary_record.dart'; // DiaryRecordも必要なのでインポート

class AiReportToPromptMapper {
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
    final allRecords = report.records;
    if (allRecords.isNotEmpty) {
      // ソートはAnalysisReportの外で行うべきではない（AnalysisReportが持っているべきデータはrecordsのみ）
      // しかし、ここではAIプロンプト生成のために一時的に使用するため許容する。
      // 理想的には、AnalysisReportに最高/最低スコアのレコードを取得するgetterを設けるべき。
      List<DiaryRecord> sortedRecords = List.from(allRecords);
      sortedRecords.sort((a, b) => a.moodScore.compareTo(b.moodScore));
      final lowestScoreRecord = sortedRecords.first;
      final highestScoreRecord = sortedRecords.last;

      summary.writeln('\n期間中の最低スコアの日:');
      summary.writeln(
        '- 日時: ${dateFormat.format(lowestScoreRecord.recordDate)}',
      );
      summary.writeln('- スコア: ${lowestScoreRecord.moodScore}');
      summary.writeln('- タグ: ${lowestScoreRecord.moodTags.join(', ')}');
      summary.writeln('- 出来事: ${lowestScoreRecord.eventText}');

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
