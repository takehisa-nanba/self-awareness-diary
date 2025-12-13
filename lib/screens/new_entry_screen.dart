// lib/screens/new_entry_screen.dart (データ保存統合版)

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:http/http.dart' as http; // ★★★ HTTP通信用ライブラリ
import 'dart:convert'; // JSONデコード用

import '../main.dart';
import '../models/record.dart';
import '../services/record_service.dart';
import 'new_entry_steps/step1_mood_tag.dart';
import 'new_entry_steps/step2_score_event.dart';
import 'new_entry_steps/step3_language.dart';

import 'history_screen.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart'; // 仮で作成します

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  // ★★★ データと状態の管理 ★★★
  int _currentStep = 0;
  Set<String> _selectedMoodTags = {};
  int _moodScore = 5;
  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  // UUIDジェネレーターのインスタンス
  final _uuid = const Uuid();

  // ★★★ 気象情報APIの設定 (要置換) ★★★
  // ※ 実装時はAPIキーを安全に扱う必要があります
  // ここをあなたのAPIキーに置き換えてください。ダミーの場合はダミーのまま実行
  final String _openWeatherApiKey = '5206a2c883a8a10b280e09ebb4f1c12e';
  final String _weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  @override
  void dispose() {
    _eventController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  // ★★★ 気象情報を取得する関数 (緯度経度からAPIコール) ★★★
  Future<String> _getWeather(double lat, double lon) async {
    if (_openWeatherApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      // APIキー設定前のダミーデータ (要件 F-2対応)
      return "晴れ/25°C (API設定前)";
    }

    final url = Uri.parse(
      '$_weatherBaseUrl?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric&lang=ja',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        final weatherDescription = data['weather'][0]['description'] ?? '不明';
        final temperature = data['main']['temp'].toStringAsFixed(1) ?? 'N/A';

        return '$weatherDescription / $temperature°C';
      } else {
        debugPrint('天気情報取得失敗: ${response.statusCode}');
        return '天気情報取得失敗';
      }
    } catch (e) {
      debugPrint('天気情報通信エラー: $e');
      return '天気情報通信エラー';
    }
  }

  // ★★★ バリデーション（入力チェック） ★★★
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

  // ★★★ ナビゲーションロジック ★★★
  void _nextStep() {
    if (!_isStepValid()) return;

    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        _saveEntry();
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        Navigator.pop(context);
      }
    });
  }

  // ★★★ データ保存ロジック（F-1, F-2対応） ★★★
  Future<void> _saveEntry() async {
    if (!_isStepValid()) return;

    // --- 1. 位置情報と権限の確認 (F-2対応) ---
    Position? position;
    String locationString = '不明';
    String weatherString = '不明';

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );

        // 緯度経度から場所の文字列を生成
        locationString =
            'Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)}';

        // ★★★ 気象情報取得関数の呼び出し ★★★
        weatherString = await _getWeather(
          position.latitude,
          position.longitude,
        );
      } else {
        // 権限がない場合、不明のまま
      }
    } catch (e) {
      locationString = '取得エラー';
      weatherString = '取得エラー';
      debugPrint('外部データ取得エラー: $e');
    }

    // --- 3. データモデルの構築 ---
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

    // --- 4. Isarへの書き込み処理 ---
    await isar.writeTxn(() async {
      await isar.records.put(newRecord);
    });

    // --- 5. 画面遷移 ---
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('記録を保存しました！')));
      Navigator.pop(context, true);
    }
  }

  // ★★★ 有料プラン画面への遷移 (F-10) ★★★
  void _goToSubscription() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('【有料プラン】課金プラン画面へ遷移')));
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid = _isStepValid();
    final bool isLastStep = _currentStep == 2;
    final String actionText = isLastStep ? '保存' : '次へ';
    final bool isButtonEnabled = isLastStep || isValid;

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
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        // titleのテキストを調整
        title: Text(
          _currentStep == 0 ? '新規記録作成' : 'ステップ ${_currentStep + 1} / 3',
        ),
        // leadingのロジックを修正
        leading: _currentStep == 0
            // Step 1 (最初の画面) ではDrawerを開くアイコンを表示させる
            ? Builder(
                // Builderで囲み、Scaffoldのコンテキストを取得
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    // ★修正: Scaffold.of(context)ではなく、Builder経由のcontextを使用★
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              )
            // それ以外は戻るボタン
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              ),
        automaticallyImplyLeading: false, // leadingを自分で制御するためfalseを維持
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
                  // キャッチコピーの表示
                  Text(
                    '良い時も、悪い時も、どんな感情もあなたを照らす羅針盤',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 履歴を見る (F-5)
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('履歴を見る'),
              onTap: () {
                Navigator.pop(context); // Drawerを閉じる
                // 画面遷移
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),

            // 分析画面 (F-8)
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('気分分析'),
              onTap: () {
                Navigator.pop(context);
                // 画面遷移
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AnalysisScreen(),
                  ),
                );
              },
            ),

            const Divider(), // 区切り線
            // 課金プラン (F-10 への導線)
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('プレミアムプラン'),
              onTap: () {
                Navigator.pop(context);
                // 画面遷移
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),

            // 設定
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(context);
                // 画面遷移
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

      body: IndexedStack(index: _currentStep, children: steps),

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
