import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/write_provider.dart';
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
                  child: const Text('戻る')
                )
              else
                const SizedBox.shrink(),
              
              ElevatedButton(
                onPressed: provider.isSaving ? null : () async {
                  if (provider.currentStep == 1) {
                    await provider.prepareReflection();
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
                child: provider.isSaving 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : Text(provider.currentStep == 2 ? '保存' : '次へ'),
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