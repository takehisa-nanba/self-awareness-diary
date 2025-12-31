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

/// `WriteScreen` の状態を管理するクラス。
///
/// スクロールコントローラーを管理します。
class _WriteScreenState extends State<WriteScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 画面構築後、新規作成フローの場合のみ環境データの取得を開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final writeProvider = context.read<WriteProvider>();
      // 新規の日記作成時（編集や過去の記録でない場合）のみ現在地の環境データを取得
      if (writeProvider.isarId == null && !writeProvider.isHistoricalFlow) {
        writeProvider.fetchCurrentEnvironmentData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ヘッダー部分 (プログレスバー、場所/天気、タイトル)
        const _WriteScreenHeader(),
        // メインコンテンツ部分 (ステップごとの入力フォーム)
        _WriteScreenContent(scrollController: _scrollController),
        // ナビゲーション部分 (戻る、次へ/保存ボタン)
        const _WriteScreenNavigation(),
      ],
    );
  }
}

/// 日記作成ステップに応じたコンテンツを表示するウィジェット。
class _WriteScreenContent extends StatelessWidget {
  final ScrollController scrollController;
  const _WriteScreenContent({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final writeProvider = context.watch<WriteProvider>();

    return Expanded(
      child: Scrollbar(
        controller: scrollController,
        // スクロールバーの表示設定
        thumbVisibility: true,
        thickness: 6.0,
        radius: const Radius.circular(3.0),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // 現在のステップに応じたウィジェットを表示
          child: _buildStep(writeProvider.currentStep),
        ),
      ),
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

/// 日記作成画面のヘッダー部分を構築するウィジェット。
///
/// プログレスバー、位置情報/天気表示、現在のステップタイトルを表示します。
class _WriteScreenHeader extends StatelessWidget {
  const _WriteScreenHeader();

  @override
  Widget build(BuildContext context) {
    final writeProvider = context.watch<WriteProvider>();

    // 現在のステップに応じたタイトルを決定
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

    return Column(
      children: [
        // 現在のステップを示す線形プログレスインジケータ
        LinearProgressIndicator(value: (writeProvider.currentStep + 1) / 3),
        // 現在の位置情報と気象情報を表示するステータスバー
        const LocationStatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          // 現在のステップに応じたタイトル
          child: Text(
            currentTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// 日記作成画面のナビゲーションボタン部分を構築するウィジェット。
///
/// 「戻る」ボタンと「次へ/保存」ボタンを提供し、ステップ遷移とバリデーションロジックを含みます。
class _WriteScreenNavigation extends StatelessWidget {
  const _WriteScreenNavigation();

  @override
  Widget build(BuildContext context) {
    final writeProvider = context.watch<WriteProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 前のステップに戻るボタン
          if (writeProvider.currentStep > 0)
            TextButton(
              onPressed: writeProvider.previousStep,
              child: const Text(
                '戻る',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox.shrink(), // ステップ0の場合はボタンを表示しない
          // 次のステップへ進む、または記録を保存するボタン
          SizedBox(
            width: 108,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: writeProvider.isSaving || writeProvider.isGenerating
                  ? null // 保存中またはAI生成中はボタンを無効化
                  : () => _onNextPressed(
                      context,
                      writeProvider,
                      settingsProvider,
                    ), // ボタン押下時の処理
              // 保存中またはAI生成中はインジケータを表示、それ以外は「保存」または「次へ」を表示
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
    );
  }

  /// 「次へ」または「保存」ボタンが押された際の処理。
  ///
  /// 現在のステップに応じて入力のバリデーションを行い、次のステップへ進むか、日記を保存します。
  void _onNextPressed(
    BuildContext context,
    WriteProvider writeProvider,
    SettingsProvider settingsProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // --- バリデーションロジック ---
    if (writeProvider.currentStep == 0) {
      if (writeProvider.selectedTags.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('今の気分を一つ以上選んでくださいね。')),
        );
        return;
      }
    } else if (writeProvider.currentStep == 1) {
      if (writeProvider.eventText.trim().isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('何があったか、短くても良いので教えてください。')),
        );
        return;
      }
    }

    // バリデーション通過後
    if (writeProvider.currentStep < 2) {
      // 会員の場合、ステップ1の後にAIによる内省質問を準備
      if (writeProvider.currentStep == 1 &&
          settingsProvider.currentTier != SubscriptionTier.free) {
        await writeProvider.prepareReflection();
        if (!context.mounted) return;
      } else if (writeProvider.currentStep == 1 &&
          settingsProvider.currentTier == SubscriptionTier.free) {
        debugPrint("非会員のためAI質問生成をスキップします");
        writeProvider.reflectionQuestion = "";
      }
      writeProvider.nextStep(); // 次のステップへ
    } else {
      // 最終ステップ（自己分析）なら保存処理を実行
      await writeProvider.save();
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('記録を保存しました')),
      );
      // 記録保存後、履歴タブへ移動
      context.read<AppStateProvider>().setTab(AppTab.history);
    }
  }
}
