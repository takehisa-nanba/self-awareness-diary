// lib/screens/new_entry_screen.dart (AppShell統合版 - データ入力・保存特化)

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async'; 

import '../models/record.dart';
import '../services/record_service.dart'; 
import '../services/location_weather_service.dart'; 
import '../widgets/location_status_bar.dart';
import '../widgets/app_shell.dart'; // ★★★ AppShellをインポート ★★★

import 'new_entry_steps/step1_mood_tag.dart';
import 'new_entry_steps/step2_score_event.dart';
import 'new_entry_steps/step3_language.dart';

import 'subscription_screen.dart'; // 有料プラン画面のみ必要

import '../widgets/app_shell.dart' show AppShell, kAppHeaderH;

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  // ★★★ サービスインスタンスの生成 ★★★
  final _recordService = RecordService();
  final _locationWeatherService = LocationWeatherService();
  final _uuid = const Uuid();

  // ★★★ データと状態の管理 ★★★
  int _currentStep = 0;
  final Set<String> _selectedMoodTags = {};
  int _moodScore = 5;
  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  String locationString = '位置情報取得中...'; 
  String weatherString = '天気取得中...'; 
  
  bool _isWaitingForLocation = false; // 待機アニメーション表示用フラグ

  @override
  void dispose() {
    _eventController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocationAndWeather(); // 画面起動と同時に取得開始
  }

  // ★★★ 1. 位置情報と天気を非同期で取得するメソッド ★★★
  Future<void> _loadLocationAndWeather() async {
    final result = await _locationWeatherService.getLocationAndWeather();
    
    if (mounted) {
      setState(() {
      locationString = result['location']!;
      weatherString = result['weather']!;
      });
      debugPrint('デバッグ: 位置情報と天気の取得が完了しました。');
    }
  }
  
  // ★★★ 2. 画面リセットと再取得のトリガー ★★★
  void _resetEntry() {
    setState(() {
      _currentStep = 0; 
      _selectedMoodTags.clear(); 
      _moodScore = 5; 
      _eventController.clear(); 
      _languageController.clear(); 

      locationString = '位置情報取得中...';
      weatherString = '天気取得中...';
      _loadLocationAndWeather(); // 新しい記録のために再取得を開始
    });
  } 

  // ★★★ 3. 待機ロジック (20秒のポーリングループ) ★★★
  Future<void> _awaitLocationAndWeather() async {
    setState(() {
      _isWaitingForLocation = true; // アニメーション開始
    });
    
    const timeoutDuration = Duration(seconds: 20); 
    DateTime startTime = DateTime.now();

    // 待機アニメーションを表示しながら、バックグラウンドの取得処理の完了をポーリング
    while ((locationString == '位置情報取得中...' || weatherString == '天気取得中...') &&
          DateTime.now().difference(startTime) < timeoutDuration) {
      await Future.delayed(const Duration(milliseconds: 100)); // 100msごとにチェック
    }

    bool completedSuccessfully = 
      locationString != '位置情報取得中...' && weatherString != '天気取得中...';

    setState(() {
      _isWaitingForLocation = false; // アニメーションを停止
      
      // 20秒待っても取得できなかった場合、状態を「タイムアウト」に更新
      if (!completedSuccessfully) {
        if (locationString == '位置情報取得中...') {
          locationString = 'タイムアウト';
        }
        if (weatherString == '天気取得中...') {
          weatherString = 'タイムアウト';
        }
      }
    });

    if (mounted) {
      _saveEntry(isResuming: true); // 待機が完了（またはタイムアウト）した後、保存処理を再開
    }
  }

  // ★★★ 4. バリデーション（入力チェック） ★★★
  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedMoodTags.isNotEmpty;
      case 1:
        return _moodScore > 0 && _eventController.text.trim().isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  // ★★★ 5. ステップ切り替えロジック ★★★
  void _nextStep() async {
    if (!_isStepValid()) return;
    
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      
    } else {
      _saveEntry();
    }
  }

  // 画面がルート画面なので、戻るボタンは画面を閉じるのではなく、Step 1より手前では何もしない
  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        debugPrint('デバッグ: Step 1 で戻るボタンが押されましたが、ルート画面のため何もしません。');
      }
    });
  }

  // ★★★ 6. データ保存ロジック（サービス利用版） ★★★
  Future<void> _saveEntry({bool isResuming = false}) async {
    if (!_isStepValid()) {
      debugPrint('デバッグ: バリデーションに失敗し、保存処理が中止されました。');
      return;
    }
    
    // 待機が必要かどうかのチェック
    if ((locationString == '位置情報取得中...' || weatherString == '天気取得中...') && !isResuming) {
      
      final bool? shouldSave = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('位置情報／天気情報の取得中です'),
            content: const Text(
              'データ取得が完了していません。このまま未取得として保存しますか？\n（待機することで取得できる場合があります）',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // 待機
                child: const Text('待機する'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // 未取得として保存
                child: const Text('そのまま保存'),
              ),
            ],
          );
        },
      );

      if (shouldSave == false) {
        _awaitLocationAndWeather(); 
        return; 
      }
      
      // 未取得として保存する場合の文字列変換
      if (locationString == '位置情報取得中...') {
        locationString = '未取得';
      }
      if (weatherString == '天気取得中...') {
        weatherString = '未取得';
      }
    }

    // --- データモデルの構築と保存 ---
    final newRecord = Record(
      recordId: _uuid.v4(), 
      recordDate: DateTime.now(), 
      moodScore: _moodScore,
      eventText: _eventController.text,
      moodTags: _selectedMoodTags.toList(),
      selfAnalysis: _languageController.text,
      location: locationString, 
      weather: weatherString,
    ); 
    
    try {
      await _recordService.saveRecord(newRecord); 
      
      if (mounted) {
        await ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記録を保存しました！')),
        ).closed;
        
        _resetEntry(); // 画面リセット
      }
    } catch (e) {
      debugPrint('デバッグ: データベース書き込みエラーが発生しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('データベース書き込みエラー: $e')));
      }
    } 
  }

  // ★★★ 有料プラン画面への遷移 (AppShellのナビゲーションには含めない) ★★★
  void _goToSubscription() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid = _isStepValid();
    final bool isLastStep = _currentStep == 2;
    final String actionText = isLastStep ? '保存' : '次へ';
    // 待機中はボタンを無効化
    final bool isButtonEnabled = (isLastStep || isValid) && !_isWaitingForLocation; 

    // ステップ定義
    final List<Widget> steps = [
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

      Step2ScoreEventScreen(
        moodScore: _moodScore,
        eventController: _eventController,
        onScoreChanged: (score) {
        setState(() {
          _moodScore = score;
          });
        },
        onContentChanged: () {
          setState(() {});
        },
      ),

      Step3LanguageScreen(
        languageController: _languageController,
        onPremiumTap: _goToSubscription,
        locationString: locationString,
        weatherString: weatherString,
      ),
    ]; 

    final Widget? stepFab = _currentStep < 3
        ? FloatingActionButton.extended(
              onPressed: isButtonEnabled ? _nextStep : null,
              // ★★★ 修正: ラベルとアイコンをステップに応じて変更 ★★★
              label: Text(actionText),
              icon: Icon(isLastStep ? Icons.save : Icons.arrow_forward),
              // ... (色はそのまま) ...
              backgroundColor: isButtonEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
              foregroundColor: isButtonEnabled ? Colors.white : Colors.grey.shade600,
            )
          : null; // 存在しない Step 3 以降は null
          
    // 保存ボタンの位置 (Step 2 のみ右下)
    final fabLocation = isLastStep
        ? FloatingActionButtonLocation.endFloat
        : null;

    // ★★★ AppShell に渡す変数を saveFab から stepFab に変更 (名前を分かりやすく) ★★★
    return AppShell(
      floatingActionButton: stepFab, // ★★★ ここを修正 ★★★
      floatingActionButtonLocation: fabLocation,

      // メインコンテンツ (Stack)
      child: Stack(
        children: [
          // 1. 画面上部のカスタムヘッダーエリアをStackの一番上に配置
          Positioned( // ContainerをPositionedでラップし、明確に位置指定する
             left: 0,
             right: 0,
             top: 0, // ★★★ 修正: AppShellがステータスバーを考慮したので、ここは0でOK ★★★
            child: Container(
              height: kAppHeaderH, // ★★★ 修正: kAppHeaderHを使用 ★★★
              color: Theme.of(context).scaffoldBackgroundColor, // 背景色を不透明にして、下のコンテンツを隠す
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // 戻るボタン (Step 0以外)
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _previousStep,
                    ),
                  const SizedBox(width: 8),
                  // ステップタイトル
                  Text(
                    _currentStep == 0 
                        ? '新規記録作成' : 'ステップ ${_currentStep + 1} / 3',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          
          // 2. 実際の入力コンテンツ 
          // ★★★ 修正: カスタムヘッダーの高さ分、下にスペースを確保(60.0) ★★★
          Padding(
            padding: const EdgeInsets.only(top: kAppHeaderH), // ★★★ 修正: kAppHeaderHを使用 ★★★
            child: IndexedStack(index: _currentStep, children: steps),
          ),

          // ... (待機インジケータとロケーションステータスバーのロジックはそのまま) ...
          if (_isWaitingForLocation)
            Container(
              color: Colors.black.withAlpha(128), 
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '位置情報と天気の取得を待機中...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          
          // ロケーションステータスバーのロジックはそのまま
          Positioned(
            left: 10,
            bottom: 10,
            child: Padding( 
              padding: isLastStep ? const EdgeInsets.only(right: 80.0) : EdgeInsets.zero,
              child: LocationStatusBar(
                location: locationString,
                weather: weatherString,
              ),
            ),
          ),
        ],
      ),
    );
  }
}