import 'package:isar/isar.dart';

part 'location_setting.g.dart';

@collection
class LocationSetting {
  Id id = Isar.autoIncrement;

  String label = ''; // 「自宅」「職場」など
  String address = ''; // 表示用の住所文字列

  double? latitude; // 距離判定用の緯度
  double? longitude; // 距離判定用の経度

  LocationSetting({
    this.label = '',
    this.address = '',
    this.latitude,
    this.longitude,
  });
}
