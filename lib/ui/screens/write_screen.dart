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
    debugPrint("WriteScreenが表示されました。環境データ取得を開始します。");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WriteProvider>().fetchEnvironmentData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final writeProvider = context.watch<WriteProvider>();
    // SettingsProviderは監視不要なのでreadでOK
    final settingsProvider = context.read<SettingsProvider>();
    final startFromStep2 = settingsProvider.startFromStep2;

    return Column(
      children: [
        LinearProgressIndicator(value: (writeProvider.currentStep + 1) / 3),
        const LocationStatusBar(),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStep(writeProvider.currentStep, startFromStep2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (writeProvider.currentStep > 0)
                TextButton(
                  onPressed: writeProvider.previousStep,
                  child: const Text('戻る', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox.shrink(),
              
              SizedBox(
                width: 108,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: writeProvider.isSaving ? null : () async {
                    // --- contextを安全に使うための準備 ---
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final settingsProvider = context.read<SettingsProvider>();
                    final writeProvider = context.read<WriteProvider>(); // writeProviderもreadで取得

                    // --- バリデーションロジック ---
                    final currentStepIndex = writeProvider.currentStep;
                    final isMoodStep = (!startFromStep2 && currentStepIndex == 0) || (startFromStep2 && currentStepIndex == 1);
                    final isEventStep = (!startFromStep2 && currentStepIndex == 1) || (startFromStep2 && currentStepIndex == 0);

                    if (isMoodStep) {
                      if (writeProvider.selectedTags.isEmpty) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('今の気分を一つ以上選んでくださいね。'))
                        );
                        return;
                      }
                    } else if (isEventStep) {
                      if (writeProvider.eventText.trim().isEmpty) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('何があったか、短くても良いので教えてください。'))
                        );
                        return;
                      }
                      
                      if (settingsProvider.isPremium) {
                        await writeProvider.prepareReflection();
                        if (!context.mounted) return;
                      } else {
                        debugPrint("非会員のためAI質問生成をスキップします");
                        writeProvider.reflectionQuestion = "";
                      }
                    }

                    // バリデーション通過後
                    if (writeProvider.currentStep < 2) {
                      writeProvider.nextStep();
                    } else { // 最後のステップなら保存
                      await writeProvider.save();
                      if (!context.mounted) return;
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('記録を保存しました'))
                      );
                    }
                  },
                  child: (writeProvider.isSaving || writeProvider.isGenerating) 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                    )
                    : Text(
                        writeProvider.currentStep == 2 ? '保存' : '次へ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 設定に応じて表示するウィジェットを切り替える
  Widget _buildStep(int step, bool startFromStep2) {
    if (startFromStep2) {
      // Step2から開始するフロー
      switch (step) {
        case 0: return const Step2Write();
        case 1: return const Step1Write();
        case 2: return const Step3Write();
        default: return const Step2Write();
      }
    } else {
      // Step1から開始するフロー
      switch (step) {
        case 0: return const Step1Write();
        case 1: return const Step2Write();
        case 2: return const Step3Write();
        default: return const Step1Write();
      }
    }
  }
}