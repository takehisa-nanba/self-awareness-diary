import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WeatherService {
  final String apiKey;
  WeatherService(this.apiKey);

  Future<String> getWeather(double lat, double lon) async {
    if (apiKey.isEmpty) return "APIキー未設定";
    
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&lang=ja&units=metric';
      final response = await http.get(Uri.parse(url));

      debugPrint("Weather API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final description = data['weather'][0]['description'];
        final temp = data['main']['temp'].round();
        return "$description ($temp°C)";
      } else {
        // ここで詳細なエラーをログに出す
        debugPrint("Weather API Error Body: ${response.body}");
        return "取得エラー(${response.statusCode})";
      }
    } catch (e) {
      debugPrint("Weather Service Exception: $e");
      return "通信エラー";
    }
  }
}

late WeatherService weatherService;