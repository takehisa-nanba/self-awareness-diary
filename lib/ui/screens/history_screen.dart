import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../widgets/app_shell.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // HistoryProviderを監視
    final provider = context.watch<HistoryProvider>();

    return AppShell(
      title: '過去の記録',
      child: ListView.builder(
        itemCount: provider.records.length,
        itemBuilder: (context, index) {
          final record = provider.records[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${record.moodScore}')),
            title: Text(record.eventText),
            subtitle: Text(record.moodTags.join(', ')),
            trailing: Text(record.timeString),
          );
        },
      ),
    );
  }
}