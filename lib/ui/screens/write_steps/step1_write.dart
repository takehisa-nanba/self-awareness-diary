// lib/ui/screens/write_steps/step1_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';
import '../../../providers/mood_tag_provider.dart'; // MoodTagProviderをインポート
// import '../../widgets/horizontal_mood_selector.dart'; // HorizontalMoodSelectorはStep2Writeへ移動

class Step1Write extends StatelessWidget {
  const Step1Write({super.key});

  @override
  Widget build(BuildContext context) {
    final moodTagProvider = context.watch<MoodTagProvider>();

    return Column(
      children: [
        // 'なぜその気分？（複数選択可）'のタイトルはWriteScreenに移動

        // Consumerでラップし、selectedTagsの変更だけを監視
        Consumer<WriteProvider>(
          builder: (context, writeProvider, child) {
            final moodTags = moodTagProvider.availableMoodTags;
            return Scrollbar(
              thumbVisibility: true, // スクロールバーを常に表示
              thickness: 6.0, // スクロールバーの太さ
              radius: const Radius.circular(3.0), // スクロールバーの角の丸み
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // SingleChildScrollViewが親なので無効にする
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 1行に2つのタグに調整
                  childAspectRatio: 4.0, // タグの幅/高さの比率を調整 (3.5から4.0程度)
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: moodTags.length,
                itemBuilder: (context, index) {
                  final tag = moodTags[index];
                  final isSelected = writeProvider.selectedTags.contains(
                    tag.label,
                  );
                  return SizedBox( // FilterChipをSizedBoxでラップして幅を制御
                    width: 120.0, // 固定幅を設定（7文字幅相当）
                    child: FilterChip(
                      label: Row( // RowでTextをラップし、ExpandedでTextを広げる
                        children: [
                          Expanded(
                            child: Text(
                        tag.label,
                        textAlign: TextAlign.center, // 文字を中央揃え
                        maxLines: 1, // 1行に限定
                        overflow: TextOverflow.ellipsis, // 長すぎる場合は...で省略
                      ),
                          ),
                        ],
                      ),
                      avatar: Icon(tag.icon, size: 18),
                      selected: isSelected,
                      selectedColor: tag.color.withAlpha(80),
                      onSelected: (val) {
                        if (val) {
                          writeProvider.selectedTags.add(tag.label);
                        } else {
                          writeProvider.selectedTags.remove(tag.label);
                        }
                        writeProvider.notify();
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}