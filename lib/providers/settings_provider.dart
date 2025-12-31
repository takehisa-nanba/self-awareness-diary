// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import '../services/isar_service.dart';
import '../../domain/repositories/diary_repository.dart';
import 'package:table_calendar/table_calendar.dart'; // isSameDayのため

enum SubscriptionTier { free, tier1, tier2 }

class SettingsProvider extends ChangeNotifier {
  final IsarService _isarService;

  bool _startFromStep2 = false;
  bool get startFromStep2 => _startFromStep2;

  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  bool isFirstLaunch = true;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // --- AI分析利用回数 ---
  int weeklyAnalysisCount = 0;
  int monthlyAnalysisCount = 0;
  DateTime? lastWeeklyReset;
  DateTime? lastMonthlyReset;
  DateTime? lastDailyAnalysis;

  SettingsProvider(this._isarService, DiaryRepository diaryRepository) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    // isFirstLaunchフラグの読み込み
    final firstLaunchFlag = await _isarService.getSetting('isFirstLaunch');
    isFirstLaunch = firstLaunchFlag != 'false';

    final savedStepSetting = await _isarService.getSetting('startFromStep2');
    _startFromStep2 = savedStepSetting == 'true';

    final savedTier = await _isarService.getSetting('subscriptionTier');
    _currentTier = (savedTier != null)
        ? SubscriptionTier.values[int.tryParse(savedTier) ?? 0]
        : SubscriptionTier.free;

    // AI分析関連の読み込みとリセット判定
    await _loadAndCheckUsageCounts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAndCheckUsageCounts() async {
    final now = DateTime.now();

    // 日次リセット（Tier 1）
    final lastDailyStr = await _isarService.getSetting('lastDailyAnalysis');
    lastDailyAnalysis = lastDailyStr != null
        ? DateTime.tryParse(lastDailyStr)
        : null;

    // 週次リセット（Free）
    final weeklyCountStr = await _isarService.getSetting('weeklyAnalysisCount');
    final lastWeeklyResetStr = await _isarService.getSetting('lastWeeklyReset');
    weeklyAnalysisCount = int.tryParse(weeklyCountStr ?? '0') ?? 0;
    lastWeeklyReset = lastWeeklyResetStr != null
        ? DateTime.tryParse(lastWeeklyResetStr)
        : null;

    if (lastWeeklyReset == null ||
        now.difference(lastWeeklyReset!).inDays >= 7) {
      weeklyAnalysisCount = 0;
      lastWeeklyReset = now;
      await _isarService.saveSetting('weeklyAnalysisCount', '0');
      await _isarService.saveSetting('lastWeeklyReset', now.toIso8601String());
    }

    // 月次リセット（Free）
    final monthlyCountStr = await _isarService.getSetting(
      'monthlyAnalysisCount',
    );
    final lastMonthlyResetStr = await _isarService.getSetting(
      'lastMonthlyReset',
    );
    monthlyAnalysisCount = int.tryParse(monthlyCountStr ?? '0') ?? 0;
    lastMonthlyReset = lastMonthlyResetStr != null
        ? DateTime.tryParse(lastMonthlyResetStr)
        : null;

    if (lastMonthlyReset == null ||
        now.month != lastMonthlyReset!.month ||
        now.year != lastMonthlyReset!.year) {
      monthlyAnalysisCount = 0;
      lastMonthlyReset = now;
      await _isarService.saveSetting('monthlyAnalysisCount', '0');
      await _isarService.saveSetting('lastMonthlyReset', now.toIso8601String());
    }
  }

  /// 手動でのAI分析が実行可能か判定する
  bool canPerformManualAnalysis() {
    switch (_currentTier) {
      case SubscriptionTier.tier2:
        return true; // 常に許可
      case SubscriptionTier.tier1:
        // 最終利用日がないか、今日より前なら許可
        return lastDailyAnalysis == null ||
            !isSameDay(lastDailyAnalysis, DateTime.now());
      case SubscriptionTier.free:
        // 週次または月次の利用回数が残っていれば許可
        return weeklyAnalysisCount < 1 || monthlyAnalysisCount < 1;
    }
  }

  /// 手動AI分析の実行を記録する
  Future<void> recordManualAnalysis() async {
    switch (_currentTier) {
      case SubscriptionTier.tier2:
        // 何もしない
        break;
      case SubscriptionTier.tier1:
        lastDailyAnalysis = DateTime.now();
        await _isarService.saveSetting(
          'lastDailyAnalysis',
          lastDailyAnalysis!.toIso8601String(),
        );
        break;
      case SubscriptionTier.free:
        if (weeklyAnalysisCount < 1) {
          weeklyAnalysisCount++;
          await _isarService.saveSetting(
            'weeklyAnalysisCount',
            weeklyAnalysisCount.toString(),
          );
        } else if (monthlyAnalysisCount < 1) {
          monthlyAnalysisCount++;
          await _isarService.saveSetting(
            'monthlyAnalysisCount',
            monthlyAnalysisCount.toString(),
          );
        }
        break;
    }
    notifyListeners();
  }

  Future<void> completeFirstLaunch() async {
    isFirstLaunch = false;
    await _isarService.saveSetting('isFirstLaunch', 'false');
    notifyListeners();
  }

  Future<void> resetFirstLaunchFlag() async {
    isFirstLaunch = true;
    await _isarService.saveSetting('isFirstLaunch', 'true');
    notifyListeners();
  }

  Future<void> setStartFromStep2(bool value) async {
    _startFromStep2 = value;
    await _isarService.saveSetting('startFromStep2', value.toString());
    notifyListeners();
  }

  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    _currentTier = tier;
    await _isarService.saveSetting('subscriptionTier', tier.index.toString());
    // ティア変更時に利用回数をリロード＆リセット
    await _loadAndCheckUsageCounts();
    notifyListeners();
  }
}
