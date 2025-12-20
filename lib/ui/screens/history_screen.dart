import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/app_shell.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // 画面が開いた時に実行
    Future.microtask(() {
      if (!mounted) return; // 画面が消えていたら何もしない
      context.read<HistoryProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return AppShell(
      title: '過去の記録',
      child: provider.records.isEmpty
          ? const Center(child: Text('まだ記録がありません'))
          : ListView.builder(
              itemCount: provider.records.length,
              itemBuilder: (context, index) {
                final record = provider.records[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${record.moodScore}', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(record.eventText, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('気分: ${record.moodTags.join(", ")}'),
                        // ★ここ！位置と天気を表示
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            Text(' ${record.location ?? "不明"}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            const Icon(Icons.wb_sunny, size: 14, color: Colors.grey),
                            Text(' ${record.weather ?? "不明"}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(record.timeString, style: const TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }
}