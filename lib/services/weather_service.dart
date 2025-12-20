// lib/services/weather_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final String apiKey;
  WeatherService(this.apiKey);

  Future<String> getWeather(double lat, double lon) async {
    if (apiKey.isEmpty) return "キー未設定";
    
    try {
      // 実際のリクエスト例（OpenWeatherを想定）
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&lang=ja&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['weather'][0]['description']; // 「曇りがち」など
      }
      return "取得失敗(${response.statusCode})";
    } catch (e) {
      return "通信エラー";
    }
  }
}

// 初期化用の late 変数
late WeatherService weatherService;