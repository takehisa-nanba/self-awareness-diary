import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String title;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.child,
    this.title = '自己覚知日記',
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final safePaddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // コンテンツ
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
              color: Colors.indigo.shade700,
              alignment: Alignment.center,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 独自のナビゲーションボタン（以前のExtendedFabを配置）
          Positioned(
            left: 16,
            top: safePaddingTop + 8,
            child: const ExtendedFabNavigator(),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}