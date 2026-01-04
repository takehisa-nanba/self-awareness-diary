// lib/providers/mood_tag_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import '../data/mood_tag_list.dart'; // allMoodTags のインポート
import '../domain/models/mood_tag.dart';
import 'settings_provider.dart'; // _settingsProvider のインポート

/// ユーザーのサブスクリプションティアに基づいて、利用可能な気分タグを管理するプロバイダークラス。
///
/// [SettingsProvider] を監視し、ユーザーのティアが変更された場合に
/// 利用可能な気分タグのリストを動的に更新します。
class MoodTagProvider extends ChangeNotifier {
  /// ユーザーのサブスクリプション設定を管理する [SettingsProvider] のインスタンス。
  final SettingsProvider _settingsProvider;

  /// [MoodTagProvider] のコンストラクタ。
  ///
  /// [SettingsProvider] をリッスンし、設定変更時に UI を更新できるよう通知します。
  MoodTagProvider(this._settingsProvider) {
    _settingsProvider.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsProvider.removeListener(_onSettingsChanged); // リスナーを解除してメモリリークを防ぐ
    super.dispose();
  }

  /// [SettingsProvider] から変更通知があったときに、自身も UI を更新するよう通知します。
  void _onSettingsChanged() {
    notifyListeners();
  }

  /// 現在のユーザーのサブスクリプションティアに基づいて、利用可能な気分タグのリストを返します。
  ///
  /// ユーザーのティア以上のタグはフィルタリングされます。
  List<MoodTag> get availableMoodTags {
    final userTierIndex = _settingsProvider.currentTier.index;

    // allMoodTagsから、ユーザーのTier以下のものだけを抽出する
    return allMoodTags.where((tag) => tag.tier.index <= userTierIndex).toList();
  }
}
