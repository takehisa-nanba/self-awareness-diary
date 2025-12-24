// lib/ui/screens/write_steps/step1_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';
import '../../../data/mood_tag_list.dart';
import '../../widgets/horizontal_mood_selector.dart'; // ← 追加

class Step1Write extends StatelessWidget {
  const Step1Write({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch() から context.read() に変更し、不要な再ビルドを防ぐ
    return Column(
      children: [
        // Consumerでラップし、moodScoreの変更だけを監視
        Consumer<WriteProvider>(
          builder: (context, writeProvider, child) {
            return HorizontalMoodSelector(
              currentMood: writeProvider.moodScore,
              onChanged: (newMood) {
                writeProvider.moodScore = newMood;
                writeProvider.notify();
              },
            );
          },
        ),
        const SizedBox(height: 30),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'なぜその気分？（複数選択可）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 10),
        // Consumerでラップし、selectedTagsの変更だけを監視
        Consumer<WriteProvider>(
          builder: (context, writeProvider, child) {
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: moodTagList.map((tag) {
                final isSelected = writeProvider.selectedTags.contains(tag.label);
                return FilterChip(
                  label: Text(tag.label),
                  avatar: Icon(tag.icon, size: 18),
                  selected: isSelected,
                  selectedColor: tag.color.withAlpha(80), // .withValuesは非推奨
                  onSelected: (val) {
                    if (val) {
                      writeProvider.selectedTags.add(tag.label);
                    } else {
                      writeProvider.selectedTags.remove(tag.label);
                    }
                    writeProvider.notify();
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}