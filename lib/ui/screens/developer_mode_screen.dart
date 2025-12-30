// lib/ui/screens/developer_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/developer_service.dart';
import '../../providers/history_provider.dart';
import 'brand_splash_screen.dart'; // BrandSplashScreenをインポート

class DeveloperModeScreen extends StatelessWidget {
  const DeveloperModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 2つのProviderを監視する
    final settingsProvider = context.watch<SettingsProvider>();
    final devService = context.watch<DeveloperService>();

    return Scaffold(
      appBar: AppBar(title: const Text('開発者モード')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('サブスクリプション設定', style: Theme.of(context).textTheme.titleLarge),
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
                  icon: Icon(Icons.money_off),
                ),
                ButtonSegment(
                  value: SubscriptionTier.tier1,
                  label: Text('Tier 1'),
                  icon: Icon(Icons.star_border),
                ),
                ButtonSegment(
                  value: SubscriptionTier.tier2,
                  label: Text('Tier 2'),
                  icon: Icon(Icons.star),
                ),
              ],
              selected: {settingsProvider.currentTier},
              onSelectionChanged: (Set<SubscriptionTier> newSelection) {
                settingsProvider.setSubscriptionTier(newSelection.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                fixedSize: WidgetStateProperty.all(
                  Size(MediaQuery.of(context).size.width / 3.5, 48),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('データ生成', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.errorContainer.withAlpha(80),
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('テストデータを生成'),
                subtitle: devService.isLoading
                    ? LinearProgressIndicator(
                        value: devService.totalTestRecordCount > 0
                            ? devService.currentTestRecordCount /
                                  devService.totalTestRecordCount
                            : 0,
                        semanticsLabel: 'テストデータ生成中',
                      )
                    : const Text('過去50日間に約500件のランダムな日記を生成します。'),
                onTap: devService.isLoading
                    ? null
                    : () async {
                        // UI層でオーケストレーションを行う
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final historyProvider = context.read<HistoryProvider>();

                        // サービスにデータ生成を依頼
                        await devService.generateTestRecords();

                        // 処理完了後、UI関連の更新を行う
                        if (!context.mounted) return;

                        // 1. 履歴をリフレッシュ
                        await historyProvider.refreshHistory();

                        // 2. 特定の日付にジャンプ
                        final targetDate = DateTime.now().subtract(
                          const Duration(days: 25),
                        );
                        historyProvider.jumpToDate(targetDate);

                        // 3. 完了をユーザーに通知
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('テストデータの生成が完了しました。')),
                        );
                      },
                trailing: devService.isLoading
                    ? Text(
                        '${devService.currentTestRecordCount}/${devService.totalTestRecordCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : const Icon(Icons.add_circle_outline),
              ),
            ),
            const SizedBox(height: 32),
            Text('起動シーケンス', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withAlpha(80),
              child: ListTile(
                leading: const Icon(Icons.replay),
                title: const Text('初回起動フラグをリセット'),
                subtitle: const Text('次回のアプリ起動時にスプラッシュ画面を表示します。'),
                onTap: () async {
                  await settingsProvider.resetFirstLaunchFlag();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('初回起動フラグをリセットしました。')),
                  );
                },
              ),
            ),
            Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withAlpha(80),
              child: ListTile(
                leading: const Icon(Icons.preview_outlined),
                title: const Text('スプラッシュ画面をプレビュー'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrandSplashScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
