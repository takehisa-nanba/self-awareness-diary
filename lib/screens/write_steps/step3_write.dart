// lib/screens/write_steps/step3_write.dart (修正版)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/write_core.dart';

class Step3WriteScreen extends StatelessWidget {
  final TextEditingController languageController;
  final VoidCallback onPremiumTap;
  final String locationString;
  final String weatherString;

  const Step3WriteScreen({
    super.key,
    required this.languageController,
    required this.onPremiumTap,
    required this.locationString,
    required this.weatherString,
  });

  @override
  Widget build(BuildContext context) {
    final core = Provider.of<WriteCore>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // 1. AIからの内省の質問表示エリア
        if (core.isGeneratingQuestion)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (core.reflectionQuestion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '【AIコーチからの質問】',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.lightBlue.shade200),
                  ),
                  child: Text(
                    core.reflectionQuestion, // ★★★ 質問を表示 ★★★
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
        // 2. 詳細（内省/回答）の入力エリア
        const Text(
          '【内省】質問に対する答えを記録する',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: languageController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: '例：この質問に答えるためには、まずあの時の自分の表情を思い出しました。…',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12.0),
            suffixIcon: IconButton(
              icon: const Icon(Icons.star_border),
              onPressed: onPremiumTap,
              tooltip: 'AIによる記述サマリー（有料機能）',
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 補足説明テキスト
        const Text(
          '例：プロジェクト完了は嬉しいが、次のタスクへの不安で落ち着かない。\n※履歴画面でも編集できますので、そのまま保存しても大丈夫です。',
          style: TextStyle(fontSize: 12.0, color: Colors.black54),
        ),

        const SizedBox(height: 20),
        
        // 環境ステータス（ダミー）を非表示にする
        // LocationStatusBar(location: locationString, weather: weatherString),
      ],
    );
  }
}