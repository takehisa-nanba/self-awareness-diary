// lib/services/location_weather_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ★★★ 修正1: geocodingをインポート ★★★
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

// サービス層の公開インスタンス
final locationWeatherService = LocationWeatherService();

class LocationWeatherService {
  final String _openWeatherApiKeyName = 'OPEN_WEATHER_API_KEY';
  final String _weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // ★★★ 位置情報と天気を同時に取得し、マップ形式で返す ★★★
  // 返り値: { 'latitude': 'XX.XX', 'longitude': 'XX.XX', 'locationName': '場所名', 'weather': '天気' }
  Future<Map<String, String>> getLocationAndWeather() async {
    Position? position;
    String locationName = '不明';
    String weatherString = '不明';

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, 
          timeLimit: const Duration(seconds: 10),
        );
        
        // ★★★ 修正2: 緯度経度から場所名を取得するロジックを追加 ★★★
        locationName = await _getLocationName(position.latitude, position.longitude);
        print('外部データ: 場所名取得完了 ($locationName)');
        
        // ★★★ 天気情報取得をサブ関数で実行 ★★★
        try {
          weatherString = await _getWeather(position.latitude, position.longitude);
          print('外部データ: 天気情報取得完了 ($weatherString)');
        } catch (e) {
          weatherString = '天気取得エラー';
          print('外部データ: 天気取得サブエラー: $e');
        }
        
      } else {
        locationName = '権限なし';
        weatherString = '権限なし';
      }
      
    } catch (e) {
      print('外部データ取得メインエラー: $e');
      locationName = '取得エラー';
      weatherString = '取得エラー';
    }
    
    // 緯度経度はStringに変換して返す
    return {
      'latitude': position != null ? position.latitude.toString() : '0.0',
      'longitude': position != null ? position.longitude.toString() : '0.0',
      'locationName': locationName, 
      'weather': weatherString,
    };
  }
  
  // 逆ジオコーディング（緯度経度から場所名を取得）
  Future<String> _getLocationName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lon,
        localeIdentifier: "ja_JP",
      );
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        
        // ★★★ 修正箇所: 優先順位を変更し、subLocalityを最優先に試みる ★★★
        String preciseName = p.name ?? '';       // 最も具体的な場所名
        String subLocality = p.subLocality ?? ''; // 区や町名に相当
        String street = p.thoroughfare ?? '';    // ストリート名/通り名
        String city = p.locality ?? '';          // 市区町村
        
        String result = '';
        
        if (preciseName.isNotEmpty) {
          // name が取得できた場合、それをそのまま採用する
          result = preciseName; 
        } else if (subLocality.isNotEmpty) {
          // name が空の場合、subLocality (町名/区名) を採用
          result = subLocality;
        } else if (city.isNotEmpty && street.isNotEmpty) {
          // それでもなければ、市区町村 + ストリート
          result = "$city $street";
        } else if (city.isNotEmpty) {
          // 市区町村のみ
          result = city;
        }

        // 結果を最大18文字に制限し、長すぎる場合は...を付ける
        if (result.length > 18) {
          return "${result.substring(0, 18)}...";
        }
        
        return result.isNotEmpty ? result : "場所を特定できませんでした";
      }
      return "場所を特定できませんでした";

    } catch (e) {
      print('逆ジオコーディングエラー: $e');
      return "場所特定エラー";
    }
  }
  // 2. 気象情報を取得するサブ関数
  Future<String> _getWeather(double lat, double lon) async {
    // ★★★ 修正3: APIキー名に _openWeatherApiKeyName を使用 ★★★
    final String? apiKey = dotenv.env[_openWeatherApiKeyName]; 
    
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
        return '$weatherDescription / $temperature°C'; 
      } else {
        return '天気情報取得失敗 (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('デバッグ: 天気情報通信エラー: $e');
      return '天気情報通信エラー';
    }
  } 
}