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
    notifyListeners(); 
  }

  // エラー解決：refを使わず _settingsProvider を直接参照
  List<MoodTag> get availableMoodTags {
    final userTierIndex = _settingsProvider.currentTier.index;
    
    // allMoodTagsから、ユーザーのTier以下のものだけを抽出する
    return allMoodTags.where((tag) => tag.tier.index <= userTierIndex).toList();
  }
}