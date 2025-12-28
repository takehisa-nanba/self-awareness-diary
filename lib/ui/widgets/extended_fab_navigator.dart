// lib/ui/widgets/extended_fab_navigator.dart

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart'; // Providerをインポート

class ExtendedFabNavigator extends StatelessWidget {
  const ExtendedFabNavigator({super.key});

  void _changeTab(BuildContext context, AppTab tab) {
    context.read<AppStateProvider>().setTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      // メインボタンのアイコン
      icon: Icons.menu,
      activeIcon: Icons.close,
      // 展開方向を下に設定
      direction: SpeedDialDirection.down,
      // ラベルの表示位置を切り替える
      switchLabelPosition: true,
      // アニメーション設定
      animatedIconTheme: const IconThemeData(size: 22.0),
      curve: Curves.bounceIn,
      // ボタンの見た目
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      // 子ボタンのリスト
      children: [
        SpeedDialChild(
          child: const Icon(Icons.edit),
          label: '記録',
          onTap: () => _changeTab(context, AppTab.write),
        ),
        SpeedDialChild(
          child: const Icon(Icons.history),
          label: '履歴',
          onTap: () => _changeTab(context, AppTab.history),
        ),
        SpeedDialChild(
          child: const Icon(Icons.analytics_outlined),
          label: '分析',
          onTap: () => _changeTab(context, AppTab.analysis),
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: '設定',
          onTap: () => _changeTab(context, AppTab.settings),
        ),
      ],
    );
  }
}
