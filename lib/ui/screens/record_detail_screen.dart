import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/diary_record.dart';
import '../../providers/detail_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/isar_service.dart';

class RecordDetailScreen extends StatelessWidget {
  final DiaryRecord record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DetailProvider(record),
      child: Scaffold(
        appBar: AppBar(title: const Text('記録の詳細')),
        body: const _DetailBody(),
      ),
    );
  }
}

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
          // 1. 環境情報 ＆ 場所登録ボタン
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              final isUnregistered = provider.isLocationUnregistered(settings);
              return Row(
                children: [
                  Expanded(
                    child: Text(provider.environmentInfo, 
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  if (isUnregistered)
                    TextButton.icon(
                      onPressed: () => _showLocationDialog(context, provider),
                      icon: const Icon(Icons.add_location_alt, size: 16),
                      label: const Text("場所を登録", style: TextStyle(fontSize: 12)),
                    ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          const _SectionTitle("起きたこと"),
          const SizedBox(height: 8),
          Text(record.eventText, style: const TextStyle(fontSize: 18)),
          
          const SizedBox(height: 32),

          // 2. 振り返りセクション（編集可能）
          const _SectionTitle("振り返り（セルフアナリシス）"),
          const SizedBox(height: 8),
          if (provider.isEditing)
            _AnalysisEditor(provider: provider)
          else
            _AnalysisDisplay(provider: provider),

          const SizedBox(height: 32),
          
          // 3. AI分析結果
          const _SectionTitle("AI分析結果"),
          const SizedBox(height: 12),
          _AIAnalysisCard(provider: provider),
        ],
      ),
    );
  }

// 場所登録ダイアログ（UIの表示はScreenの役目）
  void _showLocationDialog(BuildContext context, DetailProvider provider) {
    final controller = TextEditingController();
    bool updatePast = false; // 過去も書き換えるかのフラグ

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // チェックボックスの動的更新に必要
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
                title: const Text("過去の同じ場所の記録も書き換える", style: TextStyle(fontSize: 12)),
                value: updatePast,
                onChanged: (val) => setDialogState(() => updatePast = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
            ElevatedButton(
              onPressed: () async {
                final label = controller.text;
                if (label.isEmpty) return;

                final lat = provider.record.latitude;
                final lng = provider.record.longitude;

                // 1. 過去分の一括更新チェック
                if (updatePast && lat != null && lng != null) {
                  // 30m圏内の記録を点呼
                  final nearbyRecords = await isarService.findNearbyRecords(lat, lng);
                  
                  if (nearbyRecords.isNotEmpty) {
                    // 二段目の確認（context.mountedをチェックして呼び出し）
                    if (!context.mounted) return;
                    final bool? confirm = await _showConfirmDialog(context, nearbyRecords.length, label);
                    
                    if (confirm == true) {
                      await isarService.updateRecordsLocation(nearbyRecords, label);
                    }
                  }
                }

                // 2. SettingsProviderへの登録
                if (!context.mounted) return;
                await context.read<SettingsProvider>().addLocation(
                  label,
                  provider.record.location!,
                );

                // 3. 今回のレコード自体の表示名も更新
                await provider.updateLocationName(label);
                
                if (context.mounted) {
                  context.read<HistoryProvider>().refreshHistory();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('「$label」を登録しました'))
                  );
                }
              },
              child: const Text("登録"),
            ),
          ],
        ),
      ),
    );
  }

  // 二段目の確認ダイアログ
  Future<bool?> _showConfirmDialog(BuildContext context, int count, String label) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("過去記録の一括更新"),
        content: Text("同じ場所の記録が $count 件見つかりました。\nこれらもすべて「$label」に変更しますか？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("いいえ")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("はい、更新します"),
          ),
        ],
      ),
    );
  }
}

// --- 内部部品：振り返り表示 ---
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
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          text.isEmpty ? "タップして今の気持ちを書き留める" : text,
          style: TextStyle(
            fontSize: 16,
            color: text.isEmpty ? Colors.grey : Colors.black87,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// --- 内部部品：振り返り編集 ---
class _AnalysisEditor extends StatefulWidget {
  final DetailProvider provider;
  const _AnalysisEditor({required this.provider});

  @override
  State<_AnalysisEditor> createState() => _AnalysisEditorState();
}

class _AnalysisEditorState extends State<_AnalysisEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.provider.record.selfAnalysis);
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
            TextButton(onPressed: () => widget.provider.toggleEdit(), child: const Text("キャンセル")),
            ElevatedButton(
              onPressed: () async {
              // 1. await の前に必要な Provider を取得しておく（推奨）
                final historyProvider = context.read<HistoryProvider>();
                
                // 2. 非同期処理（保存）を実行
                await widget.provider.updateSelfAnalysis(_controller.text);
                
                // 3. 画面がまだ存在するか確認（StatefulWidget なら mounted でOK）
                if (!mounted) return;

                // 4. すでに取得済みの Provider を使ってリフレッシュ
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

// --- 内部部品：セクションタイトル（共通） ---
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }
}

// --- 内部部品：AI分析カード ---
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("感情の安定度", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                provider.hasAnalysis ? "${record.aiStabilityScore}%" : "--%",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.aiAnalysisReason ?? "分析データはありません",
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}