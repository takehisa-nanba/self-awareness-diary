// lib/widgets/location_status_bar.dart

import 'package:flutter/material.dart';

class LocationStatusBar extends StatelessWidget {
  final String location;
  final String weather;
  final VoidCallback? onTap; // ★ 追加を受け取る
  
  const LocationStatusBar({
    super.key,
    required this.location,
    required this.weather,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    if (status.contains('不明') || status.contains('権限なし') || status.contains('エラー')) {
      return Colors.red.shade50; // エラー時はより薄い赤で警告感を出す
    } else {
      return Colors.blue.shade50; 
    }
  }

  IconData _getStatusIcon(String status) {
    if (status.contains('不明') || status.contains('権限なし') || status.contains('エラー')) {
      return Icons.refresh; // ★ エラー時は「更新」を促すアイコンに変更
    } else {
      return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDataReady = !location.contains('不明') && !weather.contains('不明');
    final isLocationFetching = location == '場所特定中...';
    final isError = location.contains('不明') || location.contains('権限なし') || location.contains('エラー');
    
    String weatherDescription = weather.split('/').first.trim();
    String temperature = weather.contains('/') ? weather.split('/').last.trim() : '';
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
        child: Card(
          elevation: isError ? 6 : 2, // エラー時は少し浮かせてボタンであることを強調
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: _getStatusColor(location),
          // ★ InkWell を追加してタップ可能にする
          child: InkWell(
            onTap: onTap, // 親から渡された再取得ロジックを実行
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isLocationFetching) 
                    Icon(
                      _getStatusIcon(location),
                      color: isError ? Colors.red.shade700 : Colors.blue.shade700,
                      size: 20,
                    )
                  else
                    const SizedBox(
                      width: 16, height: 16, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  
                  const SizedBox(width: 12),
      
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!location.contains('不明') && !isError) 
                            Icon(Icons.location_pin, size: 14, color: Colors.blue.shade700),
                          if (!location.contains('不明') && !isError)
                            const SizedBox(width: 4),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: isError ? Colors.red.shade900 : Colors.black87
                            ),
                          ),
                        ],
                      ),
                      if (isDataReady)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wb_sunny_outlined, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '$weatherDescription ${temperature.isNotEmpty ? "| $temperature" : ""}',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      // ★ エラー時のみ「タップして再取得」のガイドを出す
                      if (isError)
                        const Text(
                          'タップして再取得',
                          style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}