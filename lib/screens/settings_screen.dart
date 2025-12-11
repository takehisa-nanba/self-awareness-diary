// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBarはナビゲーションに任せられないので、ここで定義
        AppBar(title: const Text('設定'), elevation: 1),

        // 設定項目リスト
        Expanded(
          child: ListView(
            children: [
              // ----------------------------------
              // 1. アプリの課金/プラン関連 (F-10 導線)
              // ----------------------------------
              ListTile(
                leading: const Icon(Icons.star_rate),
                title: const Text('プレミアムプランの管理'),
                subtitle: const Text('AIアシストの無制限利用や高度な分析を有効にします'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: サブスクリプション管理画面へ遷移 (subscription_screen.dartへ)
                },
              ),
              const Divider(),

              // ----------------------------------
              // 2. データ管理
              // ----------------------------------
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('データのエクスポート'),
                subtitle: const Text('記録をCSVファイルとして出力します'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: データのエクスポート処理を実装
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('すべてのデータを削除'),
                subtitle: const Text(
                  '元に戻せません',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: データ削除確認ダイアログを表示
                },
              ),
              const Divider(),

              // ----------------------------------
              // 3. アプリ情報
              // ----------------------------------
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('アプリについて'),
                subtitle: const Text('バージョン情報や利用規約'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: アプリ情報ダイアログを表示
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
