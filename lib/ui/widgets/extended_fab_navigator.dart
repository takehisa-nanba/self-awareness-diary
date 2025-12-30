// lib/ui/widgets/extended_fab_navigator.dart

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

/// アプリケーションの主要な画面間を移動するための拡張可能なフローティングアクションボタン (FAB) ナビゲーターウィジェット。
///
/// `flutter_speed_dial` パッケージを利用して、複数のナビゲーションオプションをコンパクトに提供します。
class ExtendedFabNavigator extends StatelessWidget {
  const ExtendedFabNavigator({super.key});

  /// [AppStateProvider] を介して、アプリケーションの現在のタブを変更します。
  ///
  /// [context] ビルドコンテキスト。
  /// [tab] 遷移先のタブ ([AppTab] 列挙型)。
  void _changeTab(BuildContext context, AppTab tab) {
    context.read<AppStateProvider>().setTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      direction: SpeedDialDirection.down, // FABメニューが下方向に展開
      switchLabelPosition: true, // ラベルの位置を切り替える
      animatedIconTheme: const IconThemeData(size: 22.0),
      curve: Curves.bounceIn, // アニメーションのカーブ
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      children: [
        /// 「記録」画面への遷移ボタン。
        SpeedDialChild(
          child: const Icon(Icons.edit),
          label: '記録',
          onTap: () => _changeTab(context, AppTab.write),
        ),
        /// 「履歴」画面への遷移ボタン。
        SpeedDialChild(
          child: const Icon(Icons.history),
          label: '履歴',
          onTap: () => _changeTab(context, AppTab.history),
        ),
        /// 「分析」画面への遷移ボタン。
        SpeedDialChild(
          child: const Icon(Icons.analytics_outlined),
          label: '分析',
          onTap: () => _changeTab(context, AppTab.analysis),
        ),
        /// 「設定」画面への遷移ボタン。
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: '設定',
          onTap: () => _changeTab(context, AppTab.settings),
        ),
      ],
    );
  }
}
