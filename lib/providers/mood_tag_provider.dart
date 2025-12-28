// lib/providers/mood_tag_provider.dart

import 'package:flutter/material.dart';
import '../data/mood_tag_list.dart';
import '../domain/models/mood_tag.dart';
import 'settings_provider.dart';

class MoodTagProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  MoodTagProvider(this._settingsProvider) {
    _settingsProvider.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsProvider.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    notifyListeners(); // 設定プロバイダの変更に応じてUIを更新
  }

  List<MoodTag> get availableMoodTags {
    switch (_settingsProvider.currentTier) {
      case SubscriptionTier.free:
        return freeMoodTagList;
      case SubscriptionTier.tier1:
        return tier1MoodTagList;
      case SubscriptionTier.tier2:
        return tier2MoodTagList;
    }
  }
}