// lib/ui/widgets/location_status_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/write_provider.dart';

/// 現在の場所と天気の情報を表示するステータスバーウィジェット。
///
/// 位置情報や気象情報が取得中の場合はローディング表示を行い、
/// 取得完了後はその情報をアイコンとテキストで分かりやすく表示します。
class LocationStatusBar extends StatelessWidget {
  const LocationStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WriteProvider>();
    final location = provider.tempLocation;
    final weather = provider.tempWeather;

    // 位置情報がまだ取得中の場合、ローディング表示
    if (location == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
        child: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('位置・気象情報を取得中...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    // 位置情報が取得できた場合、アイコンと情報を表示
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withAlpha((255 * 0.5).round()),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.wb_sunny,
            size: 14,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(weather ?? '取得中', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
