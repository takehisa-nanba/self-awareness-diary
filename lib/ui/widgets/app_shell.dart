// lib/ui/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

/// アプリケーションの共通のレイアウト（シェル）を提供するウィジェット。
///
/// このシェルは、メインコンテンツ、画面上部のヘッダー、
/// そして左上部に配置される拡張可能なフローティングアクションボタン（FAB）ナビゲーターを統合します。
class AppShell extends StatelessWidget {
  /// シェルの中央に表示されるメインコンテンツ。
  final Widget child;

  /// ヘッダーに表示されるタイトル文字列。
  final String title;

  const AppShell({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    final safePaddingTop = MediaQuery.of(context).padding.top;

    // Scaffoldを返さず、Stackのみを返す
    return Stack(
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
          child: Container(
            height: 66.0,
            color: Theme.of(context).colorScheme.primaryContainer,
            alignment: Alignment.center,
            child: Text(
              title,
              style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),

        // 左上のナビゲーター
        Positioned(
          left: 16,
          top: safePaddingTop + 5,
          child: const ExtendedFabNavigator(),
        ),
      ],
    );
  }
}
