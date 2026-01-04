// lib/domain/use_cases/get_universe_interpretation_use_case.dart

import 'package:flutter/foundation.dart';
import 'package:self_awareness_diary/domain/mappers/cosmic_map_to_prompt_mapper.dart';
import 'package:self_awareness_diary/domain/models/analysis_report.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/subscription_tier.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/providers/subscription_provider.dart';
import 'package:self_awareness_diary/services/gemini_service.dart';


class GetUniverseInterpretationParams {
  final AnalysisReport report;
  final Map<DiaryRecord, UniverseCoordinate> visibleRecordCoordinates;

  GetUniverseInterpretationParams({
    required this.report,
    required this.visibleRecordCoordinates,
  });
}

class GetUniverseInterpretationResult {
  final String? interpretation;
  final FeatureStatus status;

  GetUniverseInterpretationResult({this.interpretation, required this.status});
}

class GetUniverseInterpretationUseCase {
  final GeminiService _geminiService;
  final SubscriptionProvider _subscriptionProvider;

  GetUniverseInterpretationUseCase(this._geminiService, this._subscriptionProvider);

  Future<GetUniverseInterpretationResult> execute(GetUniverseInterpretationParams params) async {
    debugPrint(
      '[UseCase] triggerInterpretation START: Tier: ${_subscriptionProvider.currentTier}, Visible records: ${params.visibleRecordCoordinates.length}',
    );

    if (params.visibleRecordCoordinates.length < 3) {
      return GetUniverseInterpretationResult(status: FeatureStatus.notEnoughData);
    }

    final status = await _subscriptionProvider.checkFeatureStatus('ai_interpretation');

    String? interpretation;
    if (status == FeatureStatus.allowed) {
      try {
        final tempReport = AnalysisReport(
          records: params.visibleRecordCoordinates.keys.toList(),
          dateRange: params.report.dateRange,
          userProfile: params.report.userProfile,
          geminiService: _geminiService,
        );
        final promptSummary = CosmicMapToPromptMapper.toPrompt(tempReport);
        interpretation = await _geminiService.interpretCosmicMap(promptSummary);

        if (_subscriptionProvider.currentTier == SubscriptionTier.tier1) {
          _subscriptionProvider.recordUsage('ai_interpretation');
        }
      } catch (e) {
        interpretation = 'AIとの通信に失敗しました。';
      }
    } else if (status == FeatureStatus.needsReward) {
      interpretation = 'この機能は広告を視聴すると今週1回ご利用いただけます。';
    } else if (status == FeatureStatus.needsRewardMonthly) {
      interpretation = 'この機能は広告を視聴すると今月1回ご利用いただけます。';
    } else if (status == FeatureStatus.forbidden) {
      interpretation = 'この機能は上位プランでご利用いただけます。';
    }

    return GetUniverseInterpretationResult(interpretation: interpretation, status: status);
  }
}


