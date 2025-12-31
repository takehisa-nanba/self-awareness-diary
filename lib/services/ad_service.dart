// lib/services/ad_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// アプリ内の広告（バナー、インタースティシャル、リワード）を管理するサービスクラス。
///
/// 開発中はテストIDを使用し、本番環境では実際の広告IDを使用します。
/// 各広告フォーマットのロードと表示をカプセル化します。
class AdService {
  // --- 広告ユニットID ---
  // kDebugModeがtrue（開発中）の場合、Google提供のテストIDを使用。
  // それ以外（本番環境）の場合は、実際の広告ユニットIDを使用（TODO: AdMobで取得したIDに置き換える）。

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // テスト用のバナーID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // TODO: 本番用のバナーIDに置き換える
    return "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx";
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      // テスト用のインタースティシャルID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    // TODO: 本番用のインタースティシャルIDに置き換える
    return "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx";
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      // テスト用のリワードID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    // TODO: 本番用のリワードIDに置き換える
    return "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx";
  }

  /// バナー広告をロードして、準備ができたBannerAdウィジェットを返します。
  ///
  /// 失敗した場合はnullを返します。
  Future<BannerAd?> loadBannerAd() async {
    final bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    try {
      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      return null;
    }
  }

  /// インタースティシャル広告を表示します。
  ///
  /// [onClosed] 広告が閉じた後に実行されるコールバック。
  void showInterstitialAd(VoidCallback onClosed) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onClosed(); // 広告を閉じたらコールバックを実行
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('InterstitialAd failed to show: $error');
              ad.dispose();
              onClosed(); // 失敗した場合もコールバックを実行
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          onClosed(); // ロードに失敗した場合もコールバックを実行
        },
      ),
    );
  }

  /// リワード広告を表示します。
  ///
  /// [onEarned] ユーザーが広告を最後まで視聴し、報酬を獲得したときに実行されるコールバック。
  void showRewardedAd(VoidCallback onEarned) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('RewardedAd failed to show: $error');
              ad.dispose();
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              debugPrint('Reward earned: ${reward.amount} ${reward.type}');
              onEarned(); // 報酬獲得時にコールバックを実行
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          // 報酬広告のロードに失敗した場合、報酬は得られない
        },
      ),
    );
  }
}
