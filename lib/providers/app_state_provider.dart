// lib/providers/app_state_provider.dart

import 'package:flutter/material.dart';

// アプリ内の主要なタブを定義
enum AppTab { write, history, analysis, settings }

class AppStateProvider extends ChangeNotifier {
  // 初期状態は「記録（write）」画面
  AppTab _currentTab = AppTab.write;

  AppTab get currentTab => _currentTab;

  // タブを切り替えるメソッド
  void setTab(AppTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners(); // 画面を再描画
  }
}
