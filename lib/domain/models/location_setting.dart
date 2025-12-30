// C:\Users\ramp1\Desktop\self-awareness-diary\lib\domain\models\location_setting.dart

import 'package:isar/isar.dart';

part 'location_setting.g.dart';

/// ユーザーが登録した特定の場所（例：自宅、職場）の情報を保持するデータモデル。
/// Isarデータベースに永続化されることを示す @collection アノテーションが付与されています。
@collection
class LocationSetting {
  /// Isarが自動的に割り当てる一意のID。
  Id id = Isar.autoIncrement;

  /// ユーザーが設定する場所のラベル（例：「自宅」「職場」）。
  String label = '';

  /// 表示用の整形された住所文字列。
  String address = '';

  /// 場所の緯度。距離の計算に使用されます。
  double? latitude;

  /// 場所の経度。距離の計算に使用されます。
  double? longitude;

  /// [LocationSetting] のコンストラクタ。
  LocationSetting({
    this.label = '',
    this.address = '',
    this.latitude,
    this.longitude,
  });
}
