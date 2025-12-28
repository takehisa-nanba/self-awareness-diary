// lib/ui/screens/developer_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class DeveloperModeScreen extends StatelessWidget {
  const DeveloperModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('開発者モード'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'サブスクリプション設定',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'アプリのサブスクリプションの状態を強制的に切り替えます。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<SubscriptionTier>(
              segments: const <ButtonSegment<SubscriptionTier>>[
                ButtonSegment(
                    value: SubscriptionTier.free,
                    label: Text('無料版'),
                    icon: Icon(Icons.money_off)),
                ButtonSegment(
                    value: SubscriptionTier.tier1,
                    label: Text('Tier 1'),
                    icon: Icon(Icons.star_border)),
                ButtonSegment(
                    value: SubscriptionTier.tier2,
                    label: Text('Tier 2'),
                    icon: Icon(Icons.star)),
              ],
              selected: {provider.currentTier},
              onSelectionChanged: (Set<SubscriptionTier> newSelection) {
                provider.setSubscriptionTier(newSelection.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                fixedSize: WidgetStateProperty.all(
                  Size(MediaQuery.of(context).size.width / 3.5, 48),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'データ生成',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Card(
              elevation: 0,
              color:
                  Theme.of(context).colorScheme.errorContainer.withAlpha(80),
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('テストデータを生成'),
                subtitle: provider.isLoading
                    ? LinearProgressIndicator(
                        value: provider.totalTestRecordCount > 0
                            ? provider.currentTestRecordCount /
                                provider.totalTestRecordCount
                            : 0,
                        semanticsLabel: 'テストデータ生成中',
                      )
                    : const Text('過去50日間に約500件のランダムな日記を生成します。'),
                onTap: provider.isLoading
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        await provider.addTestRecords();
                        if (!context.mounted) return;
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('テストデータの生成が完了しました。')),
                        );
                      },
                trailing: provider.isLoading
                    ? Text(
                        '${provider.currentTestRecordCount}/${provider.totalTestRecordCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : const Icon(Icons.add_circle_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
