// lib/ui/screens/write_steps/step3_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/subscription_tier.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/write_provider.dart';

/// 日記作成プロセスにおけるステップ3のUIを構築するウィジェット。
/// ユーザーに自己分析や内省を促すテキスト入力フィールドを提供します。
class Step3Write extends StatefulWidget {
  const Step3Write({super.key});

  @override
  State<Step3Write> createState() => _Step3WriteState();
}

/// `Step3Write` の状態を管理するクラス。
///
/// テキスト入力コントローラーを管理し、プロバイダーからのデータ変更を監視します。
class _Step3WriteState extends State<Step3Write> {
  late TextEditingController _controller; // テキスト入力コントローラー

  @override
  void initState() {
    super.initState();
    // Providerから初期値を取得してコントローラーを初期化
    _controller = TextEditingController(
      text: context.read<WriteProvider>().selfAnalysisText,
    );
  }

  @override
  void didUpdateWidget(covariant Step3Write oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Providerの値が外部から変更された場合にコントローラーを更新
    final newText = context.read<WriteProvider>().selfAnalysisText;
    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WriteProvider>();
    final subscription = context.watch<SubscriptionProvider>(); // SubscriptionProviderを取得

    // 動的なガイドメッセージを生成
    final guideText =
        '「${provider.eventText}」という出来事について、${provider.selectedTags.join('、')}という気持ちを踏まえて、なぜ${provider.moodScore}点にしたのか、今の素直な気持ちを言葉にしてみましょう。';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 動的ガイドメッセージを表示するコンテナ
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            guideText,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // AIからの深掘り質問（Freeティアでなければ表示）
        if (subscription.currentTier != SubscriptionTier.free)
          if (provider.isGenerating)
            // AIが質問生成中の場合はローディングインジケータを表示
            const Center(child: CircularProgressIndicator())
          else if (provider.reflectionQuestion.isNotEmpty)
            // AIからの質問がある場合は表示
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🤖 AIからの問いかけ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.reflectionQuestion,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

        // 自己分析用のテキスト入力フィールド
        TextField(
          controller: _controller,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            // ヒントテキストにガイダンスを統合し、ユーザーに安心感を与える
            hintText: '書くことは自分を見つめる鏡です...\n（忙しい時は空欄のまま保存しても、後からゆっくり書き足せます）',
            alignLabelWithHint: true,
          ),
          onChanged: (v) => provider.selfAnalysisText = v, // 入力変更をプロバイダーに通知
        ),
      ],
    );
  }
}
