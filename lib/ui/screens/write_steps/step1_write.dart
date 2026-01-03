// lib/ui/screens/write_steps/step1_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';
import '../../../providers/mood_tag_provider.dart';

/// 日記作成プロセスにおけるステップ1のUIを構築するウィジェット。
///
/// ユーザーが現在感じている気分に関連するタグを複数選択できるインターフェースを提供します。
class Step1Write extends StatelessWidget {
  const Step1Write({super.key});

  @override
  Widget build(BuildContext context) {
    final moodTagProvider = context.watch<MoodTagProvider>();

    return Column(
      children: [
        // 'なぜその気分？（複数選択可）'のタイトルはWriteScreenに移動済み
        // Consumerでラップし、selectedTagsの変更だけを監視
        /// [WriteProvider] と [MoodTagProvider] を利用して、気分タグの選択UIを構築します。
        /// 選択可能なタグと、現在選択されているタグの状態を管理・表示します。
        Consumer<WriteProvider>(
          builder: (context, writeProvider, child) {
            final moodTags = moodTagProvider.availableMoodTags;
            return GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // GridView自体のスクロールを無効化
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2列表示
                childAspectRatio: 4.0, // 各アイテムのアスペクト比
                crossAxisSpacing: 8, // 列間のスペース
                mainAxisSpacing: 8, // 行間のスペース
              ),
              itemCount: moodTags.length,
              itemBuilder: (context, index) {
                final tag = moodTags[index];
                final isSelected = writeProvider.selectedTags.contains(
                  tag.label,
                );
                return SizedBox(
                  width: 120.0, // チップの幅
                  child: FilterChip(
                    label: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tag.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // 長いテキストは省略
                          ),
                        ),
                      ],
                    ),
                    avatar: Icon(tag.icon, size: 18), // タグのアイコン
                    selected: isSelected, // 選択状態
                    selectedColor: tag.color.withAlpha((255 * 0.3).round()), // 選択時の色
                    onSelected: (val) {
                      if (val) {
                        writeProvider.selectedTags.add(tag.label); // タグを追加
                      } else {
                        writeProvider.selectedTags.remove(tag.label); // タグを削除
                      }
                      writeProvider.notify(); // 状態更新を通知
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
