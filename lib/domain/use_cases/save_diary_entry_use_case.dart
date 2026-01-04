// lib/domain/use_cases/save_diary_entry_use_case.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/subscription_tier.dart';
import 'package:self_awareness_diary/domain/repositories/diary_repository.dart';
import 'package:self_awareness_diary/providers/diagnosis_provider.dart';
import 'package:self_awareness_diary/providers/subscription_provider.dart';
import 'package:self_awareness_diary/services/ad_service.dart';
import 'package:self_awareness_diary/services/gemini_service.dart';

/// SaveDiaryEntryUseCaseのためのパラメータを保持するクラス
class SaveDiaryEntryParams {
  final bool runAi;
  final String selfAnalysisText;
  final int? isarId;
  final bool isHistoricalFlow;
  final DateTime? historicalDate;
  final List<String> moodTags;
  final int moodScore;
  final String eventText;
  final String? location;
  final String? weather;
  final double? latitude;
  final double? longitude;

  SaveDiaryEntryParams({
    required this.runAi,
    required this.selfAnalysisText,
    this.isarId,
    required this.isHistoricalFlow,
    this.historicalDate,
    required this.moodTags,
    required this.moodScore,
    required this.eventText,
    this.location,
    this.weather,
    this.latitude,
    this.longitude,
  });
}

/// 日記のエントリを保存するビジネスロジックをカプセル化するUse Case
class SaveDiaryEntryUseCase {
  final DiaryRepository _diaryRepository;
  final GeminiService _geminiService;
  final AdService _adService;
  final SubscriptionProvider _subscriptionProvider;
  final DiagnosisProvider _diagnosisProvider;

  SaveDiaryEntryUseCase(
    this._diaryRepository,
    this._geminiService,
    this._adService,
    this._subscriptionProvider,
    this._diagnosisProvider,
  );

  Future<void> execute(SaveDiaryEntryParams params) async {
    Map<String, dynamic>? analysisResult;
    bool shouldRunAi = params.runAi;

    if (_subscriptionProvider.currentTier == SubscriptionTier.free) {
      debugPrint("FreeティアのためAI分析は実行されません。");
      shouldRunAi = false;
    }

    if (params.selfAnalysisText.isNotEmpty && shouldRunAi) {
      final status = await _subscriptionProvider.checkFeatureStatus('ai_write_eval');

      if (status == FeatureStatus.allowed) {
        debugPrint("AI Write Eval: Allowed. Performing AI analysis.");
        analysisResult = await _performAiAnalysis(params.selfAnalysisText);
        _subscriptionProvider.recordUsage('ai_write_eval');
      } else if (status == FeatureStatus.needsReward) {
        debugPrint("AI Write Eval: Needs Reward. Showing Rewarded Ad for AI analysis.");
        final adCompleter = Completer<Map<String, dynamic>?>();
        _adService.showRewardedAd(() async {
          debugPrint("Rewarded Ad shown. Performing AI analysis.");
          final result = await _performAiAnalysis(params.selfAnalysisText);
          _subscriptionProvider.recordUsage('ai_write_eval');
          adCompleter.complete(result);
        });
        analysisResult = await adCompleter.future;
      } else if (status == FeatureStatus.forbidden) {
        debugPrint("AI Write Eval: Forbidden. AI analysis skipped for this tier.");
        analysisResult = {'score': null, 'reason': 'この機能は上位プラン限定です。'};
      }
    } else {
      debugPrint("No self-analysis text provided or runAi is false. AI analysis skipped.");
    }

    final record = DiaryRecord(
      isarId: params.isarId,
      recordId: params.isarId != null
          ? (await _diaryRepository.getRecordByIsarId(params.isarId!))!.recordId
          : const Uuid().v4(),
      recordDate: params.isHistoricalFlow ? params.historicalDate! : DateTime.now(),
      moodTags: List.from(params.moodTags),
      moodScore: params.moodScore,
      eventText: params.eventText,
      selfAnalysis: params.selfAnalysisText,
      aiStabilityScore: analysisResult?['score'],
      aiAnalysisReason: analysisResult?['reason'],
      location: params.location,
      weather: params.weather,
      latitude: params.latitude,
      longitude: params.longitude,
    );

    await _diaryRepository.saveRecord(record);
    debugPrint("日記${params.isarId == null ? '保存' : '更新'}完了: ${record.recordId}");
  }

  Future<Map<String, dynamic>?> _performAiAnalysis(String selfAnalysisText) async {
    try {
      final userProfile = _diagnosisProvider.userProfile;
      final analysis = await _geminiService.analyzeStability(selfAnalysisText, userProfile);
      return {'score': analysis['score'], 'reason': analysis['reason']};
    } catch (e) {
      debugPrint("AI Analysis Error: $e");
      return null;
    }
  }
}
