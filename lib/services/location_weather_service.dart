// lib/services/location_weather_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ★★★ 追記 ★★★

class LocationWeatherService {
  // ★★★ APIキーはここで一元管理 ★★★
  final String _openWeatherApiKey = 'OPEN_WEATHER_API_KEY';
  final String _weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // ★★★ 位置情報と天気を同時に取得し、マップ形式で返す ★★★
  Future<Map<String, String>> getLocationAndWeather() async {
    Position? position;
    String locationString = '不明';
    String weatherString = '不明';

    bool locationSuccess = false;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, 
        );
        
        locationString = 'Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)}';
        locationSuccess = true; // 位置情報取得に成功

        // ★★★ 天気情報取得を別の try-catch でラップ ★★★
        try {
          weatherString = await _getWeather(position.latitude, position.longitude);
          debugPrint('デバッグ: 天気情報取得完了');
        } catch (e) {
          weatherString = '天気取得エラー';
          debugPrint('デバッグ: 天気取得サブエラー: $e');
        }
        
      } else {
        locationString = '権限なし';
        weatherString = '権限なし';
      }
      
    } catch (e) {
      // 位置情報取得自体に失敗した場合のみ、locationStringを変更
      if (!locationSuccess) {
        locationString = '取得エラー';
        weatherString = '取得エラー'; // 位置情報がないため、天気も取得エラー
      }
      debugPrint('デバッグ: 外部データ取得メインエラー: $e');
    }
    
    return {'location': locationString, 'weather': weatherString};
  }

  // 2. 気象情報を取得するサブ関数
  Future<String> _getWeather(double lat, double lon) async {
    final String? apiKey = dotenv.env[_openWeatherApiKey];
    
    // 1. APIキーがない場合のチェック
    if (apiKey == null || apiKey.isEmpty) {
      return "天気取得エラー (APIキー未設定)"; 
    }
    
    final url = Uri.parse(
      '$_weatherBaseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ja', 
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final weatherDescription = data['weather'][0]['description'] ?? '不明';
        final temperature = data['main']['temp'].toStringAsFixed(1) ?? 'N/A';
        return '$weatherDescription / $temperature°C'; // ★★★ 成功パス
      } else {
        return '天気情報取得失敗 (${response.statusCode})'; // ★★★ 失敗パス (ステータスコードエラー)
      }
    } catch (e) {
      // ネットワーク通信エラーやJSONパースエラー
      debugPrint('デバッグ: 天気情報通信エラー: $e');
      return '天気情報通信エラー'; // ★★★ 失敗パス (例外エラー)
    }
  } // _getWeather
} // class LocationWeatherService