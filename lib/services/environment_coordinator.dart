import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'location_service.dart';
import 'weather_service.dart';
import 'isar_service.dart';

// 返却用のデータ構造
class EnvironmentData {
  final String location;
  final String? weather;
  final double? latitude;
  final double? longitude;
  EnvironmentData({
    required this.location,
    this.weather,
    this.latitude,
    this.longitude,
  });
}

// lib/services/environment_coordinator.dart

class EnvironmentCoordinator {
  final LocationService _locationStaff;
  final WeatherService _weatherStaff;
  final IsarService _isarStaff;

  // --- キャッシュ機能の追加 ---
  EnvironmentData? _cachedData;
  DateTime? _lastFetchTime;
  static const int _refreshThresholdMinutes = 20;
  // --------------------------

  EnvironmentCoordinator(
    this._locationStaff,
    this._weatherStaff,
    this._isarStaff,
  );

  Future<EnvironmentData> fetchFullData() async {
    // --- キャッシュチェックロジック ---
    if (_cachedData != null && _lastFetchTime != null) {
      final diff = DateTime.now().difference(_lastFetchTime!);
      if (diff.inMinutes < _refreshThresholdMinutes) {
        debugPrint("店長：キャッシュが有効です。以前の情報を利用します。");
        return _cachedData!;
      }
      debugPrint("店長：キャッシュが古いため（${diff.inMinutes}分経過）、情報を再取得します。");
    }
    // ---------------------------------

    try {
      // ★ 店長による点呼：DBスタッフが準備できるまで待機
      int retry = 0;
      while (Isar.instanceNames.isEmpty && retry < 30) {
        debugPrint("店長：スタッフの準備を待っています... (${retry + 1})");
        await Future.delayed(const Duration(milliseconds: 200)); // 0.2秒ずつ確認
        retry++;
      }

      debugPrint("店長：全員揃ったな。業務を開始する！");

      // ここから初めて位置情報の取得（スタッフへの指示）を開始
      debugPrint("店長：位置情報スタッフ、現在の座標を教えてくれ！");
      final pos = await _locationStaff.getCurrentPosition();
      if (pos == null) {
        return EnvironmentData(location: "位置情報取得失敗");
      }
      debugPrint("店長：現在の座標は (${pos.latitude}, ${pos.longitude}) だな。");

      await Future.delayed(const Duration(seconds: 3)); // 少し待機してから次の業務へ

      // 3. 【修正】確定した座標を使って、天気スタッフに問い合わせる
      debugPrint("店長：天気スタッフ、現在の天気を教えてくれ！");
      final weather = await _weatherStaff.getWeather(
        pos.latitude,
        pos.longitude,
      );

      final displayWeather = weather ?? "取得失敗（オフライン）";
      debugPrint("店長：天気は「$displayWeather」だな。");

      // 4. 登録地点（Isar）との照合
      debugPrint("店長：DBスタッフ、登録地点を確認してくれ！");
      final savedLocations = await _isarStaff.getLocations();
      for (var loc in savedLocations) {
        if (loc.latitude != null && loc.longitude != null) {
          double distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            loc.latitude!,
            loc.longitude!,
          );
          debugPrint("店長：登録地点「${loc.label}」までの距離は $distance m だな。");

          if (distance <= 30.0) {
            debugPrint("【節約】登録地点と一致: ${loc.label}");
            final data = EnvironmentData(location: loc.label, weather: weather);
            _cachedData = data; // キャッシュを更新
            _lastFetchTime = DateTime.now(); // 取得時刻を更新
            return data;
          }
        }
      }
      debugPrint("店長：登録地点には一致しなかったな。");

      // 5. 登録地点になければ住所を取得（Google API）
      debugPrint("店長：位置情報スタッフ、住所を教えてくれ！");
      final address = await _locationStaff.getAddressFromLatLng(
        pos.latitude,
        pos.longitude,
      );

      final data = EnvironmentData(
        location: address,
        weather: weather,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _cachedData = data; // キャッシュを更新
      _lastFetchTime = DateTime.now(); // 取得時刻を更新
      return data;
    } catch (e) {
      debugPrint("店長業務エラー: $e");
      return EnvironmentData(location: "識別エラー");
    }
  }
}

late EnvironmentCoordinator environmentCoordinator;
