import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
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

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    // 起動時の自動実行は削除。
    // 各画面（WriteScreenなど）が必要な時に店長を呼び出す形にします。
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