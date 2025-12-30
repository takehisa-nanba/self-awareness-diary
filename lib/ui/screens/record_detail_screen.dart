// lib/ui/screens/record_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/diary_record.dart';
import '../../providers/detail_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/isar_service.dart'; // isarService にアクセスするためにインポート

/// 個々の日記レコードの詳細を表示する画面ウィジェット。
///
/// [DiaryRecord] オブジェクトを受け取り、その詳細情報、自己分析、
/// AI分析結果などを表示します。
class RecordDetailScreen extends StatelessWidget {
  /// 表示する日記レコード。
  final DiaryRecord record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    /// [DetailProvider] を作成し、[RecordDetailScreen] のウィジェットツリーで利用可能にします。
    return ChangeNotifierProvider(
      create: (context) => DetailProvider(
        record,
        context.read<GeminiService>(),
        context.read<SettingsProvider>(),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('記録の詳細')),
        body: const _DetailBody(),
      ),
    );
  }
}

/// 日記レコードの詳細コンテンツを構築するウィジェット。
///
/// 環境情報、出来事、気分タグ、自己分析、AI分析結果などを表示します。
class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetailProvider>();
    final record = provider.record;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 位置情報が未登録の場合に「場所を登録」ボタンを表示。
          FutureBuilder<bool>(
            future: provider.isLocationUnregistered(),
            builder: (context, snapshot) {
              final isUnregistered = snapshot.data ?? false;
              return Row(
                children: [
                  Expanded(
                    /// 環境情報（場所、天気、日時）を表示。
                    child: Text(
                      provider.environmentInfo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.done &&
                      isUnregistered)
                    TextButton.icon(
                      onPressed: () => _showLocationDialog(context, provider),
                      icon: const Icon(Icons.add_location_alt, size: 16),
                      label: const Text(
                        "場所を登録",
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  else if (snapshot.connectionState == ConnectionState.waiting)
                    /// 位置情報確認中はローディングインジケータを表示。
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          /// 「起きたこと」セクションのタイトル。
          const _SectionTitle("起きたこと"),
          const SizedBox(height: 8),
          /// 記録された出来事のテキスト。
          Text(record.eventText, style: const TextStyle(fontSize: 18)),
          /// 記録された気分タグがあれば表示。
          if (record.moodTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: record.moodTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 「振り返り（セルフアナリシス）」セクションのタイトル。
              const _SectionTitle("振り返り（セルフアナリシス）"),
              Row(
                children: [
                  /// 自己分析の研磨度に応じたアイコン。
                  Text(
                    record.polishingIcon,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  /// 研磨度が表示可能であればパーセンテージを表示。
                  if (record.polishingLevel > 0)
                    Text(
                      '研磨度: ${record.polishingLevel}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          /// 自己分析の表示または編集UI。
          if (provider.isEditing)
            _AnalysisEditor(provider: provider)
          else
            _AnalysisDisplay(provider: provider),

          const SizedBox(height: 32),

          /// 「AI分析結果」セクションのタイトル。
          const _SectionTitle("AI分析結果"),
          const SizedBox(height: 12),
          /// ユーザーの購読ティアに応じてAI分析カードまたはアップグレードのプレースホルダーを表示。
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              if (settings.currentTier == SubscriptionTier.tier2) {
                return _AIAnalysisCard(provider: provider);
              } else {
                return _buildUpgradePlaceholder(context);
              }
            },
          ),
        ],
      ),
    );
  }

  /// AI分析機能が利用できない場合に表示されるアップグレード促進用のプレースホルダー。
  Widget _buildUpgradePlaceholder(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.tertiaryContainer.withAlpha((255 * 0.5).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 32,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'AIによる高度な分析',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'アップグレードすると、AIがあなたの記録を分析し、パーソナライズされた洞察を提供します。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            /// プラン確認ボタン（実際の機能は未実装）。
            FilledButton.tonal(onPressed: () {}, child: const Text('プランを確認する')),
          ],
        ),
      ),
    );
  }

  /// 場所を登録するためのダイアログを表示します。
  ///
  /// 現在のレコードの位置情報を使用して新しい場所を登録し、
  /// 必要に応じて過去の類似記録を一括更新するオプションを提供します。
  void _showLocationDialog(BuildContext context, DetailProvider provider) {
    final controller = TextEditingController();
    bool updatePast = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("この場所を登録"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "場所の名前（例：自宅、職場）"),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text(
                  "過去の同じ場所の記録も書き換える",
                  style: TextStyle(fontSize: 12),
                ),
                value: updatePast,
                onChanged: (val) => setDialogState(() => updatePast = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("キャンセル"),
            ),
            ElevatedButton(
              onPressed: () async {
                final label = controller.text;
                if (label.isEmpty) return;

                final settingsProvider = context.read<SettingsProvider>();
                final historyProvider = context.read<HistoryProvider>();
                final navigator = Navigator.of(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final lat = provider.record.latitude;
                final lng = provider.record.longitude;
                bool doUpdatePast = updatePast;

                if (doUpdatePast && lat != null && lng != null) {
                  final nearbyRecords = await isarService.findNearbyRecords(
                    lat,
                    lng,
                  );
                  if (context.mounted && nearbyRecords.isNotEmpty) {
                    final bool? confirmed = await _showConfirmDialog(
                      context,
                      nearbyRecords.length,
                      label,
                    );
                    if (confirmed == false) {
                      doUpdatePast = false;
                    }
                  }
                }

                await settingsProvider.addNewLocationAndUpdateRecords(
                  label: label,
                  address: provider.record.location!,
                  lat: lat,
                  lng: lng,
                  updatePast: doUpdatePast,
                );

                await provider.updateLocationName(label);
                historyProvider.refreshHistory();

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('「$label」を登録しました')),
                );
              },
              child: const Text("登録"),
            ),
          ],
        ),
      ),
    );
  }

  /// 過去の記録を一括更新する際の確認ダイアログを表示します。
  Future<bool?> _showConfirmDialog(
    BuildContext context,
    int count,
    String label,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("過去記録の一括更新"),
        content: Text("同じ場所の記録が $count 件見つかりました。\nこれらもすべて「$label」に変更しますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("いいえ"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("はい、更新します"),
          ),
        ],
      ),
    );
  }
}

/// 自己分析のテキストを表示するウィジェット。
///
/// タップすることで編集モードに切り替わります。
class _AnalysisDisplay extends StatelessWidget {
  final DetailProvider provider;
  const _AnalysisDisplay({required this.provider});

  @override
  Widget build(BuildContext context) {
    final text = provider.record.selfAnalysis ?? "";
    return InkWell(
      onTap: () => provider.toggleEdit(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          text.isEmpty ? "タップして今の気持ちを書き留める" : text,
          style: TextStyle(
            fontSize: 16,
            color: text.isEmpty
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

/// 自己分析のテキストを編集するためのウィジェット。
class _AnalysisEditor extends StatefulWidget {
  final DetailProvider provider;
  const _AnalysisEditor({required this.provider});

  @override
  State<_AnalysisEditor> createState() => _AnalysisEditorState();
}

/// [_AnalysisEditor] の状態を管理するクラス。
class _AnalysisEditorState extends State<_AnalysisEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.provider.record.selfAnalysis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            /// 編集をキャンセルするボタン。
            TextButton(
              onPressed: () => widget.provider.toggleEdit(),
              child: const Text("キャンセル"),
            ),
            /// 自己分析の内容を更新するボタン。
            ElevatedButton(
              onPressed: () async {
                final historyProvider = context.read<HistoryProvider>();
                await widget.provider.updateSelfAnalysis(_controller.text);
                if (!mounted) return;
                historyProvider.refreshHistory();
              },
              child: const Text("更新"),
            ),
          ],
        ),
      ],
    );
  }
}

/// 各セクションのタイトルを表示するための再利用可能なウィジェット。
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// AIによる分析結果（感情の安定度と分析理由）を表示するカードウィジェット。
class _AIAnalysisCard extends StatelessWidget {
  final DetailProvider provider;
  const _AIAnalysisCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final record = provider.record;
    final color = provider.scoreColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "感情の安定度",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              /// AIによる感情の安定度スコア。
              Text(
                provider.hasAnalysis ? "${record.aiStabilityScore}%" : "--%",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          /// AIによる分析理由のテキスト。
          Text(
            record.aiAnalysisReason ?? "分析データはありません",
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
