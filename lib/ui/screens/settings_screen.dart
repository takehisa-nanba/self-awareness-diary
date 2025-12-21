// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    // ★ Scaffold を削除し、直接ウィジェットを返す
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('よく行く場所の登録', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('登録した住所が自動的にラベル（自宅など）に変換されます。', 
            style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          
          // 入力エリア (Card)
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                      // 現在地取得ボタン
                      IconButton.filledTonal(
                        onPressed: provider.isLoading ? null : () async {
                          final addr = await provider.getCurrentLocationAddress();
                          if (addr != null) {
                            setState(() {
                              _addressController.text = addr;
                            });
                          }
                        },
                        icon: provider.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_labelController.text.isNotEmpty && _addressController.text.isNotEmpty) {
                          await provider.addLocation(_labelController.text, _addressController.text);
                          _labelController.clear();
                          _addressController.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登録しました')));
                          }
                        }
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
          const Text('登録済み一覧', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          
          // 一覧エリア
          provider.locations.isEmpty 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('登録された場所はありません', style: TextStyle(color: Colors.grey))),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.locations.length,
                itemBuilder: (context, index) {
                  final loc = provider.locations[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.place, size: 20)),
                    title: Text(loc.label),
                    subtitle: Text(loc.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => provider.deleteLocation(loc.id),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}