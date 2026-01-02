// lib/domain/models/user_profile.dart

import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement; // Auto-incrementing primary key

  // Ego gram scores (e.g., from a 53-question personality test)
  int? cp; // Critical Parent
  int? np; // Nurturing Parent
  int? a; // Adult
  int? fc; // Free Child
  int? ac; // Adapted Child

  DateTime? lastDiagnosisDate; // Date of the last personality diagnosis
  double? currentGritLevel; // Current level of self-awareness 'grit'

  UserProfile({
    this.cp,
    this.np,
    this.a,
    this.fc,
    this.ac,
    this.lastDiagnosisDate,
    this.currentGritLevel,
  });
}
