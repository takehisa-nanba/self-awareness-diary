// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // debugPrintに必要です

class WeatherService {
  final String apiKey;

  WeatherService(this.apiKey);

  Future<String?> getWeather(double lat, double lon) async {
    try {
      // ★ ここが「堂々とした」報告です
      debugPrint("天気スタッフ：座標($lat, $lon)の天気を問い合わせます...");

      debugPrint("天気スタッフ：OpenWeatherMap API に接続中...");
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ja'
      );

      final response = await http.get(url);
      debugPrint("天気スタッフ：API からの応答を受信しました。ステータスコード: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final description = data['weather'][0]['description'];
        final temp = data['main']['temp'];
        
        final result = "$description (${temp.toStringAsFixed(1)}°C)";
        debugPrint("天気スタッフ：取得完了！ $result");
        return result;
      } else {
        debugPrint("天気スタッフ：通信エラー (${response.statusCode})");
        return null;
      }
    } catch (e) {
      debugPrint("天気スタッフ：予期せぬエラー: $e");
      return null;
    }
  }
}

late WeatherService weatherService;