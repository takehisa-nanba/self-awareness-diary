import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/diary_record.dart';
import '../domain/repositories/diary_repository.dart';

class DeveloperService with ChangeNotifier {
  final DiaryRepository _diaryRepository;

  DeveloperService(this._diaryRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentTestRecordCount = 0;
  int get currentTestRecordCount => _currentTestRecordCount;

  int _totalTestRecordCount = 0;
  int get totalTestRecordCount => _totalTestRecordCount;

  Future<void> generateTestRecords() async {
    _isLoading = true;
    _currentTestRecordCount = 0;
    _totalTestRecordCount = 0;
    notifyListeners();

    try {
      final random = Random();
      final now = DateTime.now();
      const tags = ['仕事', '人間関係', '自己成長', '健康', '趣味', '家族'];
      const int totalDays = 50;
      const int recordsPerDay = 10;
      _totalTestRecordCount = totalDays * recordsPerDay;

      for (int i = 0; i < _totalTestRecordCount; i++) {
        final dayOffset = random.nextInt(totalDays);
        final date = now.subtract(
          Duration(
            days: dayOffset,
            hours: random.nextInt(24),
            minutes: random.nextInt(60),
          ),
        );
        final moodScore = random.nextInt(10) + 1;
        final selfAnalysis = random.nextDouble() > 0.7
            ? 'これはテスト用の自己分析です。No.${i + 1}'
            : '';

        final record = DiaryRecord(
          recordId: const Uuid().v4(),
          recordDate: date,
          moodTags: (List<String>.from(
            tags,
          )..shuffle()).take(random.nextInt(3) + 1).toList(),
          moodScore: moodScore,
          eventText: 'テストイベント ${i + 1}',
          selfAnalysis: selfAnalysis,
          location: 'テスト地点',
          weather: '晴れ',
        );

        await _diaryRepository.saveRecord(record);
        _currentTestRecordCount = i + 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("DeveloperService: エラー発生 - $e");
    } finally {
      _isLoading = false;
      _currentTestRecordCount = 0;
      _totalTestRecordCount = 0;
      notifyListeners();
    }
  }
}
