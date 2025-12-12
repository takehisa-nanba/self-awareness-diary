// lib/screens/subscription_screen.dart (新規作成)

import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プラン選択')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            '【F-10/F-12】有料プラン比較と購入の画面です。\n\n- スタンダード(150円)：全タグ解放、AIアシスト無制限\n- プレミアム(300円)：高度なテクニカル分析、自己覚知度提示',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
