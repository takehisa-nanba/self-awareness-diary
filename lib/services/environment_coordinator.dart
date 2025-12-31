// lib/services/environment_coordinator.dart

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart'; // Isar サービスが準備完了か確認するため
import 'location_service.dart';
import 'weather_service.dart';
import 'isar_service.dart';

/// 現在の場所、天気、緯度、経度を含む環境データのデータ構造。
///
/// このクラスは、取得した環境情報をカプセル化し、他の部分に渡すために使用されます。
class EnvironmentData {
  /// 現在の場所の表示名（例：「自宅」「東京タワー」）。
  final String location;

  /// 現在の天気情報（例：「晴れ (25.0°C)」）。
  final String? weather;

  /// 現在地の緯度。
  final double? latitude;

  /// 現在地の経度。
  final double? longitude;

  EnvironmentData({
    required this.location,
    this.weather,
    this.latitude,
    this.longitude,
  });
}

/// デバイスの現在の環境情報（位置情報、天気）を取得、キャッシュ、および調整するサービス。
///
/// 登録済みの場所との照合を行い、よりユーザーフレンドリーな場所情報を提供します。
class EnvironmentCoordinator {
  final LocationService _locationService;
  final WeatherService _weatherService;
  final IsarService _isarService;

  // キャッシュ機能
  /// 環境データのキャッシュ。一定時間内は再利用されます。
  EnvironmentData? _cachedData;

  /// 最後にデータを取得した日時。
  DateTime? _lastFetchTime;

  /// キャッシュを更新するまでのしきい値時間（分）。
  static const int _refreshThresholdMinutes = 20;

  /// [EnvironmentCoordinator] のコンストラクタ。
  ///
  /// 依存する位置情報サービス、天気サービス、Isarサービスを受け取ります。
  EnvironmentCoordinator(
    this._locationService,
    this._weatherService,
    this._isarService,
  );

  /// 現在の環境情報（場所、天気）を非同期で取得します。
  ///
  /// 既存のキャッシュが有効な場合はキャッシュされたデータを返し、
  /// そうでない場合は、デバイスの位置情報、天気情報、および登録地点との照合を行います。
  Future<EnvironmentData> fetchFullData() async {
    // キャッシュの鮮度をチェック
    if (_cachedData != null && _lastFetchTime != null) {
      final diff = DateTime.now().difference(_lastFetchTime!);
      if (diff.inMinutes < _refreshThresholdMinutes) {
        debugPrint("EnvironmentCoordinator: キャッシュが有効なため、以前の情報を返します。");
        return _cachedData!;
      }
      debugPrint(
        "EnvironmentCoordinator: キャッシュが古いため（${diff.inMinutes}分経過）、情報を再取得します。",
      );
    }

    try {
      // Isarが準備できるまで待機
      int retry = 0;
      while (Isar.instanceNames.isEmpty && retry < 30) {
        debugPrint("EnvironmentCoordinator: Isarの準備を待っています... (${retry + 1})");
        await Future.delayed(const Duration(milliseconds: 200));
        retry++;
      }
      debugPrint("EnvironmentCoordinator: サービスの準備が完了しました。業務を開始します。");

      // 位置情報の取得
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        return EnvironmentData(location: "位置情報取得失敗");
      }
      debugPrint(
        "EnvironmentCoordinator: 現在の座標を取得しました (${pos.latitude}, ${pos.longitude})。",
      );

      await Future.delayed(const Duration(seconds: 3)); // 天気情報の取得前に少し待機

      // 天気情報の取得
      final weather = await _weatherService.getWeather(
        pos.latitude,
        pos.longitude,
      );
      final displayWeather = weather ?? "取得失敗（オフライン）";
      debugPrint("EnvironmentCoordinator: 天気を取得しました「$displayWeather」。");

      // 登録地点との照合
      final savedLocations = await _isarService.getLocations();
      for (var loc in savedLocations) {
        if (loc.latitude != null && loc.longitude != null) {
          double distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            loc.latitude!,
            loc.longitude!,
          );
          debugPrint(
            "EnvironmentCoordinator: 登録地点「${loc.label}」までの距離は $distance mです。",
          );

          if (distance <= 30.0) {
            debugPrint("EnvironmentCoordinator: 登録地点と一致しました: ${loc.label}");
            final data = EnvironmentData(location: loc.label, weather: weather);
            _cachedData = data;
            _lastFetchTime = DateTime.now();
            return data;
          }
        }
      }
      debugPrint("EnvironmentCoordinator: 登録地点には一致しませんでした。");

      // 住所の取得
      final address = await _locationService.getAddressFromLatLng(
        pos.latitude,
        pos.longitude,
      );

      final data = EnvironmentData(
        location: address,
        weather: weather,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _cachedData = data;
      _lastFetchTime = DateTime.now();
      return data;
    } catch (e) {
      debugPrint("EnvironmentCoordinator: 業務エラー: $e");
      return EnvironmentData(location: "識別エラー"); // エラー発生時は汎用エラーを返す
    }
  }

  /// 指定された過去の日付の天気情報を取得します。
  ///
  /// 内部で [WeatherService] のメソッドを呼び出します。
  Future<String> getHistoricalWeather(
    double lat,
    double lon,
    DateTime date,
  ) async {
    return await _weatherService.getHistoricalWeather(lat, lon, date);
  }
}

/// グローバルにアクセス可能な [EnvironmentCoordinator] のインスタンス。
/// アプリケーションの初期化時に設定されることを想定しています。
late EnvironmentCoordinator environmentCoordinator;
