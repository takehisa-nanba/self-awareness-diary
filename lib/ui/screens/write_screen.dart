import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/write_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/app_state_provider.dart';
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
  late ScrollController _scrollController;
  final TextEditingController _eventTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    debugPrint("WriteScreenが表示されました。環境データ取得を開始します。");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WriteProvider>().fetchEnvironmentData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _eventTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final writeProvider = context.watch<WriteProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // --- ステップ判定 ---
    final currentStepIndex = writeProvider.currentStep;
    final isMoodTagsStep = currentStepIndex == 0; // Step 0がイベントテキスト入力

    // _eventTextControllerの初期値をwriteProviderから設定
    _eventTextController.text = writeProvider.eventText;
    // カーソル位置を末尾に移動（テキスト変更時に先頭に戻るのを防ぐ）
    _eventTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _eventTextController.text.length),
    );

    return Column(
      children: [
        LinearProgressIndicator(value: (writeProvider.currentStep + 1) / 3),
        const LocationStatusBar(),
        const SizedBox(height: 20),
        // 常時表示される「なぜその気分？」（イベントテキスト）フィールド
        if (isMoodTagsStep) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今の気分は？（複数選択可）',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true, // スクロールバーを常に表示
            thickness: 6.0, // スクロールバーの太さ
            radius: const Radius.circular(3.0), // スクロールバーの角の丸み
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // _buildStepのコンテンツをここに入れる
              child: _buildStep(writeProvider.currentStep),
            ),
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
                  child: const Text(
                    '戻る',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                  onPressed: writeProvider.isSaving
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );

                          // --- バリデーションロジック ---
                          if (isMoodTagsStep) {
                            // Step 0: ムードタグ選択
                            if (writeProvider.selectedTags.isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('今の気分を一つ以上選んでくださいね。'),
                                ),
                              );
                              return;
                            }
                          } else if (currentStepIndex == 1) {
                            // Step 1: ムードスコアと出来事入力
                            // Validation for eventText moved to Step2Write, but currentStepIndex==1 refers to Step2Write
                            // So, the eventText validation should happen when currentStepIndex == 1 (Step2Write)
                            // and the _eventTextController is managed in Step2Write.
                            // However, eventText is managed in writeProvider.eventText, so the validation remains here.
                            if (writeProvider.eventText.trim().isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('何があったか、短くても良いので教えてください。'),
                                ),
                              );
                              return;
                            }
                          }

                          // バリデーション通過後
                          if (writeProvider.currentStep < 2) {
                            // Step 2 (Self-analysis & AI) に進む前にAI質問生成
                            if (writeProvider.currentStep == 1 &&
                                settingsProvider.currentTier !=
                                    SubscriptionTier.free) {
                              await writeProvider.prepareReflection();
                              if (!context.mounted) return;
                            } else if (writeProvider.currentStep == 1 &&
                                settingsProvider.currentTier ==
                                    SubscriptionTier.free) {
                              debugPrint("非会員のためAI質問生成をスキップします");
                              writeProvider.reflectionQuestion = "";
                            }
                            writeProvider.nextStep();
                          } else {
                            // 最後のステップなら保存
                            await writeProvider.save();
                            if (!context.mounted) return;
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('記録を保存しました')),
                            );
                            // 保存後、履歴画面に遷移
                            context.read<AppStateProvider>().setTab(
                              AppTab.history,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 設定に応じて表示するウィジェットを切り替える
  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return const Step1Write(); // Step 0がムードタグ
      case 1:
        return const Step2Write(); // Step 1がムードスコアと出来事入力
      case 2:
        return const Step3Write(); // Step 2が自己分析とAI
      default:
        return const Step1Write();
    }
  }
}
