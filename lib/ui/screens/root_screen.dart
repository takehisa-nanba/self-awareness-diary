import 'package:flutter/material.dart';
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
  
  @override
  void initState() {
    super.initState();
    // 2. ライフサイクルの監視を開始
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 3. 監視を終了（メモリリーク防止）
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. アプリの状態変化を検知するメソッドを追加
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: AppShell(
        title: _getTitle(currentTab),
        child: _getScreen(currentTab),
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
    );
  }

  int _getSelectedIndex(AppTab tab) {
    if (tab == AppTab.analysis) return 1;
    if (tab == AppTab.settings) return 2;
    return 0;
  }

  Widget _getScreen(AppTab tab) {
    switch (tab) {
      case AppTab.write: return const WriteScreen();
      case AppTab.history: return const HistoryScreen();
      case AppTab.analysis: return const AnalysisScreen();
      case AppTab.settings: return const SettingsScreen();
    }
  }

  String _getTitle(AppTab tab) {
    switch (tab) {
      case AppTab.write: return "今を刻む";
      case AppTab.history: return "履歴";
      case AppTab.analysis: return "分析";
      case AppTab.settings: return "設定";
    }
  }
}