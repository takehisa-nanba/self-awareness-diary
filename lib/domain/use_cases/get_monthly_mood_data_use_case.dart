import '../repositories/diary_repository.dart';

class GetMonthlyMoodDataUseCase {
  final DiaryRepository _diaryRepository;

  GetMonthlyMoodDataUseCase(this._diaryRepository);

  Future<Map<int, double>> execute(int year, int month) async {
    final allRecords = await _diaryRepository.getAllRecords();

    // 選択された年月のレコードをフィルタリング
    final monthlyRecords = allRecords.where((record) {
      return record.recordDate.year == year && record.recordDate.month == month;
    }).toList();

    if (monthlyRecords.isEmpty) {
      return {};
    }

    // 日ごとのムードスコアを合計し、レコード数をカウント
    final Map<int, List<int>> dailyMoods = {};
    for (var record in monthlyRecords) {
      final day = record.recordDate.day;
      if (!dailyMoods.containsKey(day)) {
        dailyMoods[day] = [];
      }
      dailyMoods[day]!.add(record.moodScore);
    }

    // 日ごとの平均ムードスコアを計算
    final Map<int, double> dailyAverageMoods = {};
    dailyMoods.forEach((day, moods) {
      final average = moods.reduce((a, b) => a + b) / moods.length;
      dailyAverageMoods[day] = average;
    });

    return dailyAverageMoods;
  }
}
