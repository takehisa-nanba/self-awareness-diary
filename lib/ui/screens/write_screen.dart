import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/write_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/location_status_bar.dart';
import 'write_steps/step1_write.dart';
import 'write_steps/step2_write.dart';
import 'write_steps/step3_write.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  @override
  void initState() {
    super.initState();
    // 画面が表示された「直後（0秒後）」に堂々と開始する
    debugPrint("WriteScreenが表示されました。環境データ取得を開始します。");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WriteProvider>().fetchEnvironmentData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WriteProvider>();

    return Column(
      children: [
        // 進捗インジケータ
        LinearProgressIndicator(value: (provider.currentStep + 1) / 3),
        
        // ステータスバー（ここで「取得中...」などの表示が出るはずです）
        const LocationStatusBar(), 
        
        const SizedBox(height: 20),
        
        // 各ステップの表示
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStep(provider.currentStep),
          ),
        ),
        
        // 操作ボタンエリア
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (provider.currentStep > 0)
                TextButton(
                  onPressed: provider.previousStep, 
                  child: const Text(
                    '戻る',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                )
              else
                const SizedBox.shrink(),
              
              SizedBox(
                width: 108,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: provider.isSaving ? null : () async {
                  // --- バリデーションチェック ---
                  if (provider.currentStep == 0) {
                    // Step 1: 気分タグが一つも選ばれていない場合は進ませない
                    if (provider.selectedTags.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('今の気分を一つ以上選んでくださいね。'))
                      );
                      return;
                    }
                  // 問題なければ次のステップへ
                  provider.nextStep();

                  } else if (provider.currentStep == 1) {
                    // Step 2: 出来事が空欄の場合は進ませない
                    if (provider.eventText.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('何があったか、短くても良いので教えてください。'))
                      );
                      return;
                    }
                    
                    // --- サブスクチェック（AI呼び出し判定） ---
                    // SettingsProvider などでサブスク状態を管理している想定
                    final isSubscribed = context.read<SettingsProvider>().isPremium;
                    
                    if (isSubscribed) {
                      await provider.prepareReflection();
                    } else {
                      // 非会員はAIを飛ばして直接 Step 3 へ
                      debugPrint("非会員のためAI質問生成をスキップします");
                      provider.reflectionQuestion = ""; // またはデフォルト定型文
                    }

                    // 問題なければ次のステップへ
                    provider.nextStep();

                    } else if (provider.currentStep == 2) {
                      final messenger = ScaffoldMessenger.of(context);
                      await provider.save();
                      if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('記録を保存しました'))
                        );
                    } else {
                      provider.nextStep();
                    }
                  },
                child: (provider.isSaving || provider.isGenerating) 
                  ? const SizedBox(
                      width: 24, // ボタンの高さに合わせて少し小さめに
                      height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 3),
                  )
                  : Text(
                      provider.currentStep == 2 ? '保存' : '次へ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // 文字を太く大きく
                  )
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0: return const Step1Write();
      case 1: return const Step2Write();
      case 2: return const Step3Write();
      default: return const Step1Write();
    }
  }
}