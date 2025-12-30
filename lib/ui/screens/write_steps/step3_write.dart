// C:\Users\ramp1\Desktop\self-awareness-diary\lib\ui\screens\write_steps\step3_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';
import '../../../providers/settings_provider.dart';

/// 日記作成プロセスにおけるステップ3のUIを構築するウィジェット。
/// ユーザーに自己分析や内省を促すテキスト入力フィールドを提供します。
/// AIによる質問や、入力フィールドのガイダンスメッセージも表示します。
class Step3Write extends StatelessWidget {
  const Step3Write({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WriteProvider>();
    final settings = context.watch<SettingsProvider>();

    String message;
    if (settings.currentTier == SubscriptionTier.tier2) {
      message = provider.reflectionQuestion.isEmpty
          ? "AIがあなたの言葉を待っています..."
          : provider.reflectionQuestion;
    } else {
      message = provider.reflectionQuestion.isEmpty
          ? "気分を深掘りして、採掘した原石を磨きましょう 🪨\n（忙しい時はそのまま保存しても、後から磨けます）"
          : provider.reflectionQuestion;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 左寄せで読みやすく
      children: [
        // AIからの問いかけ
        if (provider.isGenerating)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                height: 1.5, // 行間を少し広げる
              ),
            ),
          ),

        const SizedBox(height: 12),

        // ガイダンスメッセージ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "※忙しい時は空欄のまま保存しても大丈夫です。\n後ほど「履歴」からゆっくりと書き足せます。",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          maxLines: 8, // 書くスペースを広めに確保
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '今の気持ちや、気づいたこと（任意）',
            alignLabelWithHint: true,
          ),
          onChanged: (v) => provider.selfAnalysisText = v,
        ),
      ],
    );
  }
}