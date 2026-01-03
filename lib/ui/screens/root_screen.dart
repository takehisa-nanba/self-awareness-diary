// lib/ui/screens/root_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/write_provider.dart';
import '../widgets/app_shell.dart';
import 'write_screen.dart';
import 'history_screen.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';

/// アプリケーションのメイン画面であり、ナビゲーションのルートとなるウィジェット。
///
/// タブ切り替えによる画面表示、アプリのライフサイクル管理、
/// およびアプリ終了時の確認ダイアログの表示などを担当します。
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

/// [RootScreen] の状態を管理するクラス。
///
/// [WidgetsBindingObserver] を利用してアプリのライフサイクルイベント（再開時など）を監視し、
/// 環境データの更新などを行います。
class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  /// アプリのポップ（終了）が許可されるかどうかの制御フラグ。
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    // ライフサイクルの監視を開始
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 監視を終了（メモリリーク防止）
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// アプリケーションのライフサイクル状態が変更されたときに呼び出されます。
  ///
  /// アプリがフォアグラウンドに復帰した際に、最新の環境データを再取得します。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("【生体反応検知】アプリが再開されました。環境データを更新します。");
      // 最新の場所と天気を取得し直す
      context.read<WriteProvider>().fetchCurrentEnvironmentData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final writeState = context.watch<WriteProvider>(); // WriteProviderを監視
    final currentTab = appState.currentTab;

    // WriteScreenのStep3（清書画面）かどうかを判定
    final bool isSanctuary =
        currentTab == AppTab.write && writeState.currentStep == 2;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // 既にポップされた場合は何もしない

        // 終了確認ダイアログを表示
        final confirmExit = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('終了しますか？'),
            content: const Text('アプリを終了します。よろしいですか？'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('いいえ'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('はい'),
              ),
            ],
          ),
        );

        if (confirmExit == true && context.mounted) {
          // ユーザーが終了を確認
          final appState = Provider.of<AppStateProvider>(
            context,
            listen: false,
          );
          appState.setTab(AppTab.write); // アプリ終了前に状態をリセット

          // アプリを終了
          setState(() {
            _canPop = true;
          });
          SystemNavigator.pop();
        } else {
          // ユーザーが終了をキャンセル
          setState(() {
            _canPop = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: AppShell(
          title: _getTitle(currentTab),
          isSanctuary: isSanctuary, // isSanctuaryフラグをAppShellに渡す
          child: _getScreen(currentTab),
        ),

        /// 現在のタブが「記録」の場合はFABを非表示にする。
        floatingActionButton: currentTab == AppTab.write
            ? null
            : FloatingActionButton(
                onPressed: () => appState.setTab(AppTab.write),
                child: const Icon(Icons.add),
              ),

        /// 現在のタブが「記録」の場合はナビゲーションバーを非表示にする。
        bottomNavigationBar: currentTab == AppTab.write
            ? null
            : NavigationBar(
                selectedIndex: _getSelectedIndex(currentTab),
                onDestinationSelected: (index) {
                  const tabs = [
                    AppTab.history,
                    AppTab.analysis,
                    AppTab.settings,
                  ];
                  appState.setTab(tabs[index]);
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
                  NavigationDestination(
                    icon: Icon(Icons.analytics),
                    label: '分析',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings),
                    label: '設定',
                  ),
                ],
              ),
      ),
    );
  }

  /// 現在選択されているタブ [AppTab] に対応する [NavigationBar] のインデックスを返します。
  int _getSelectedIndex(AppTab tab) {
    switch (tab) {
      case AppTab.history:
        return 0;
      case AppTab.analysis:
        return 1;
      case AppTab.settings:
        return 2;
      default:
        return 0; // デフォルトは履歴タブ
    }
  }

  /// 現在選択されているタブ [AppTab] に対応する画面ウィジェットを返します。
  Widget _getScreen(AppTab tab) {
    switch (tab) {
      case AppTab.write:
        return const WriteScreen();
      case AppTab.history:
        return const HistoryScreen();
      case AppTab.analysis:
        return const AnalysisScreenWrapper();
      case AppTab.settings:
        return const SettingsScreen();
    }
  }

  /// 現在選択されているタブ [AppTab] に対応する画面タイトル文字列を返します。
  String _getTitle(AppTab tab) {
    switch (tab) {
      case AppTab.write:
        return "記録";
      case AppTab.history:
        return "履歴";
      case AppTab.analysis:
        return "分析";
      case AppTab.settings:
        return "設定";
    }
  }
}
