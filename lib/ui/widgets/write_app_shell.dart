// lib/ui/widgets/write_app_shell.dart

import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

class WriteAppShell extends StatelessWidget {
  final Widget child;

  const WriteAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final safePaddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 66.0 + safePaddingTop),
            child: child,
          ),
          // ヘッダー（タイトル固定）
          Positioned(
            top: safePaddingTop,
            left: 0,
            right: 0,
            child: _buildHeader("今を刻む"),
          ),
          // ナビゲーター（左上固定）
          Positioned(
            left: 16,
            top: safePaddingTop + 8,
            child: const ExtendedFabNavigator(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      height: 66.0,
      color: Colors.indigo.shade700,
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}