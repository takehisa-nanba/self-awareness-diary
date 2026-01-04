import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math.dart';

import 'diary_record.dart';
import 'universe_coordinate.dart';
import 'user_profile.dart';

/// 日記レコードのリストを元に、様々な角度から分析した結果を保持するモデル。
/// 計算ロジックをProviderから分離し、ここに集約する。
class AnalysisReport {
  final List<DiaryRecord> _records;
  final DateTimeRange dateRange;
  final UserProfile userProfile;

  List<DiaryRecord> get records => _records;

  // --- 宇宙図関連の定義 ---

  /// UIと計算ロジックで共有する、指標と角度（度数）のマッピング
  static const Map<String, double> egoStateAnglesDeg = {
    'CP': 270, // 規律 (真上)
    'NP': 198, // 慈愛 (18 + 180 = 198)
    'A': 126, // 論理 (306 + 180 = 486 => 126)
    'FC': 54, // 自由 (234 + 180 = 414 => 54)
    'AC': 342, // 順応 (162 + 180 = 342)
  };

  /// 指標と角度（ラジアン）のマッピング (getter)
  Map<String, double> get indicatorAnglesRad {
    return egoStateAnglesDeg.map((key, value) => MapEntry(key, radians(value)));
  }

  /// ムードタグと、それが引き寄せられる指標のマッピング
  static const Map<String, String> tagToIndicatorMap = {
    // CP (Critical Parent)
    'やるべき': 'CP', '集中': 'CP', '反省': 'CP', '責任感': 'CP',
    // NP (Nurturing Parent)
    'ほっとする': 'NP', '安心した': 'NP', '満たされる': 'NP', '感謝': 'NP', '穏やか': 'NP',
    // A (Adult)
    'いつも通り': 'A', 'すっきり': 'A', '発見': 'A', '学び': 'A', '冷静': 'A',
    // FC (Free Child)
    'わくわく': 'FC', 'うれしい': 'FC', '楽しい': 'FC', '趣味': 'FC', '自由': 'FC', '幸せ': 'FC',
    // AC (Adapted Child)
    'つかれた': 'AC',
    'もやもや': 'AC',
    '不安': 'AC',
    '我慢': 'AC',
    '悲しい': 'AC',
    '違和感': 'AC',
  };

  // --- コンストラクタ ---
  AnalysisReport({
    required List<DiaryRecord> records,
    required this.dateRange,
    required this.userProfile,
  }) : _records = records;

  // --- publicな分析結果 (late final) ---

  /// 各日記レコードの宇宙座標
  late final Map<DiaryRecord, UniverseCoordinate> recordCoordinates =
      _calculateRecordCoordinates();

  /// 分析対象の期間が単日かどうか
  bool get isSingleDay => dateRange.duration.inDays == 0;

  /// 日付(DateTime) -> 平均ムードスコア
  late final Map<DateTime, double> dailyMoodScores =
      _calculateDailyMoodScores();

  /// 時間(int) -> 平均ムードスコア
  late final Map<int, double> hourlyMoodScores = _calculateHourlyMoodScores();

  /// タグ(String) -> 出現回数(int)
  late final Map<String, int> moodTagDistribution =
      _calculateMoodTagDistribution();

  /// 平均ムードスコア
  late final double averageMoodScore = _calculateAverageMoodScore();

  /// 研磨度アイコン(String) -> 出現回数(int)
  late final Map<String, int> polishingDistribution =
      _calculatePolishingDistribution();

  /// 天気(String) -> 平均ムードスコア(double)
  late final Map<String, double> weatherCorrelation =
      _calculateWeatherCorrelation();

  /// タグのペア(`Set<String>`) -> 出現回数(int)
  late final Map<String, int> tagPairs = _calculateTagPairs();

  /// 期間中の最高スコアのレコード
  late final DiaryRecord? highestScoreRecord = _records.isEmpty
      ? null
      : _records.reduce((a, b) => a.moodScore > b.moodScore ? a : b);

  /// 期間中の最低スコアのレコード
  late final DiaryRecord? lowestScoreRecord = _records.isEmpty
      ? null
      : _records.reduce((a, b) => a.moodScore < b.moodScore ? a : b);

  /// 気圧の時系列データ
  late final Map<DateTime, double> pressureData = _extractWeatherData(
    'pressure',
  );

  /// 気温の時系列データ
  late final Map<DateTime, double> temperatureData = _extractWeatherData(
    'temperature',
  );

  /// 研磨度の時系列データ
  late final Map<DateTime, int> polishingLevelData =
      _calculatePolishingLevelData();

  /// 時間ごとの気圧データ
  late final Map<int, double> hourlyPressureScores =
      _calculateHourlyPressureScores();

  /// 時間ごとの気温データ
  late final Map<int, double> hourlyTemperatureScores =
      _calculateHourlyTemperatureScores();

  /// 時間ごとの研磨度データ
  late final Map<int, double> hourlyPolishingLevelData =
      _calculateHourlyPolishingLevelData();

  // --- privateな計算メソッド群 ---

  /// レコードごとの宇宙座標を計算する
  Map<DiaryRecord, UniverseCoordinate> _calculateRecordCoordinates() {
    final Map<DiaryRecord, UniverseCoordinate> coordinates = {};

    // ユーザープロファイルのスコアから基本的な重心を計算
    final Map<String, int> scores = {
      'CP': userProfile.cp ?? 0,
      'NP': userProfile.np ?? 0,
      'A': userProfile.a ?? 0,
      'FC': userProfile.fc ?? 0,
      'AC': userProfile.ac ?? 0,
    };
    final double totalScore = scores.values.fold(0, (a, b) => a + b).toDouble();
    Vector2 basePosition = Vector2.zero();

    if (totalScore > 0) {
      scores.forEach((key, score) {
        final angle = indicatorAnglesRad[key]!;
        basePosition += Vector2(cos(angle), sin(angle)) * score.toDouble();
      });
      basePosition /= totalScore;
    }

    // 各レコードについて、タグに基づいて座標を調整
    for (final record in _records) {
      Vector2 finalPosition = Vector2.copy(basePosition);
      int attractionCount = 0;

      for (final tag in record.moodTags) {
        final indicator = tagToIndicatorMap[tag];
        if (indicator != null) {
          final angle = indicatorAnglesRad[indicator]!;
          final attractionVector = Vector2(cos(angle), sin(angle));
          // 重心から指標へのベクトルを算出し、その方向に座標を寄せる
          final vectorToIndicator = attractionVector - basePosition;
          finalPosition += vectorToIndicator * 0.1; // 引き寄せの強さ (0.1 = 10%)
          attractionCount++;
        }
      }

      // 複数のタグがある場合、平均化を防ぐために少し補正
      if (attractionCount > 1) {
        finalPosition /= (1 + (attractionCount - 1) * 0.05);
      }

      // Z座標は研磨度から算出
      final double finalZ = record.polishingLevel.clamp(0, 100) / 100.0;

      // 最終的な座標を-1.0から1.0の範囲にクランプ
      coordinates[record] = UniverseCoordinate(
        x: finalPosition.x.clamp(-1.0, 1.0),
        y: finalPosition.y.clamp(-1.0, 1.0),
        z: finalZ,
      );
    }

    return coordinates;
  }

  Map<DateTime, double> _calculateDailyMoodScores() {
    final groupedByDay = groupBy(
      _records,
      (record) => DateTime(
        record.recordDate.year,
        record.recordDate.month,
        record.recordDate.day,
      ),
    );
    return groupedByDay.map((date, records) {
      final totalScore = records
          .map((r) => r.moodScore)
          .reduce((a, b) => a + b);
      return MapEntry(date, totalScore / records.length);
    });
  }

  Map<int, double> _calculateHourlyMoodScores() {
    if (!isSingleDay) return {};
    final groupedByHour = groupBy(_records, (record) => record.recordDate.hour);
    return groupedByHour.map((hour, records) {
      final totalScore = records
          .map((r) => r.moodScore)
          .reduce((a, b) => a + b);
      return MapEntry(hour, totalScore / records.length);
    });
  }

  Map<String, int> _calculateMoodTagDistribution() {
    final Map<String, int> distribution = {};
    for (final record in _records) {
      for (final tag in record.moodTags) {
        distribution[tag] = (distribution[tag] ?? 0) + 1;
      }
    }
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final finalDistribution = Map.fromEntries(sortedEntries);
    return finalDistribution;
  }

  double _calculateAverageMoodScore() {
    if (_records.isEmpty) return 0.0;
    final total = _records
        .map((r) => r.moodScore)
        .reduce((sum, score) => sum + score);
    return total / _records.length;
  }

  Map<String, int> _calculatePolishingDistribution() {
    final Map<String, int> distribution = {};
    for (final record in _records) {
      final icon = record.polishingIcon;
      distribution[icon] = (distribution[icon] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, double> _calculateWeatherCorrelation() {
    final Map<String, List<int>> scoresByWeather = {};
    for (final record in _records) {
      if (record.weather != null) {
        final weatherCondition = record.weather!.split('(').first.trim();
        if (scoresByWeather.containsKey(weatherCondition)) {
          scoresByWeather[weatherCondition]!.add(record.moodScore);
        } else {
          scoresByWeather[weatherCondition] = [record.moodScore];
        }
      }
    }

    return scoresByWeather.map((weather, scores) {
      final average = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(weather, average);
    });
  }

  Map<String, int> _calculateTagPairs() {
    final Map<String, int> pairCounts = {};
    for (final record in _records) {
      if (record.moodTags.length >= 2) {
        final tags = List<String>.from(record.moodTags)..sort();
        for (int i = 0; i < tags.length; i++) {
          for (int j = i + 1; j < tags.length; j++) {
            final pairKey = '${tags[i]} & ${tags[j]}';
            pairCounts[pairKey] = (pairCounts[pairKey] ?? 0) + 1;
          }
        }
      }
    }
    final sortedEntries = pairCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  Map<DateTime, double> _extractWeatherData(String type) {
    final Map<DateTime, double> data = {};
    for (final record in _records) {
      if (record.weather != null) {
        RegExp regExp;
        if (type == 'pressure') {
          regExp = RegExp(r'(\d+)hPa');
        } else {
          regExp = RegExp(r'(-?\d+\.\d+)°C');
        }
        final match = regExp.firstMatch(record.weather!);
        if (match != null && match.group(1) != null) {
          data[record.recordDate] = double.tryParse(match.group(1)!) ?? 0.0;
        }
      }
    }
    return data;
  }

  Map<DateTime, int> _calculatePolishingLevelData() {
    final Map<DateTime, int> data = {};
    for (final record in _records) {
      data[record.recordDate] = record.polishingLevel;
    }
    return data;
  }

  Map<int, double> _calculateHourlyPressureScores() {
    if (!isSingleDay) return {};
    final Map<int, List<double>> hourlyValues = {};
    for (final record in _records) {
      if (record.weather != null) {
        final match = RegExp(r'(\d+)hPa').firstMatch(record.weather!);
        if (match != null && match.group(1) != null) {
          final value = double.tryParse(match.group(1)!) ?? 0.0;
          final hour = record.recordDate.hour;
          if (hourlyValues.containsKey(hour)) {
            hourlyValues[hour]!.add(value);
          } else {
            hourlyValues[hour] = [value];
          }
        }
      }
    }
    return hourlyValues.map((hour, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(hour, average);
    });
  }

  Map<int, double> _calculateHourlyTemperatureScores() {
    if (!isSingleDay) return {};
    final Map<int, List<double>> hourlyValues = {};
    for (final record in _records) {
      if (record.weather != null) {
        final match = RegExp(r'(-?\d+\.\d+)°C').firstMatch(record.weather!);
        if (match != null && match.group(1) != null) {
          final value = double.tryParse(match.group(1)!) ?? 0.0;
          final hour = record.recordDate.hour;
          if (hourlyValues.containsKey(hour)) {
            hourlyValues[hour]!.add(value);
          } else {
            hourlyValues[hour] = [value];
          }
        }
      }
    }
    return hourlyValues.map((hour, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(hour, average);
    });
  }

  Map<int, double> _calculateHourlyPolishingLevelData() {
    if (!isSingleDay) return {};
    final Map<int, List<int>> hourlyValues = {};
    for (final record in _records) {
      final hour = record.recordDate.hour;
      if (hourlyValues.containsKey(hour)) {
        hourlyValues[hour]!.add(record.polishingLevel);
      } else {
        hourlyValues[hour] = [record.polishingLevel];
      }
    }
    return hourlyValues.map((hour, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(hour, average);
    });
  }
}
