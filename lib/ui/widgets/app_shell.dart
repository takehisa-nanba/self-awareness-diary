// lib/ui/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String title;

  const AppShell({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    final safePaddingTop = MediaQuery.of(context).padding.top;

    // ★ Scaffold を絶対に返さないこと。Stack だけにする。
    return Stack(
      children: [
        // メインコンテンツ（ここが各画面の中身）
        Padding(
          padding: EdgeInsets.only(top: 66.0 + safePaddingTop),
          child: child,
        ),
        
        // ヘッダー（最前面）
        Positioned(
          top: safePaddingTop,
          left: 0,
          right: 0,
          child: Container(
            height: 66.0,
            color: Colors.indigo.shade700,
            alignment: Alignment.center,
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),

        // 左上のナビゲーター（最前面）
        Positioned(
          left: 16,
          top: safePaddingTop + 8,
          child: const ExtendedFabNavigator(),
        ),
      ],
    );
  }
}