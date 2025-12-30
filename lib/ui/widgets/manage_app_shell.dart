// lib/ui/widgets/manage_app_shell.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import 'extended_fab_navigator.dart';

/// アプリケーションの管理画面（履歴、分析、設定など）の共通レイアウトを構成するシェルウィジェット。
///
/// このシェルは、コンテンツ領域、上部のヘッダー、拡張フローティングアクションボタン、
/// そして下部のナビゲーションバーを統合します。
class ManageAppShell extends StatelessWidget {
  /// シェルの中央に表示されるメインコンテンツ。
  final Widget child;

  /// ヘッダーに表示される画面のタイトル。
  final String title;

  const ManageAppShell({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final safePaddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // メインコンテンツ
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
          // 拡張ナビゲーションFAB
          Positioned(
            left: 16,
            top: safePaddingTop + 8,
            child: const ExtendedFabNavigator(),
          ),
        ],
      ),
      // 「記録」画面以外のFAB
      /// 「記録」画面への遷移を促すフローティングアクションボタン。
      floatingActionButton: FloatingActionButton(
        onPressed: () => appState.setTab(AppTab.write),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      // フッターナビゲーション
      /// アプリケーションの主要なセクション間を移動するためのボトムナビゲーションバー。
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

  /// 現在の [AppTab] に基づいて、[NavigationBar] の選択されたインデックスを返します。
  int _getSelectedIndex(AppTab tab) {
    if (tab == AppTab.history) return 0;
    if (tab == AppTab.analysis) return 1;
    if (tab == AppTab.settings) return 2;
    return 0; // デフォルトは履歴タブ
  }

  /// 画面上部に表示されるヘッダーウィジェットを構築します。
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
