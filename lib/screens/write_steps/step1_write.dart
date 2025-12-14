// lib/screens/write_steps/step1_write.dart (最新版)

import 'package:flutter/material.dart';
import 'package:myapp/data/mood_tags.dart'; // ★★★ 新しく作成したタグデータをインポート ★★★

class Step1WriteScreen extends StatelessWidget {
  final Set<String> selectedTags;
  final ValueChanged<String> onTagSelected;

  const Step1WriteScreen({
    super.key,
    required this.selectedTags,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 便宜上、全てのタグ（無料版のみ）を分類ごとにフィルタリング
    final positiveTags = visibleMoodTags
        .where((t) => t.category == TagCategory.positive)
        .toList();
    final flatTags = visibleMoodTags
        .where((t) => t.category == TagCategory.flat)
        .toList();
    final negativeTags = visibleMoodTags
        .where((t) => t.category == TagCategory.negative)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 16.0, left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今の気分に合うタグを選択してください（複数選択可）',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // --- ポジティブタグエリア ---
          _buildTagSection(
            title: 'ポジティブ (${positiveTags.length}個)',
            tags: positiveTags,
            context: context,
          ),

          // --- フラットタグエリア ---
          _buildTagSection(
            title: 'フラット (${flatTags.length}個)',
            tags: flatTags,
            context: context,
          ),

          // --- ネガティブタグエリア ---
          _buildTagSection(
            title: 'ネガティブ (${negativeTags.length}個)',
            tags: negativeTags,
            context: context,
          ),

          const SizedBox(height: 30),

          // --- 有料版タグへの導線 (F-10) ---
          _buildPremiumAd(context),
        ],
      ),
    );
  }

  // タグセクションのウィジェット構築
  Widget _buildTagSection({
    required String title,
    required List<MoodTag> tags,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tags.first.color,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: tags.map((tag) {
              final isSelected = selectedTags.contains(tag.name);
              return ActionChip(
                label: Text(tag.name),
                onPressed: () => onTagSelected(tag.name),
                backgroundColor: isSelected
                    ? tag.color
                    : Colors.grey.shade200, // 選択時に色を付ける
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: tag.color,
                  width: 1.5,
                ), // ★★★ 枠線で分類を示す ★★★
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 有料プランへの広告ウィジェット
  Widget _buildPremiumAd(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.lock, color: Colors.indigo),
        title: Text(
          '$premiumTagCount個の感情タグを解放',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('より詳細な感情を言語化し、自己覚知の粒度を細かくしましょう。'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('【有料プラン】課金プラン画面へ遷移')));
        },
      ),
    );
  }
}
