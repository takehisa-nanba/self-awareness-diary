// lib/providers/app_state_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要

/// アプリケーション内で使用される主要なタブを定義する列挙型。
///
/// - [write]: 日記を記録するタブ。
/// - [history]: 過去の日記履歴を表示するタブ。
/// - [analysis]: 日記の分析結果を表示するタブ。
/// - [settings]: アプリケーションの設定を行うタブ。
enum AppTab { write, history, analysis, settings }

/// アプリケーションのグローバルな状態（主に現在選択されているタブ）を管理するプロバイダークラス。
///
/// [ChangeNotifier] を継承しており、状態の変更をリスナーに通知します。
class AppStateProvider extends ChangeNotifier {
  /// 現在選択されているタブ。初期値は [AppTab.write]（記録タブ）。
  AppTab _currentTab = AppTab.write;

  /// 現在選択されているタブを取得します。
  AppTab get currentTab => _currentTab;

  /// アプリケーションのタブを切り替えるメソッド。
  ///
  /// 現在のタブと新しいタブが異なる場合のみ状態を更新し、リスナーに通知します。
  /// [tab] 新しく設定するタブ。
  void setTab(AppTab tab) {
    if (_currentTab == tab) return; // 同じタブが選択された場合は何もしない
    _currentTab = tab;
    notifyListeners(); // UIを再描画
  }
}
