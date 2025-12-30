// lib/ui/screens/location_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/location_setting.dart';
import '../../providers/location_provider.dart';

/// 登録された場所の詳細を編集および削除するための画面ウィジェット。
///
/// ユーザーは場所のラベルを変更したり、場所の登録自体を削除したりできます。
class LocationEditScreen extends StatefulWidget {
  /// 編集対象となる [LocationSetting] オブジェクト。
  final LocationSetting location;

  const LocationEditScreen({super.key, required this.location});

  @override
  State<LocationEditScreen> createState() => _LocationEditScreenState();
}

/// [LocationEditScreen] の状態を管理するクラス。
///
/// 場所のラベル入力用のテキストコントローラーを管理します。
class _LocationEditScreenState extends State<LocationEditScreen> {
  late final TextEditingController _labelController; // ラベル入力用コントローラー

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.location.label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  /// 現在表示している場所の登録を削除します。
  ///
  /// ユーザーに削除の確認ダイアログを表示し、承認された場合に削除を実行します。
  Future<void> _deleteLocation() async {
    // 非同期処理の前にcontextを取得
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 削除確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('場所の削除'),
        content: Text('「${widget.location.label}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // キャンセル
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // 削除実行
            child: Text(
              '削除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return; // ダイアログが閉じられた後にウィジェットが破棄されている可能性を考慮

    if (confirmed == true) {
      // LocationProviderを介して場所を削除
      await context.read<LocationProvider>().deleteLocation(widget.location.id);
      if (!mounted) return;

      navigator.pop(); // 画面を閉じる
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('場所を削除しました。')), // 削除完了メッセージ
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('場所の編集'),
        actions: [
          /// 場所を削除するためのアイコンボタン。
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: _deleteLocation, // 削除処理を実行
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 場所のラベルを編集するためのテキストフィールド。
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'ラベル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// 場所の住所を表示するテキストフィールド（読み取り専用）。
            TextField(
              readOnly: true,
              controller: TextEditingController(text: widget.location.address),
              decoration: InputDecoration(
                labelText: '住所',
                border: const OutlineInputBorder(),
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                filled: true,
              ),
              maxLines: null, // 住所が長い場合に複数行で表示
            ),
            const SizedBox(height: 32),

            /// 変更を保存するためのボタン。
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              onPressed: () async {
                final newLabel = _labelController.text;
                if (newLabel.isNotEmpty) {
                  final locationProvider = context
                      .read<LocationProvider>(); // LocationProviderを取得
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  // LocationProviderを介して場所のラベルを更新
                  await locationProvider.updateLocation(
                    widget.location,
                    newLabel,
                  );
                  if (!mounted) return;

                  navigator.pop(); // 画面を閉じる
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('場所のラベルを更新しました。'),
                    ), // 更新完了メッセージ
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
