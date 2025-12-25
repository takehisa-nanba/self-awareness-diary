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

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

// 1. WidgetsBindingObserver をミックスインに追加
class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  // ポップ（終了）が許可されるかどうかを制御するステート変数。
  // バックボタンが押された際に確認ダイアログを表示するために、デフォルトでfalseに設定します。
  // ダイアログ操作後またはキャンセル後にtrue/falseに設定され、ポップの挙動を制御します。
  bool _canPop = false; // 修正: 初期値をfalseに設定

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

  // アプリの状態変化を検知するメソッド
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("【生体反応検知】アプリが再開されました。店長、データを更新してください。");
      // ここで最新の場所と天気を取得し直す
      context.read<WriteProvider>().fetchEnvironmentData(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentTab = appState.currentTab;

    return PopScope(
      canPop: _canPop, // バックナビゲーションが許可されるかを制御します。ステートによって管理されます。
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        // onPopInvokedWithResultはポップが試行された後に呼び出されます。
        // canPopがfalseなので、didPopは常にfalseになります。
        // つまり、このコールバックは常にポップがブロックされた時に呼び出されます。

        // ここがダイアログを表示するトリガーです。
        final confirmExit = await showDialog<bool>(
          context: context, // buildメソッドのcontextを使用
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('終了しますか？'),
            content: const Text('アプリを終了します。よろしいですか？'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false), // キャンセル
                child: const Text('いいえ'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true), // 確認
                child: const Text('はい'),
              ),
            ],
          ),
        );

        if (confirmExit == true) {
          if (!context.mounted) return; // 非同期ギャップを越えたBuildContextの使用をガード
          // ユーザーが終了を確認
          // 次回起動時のデフォルトタブを設定
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          if (!context.mounted) return; // 非同期ギャップを越えたBuildContextの使用をガード
          appState.setTab(AppTab.write);

          // 終了を完了させるために一時的にポップを有効化します。
          setState(() {
            _canPop = true; // ポップを許可
          });
          // ブロックされていたポップをプログラム的にトリガーします。
          if (context.mounted) { 
            SystemNavigator.pop();
          }
        } else {
          if (!context.mounted) return; // 非同期ギャップを越えたBuildContextの使用をガード
          // ユーザーが終了をキャンセル
          // ポップをブロックした状態を維持します。
          // _canPopは既にfalseなので、変更は不要ですが、setStateを呼び出してUIが最新の状態であることを保証します。
          setState(() {
            _canPop = false; // ポップを許可しない状態を維持
          });
        }
      },
      child: Scaffold( // 元のScaffoldをラップ
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: AppShell(
          title: _getTitle(currentTab),
          child: _getScreen(currentTab),
        ),
        // 「記録」ページ以外の時にFABを表示
        floatingActionButton: currentTab == AppTab.write
            ? null
            : FloatingActionButton(
                onPressed: () => appState.setTab(AppTab.write),
                child: const Icon(Icons.add),
              ),
        bottomNavigationBar: currentTab == AppTab.write
            ? null
            : NavigationBar(
                selectedIndex: _getSelectedIndex(currentTab),
                onDestinationSelected: (index) {
                  const tabs = [AppTab.history, AppTab.analysis, AppTab.settings];
                  appState.setTab(tabs[index]);
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
                  NavigationDestination(icon: Icon(Icons.analytics), label: '分析'),
                  NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
                ],
              ),
      ),
    );
  }

  // 選択されたタブのインデックスを取得
  int _getSelectedIndex(AppTab tab) {
    if (tab == AppTab.analysis) return 1;
    if (tab == AppTab.settings) return 2;
    return 0;
  }

  // 現在のタブに対応する画面ウィジェットを取得
  Widget _getScreen(AppTab tab) {
    switch (tab) {
      case AppTab.write: return const WriteScreen();
      case AppTab.history: return const HistoryScreen();
      case AppTab.analysis: return const AnalysisScreen();
      case AppTab.settings: return const SettingsScreen();
    }
  }

  // 現在のタブに対応するタイトルを取得
  String _getTitle(AppTab tab) {
    switch (tab) {
      case AppTab.write: return "記録";
      case AppTab.history: return "履歴";
      case AppTab.analysis: return "分析";
      case AppTab.settings: return "設定";
    }
  }
}