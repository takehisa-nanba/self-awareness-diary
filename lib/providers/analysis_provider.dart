import 'package:flutter/material.dart';
import '../../domain/use_cases/get_monthly_mood_data_use_case.dart';

class AnalysisProvider with ChangeNotifier {
  final GetMonthlyMoodDataUseCase _getMonthlyMoodDataUseCase;

  AnalysisProvider(this._getMonthlyMoodDataUseCase);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  Map<int, double> _monthlyMoodData = {}; // 日付(int) -> 平均ムードスコア
  Map<int, double> get monthlyMoodData => _monthlyMoodData;

  double _averageMoodScore = 0.0;
  double get averageMoodScore => _averageMoodScore;

  Future<void> loadMonthlyMoodData() async {
    _isLoading = true;
    notifyListeners();

    _monthlyMoodData = await _getMonthlyMoodDataUseCase.execute(_selectedYear, _selectedMonth);
    _calculateAverageMoodScore();

    _isLoading = false;
    notifyListeners();
  }

  void _calculateAverageMoodScore() {
    if (_monthlyMoodData.isEmpty) {
      _averageMoodScore = 0.0;
      return;
    }
    final total = _monthlyMoodData.values.reduce((sum, score) => sum + score);
    _averageMoodScore = total / _monthlyMoodData.length;
  }

  void selectMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    loadMonthlyMoodData();
  }

  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    loadMonthlyMoodData();
  }

  void nextMonth() {
    // 現在の月より先に進めない
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return;
    }

    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    loadMonthlyMoodData();
  }
}
