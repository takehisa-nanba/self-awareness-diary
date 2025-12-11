// lib/screens/new_entry_screen.dart (最終コントローラーファイル)

import 'package:flutter/material.dart';
import '../main.dart'; // グローバルなisarインスタンスへのアクセス
import '../models/diary_entry.dart'; // DBモデル
import 'new_entry_steps/step1_mood_tag.dart'; // Step 1 UI
import 'new_entry_steps/step2_score_event.dart'; // Step 2 UI
import 'new_entry_steps/step3_language.dart'; // Step 3 UI

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  // ★★★ データと状態の管理 ★★★
  int _currentStep = 0;
  Set<String> _selectedMoodTags = {}; // Step 1 データ
  int _moodScore = 5; // Step 2 スコア (Sliderエラー回避のため初期値は1)
  final TextEditingController _eventController =
      TextEditingController(); // Step 2 出来事
  final TextEditingController _languageController =
      TextEditingController(); // Step 3 言語化

  @override
  void dispose() {
    _eventController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  // ★★★ バリデーション（入力チェック） ★★★
  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        // Step 1: 気分タグが1つ以上選択されていること
        return _selectedMoodTags.isNotEmpty;
      case 1:
        // Step 2: スコアが0より大きく、出来事が入力されていること
        // (Sliderの初期値が1なので、_moodScore > 0 は常にtrueに近いが、念のため)
        return _moodScore > 0 && _eventController.text.trim().isNotEmpty;
      case 2:
        // Step 3: 言語化は必須ではないため、常に有効（保存可能）
        return true;
      default:
        return false;
    }
  }

  // ★★★ ナビゲーションロジック ★★★
  void _nextStep() {
    if (!_isStepValid()) return;

    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        _saveEntry(); // 最終ステップなら保存
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        Navigator.pop(context); // 最初の画面なら閉じる
      }
    });
  }

  // ★★★ データ保存ロジック（F-1） ★★★
  Future<void> _saveEntry() async {
    // 必須入力の最終チェック
    if (!_isStepValid()) return;

    final newEntry = DiaryEntry(
      date: DateTime.now(),
      moodScore: _moodScore,
      content: _eventController.text,
      tags: _selectedMoodTags.toList(),
      languageDetail: _languageController.text,
    );

    // Isarへの書き込み処理
    await isar.writeTxn(() async {
      await isar.diaryEntrys.put(newEntry); // isar.diaryEntrys は自動生成されたアクセサ
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('記録を保存しました！')));
      // 画面を閉じて、履歴画面の更新を促す (trueを渡す)
      Navigator.pop(context, true);
    }
  }

  // ★★★ 有料プラン画面への遷移（F-10） ★★★
  void _goToSubscription() {
    // TODO: subscription_screen.dartを作成し、そこに遷移するロジックを実装
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('有料プラン画面へ遷移（未実装）')));
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid = _isStepValid();
    final bool isLastStep = _currentStep == 2;
    final String actionText = isLastStep ? '保存' : '次へ';
    final bool isButtonEnabled = isLastStep || isValid; // Step 3は常に有効

    // IndexedStackの子ウィジェットリスト (3ステップ画面)
    final List<Widget> steps = [
      // Step 1: 気分タグ選択
      Step1MoodTagScreen(
        selectedTags: _selectedMoodTags,
        onTagSelected: (tag) {
          setState(() {
            if (_selectedMoodTags.contains(tag)) {
              _selectedMoodTags.remove(tag);
            } else {
              _selectedMoodTags.add(tag);
            }
          });
        },
      ),

      // Step 2: スコア評価と出来事入力
      Step2ScoreEventScreen(
        moodScore: _moodScore,
        eventController: _eventController,
        onScoreChanged: (score) {
          setState(() {
            _moodScore = score;
          });
        },
        // ★★★ 修正箇所: テキストが変更されたら状態を更新するコールバックを追加 ★★★
        onContentChanged: () {
          setState(() {
            // 何もしなくても、setStateが呼ばれれば_isStepValidが再評価される
          });
        },
      ),

      // Step 3: 気分の言語化 (AI導線)
      Step3LanguageScreen(
        languageController: _languageController,
        onPremiumTap: _goToSubscription,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('新規記録 - ステップ ${_currentStep + 1} / 3'),
        leading: IconButton(
          icon: Icon(_currentStep == 0 ? Icons.close : Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),

      body: IndexedStack(index: _currentStep, children: steps),

      // ★★★ FAB (次へ/保存) の表示制御 ★★★
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isButtonEnabled ? _nextStep : null,
        label: Text(actionText),
        icon: Icon(isLastStep ? Icons.save : Icons.arrow_forward),
        backgroundColor: isButtonEnabled
            ? Theme.of(context)
                  .colorScheme
                  .primary // 有効時はテーマカラー
            : Colors.grey.shade400, // 無効時はグレー
        foregroundColor: isButtonEnabled ? Colors.white : Colors.grey.shade600,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
