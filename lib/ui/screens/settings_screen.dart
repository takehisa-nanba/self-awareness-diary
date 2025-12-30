// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'developer_mode_screen.dart';
import 'location_edit_screen.dart';

/// アプリケーション全体の設定を管理する画面ウィジェット。
///
/// 一般設定、よく訪れる場所の登録と管理、開発者モードへのアクセス機能を提供します。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// [SettingsScreen] の状態を管理するクラス。
///
/// 入力フィールドのコントローラー、バージョンタップカウント、
/// および場所登録・編集に関するロジックを扱います。
class _SettingsScreenState extends State<SettingsScreen> {
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  int _versionTapCount = 0; // 開発者モードを有効にするためのタップカウント

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 「一般設定」セクションのタイトル。
          const Text(
            '一般設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          /// 「出来事から書き始める」設定のスイッチ。
          ///
          /// オンにすると、日記作成画面が気分選択ではなく出来事入力から始まります。
          Card(
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(80),
            child: SwitchListTile(
              title: const Text('「出来事」から書き始める'),
              subtitle: const Text('オンにすると、日記を書き始める画面が「出来事の入力」からになります。'),
              value: provider.startFromStep2,
              onChanged: (value) {
                provider.setStartFromStep2(value);
              },
              secondary: const Icon(Icons.edit_note),
            ),
          ),

          const SizedBox(height: 32),

          /// 「よく行く場所の登録」セクションのタイトル。
          const Text(
            'よく行く場所の登録',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          /// 場所登録に関する補足説明。
          Text(
            '登録した住所が自動的にラベル（自宅など）に変換されます。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          /// 場所登録フォーム。
          Card(
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(80),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ラベル入力フィールド（例：自宅、職場）。
                  TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'ラベル',
                      hintText: '例：自宅、職場',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      /// 住所入力フィールド。
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: '住所',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// 現在地を住所として自動入力するボタン。
                      IconButton.filledTonal(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                final addr = await provider
                                    .getCurrentLocationAddress();
                                if (addr != null) {
                                  setState(() {
                                    _addressController.text = addr;
                                  });
                                }
                              },
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// 場所を登録するボタン。
                  ///
                  /// ラベルと住所が入力されている場合のみ有効化され、
                  /// 過去の日記に関連する場所が見つかれば、更新の確認ダイアログが表示されます。
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_labelController.text.isEmpty ||
                            _addressController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ラベルと住所の両方を入力してください。'),
                            ),
                          );
                          return;
                        }

                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final label = _labelController.text;
                        final address = _addressController.text;

                        final count = await provider.addLocation(
                          label,
                          address,
                        );
                        if (!context.mounted) return;

                        if (count > 0) {
                          final bool? confirmed = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('過去の日記の更新'),
                              content: Text(
                                '近くに$count件の日記が見つかりました。場所を「$label」に更新しますか？',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => navigator.pop(false),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => navigator.pop(true),
                                  child: const Text('更新する'),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted) return;

                          if (confirmed == true &&
                              provider.lastLat != null &&
                              provider.lastLng != null) {
                            await provider.updatePastRecords(
                              label,
                              provider.lastLat!,
                              provider.lastLng!,
                            );
                            if (!context.mounted) return;
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('$count件の日記の場所を「$label」に更新しました。'),
                              ),
                            );
                          } else {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('場所を登録しました。（過去の日記は更新されませんでした）'),
                              ),
                            );
                          }
                        } else {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('場所を登録しました。')),
                          );
                        }
                        _labelController.clear();
                        _addressController.clear();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('登録する'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          /// 登録済み場所一覧のタイトル。
          const Text(
            '登録済み一覧',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),

          /// 登録された場所がない場合に表示されるメッセージ。
          provider.locations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      '登録された場所はありません',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              /// 登録された場所をリスト表示。
              ///
              /// 各項目をタップすると、その場所の編集画面へ遷移します。
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.locations.length,
                  itemBuilder: (context, index) {
                    final loc = provider.locations[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.place, size: 20),
                      ),
                      title: Text(loc.label),
                      subtitle: Text(
                        loc.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                LocationEditScreen(location: loc),
                          ),
                        );
                      },
                    );
                  },
                ),

          const SizedBox(height: 32),
          const Divider(),

          /// バージョン情報と開発者モード有効化のための GestureDetector。
          ///
          /// バージョン表示部分を7回タップすると開発者モード画面へ遷移します。
          GestureDetector(
            onTap: () {
              setState(() {
                _versionTapCount++;
              });
              if (_versionTapCount >= 7) {
                _versionTapCount = 0; // カウントをリセット
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DeveloperModeScreen(),
                  ),
                );
              }
            },
            child: ListTile(
              title: Text(
                'Version',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(
                '1.0.0-dev', // 必要に応じて実際のバージョンに置き換える
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 80), // FABとの重なりを避けるための余白
        ],
      ),
    );
  }
}
