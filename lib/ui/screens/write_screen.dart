// lib/ui/screens/write_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/write_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/location_status_bar.dart';
import 'write_steps/step1_write.dart';
import 'write_steps/step2_write.dart';
import 'write_steps/step3_write.dart';

/// 日記の記録プロセス全体を管理する画面ウィジェット。
///
/// ユーザーが気分、出来事、自己分析を入力するための複数のステップを提供し、
/// 位置情報や気象情報の自動取得、AIによる補助機能を統合します。
class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

/// [WriteScreen] の状態を管理するクラス。
///
/// スクロールコントローラー、テキスト入力コントローラー、
/// ステップごとの入力検証および画面遷移ロジックを扱います。
class _WriteScreenState extends State<WriteScreen> {
  late ScrollController _scrollController;
  final TextEditingController _eventTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    debugPrint("WriteScreenが表示されました。環境データ取得を開始します。");
    // ウィジェットが完全にビルドされた後に環境データの取得を開始
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

    // ステップに応じてタイトルを決定
    String currentTitle;
    switch (writeProvider.currentStep) {
      case 0:
        currentTitle = '感情を掘り起こす🔨（複数選択可）';
        break;
      case 1:
        currentTitle = '気分を評価し、出来事を採掘する🔨';
        break;
      case 2:
        currentTitle = '原石を磨き、言葉にする💎';
        break;
      default:
        currentTitle = '記録';
    }

    // writeProviderから_eventTextControllerの初期値を設定
    _eventTextController.text = writeProvider.eventText;
    // カーソル位置を末尾に移動（テキスト変更時に先頭に戻るのを防ぐ）
    _eventTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _eventTextController.text.length),
    );

    return Column(
      children: [
        /// 現在のステップを示す線形プログレスインジケータ。
        LinearProgressIndicator(value: (writeProvider.currentStep + 1) / 3),
        /// 現在の位置情報と気象情報を表示するステータスバー。
        const LocationStatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          /// 現在のステップに応じたタイトル。
          child: Text(
            currentTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          /// スクロール可能なコンテンツ領域。
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 6.0,
            radius: const Radius.circular(3.0),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStep(writeProvider.currentStep),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// 前のステップに戻るボタン。
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
              /// 次のステップへ進む、または記録を保存するボタン。
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
                          if (writeProvider.currentStep == 0) {
                            if (writeProvider.selectedTags.isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('今の気分を一つ以上選んでくださいね。'),
                                ),
                              );
                              return;
                            }
                          } else if (writeProvider.currentStep == 1) {
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
                            // 会員の場合、ステップ1の後にAIによる内省質問を準備
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
                            writeProvider.nextStep(); // 次のステップへ
                          } else {
                            // 最終ステップなら保存
                            await writeProvider.save();
                            if (!context.mounted) return;
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('記録を保存しました')),
                            );
                            context.read<AppStateProvider>().setTab(
                              AppTab.history,
                            ); // 履歴タブへ移動
                          }
                        },
                  /// 保存中またはAI生成中はインジケータを表示、それ以外は「保存」または「次へ」を表示。
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

  /// 現在のステップ番号に応じて、表示するステップウィジェットを切り替えます。
  ///
  /// [step] 現在のステップ番号 (0, 1, 2)。
  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return const Step1Write();
      case 1:
        return const Step2Write();
      case 2:
        return const Step3Write();
      default:
        return const Step1Write(); // 未定義の場合はステップ1を表示
    }
  }
}
