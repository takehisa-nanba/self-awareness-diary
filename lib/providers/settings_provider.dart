// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import '../services/isar_service.dart';
import '../../domain/repositories/diary_repository.dart';
import 'package:table_calendar/table_calendar.dart'; // isSameDayのため
import '../../domain/models/subscription_tier.dart'; // SubscriptionTierをインポート

/// アプリの設定（サブスクリプションティア、初回起動フラグ、AI利用回数など）を管理するプロバイダークラス。
///
/// 設定値は `IsarService` を介して永続化されます。
class SettingsProvider extends ChangeNotifier {
  final IsarService _isarService; // 設定の永続化に使用するIsarService

  // チュートリアルの開始ステップ設定
  bool _startFromStep2 = false;
  bool get startFromStep2 => _startFromStep2;

  // 現在のユーザーのサブスクリプションティア
  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  // 初回起動かどうかを示すフラグ
  bool isFirstLaunch = true;
  // 性格診断が完了しているかどうかを示すフラグ (外部から更新される)
  bool _isDiagnosisComplete = false;
  bool get isDiagnosisComplete => _isDiagnosisComplete;
  // 設定読み込み中かどうかのフラグ
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // 日記作成時にAIの選択ボタンを表示するかどうか
  bool _showAiOptionsDuringWrite = false;
  bool get showAiOptionsDuringWrite => _showAiOptionsDuringWrite;

  // --- AI分析利用回数管理 ---
  // 無料ユーザー向けの週次利用回数
  int weeklyAnalysisCount = 0;
  // 無料ユーザー向けの月次利用回数
  int monthlyAnalysisCount = 0;
  // 週次利用回数のリセット日
  DateTime? lastWeeklyReset;
  // 月次利用回数のリセット日
  DateTime? lastMonthlyReset;
  // Tier 1ユーザーの最終AI分析実行日（日次リセット用）
  DateTime? lastDailyAnalysis;

  // コンストラクタ。IsarServiceとDiaryRepository（現在は未使用）を受け取る。
  SettingsProvider(this._isarService, DiaryRepository diaryRepository) {
    _loadSettings(); // アプリ起動時に設定を読み込む
  }

  /// 設定値をIsarから非同期で読み込み、プロバイダーの状態を初期化します。
  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners(); // ローディング開始をUIに通知

    // isFirstLaunchフラグの読み込み
    final firstLaunchFlag = await _isarService.getSetting('isFirstLaunch');
    isFirstLaunch = firstLaunchFlag != 'false'; // 'false'以外はtrueとする

    // 開始ステップ設定の読み込み
    final savedStepSetting = await _isarService.getSetting('startFromStep2');
    _startFromStep2 = savedStepSetting == 'true'; // 'true'の場合のみtrueとする

    // showAiOptionsDuringWriteフラグの読み込み
    final savedAiOptionsSetting = await _isarService.getSetting(
      'showAiOptionsDuringWrite',
    );
    _showAiOptionsDuringWrite =
        savedAiOptionsSetting == 'true'; // 'true'の場合のみtrueとする

    // サブスクリプションティアの読み込み
    final savedTier = await _isarService.getSetting('subscriptionTier');
    _currentTier = (savedTier != null)
        ? SubscriptionTier.values[int.tryParse(savedTier) ??
              0] // 保存されたインデックスからティアを復元、無効ならfree（0）
        : SubscriptionTier.free; // 保存されたティアがない場合はデフォルトでfree

    // AI分析関連の利用回数とリセット日を読み込み、必要に応じてリセット処理を行う
    await _loadAndCheckUsageCounts();

    _isLoading = false; // ローディング完了
    notifyListeners(); // 設定読み込み完了をUIに通知
  }

  /// AI分析利用回数とリセット日を読み込み、期間に応じたリセット処理を実行します。
  Future<void> _loadAndCheckUsageCounts() async {
    final now = DateTime.now(); // 現在日時

    // --- 日次リセット処理（Tier 1用）---
    // 最終分析実行日の設定を読み込む
    final lastDailyStr = await _isarService.getSetting('lastDailyAnalysis');
    lastDailyAnalysis = lastDailyStr != null
        ? DateTime.tryParse(lastDailyStr) // Iso8601文字列からDateTimeにパース
        : null; // パースできない場合はnull

    // --- 週次リセット処理（Freeティア用）---
    // 週次利用回数と最終週次リセット日を読み込む
    final weeklyCountStr = await _isarService.getSetting('weeklyAnalysisCount');
    final lastWeeklyResetStr = await _isarService.getSetting('lastWeeklyReset');
    weeklyAnalysisCount =
        int.tryParse(weeklyCountStr ?? '0') ?? 0; // 文字列から数値へパース、失敗時は0
    lastWeeklyReset = lastWeeklyResetStr != null
        ? DateTime.tryParse(lastWeeklyResetStr) // Iso8601文字列からDateTimeにパース
        : null; // パースできない場合はnull

    // 最終週次リセット日がない、または7日以上経過している場合、週次カウントをリセット
    if (lastWeeklyReset == null ||
        now.difference(lastWeeklyReset!).inDays >= 7) {
      weeklyAnalysisCount = 0; // 週次カウントを0にリセット
      lastWeeklyReset = now; // 最終リセット日を現在日時に更新
      // リセット後の設定値をIsarに保存
      await _isarService.saveSetting('weeklyAnalysisCount', '0');
      await _isarService.saveSetting('lastWeeklyReset', now.toIso8601String());
    }

    // --- 月次リセット処理（Freeティア用）---
    // 月次利用回数と最終月次リセット日を読み込む
    final monthlyCountStr = await _isarService.getSetting(
      'monthlyAnalysisCount',
    );
    final lastMonthlyResetStr = await _isarService.getSetting(
      'lastMonthlyReset',
    );
    monthlyAnalysisCount =
        int.tryParse(monthlyCountStr ?? '0') ?? 0; // 文字列から数値へパース、失敗時は0
    lastMonthlyReset = lastMonthlyResetStr != null
        ? DateTime.tryParse(lastMonthlyResetStr) // Iso8601文字列からDateTimeにパース
        : null; // パースできない場合はnull

    // 最終月次リセット日がない、または月/年が異なる場合、月次カウントをリセット
    if (lastMonthlyReset == null ||
        now.month != lastMonthlyReset!.month ||
        now.year != lastMonthlyReset!.year) {
      monthlyAnalysisCount = 0; // 月次カウントを0にリセット
      lastMonthlyReset = now; // 最終リセット日を現在日時に更新
      // リセット後の設定値をIsarに保存
      await _isarService.saveSetting('monthlyAnalysisCount', '0');
      await _isarService.saveSetting('lastMonthlyReset', now.toIso8601String());
    }
  }

  /// 現在のティアにおいて、手動でのAI分析が実行可能かどうかを判定します。
  ///
  /// 各ティアごとに異なる条件（利用回数、リセット日など）に基づいて判定します。
  bool canPerformManualAnalysis() {
    switch (_currentTier) {
      case SubscriptionTier.tier2: // Tier 2: 無制限
        return true; // 常に許可
      case SubscriptionTier.tier1: // Tier 1: 日次制限
        // 最終分析実行日がない、または今日より前であれば許可
        return lastDailyAnalysis == null ||
            !isSameDay(lastDailyAnalysis, DateTime.now());
      case SubscriptionTier.free: // Free: 週次/月次制限
        // 週次カウントが0、または月次カウントが0であれば許可
        // (週次と月次でそれぞれ1回ずつ、合計2回まで分析可能というロジック)
        return weeklyAnalysisCount < 1 || monthlyAnalysisCount < 1;
    }
  }

  /// 手動AI分析が実行された際に、利用回数や最終実行日を記録・更新します。
  ///
  /// 実行されたティアに応じて、対応するカウンターまたは日付を更新し、Isarに保存します。
  Future<void> recordManualAnalysis() async {
    final now = DateTime.now(); // 現在日時

    switch (_currentTier) {
      case SubscriptionTier.tier2:
        // Tier 2は無制限のため、何も記録しない
        break;
      case SubscriptionTier.tier1:
        // Tier 1: 日次利用日を今日に更新
        lastDailyAnalysis = now;
        await _isarService.saveSetting(
          'lastDailyAnalysis',
          lastDailyAnalysis!.toIso8601String(), // DateTimeを文字列として保存
        );
        break;
      case SubscriptionTier.free:
        // Freeティア: 週次または月次の利用回数を消費
        // まず週次カウントを消費しようと試みる
        if (weeklyAnalysisCount < 1) {
          weeklyAnalysisCount++; // 週次カウントをインクリメント
          await _isarService.saveSetting(
            'weeklyAnalysisCount',
            weeklyAnalysisCount.toString(), // Countを文字列として保存
          );
        }
        // 週次カウントが既に1で、月次カウントが0なら月次カウントを消費
        else if (monthlyAnalysisCount < 1) {
          monthlyAnalysisCount++; // 月次カウントをインクリメント
          await _isarService.saveSetting(
            'monthlyAnalysisCount',
            monthlyAnalysisCount.toString(), // Countを文字列として保存
          );
        }
        // (補足: このロジックでは、週次で1回、月次で1回、合計2回まで利用可能となる)
        break;
    }
    notifyListeners(); // 利用回数変更をUIに通知
  }

  /// 初回起動フラグを完了済みに設定します。
  Future<void> completeFirstLaunch() async {
    isFirstLaunch = false;
    await _isarService.saveSetting('isFirstLaunch', 'false');
    notifyListeners();
  }

  /// 初回起動フラグをリセットします（デバッグやテスト用）。
  Future<void> resetFirstLaunchFlag() async {
    isFirstLaunch = true;
    await _isarService.saveSetting('isFirstLaunch', 'true');
    notifyListeners();
  }

  /// 性格診断のステータスをリセットし、未完了状態に戻します。
  /// （このメソッドは、診断完了ステータスが外部で管理されるようになったため、使用されなくなりました。）

  /// チュートリアルの開始ステップを設定します。
  Future<void> setStartFromStep2(bool value) async {
    _startFromStep2 = value;
    await _isarService.saveSetting('startFromStep2', value.toString());
    notifyListeners();
  }

  /// 日記作成時にAIの選択ボタンを表示するかどうかを設定します。
  Future<void> setShowAiOptionsDuringWrite(bool value) async {
    _showAiOptionsDuringWrite = value;
    await _isarService.saveSetting(
      'showAiOptionsDuringWrite',
      value.toString(),
    );
    notifyListeners();
  }

  /// サブスクリプションティアを変更し、永続化します。
  ///
  /// ティア変更時に、AI利用回数もリロード・リセットして最新の状態にします。
  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    _currentTier = tier;
    await _isarService.saveSetting(
      'subscriptionTier',
      tier.index.toString(),
    ); // enumのindexを保存
    // ティア変更時に利用回数をリロード＆リセットして、新しいティアの制限に合わせる
    await _loadAndCheckUsageCounts();
    notifyListeners();
  }

  /// 外部から性格診断の完了ステータスを更新するメソッド。
  void updateDiagnosisStatus(bool isComplete) {
    if (_isDiagnosisComplete != isComplete) {
      _isDiagnosisComplete = isComplete;
      notifyListeners();
    }
  }
}
