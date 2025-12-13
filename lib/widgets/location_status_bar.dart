// lib/widgets/location_status_bar.dart (新規作成)

import 'package:flutter/material.dart';

class LocationStatusBar extends StatelessWidget {
  final String location;
  final String weather;
  
  const LocationStatusBar({
    super.key,
    required this.location,
    required this.weather,
  });

  // ステータスに基づいて色を決定するヘルパー関数
  Color _getStatusColor(String status) {
    if (status.contains('取得中')) {
      return Colors.blue.shade100; // 取得中
    } else if (status.contains('エラー') || status.contains('タイムアウト') || status.contains('権限なし')) {
      return Colors.red.shade100; // エラー、タイムアウト、権限なし
    } else {
      return Colors.green.shade100; // 取得完了
    }
  }

  // ステータスに基づいてアイコンを決定するヘルパー関数
  IconData _getStatusIcon(String status) {
    if (status.contains('取得中')) {
      return Icons.refresh;
    } else if (status.contains('エラー') || status.contains('タイムアウト')) {
      return Icons.error_outline;
    } else if (status.contains('権限なし')) {
      return Icons.location_off;
    } else {
      return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画面下部に固定するためのSafeAreaを使用
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: _getStatusColor(location), // 位置情報ステータスに基づいて色を変える
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min, // コンテンツのサイズに合わせる
              children: [
                Icon(
                  _getStatusIcon(location),
                  color: _getStatusColor(location) == Colors.blue.shade100 
                      ? Colors.blue.shade800 
                      : Colors.black87,
                  size: 18,
                ),
                const SizedBox(width: 8),
                
                // 位置情報ステータス
                Text(
                  '${location.split(',').first} | ${weather.split('/').first.trim()}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}