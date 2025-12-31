// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// OpenWeatherMap API を利用して天気情報を取得するサービス。
///
/// 指定された緯度経度に基づき、現在の天気とその説明、気温を返します。
class WeatherService {
  /// OpenWeatherMap API にアクセスするためのAPIキー。
  final String apiKey;

  /// [WeatherService] のコンストラクタ。APIキーを受け取ります。
  WeatherService(this.apiKey);

  /// 指定された緯度と経度から天気情報を非同期で取得します。
  ///
  /// 成功した場合は「天気の説明 (気温°C)」形式の文字列を返し、
  /// 失敗した場合は `null` を返します。
  /// [lat] 緯度。
  /// [lon] 経度。
  Future<String?> getWeather(double lat, double lon) async {
    try {
      debugPrint("天気スタッフ：座標($lat, $lon)の天気を問い合わせます...");
      debugPrint("天気スタッフ：OpenWeatherMap API に接続中...");
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ja',
      );

      final response = await http.get(url);
      debugPrint("天気スタッフ：API からの応答を受信しました。ステータスコード: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final description = data['weather'][0]['description'];
        final temp = data['main']['temp'];
        final pressure = data['main']['pressure']; // 気圧データを取得

        final result =
            "$description (${temp.toStringAsFixed(1)}°C / ${pressure}hPa)"; // 気圧を追加
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

  /// 指定された過去の日付の天気情報を非同期で取得します（ダミー実装）。
  ///
  /// [lat] 緯度。
  /// [lon] 経度。
  /// [date] 過去の日付。
  Future<String> getHistoricalWeather(
    double lat,
    double lon,
    DateTime date,
  ) async {
    // API未契約のため、2秒待ってからダミーデータを返す
    await Future.delayed(const Duration(seconds: 2));
    debugPrint(
      "天気スタッフ (過去): 座標($lat, $lon) の ${date.toIso8601String()} の天気を問い合わせます (ダミー)",
    );
    return "晴れ (22.5°C) [Historical/Dummy]";
  }
}

/// グローバルにアクセス可能な [WeatherService] のインスタンス。
/// 初期化時に設定されることを想定しています。
late WeatherService weatherService;
