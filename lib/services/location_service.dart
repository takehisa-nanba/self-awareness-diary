import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final String googleApiKey; // コンストラクタで受け取る
  LocationService(this.googleApiKey);

  Future<String> getCurrentCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "位置情報OFF";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "許可なし";
      }

      Position position = await Geolocator.getCurrentPosition();
      // 本来はここで逆ジオコーディングしますが、まずは座標か簡易表示で
      return "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
    } catch (e) {
      return "取得失敗";
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey&language=ja'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // 1. まずは一番詳細な住所を取得
          // 例: "日本、〒430-0926 静岡県浜松市中央区砂山町２６５−１６"
          String address = data['results'][0]['formatted_address'];

          // 2. 「日本、〒... 」の部分を正規表現で綺麗にカット（機能美）
          // 静岡県から始まるスッキリした住所にする
          address = address
              .replaceFirst(RegExp(r'^日本、'), '')
              .replaceFirst(RegExp(r'〒\d{3}-\d{4} '), '')
              .trim();

          // 3. もし「浜松駅」のようなランドマークが別の result にあれば、それも検討できますが
          // まずはこの詳細住所が最強です。
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