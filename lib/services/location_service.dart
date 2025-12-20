import 'package:geolocator/geolocator.dart';

class LocationService {
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
}

final locationService = LocationService();