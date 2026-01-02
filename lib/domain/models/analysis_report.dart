import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'diary_record.dart';
import 'universe_coordinate.dart';
import 'user_profile.dart';

/// 日記レコードのリストを元に、様々な角度から分析した結果を保持するモデル。
/// 計算ロジックをProviderから分離し、ここに集約する。
class AnalysisReport {
  final List<DiaryRecord> _records;
  final DateTimeRange dateRange;
  final UserProfile userProfile; // UserProfileを追加

  // public getterを追加
  List<DiaryRecord> get records => _records;

  AnalysisReport({
    required List<DiaryRecord> records,
    required this.dateRange,
    required this.userProfile, // コンストラクタにUserProfileを追加
  }) : _records = records;

  /// 各日記レコードの宇宙座標
  late final Map<DiaryRecord, UniverseCoordinate> recordCoordinates =
      _calculateRecordCoordinates();

  /// レコードごとの宇宙座標を計算するプライベートメソッド
  Map<DiaryRecord, UniverseCoordinate> _calculateRecordCoordinates() {
    final Map<DiaryRecord, UniverseCoordinate> coordinates = {};
    for (final record in _records) {
      coordinates[record] = AnalysisReportUniverse(this)
          .calculateUniversePosition(
            userProfile,
            record.polishingLevel.toDouble(),
          );
    }
    return coordinates;
  }

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

  // --- 新しい分析データのgetter ---
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

  // --- privateな計算メソッド ---

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
    debugPrint('[AnalysisReport] ${_records.length} 件のレコードからムードの分布を計算します。');
    final Map<String, int> distribution = {};
    for (final record in _records) {
      for (final tag in record.moodTags) {
        distribution[tag] = (distribution[tag] ?? 0) + 1;
      }
    }
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final finalDistribution = Map.fromEntries(sortedEntries);
    debugPrint('[AnalysisReport] 計算結果: $finalDistribution');
    return finalDistribution;
  }

  double _calculateAverageMoodScore() {
    if (_records.isEmpty) return 0.0;
    final total = _records
        .map((r) => r.moodScore)
        .reduce((sum, score) => sum + score);
    return total / _records.length;
  }

  /// 期間内の日記の研磨度アイコンごとの出現回数を計算します。
  Map<String, int> _calculatePolishingDistribution() {
    final Map<String, int> distribution = {};
    for (final record in _records) {
      final icon = record.polishingIcon;
      distribution[icon] = (distribution[icon] ?? 0) + 1;
    }
    return distribution;
  }

  /// 天気ごとの平均ムードスコアを計算します。
  Map<String, double> _calculateWeatherCorrelation() {
    final Map<String, List<int>> scoresByWeather = {};
    for (final record in _records) {
      if (record.weather != null) {
        // 天気情報から温度と気圧の部分を除外
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

  /// 同時に記録された気分タグのペアの出現頻度を計算し、ランキング形式で返します。
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
    // 出現回数でソート
    final sortedEntries = pairCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  /// 気圧または気温の時系列データを抽出します。
  Map<DateTime, double> _extractWeatherData(String type) {
    final Map<DateTime, double> data = {};
    for (final record in _records) {
      if (record.weather != null) {
        RegExp regExp;
        if (type == 'pressure') {
          // 例: "曇り (15.5°C / 1012hPa)" -> 1012
          regExp = RegExp(r'(\d+)hPa');
        } else {
          // 例: "曇り (15.5°C / 1012hPa)" -> 15.5
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

  /// 研磨度の時系列データを計算します。
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

/// [AnalysisReport] の宇宙座標計算に関する拡張
extension AnalysisReportUniverse on AnalysisReport {
  /// ユーザープロファイルと研磨度から宇宙座標を計算します。
  ///
  /// [profile] ユーザーのエゴグラムスコアを含むプロファイル。
  /// [polishingLevel] 日記の研磨度 (0-100)。
  ///
  /// 5つの指標（CP, NP, A, FC, AC）を円周上に配置し、スコアを重みとした
  /// 重心計算により、現在の心の位置をX,Y座標として算出します。
  /// Z座標は研磨度から算出され、自己分析の深さを示します。
  UniverseCoordinate calculateUniversePosition(
    UserProfile profile,
    double polishingLevel,
  ) {
    // 角度をラジアンに変換するヘルパー
    double degToRad(double deg) => deg * (pi / 180.0);

    // 各指標のスコアと角度(ラジアン)をマップで定義
    final Map<String, double> angles = {
      'cp': degToRad(90), // 規律 (真上)
      'np': degToRad(18), // 慈愛
      'a': degToRad(306), // 論理
      'fc': degToRad(234), // 自由
      'ac': degToRad(162), // 順応
    };

    final Map<String, int> scores = {
      'cp': profile.cp ?? 0,
      'np': profile.np ?? 0,
      'a': profile.a ?? 0,
      'fc': profile.fc ?? 0,
      'ac': profile.ac ?? 0,
    };

    double totalScore = scores.values.reduce((a, b) => a + b).toDouble();
    double weightedX = 0;
    double weightedY = 0;

    scores.forEach((key, score) {
      weightedX += score * cos(angles[key]!);
      weightedY += score * sin(angles[key]!);
    });

    // 合計スコアが0の場合は中心 (0,0) とする
    double finalX = totalScore == 0 ? 0 : weightedX / totalScore;
    double finalY = totalScore == 0 ? 0 : weightedY / totalScore;

    // Z座標を正規化 (0.0 - 1.0)
    double finalZ = polishingLevel.clamp(0, 100) / 100.0;

    return UniverseCoordinate(x: finalX, y: finalY, z: finalZ);
  }
}
