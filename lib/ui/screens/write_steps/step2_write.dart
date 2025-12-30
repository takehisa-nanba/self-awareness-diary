// lib/ui/screens/write_steps/step2_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';
import '../../widgets/horizontal_mood_selector.dart';

/// 日記作成プロセスにおけるステップ2のUIを構築するウィジェット。
///
/// ユーザーが気分のスコアを選択し、その日の出来事をテキスト入力するインターフェースを提供します。
class Step2Write extends StatefulWidget {
  const Step2Write({super.key});

  @override
  State<Step2Write> createState() => _Step2WriteState();
}

/// [Step2Write] の状態を管理するクラス。
///
/// 出来事のテキスト入力用のコントローラーを管理します。
class _Step2WriteState extends State<Step2Write> {
  final TextEditingController _eventTextController = TextEditingController();

  @override
  void dispose() {
    _eventTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final writeProvider = context.watch<WriteProvider>();

    // writeProviderから_eventTextControllerの初期値を設定
    _eventTextController.text = writeProvider.eventText;
    // カーソル位置を末尾に移動（テキスト変更時に先頭に戻るのを防ぐ）
    _eventTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _eventTextController.text.length),
    );

    return Column(
      children: [
        // ムードスコアセレクター
        /// [WriteProvider] を利用して、気分スコアを選択するための横スクロールセレクター。
        /// ユーザーがスコアを変更すると、[WriteProvider] の状態が更新されます。
        Consumer<WriteProvider>(
          builder: (context, wp, child) {
            return HorizontalMoodSelector(
              currentMood: wp.moodScore,
              onChanged: (newMood) {
                wp.moodScore = newMood;
                wp.notify(); // 変更を通知
              },
            );
          },
        ),
        const SizedBox(height: 30),
        // 出来事テキスト入力
        /// ユーザーがその日の出来事を入力するためのテキストフィールド。
        /// 入力内容は [WriteProvider] の `eventText` に同期されます。
        TextField(
          controller: _eventTextController,
          maxLines: 5, // 複数行入力可能
          decoration: const InputDecoration(
            border: OutlineInputBorder(), // アウトラインボーダー
            hintText: '出来事を入力...', // ヒントテキスト
          ),
          onChanged: (v) => writeProvider.eventText = v, // 入力内容をプロバイダーに反映
        ),
      ],
    );
  }
}
