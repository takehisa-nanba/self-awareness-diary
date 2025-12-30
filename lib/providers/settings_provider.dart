// lib/providers/settings_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import '../../domain/repositories/diary_repository.dart'; // Repositoryの参照は残しておくが、直接は使わない
import '../services/isar_service.dart'; // IsarServiceの操作のため

/// アプリケーションのサブスクリプションの階層を定義する列挙型。
///
/// - [free]: 無料プラン。
/// - [tier1]: Tier 1 プラン。
/// - [tier2]: Tier 2 プラン（最も機能が充実）。
enum SubscriptionTier { free, tier1, tier2 }

/// アプリケーションの設定（初回起動フラグ、日記の開始ステップ、
/// サブスクリプションティアなど）を管理するプロバイダークラス。
///
/// 設定の永続化と取得、および関連するUIの状態更新を行います。
class SettingsProvider extends ChangeNotifier {
  final IsarService _isarService; // IsarServiceのインスタンス

  bool _startFromStep2 = false; // 日記をステップ2（出来事の入力）から開始するかどうかを示すフラグ
  bool get startFromStep2 => _startFromStep2;

  SubscriptionTier _currentTier = SubscriptionTier.free; // 現在のユーザーのサブスクリプションティア
  SubscriptionTier get currentTier => _currentTier;

  // --- 初回起動判定 ---
  bool isFirstLaunch = true; // アプリが初回起動かどうかを示すフラグ
  // ---------------------

  // 設定読み込み中の状態
  bool _isLoading = true; // 設定データ読み込み中かどうかを示すフラグ
  bool get isLoading => _isLoading;

  /// [SettingsProvider] のコンストラクタ。
  ///
  /// Isarサービスを受け取り、保存されている設定を読み込みます。
  SettingsProvider(this._isarService, DiaryRepository diaryRepository) {
    _loadSettings();
  }

  /// データベースからすべての設定（初回起動フラグ、開始ステップ、ティア）を非同期で読み込みます。
  Future<void> _loadSettings() async {
    _isLoading = true; // 読み込み開始
    notifyListeners();

    // isFirstLaunchフラグの読み込み
    final firstLaunchFlag = await _isarService.getSetting('isFirstLaunch');
    if (firstLaunchFlag == 'false') {
      isFirstLaunch = false;
    }

    // `startFromStep2` 設定の読み込み
    final savedStepSetting = await _isarService.getSetting('startFromStep2');
    _startFromStep2 = savedStepSetting == 'true';

    // サブスクリプションティアの読み込み
    final savedTier = await _isarService.getSetting('subscriptionTier');
    if (savedTier != null) {
      _currentTier = SubscriptionTier.values[int.tryParse(savedTier) ?? 0];
    }

    _isLoading = false; // 読み込み完了
    notifyListeners();
  }

  /// アプリの初回起動プロセスが完了したことをマークし、その状態を永続化します。
  Future<void> completeFirstLaunch() async {
    isFirstLaunch = false;
    await _isarService.saveSetting('isFirstLaunch', 'false'); // データベースに保存
    notifyListeners();
  }

  /// 初回起動フラグをリセットします（主に開発者向けのデバッグ機能）。
  Future<void> resetFirstLaunchFlag() async {
    isFirstLaunch = true;
    await _isarService.saveSetting('isFirstLaunch', 'true'); // データベースに保存
    notifyListeners();
  }

  /// 日記をステップ2から開始する設定を更新し、永続化します。
  ///
  /// [value] 新しい設定値。
  Future<void> setStartFromStep2(bool value) async {
    _startFromStep2 = value;
    await _isarService.saveSetting(
      'startFromStep2',
      value.toString(),
    ); // データベースに保存
    notifyListeners();
  }

  /// 現在のユーザーのサブスクリプションティアを更新し、永続化します。
  ///
  /// [tier] 新しいサブスクリプションティア。
  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    _currentTier = tier;
    await _isarService.saveSetting(
      'subscriptionTier',
      tier.index.toString(),
    ); // データベースに保存
    notifyListeners();
  }
}
