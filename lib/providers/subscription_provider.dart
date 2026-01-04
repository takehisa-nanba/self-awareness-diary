// lib/providers/subscription_provider.dart

import 'package:flutter/foundation.dart';
import 'package:self_awareness_diary/domain/models/subscription_tier.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart';
import 'package:self_awareness_diary/domain/models/usage_log.dart';
import 'package:self_awareness_diary/services/isar_service.dart';
import 'package:isar/isar.dart'; // Isarをインポート

enum FeatureStatus { allowed, needsInterstitial, needsReward, needsRewardMonthly, forbidden }

class SubscriptionProvider with ChangeNotifier {
  SubscriptionTier _currentTier = SubscriptionTier.free;
  final IsarService _isarService;

  SubscriptionProvider(this._isarService, UserProfile? userProfile) {
    if (userProfile != null) {
      _currentTier = userProfile.tier;
    }
  }

  SubscriptionTier get currentTier => _currentTier;

  // ティアの更新。UserProfileの変更に基づいて呼び出される
  void updateTier(UserProfile? userProfile) {
    final newTier = userProfile?.tier ?? SubscriptionTier.free;
    if (_currentTier != newTier) {
      _currentTier = newTier;
      notifyListeners();
      debugPrint('SubscriptionProvider: Tier updated to $_currentTier');
    }
  }

  /// 本日の00:00:00を返します。
  DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 今週の月曜日00:00:00を返します。
  DateTime get _startOfThisWeek {
    final now = DateTime.now();
    // Dartのweekdayは月曜=1, 日曜=7
    // 月曜日を週の始まりとするため、(now.weekday - 1) * Duration(days: 1) を引く
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// 今月1日00:00:00を返します。
  DateTime get _startOfThisMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// 指定された期間からの機能の利用回数を取得します。
  Future<int> getUsedCount(String featureId, DateTime since) async {
    return await _isarService.isar.usageLogs
        .filter()
        .featureIdEqualTo(featureId)
        .usedAtGreaterThan(since.subtract(const Duration(microseconds: 1))) // sinceを含む
        .count();
  }

  /// 指定された機能の利用可否ステータスを返します。
  ///
  /// [featureId] チェックする機能のID (例: 'weather', 'ai_write_assist')
  Future<FeatureStatus> checkFeatureStatus(String featureId) async {
    switch (featureId) {
      case 'weather':
        if (_currentTier == SubscriptionTier.free) {
          return FeatureStatus.needsInterstitial;
        }
        return FeatureStatus.allowed;

      case 'ai_write_assist':
      case 'ai_write_eval':
        if (_currentTier == SubscriptionTier.free) {
          return FeatureStatus.forbidden;
        }
        return FeatureStatus.allowed;

      case 'ai_interpretation':
        if (_currentTier == SubscriptionTier.free) {
          final weeklyUsage = await getUsedCount(featureId, _startOfThisWeek);
          final monthlyUsage = await getUsedCount(featureId, _startOfThisMonth);

          if (weeklyUsage == 0) {
            return FeatureStatus.needsReward; // 今週利用がなければneedsReward
          } else if (monthlyUsage < 2) { // 今週使済みだが、今月2回未満ならneedsRewardMonthly
            return FeatureStatus.needsRewardMonthly;
          }
          return FeatureStatus.forbidden; // それ以外はforbidden
        } else if (_currentTier == SubscriptionTier.tier1) {
          final dailyUsage = await getUsedCount(featureId, _startOfToday);
          if (dailyUsage == 0) {
            return FeatureStatus.allowed; // 今日利用がなければallowed
          }
          return FeatureStatus.forbidden; // 1回以上利用済みならforbidden
        } else if (_currentTier == SubscriptionTier.tier2) {
          return FeatureStatus.allowed; // 無制限
        }
        break;

      case 'record_insight':
        if (_currentTier == SubscriptionTier.free) {
          return FeatureStatus.forbidden;
        } else if (_currentTier == SubscriptionTier.tier1) {
          return FeatureStatus.needsReward; // 広告視聴で利用可、回数制限なし
        } else if (_currentTier == SubscriptionTier.tier2) {
          return FeatureStatus.allowed; // 無制限
        }
        break;
    }
    return FeatureStatus.forbidden; // デフォルトでは許可しない
  }

  /// 機能の利用を記録します。
  ///
  /// [featureId] 利用した機能のID。
  Future<void> recordUsage(String featureId) async {
    final usageLog = UsageLog()
      ..featureId = featureId
      ..usedAt = DateTime.now();
    await _isarService.isar.writeTxn(() async {
      await _isarService.isar.usageLogs.put(usageLog);
    });
    notifyListeners();
    debugPrint('SubscriptionProvider: Usage recorded for $featureId');
  }
}
