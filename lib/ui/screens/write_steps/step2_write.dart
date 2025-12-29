// lib/ui/screens/write_steps/step2_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';
import '../../widgets/horizontal_mood_selector.dart'; // HorizontalMoodSelectorを追加

class Step2Write extends StatefulWidget {
  const Step2Write({super.key});

  @override
  State<Step2Write> createState() => _Step2WriteState();
}

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

    // _eventTextControllerの初期値をwriteProviderから設定
    _eventTextController.text = writeProvider.eventText;
    // カーソル位置を末尾に移動（テキスト変更時に先頭に戻るのを防ぐ）
    _eventTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _eventTextController.text.length),
    );

    return Column(
      children: [
        // ムードスコアセレクター
        Consumer<WriteProvider>(
          builder: (context, wp, child) {
            return HorizontalMoodSelector(
              currentMood: wp.moodScore,
              onChanged: (newMood) {
                wp.moodScore = newMood;
                wp.notify();
              },
            );
          },
        ),
        const SizedBox(height: 30),
        // 何がありましたか？テキスト入力
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '何がありましたか？',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _eventTextController,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '出来事を入力...',
          ),
          onChanged: (v) => writeProvider.eventText = v,
        ),
      ],
    );
  }
}
