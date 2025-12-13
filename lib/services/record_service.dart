// lib/services/record_service.dart (新規作成)

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint用

import '../main.dart'; // isarグローバル変数
import '../models/record.dart';

// ★★★ TODO: APIキーを.envから読み込むための場所を確保 ★★★
// (ここでは修正前のダミーキーを使用)
const String _openWeatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY'; 
const String _weatherBaseUrl = 'https://api.openweathermap.org/data/2.5/weather';

class RecordService {
  
  // ★★★ 外部サービス連携のロジックを分離 ★★★

  // 1. 気象情報を取得する関数
  Future<String> _getWeather(double lat, double lon) async {
    if (_openWeatherApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      return "晴れ/25°C (API設定前)"; 
    }
    
    final url = Uri.parse(
      '$_weatherBaseUrl?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric&lang=ja',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final weatherDescription = data['weather'][0]['description'] ?? '不明';
        final temperature = data['main']['temp'].toStringAsFixed(1) ?? 'N/A';
        return '$weatherDescription / $temperature°C';
      } else {
        debugPrint('天気情報取得失敗: ${response.statusCode}');
        return '天気情報取得失敗';
      }
    } catch (e) {
      debugPrint('天気情報通信エラー: $e');
      return '天気情報通信エラー';
    }
  }

  // 2. 位置情報と天候を取得するメインロジック
  Future<Map<String, String>> getLocationAndWeather() async {
    String locationString = '不明';
    String weatherString = '不明';
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best, 
          // ★★★ 修正箇所: タイムアウトを20秒に延長 ★★★
          timeLimit: const Duration(seconds: 20),
        );
        
        locationString = 'Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)}';
        weatherString = await _getWeather(position.latitude, position.longitude);
        
      } else {
        // 権限がない場合、不明のまま
      }
      
    } catch (e) {
      locationString = '取得エラー';
      weatherString = '取得エラー';
      debugPrint('外部データ取得エラー: $e');
    }
    
    return {'location': locationString, 'weather': weatherString};
  }
  
  // 3. 記録をDBに保存するメソッド
  Future<void> saveRecord(Record record) async {
     await isar.writeTxn(() async {
      await isar.records.put(record); 
    });
  }
}

// サービスを簡単に呼び出すためのインスタンス
final recordService = RecordService();