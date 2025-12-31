// lib/ui/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';
import 'banner_ad_wrapper.dart'; // BannerAdWrapperをインポート

/// アプリケーションの共通のレイアウト（シェル）を提供するウィジェット。
///
/// このシェルは、メインコンテンツ、画面上部のヘッダー、
/// そして左上部に配置される拡張可能なフローティングアクションボタン（FAB）ナビゲーターを統合します。
class AppShell extends StatelessWidget {
  /// シェルの中央に表示されるメインコンテンツ。
  final Widget child;

  /// ヘッダーに表示されるタイトル文字列。
  final String title;

  /// フローティングアクションボタン。
  final FloatingActionButton? floatingActionButton;

  /// 広告を表示しない「聖域」かどうか。
  final bool isSanctuary;

  const AppShell({
    super.key,
    required this.child,
    required this.title,
    this.floatingActionButton,
    this.isSanctuary = false, // isSanctuaryプロパティを追加
  });

  @override
  Widget build(BuildContext context) {
    // safePaddingTopが使われていないため削除
    // final safePaddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        // 左上部にExtendedFabNavigatorを配置
        leadingWidth: 70, // ExtendedFabNavigatorの幅に合わせて調整
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0), // 左からのパディングを調整
          // ExtendedFabNavigatorをAlignでラップして左寄せにする代わりに、leadingWidthとPaddingで調整
          child: ExtendedFabNavigator(),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: child), // メインコンテンツ
          BannerAdWrapper(isSanctuary: isSanctuary), // isSanctuaryを渡す
        ],
      ),
      floatingActionButton:
          floatingActionButton, // 受け取ったFloatingActionButtonを配置
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // FABの配置位置
    );
  }
}
