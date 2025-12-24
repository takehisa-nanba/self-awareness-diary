// lib/ui/widgets/manage_app_shell.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import 'extended_fab_navigator.dart';

class ManageAppShell extends StatelessWidget {
  final Widget child;
  final String title;

  const ManageAppShell({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final safePaddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 66.0 + safePaddingTop),
            child: child,
          ),
          // ヘッダー
          Positioned(
            top: safePaddingTop,
            left: 0,
            right: 0,
            child: _buildHeader(context, title),
          ),
          // ナビゲーター
          Positioned(
            left: 16,
            top: safePaddingTop + 8,
            child: const ExtendedFabNavigator(),
          ),
        ],
      ),
      // 記録画面以外にいる時だけ表示される「記録開始」ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () => appState.setTab(AppTab.write),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      // 管理画面切り替え用のフッター
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(appState.currentTab),
        onDestinationSelected: (index) {
          const tabs = [AppTab.history, AppTab.analysis, AppTab.settings];
          appState.setTab(tabs[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '履歴'),
          NavigationDestination(icon: Icon(Icons.analytics), label: '分析'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  int _getSelectedIndex(AppTab tab) {
    if (tab == AppTab.history) return 0;
    if (tab == AppTab.analysis) return 1;
    if (tab == AppTab.settings) return 2;
    return 0;
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      height: 66.0,
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}