// lib/screens/new_entry_steps/step3_language.dart

import 'package:flutter/material.dart';

class Step3LanguageScreen extends StatelessWidget {
  final TextEditingController languageController;
  final VoidCallback onPremiumTap; // 有料プラン画面への遷移コールバック

  const Step3LanguageScreen({
    super.key,
    required this.languageController,
    required this.onPremiumTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3. 気分を自由に言語化してください (オプション)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            '自己覚知を深めるための重要なステップです。',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: languageController,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例：プロジェクト完了は嬉しいが、次のタスクへの不安で落ち着かない。',
            ),
          ),

          const SizedBox(height: 30),

          // ★★★ AIアシスト（有料プラン導線）の配置 ★★★
          Card(
            color: Colors.indigo.shade50,
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.indigo),
              title: const Text(
                '【有料プラン】AIアシストを利用して言語化',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('AIがあなたの出来事とタグから、感情を詳細に分析・言語化します。'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onPremiumTap, // 課金プラン画面へ遷移
            ),
          ),
        ],
      ),
    );
  }
}
