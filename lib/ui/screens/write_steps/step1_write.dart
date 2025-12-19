import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';
import '../../../data/mood_tag_list.dart';

class Step1Write extends StatelessWidget {
  const Step1Write({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WriteProvider>();

    return Column(
      children: [
        Text('気分スコア: ${provider.moodScore}', style: const TextStyle(fontSize: 18)),
        Slider(
          value: provider.moodScore.toDouble(),
          min: 1, max: 10, divisions: 9,
          onChanged: (v) { provider.moodScore = v.round(); provider.update(); },
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          children: moodTagList.map((tag) {
            final isSelected = provider.selectedTags.contains(tag.label);
            return FilterChip(
              label: Text(tag.label),
              avatar: Icon(tag.icon, size: 18),
              selected: isSelected,
              selectedColor: tag.color.withValues(alpha: 0.3),
              onSelected: (val) {
                val ? provider.selectedTags.add(tag.label) : provider.selectedTags.remove(tag.label);
                provider.update();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}