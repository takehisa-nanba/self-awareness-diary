// lib/models/app_settings.dart

import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  String? value;
}
