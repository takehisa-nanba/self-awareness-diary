// lib/services/developer_service.dart

import 'dart:math';
import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import 'package:uuid/uuid.dart';
import '../domain/models/diary_record.dart';
import '../domain/repositories/diary_repository.dart';

/// 開発者向けの機能を提供するサービス。
///
/// 主にテストデータ（日記レコード）の生成機能を提供します。
class DeveloperService with ChangeNotifier {
  final DiaryRepository _diaryRepository;

  /// [DeveloperService] のコンストラクタ。依存する [DiaryRepository] を受け取ります。
  DeveloperService(this._diaryRepository);

  /// テストデータ生成中かどうかを示すフラグ。
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 現在までに生成されたテストレコードの数。
  int _currentTestRecordCount = 0;
  int get currentTestRecordCount => _currentTestRecordCount;

  /// 生成予定のテストレコードの総数。
  int _totalTestRecordCount = 0;
  int get totalTestRecordCount => _totalTestRecordCount;

  /// 擬似的な日記レコードを生成し、データベースに保存します。
  ///
  /// ランダムな日付、気分タグ、気分スコア、出来事、自己分析、場所、天気を持ち、
  /// 進捗状況をUIに通知します。
  Future<void> generateTestRecords() async {
    _isLoading = true;
    _currentTestRecordCount = 0;
    _totalTestRecordCount = 0;
    notifyListeners(); // UIにローディング開始を通知

    try {
      final random = Random();
      final now = DateTime.now();
      const tags = ['仕事', '人間関係', '自己成長', '健康', '趣味', '家族'];
      const int totalDays = 50; // テストデータを生成する日数
      const int recordsPerDay = 10; // 1日あたりのレコード数
      _totalTestRecordCount = totalDays * recordsPerDay;

      for (int i = 0; i < _totalTestRecordCount; i++) {
        final dayOffset = random.nextInt(totalDays); // 過去50日間のランダムなオフセット
        final date = now.subtract(
          Duration(
            days: dayOffset,
            hours: random.nextInt(24), // ランダムな時間
            minutes: random.nextInt(60), // ランダムな分
          ),
        );
        final moodScore = random.nextInt(10) + 1; // 1から10のランダムな気分スコア
        final selfAnalysis = random.nextDouble() > 0.7 // 30%の確率で自己分析を追加
            ? 'これはテスト用の自己分析です。No.${i + 1}'
            : '';

        final record = DiaryRecord(
          recordId: const Uuid().v4(), // 一意なID
          recordDate: date,
          moodTags: (List<String>.from(
            tags,
          )..shuffle()).take(random.nextInt(3) + 1).toList(), // 1から3個のランダムなタグ
          moodScore: moodScore,
          eventText: 'テストイベント ${i + 1}',
          selfAnalysis: selfAnalysis,
          location: 'テスト地点',
          weather: '晴れ',
        );

        await _diaryRepository.saveRecord(record);
        _currentTestRecordCount = i + 1;
        notifyListeners(); // UIに進捗を通知
      }
    } catch (e) {
      debugPrint("DeveloperService: エラー発生 - $e");
    } finally {
      _isLoading = false;
      _currentTestRecordCount = 0;
      _totalTestRecordCount = 0;
      notifyListeners(); // UIにローディング終了を通知
    }
  }
}
