// lib/models/diary_record.dart
import 'package:isar/isar.dart';
part 'diary_record.g.dart';

@collection
class DiaryRecord {
  Id? isarId;
  @Index(unique: true, replace: true)
  late String recordId;
  late DateTime recordDate;
  late List<String> moodTags;
  late int moodScore;    
  late String eventText; 
  String? selfAnalysis;  
  int? aiStabilityScore; 
  String? aiAnalysisReason; 
  String? location;
  String? weather;
  double? latitude;
  double? longitude;

  DiaryRecord({
    this.isarId,
    required this.recordId,
    required this.recordDate,
    required this.moodTags,
    required this.moodScore,
    required this.eventText,
    this.selfAnalysis,
    this.aiStabilityScore,
    this.aiAnalysisReason,
    this.location,
    this.weather,
    this.latitude,
    this.longitude,
  });

  bool get isGapLarge {
    if (aiStabilityScore == null) return false;
    return (moodScore * 10 - aiStabilityScore!).abs() >= 20;
  }

  String get timeString => "${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}";
}