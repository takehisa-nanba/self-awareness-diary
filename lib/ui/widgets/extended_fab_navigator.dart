// lib/ui/widgets/extended_fab_navigator.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart'; // Providerをインポート

class ExtendedFabNavigator extends StatelessWidget {
  const ExtendedFabNavigator({super.key});

  // ★ 修正：Navigatorを使わず、Providerでタブを切り替える
  void _changeTab(BuildContext context, AppTab tab) {
    context.read<AppStateProvider>().setTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppTab>( // 型をAppTabに変更
      icon: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.menu, color: Colors.indigo),
      ),
      onSelected: (tab) => _changeTab(context, tab),
      itemBuilder: (context) => [
        const PopupMenuItem(value: AppTab.write, child: Text('書く')),
        const PopupMenuItem(value: AppTab.history, child: Text('履歴')),
        const PopupMenuItem(value: AppTab.analysis, child: Text('分析')),
        const PopupMenuItem(value: AppTab.settings, child: Text('設定')),
      ],
    );
  }
}