// lib/screens/new_entry_screen.dart (責務分離・待機ブロック機能搭載版)

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ★★★ 追記 ★★★

import '../models/record.dart';
import '../services/record_service.dart'; 
import '../services/location_weather_service.dart'; 
import '../widgets/location_status_bar.dart';

import 'new_entry_steps/step1_mood_tag.dart';
import 'new_entry_steps/step2_score_event.dart';
import 'new_entry_steps/step3_language.dart';

import 'history_screen.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

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
  // ★★★ 1. 位置情報と天気を非同期で取得するメソッド ★★★
  Future<void> _loadLocationAndWeather() async {
    // ★★★ サービスを利用してデータ取得 ★★★
    final result = await _locationWeatherService.getLocationAndWeather();
    
    // 状態を更新し、UIを再描画する
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
    
    const timeoutDuration = Duration(seconds: 20); // 20秒の待機リミット
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
      // 待機が完了（またはタイムアウト）した後、保存処理を再開
      _saveEntry(isResuming: true); 
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

  // ★★★ 5. ナビゲーションロジック ★★★
  void _nextStep() async {
    if (!_isStepValid()) return;
    
    // 待機中はボタンが disabled のため、ここでは _isWaitingForLocation のチェックは不要

    if (_currentStep < 2) {
      // Step 0, 1 から次へ進む
      setState(() {
        _currentStep++;
      });
      
    } else {
      // Step 2 から保存へ
      _saveEntry();
    }
  }

  // 画面がルート画面なので、戻るボタンは画面を閉じるのではなく、Step 1より手前では何もしない
  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
      // ルート画面なので Navigator.pop(context) は削除
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
    
    // 待機が必要かどうかのチェック (isResumingがtrueの場合は、待機を経ているのでダイアログをスキップ)
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
        _awaitLocationAndWeather(); // 待機ロジックに移行し、保存処理は待機後に再開される
        return; 
      }
      
      // 「そのまま保存」またはダイアログ外タップの場合
      // 「取得中...」の文字列を「未取得」に変換して保存
      if (locationString == '位置情報取得中...') {
        locationString = '未取得';
      }
      if (weatherString == '天気取得中...') {
        weatherString = '未取得';
      }
    }


    // --- データモデルの構築 ---
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
    
    // --- サービスを利用した書き込み ---
    try {
      debugPrint('デバッグ: Isar書き込み処理開始...');
      // ★★★ サービスを呼び出し、保存ロジックを委譲 ★★★
      await _recordService.saveRecord(newRecord); 
      debugPrint('デバッグ: Isar書き込み処理完了！');
      
      // 成功後の処理
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
      return;
    } 
  }

  // ★★★ 有料プラン画面への遷移 (F-10) ★★★
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
      ), // Step 1 終了

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
      ), // Step 2 終了

      Step3LanguageScreen(
        languageController: _languageController,
        onPremiumTap: _goToSubscription,
        locationString: locationString,
        weatherString: weatherString,
      ),
    ]; // stepsリストの終了

    return Scaffold(
      appBar: AppBar(
        // titleのテキストを調整
        title: Text(
          _currentStep == 0 ? '新規記録作成' : 'ステップ ${_currentStep + 1} / 3',
        ),
        // leadingのロジックを修正
        leading: _currentStep == 0
            ? Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              ),
        automaticallyImplyLeading: false, 
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自覚日記',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '良い時も、悪い時も、どんな感情もあなたを照らす羅針盤',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // Drawerの遷移ボタンはそのまま
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('履歴を見る'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('気分分析'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AnalysisScreen(),
                  ),
                );
              },
            ),

            const Divider(), 
            
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('プレミアムプラン'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // ★★★ Stack で body をラップし、インジケータを追加 ★★★
      body: Stack(
        children: [
          IndexedStack(index: _currentStep, children: steps),
          
          if (_isWaitingForLocation)
            Container(
              color: Colors.black.withOpacity(0.5), 
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
            Align(
            alignment: Alignment.bottomCenter,
            child: LocationStatusBar(
              location: locationString,
              weather: weatherString,
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isButtonEnabled ? _nextStep : null,
        label: Text(actionText),
        icon: Icon(isLastStep ? Icons.save : Icons.arrow_forward),
        backgroundColor: isButtonEnabled
          ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade400,
        foregroundColor: isButtonEnabled ? Colors.white : Colors.grey.shade600,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}