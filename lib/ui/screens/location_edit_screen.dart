// lib/ui/screens/location_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/location_setting.dart';
import '../../providers/settings_provider.dart';

class LocationEditScreen extends StatefulWidget {
  final LocationSetting location;

  const LocationEditScreen({super.key, required this.location});

  @override
  State<LocationEditScreen> createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends State<LocationEditScreen> {
  late final TextEditingController _labelController;

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

  Future<void> _deleteLocation() async {
    // contextを非同期ギャップを越えて使用しないように、先に取得しておく
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('場所の削除'),
        content: Text('「${widget.location.label}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('削除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      await context.read<SettingsProvider>().deleteLocation(widget.location.id);
      if (!mounted) return;
      
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('場所を削除しました。')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('場所の編集'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            onPressed: _deleteLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'ラベル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: widget.location.address),
              decoration: InputDecoration(
                labelText: '住所',
                border: const OutlineInputBorder(),
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                filled: true,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              onPressed: () async {
                final newLabel = _labelController.text;
                if (newLabel.isNotEmpty) {
                  // contextを非同期ギャップを越えて使用しないように、先に取得しておく
                  final settingsProvider = context.read<SettingsProvider>();
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  await settingsProvider.updateLocation(widget.location, newLabel);
                  if (!mounted) return;

                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('場所のラベルを更新しました。')),
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
