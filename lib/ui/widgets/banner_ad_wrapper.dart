// lib/ui/widgets/banner_ad_wrapper.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/ad_service.dart';
import 'package:self_awareness_diary/domain/models/subscription_tier.dart'; // SubscriptionTierをインポート

/// バナー広告を表示するためのラッパーウィジェット。
///
/// 無料ユーザーにのみ広告を表示し、指定された「聖域」では広告を非表示にします。
/// 広告のロードと表示状態を管理します。
class BannerAdWrapper extends StatefulWidget {
  /// 広告を表示したくない「聖域」かどうか。
  final bool isSanctuary;

  const BannerAdWrapper({super.key, this.isSanctuary = false});

  @override
  State<BannerAdWrapper> createState() => _BannerAdWrapperState();
}

class _BannerAdWrapperState extends State<BannerAdWrapper> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsProvider>();

    // 無料ユーザーで、かつ聖域でない場合のみ広告をロード
    if (settings.currentTier == SubscriptionTier.free && !widget.isSanctuary) {
      if (_bannerAd == null) {
        _loadAd();
      }
    } else {
      // 有料ユーザーまたは聖域の場合は広告を破棄
      _bannerAd?.dispose();
      _bannerAd = null;
      if (_isAdLoaded) {
        // isAdLoadedの状態を更新するためにsetStateを呼ぶ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        });
      }
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 広告がロード済みの場合のみ表示エリアを確保
    if (_bannerAd != null && _isAdLoaded) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return const SizedBox.shrink(); // 広告がなければ何も表示しない
    }
  }
}
