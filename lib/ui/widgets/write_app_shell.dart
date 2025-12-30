// lib/ui/widgets/write_app_shell.dart

import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

/// 「記録」画面の基本的なレイアウトを構成するシェル（骨格）ウィジェット。
///
/// このウィジェットは、中央のコンテンツ領域、上部のヘッダー、
/// そして他の画面へ遷移するためのフローティングアクションボタン（FAB）を配置します。
class WriteAppShell extends StatelessWidget {
  /// シェルの中央に表示されるメインコンテンツ。
  final Widget child;

  const WriteAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
            child: _buildHeader(context),
          ),
          // ナビゲーター (FAB)
          Positioned(
            left: 16,
            top: safePaddingTop + 8,
            child: const ExtendedFabNavigator(),
          ),
        ],
      ),
    );
  }

  /// 画面上部のヘッダーウィジェットを構築します。
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 66.0,
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        "記録",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
