import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final String googleApiKey;
  LocationService(this.googleApiKey);

  // 純粋に現在の座標だけを返す
  Future<Position?> getCurrentPosition() async {
    debugPrint("位置情報取得を開始...");
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("位置情報の権限が拒否されました。");
          return null;
        }
      }

      // 修正：timeLimit を追加して、20秒で必ず処理を終わらせる
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        forceAndroidLocationManager: false,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (e) {
      // タイムアウトした場合はここに来る
      debugPrint("GPS取得失敗またはタイムアウト: $e");
      return null;
    }
  }

  // Google APIを使って住所文字列に変換する
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey&language=ja',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          String address = data['results'][0]['formatted_address'];
          address = address
              .replaceFirst(RegExp(r'^日本、'), '')
              .replaceFirst(RegExp(r'〒\d{3}-\d{4} '), '')
              .trim();
          return address;
        }
      }
    } catch (e) {
      debugPrint("Google API 接続エラー: $e");
    }
    return "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }
}

late LocationService locationService;
