// lib/ui/screens/write_steps/step3_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';

class Step3Write extends StatelessWidget {
  const Step3Write({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WriteProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 左寄せにして読みやすく
      children: [
        // AIからの問いかけ部分
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
              provider.reflectionQuestion.isEmpty 
                  ? "今の自分を、ゆっくり眺めてみましょう。" 
                  : provider.reflectionQuestion, 
              style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
            ),
          ),
        
        const SizedBox(height: 12),

        // 案内メッセージ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "※忙しい時は空欄のまま保存しても大丈夫です。\n後ほど「履歴」からゆっくりと書き足せます。",
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          maxLines: 8, // 少し広めにして、書く時の没頭感を確保
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