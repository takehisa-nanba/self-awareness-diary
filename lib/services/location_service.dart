// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart' as geocoding;

/// デバイスの位置情報（GPS座標）およびその座標から住所を取得するサービス。
///
/// `geolocator` パッケージでデバイスの位置情報を取得し、
/// Google Geocoding API を利用して座標を住所に変換します。
class LocationService {
  /// Google Geocoding API にアクセスするためのAPIキー。
  final String googleApiKey;

  /// [LocationService] のコンストラクタ。Google API キーを受け取ります。
  LocationService(this.googleApiKey);

  /// デバイスの現在位置（緯度・経度）を非同期で取得します。
  ///
  /// 位置情報の権限が拒否された場合や、取得中にタイムアウトした場合は `null` を返します。
  /// タイムアウトは20秒に設定されています。
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

      // 20秒でタイムアウトするように修正
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        forceAndroidLocationManager: false,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (e) {
      // タイムアウトした場合など
      debugPrint("GPS取得失敗またはタイムアウト: $e");
      return null;
    }
  }

  /// 指定された緯度・経度から Google Geocoding API を使用して住所文字列を取得します。
  ///
  /// [lat] 緯度。
  /// [lng] 経度。
  /// 成功した場合は整形された住所文字列を、失敗した場合は緯度経度を文字列として返します。
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
          // 取得した住所から不要な部分を削除し整形
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
    // 住所が取得できない場合は緯度経度を返す
    return "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }

  /// 住所文字列から緯度・経度を取得します。
  Future<geocoding.Location?> getLatLngFromAddress(String address) async {
    try {
      final locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      debugPrint("住所からの緯度経度取得エラー: $e");
      return null;
    }
  }
}

/// グローバルにアクセス可能な [LocationService] のインスタンス。
/// アプリケーションの初期化時に設定されることを想定しています。
late LocationService locationService;
