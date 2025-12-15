// lib/widgets/location_status_bar.dart

import 'package:flutter/material.dart';

class LocationStatusBar extends StatelessWidget {
  final String location;
  final String weather;
  
  const LocationStatusBar({
    super.key,
    required this.location,
    required this.weather,
  });

  // ヘルパー関数 1: 背景色
  Color _getStatusColor(String status) {
    if (status.contains('不明') || status.contains('権限なし') || status.contains('エラー')) {
      return Colors.red.shade100;
    } else {
      return Colors.blue.shade100; 
    }
  }

  // ヘルパー関数 2: ステータスアイコン
  IconData _getStatusIcon(String status) {
    if (status.contains('不明') || status.contains('権限なし') || status.contains('エラー')) {
      return Icons.error_outline;
    } else {
      return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDataReady = !location.contains('不明') && !weather.contains('不明');
    final isLocationFetching = location == '場所特定中...';
    
    // 天気から説明と温度を分離
    String weatherDescription = weather.split('/').first.trim();
    String temperature = weather.contains('/') ? weather.split('/').last.trim() : '';
    
    // ★ L38/L39の警告解消: weatherDescription と temperature は下記で使われているため警告は消えるはず

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: _getStatusColor(location),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            
            child: Row(
              mainAxisSize: MainAxisSize.min, // 幅自動フィックスを維持
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                // 1. ステータスアイコン (特定中ならローディング)
                if (!isLocationFetching) 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1-1. 位置情報のステータスアイコン (const は削除済)
                      Icon(
                        _getStatusIcon(location),
                        color: isDataReady ? Colors.blue.shade700 : Colors.red.shade700,
                        size: 20,
                      ),
                      
                      const SizedBox(width: 8),
                    ],
                  )
                else
                  const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ),
                
                // 2. アイコンとテキストの間隔を空ける
                const SizedBox(width: 8),
    
                // 3. 情報を Column で縦に配置 (2行表示)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. 1行目: 位置情報
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Iconにも const は付けない
                      if (!location.contains('不明')) 
                        Icon(Icons.location_pin, size: 14, color: Colors.blue.shade700),
                        
                      if (!location.contains('不明')) // アイコンが表示された場合のみスペースを入れる
                        const SizedBox(width: 4),                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),

                    // B. 2行目: 天気情報
                    if (isDataReady)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Iconにも const は付けない
                          Icon(Icons.wb_sunny_outlined, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            // ★ L95の不正文字エラー対策: weatherDescriptionとtemperatureを使用
                            '$weatherDescription ${temperature.isNotEmpty ? '| $temperature' : ''}',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}