// lib/domain/models/usage_log.dart

import 'package:isar/isar.dart';

part 'usage_log.g.dart';

@collection
class UsageLog {
  Id id = Isar.autoIncrement;

  late String featureId; // 例: 'weather', 'ai_interpretation', 'record_insight'

  late DateTime usedAt;
}
