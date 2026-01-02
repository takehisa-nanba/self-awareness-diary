// lib/services/cosmic_interpretation_service.dart

import 'package:self_awareness_diary/domain/models/cosmic_observation.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/services/isar_service.dart';

/// 日記レコードデータを宇宙の物理パラメータとして解釈し、管理するサービス。
///
/// IsarService と連携し、[DiaryRecord] から [CosmicObservation] オブジェクトを生成・提供します。
class CosmicInterpretationService {
  final IsarService _isarService;

  CosmicInterpretationService(this._isarService);

  /// 特定の [DiaryRecord] から [CosmicObservation] を生成します。
  CosmicObservation interpretRecord(DiaryRecord record) {
    return CosmicObservation(record: record);
  }

  /// 指定された期間のすべての [DiaryRecord] を取得し、それらを [CosmicObservation] のリストとして返します。
  Future<List<CosmicObservation>> getCosmicObservationsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final records = await _isarService.getDiaryRecordsForDateRange(
      startDate,
      endDate,
    );
    return records.map((record) => interpretRecord(record)).toList();
  }

  // 他にも、特定の条件でフィルタリングされた観測結果を取得するメソッドなどを追加できます。
}
