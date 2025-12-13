// lib/screens/new_entry_screen.dart (データ保存統合版)

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; // ★★★ HTTP通信用ライブラリ
import 'dart:convert'; // JSONデコード用
import 'dart:async'; // TimeoutException を使用するために必要

import '../main.dart';
import '../models/record.dart';
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
  final Set<String> _selectedMoodTags = {};
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
  
  String locationString = '位置情報取得中...'; // 初期値
  String weatherString = '天気取得中...';   // 初期値

  @override
  void dispose() {
    _eventController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocationAndWeather(); // アプリ起動と同時に取得開始
  }

  // ★★★ 追記: 位置情報と天気を非同期で取得するメソッド ★★★
  Future<void> _loadLocationAndWeather() async {
    Position? position;
    String newLocation = '不明';
    String newWeather = '不明';

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) 
      {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );

        // 位置情報文字列の生成
        newLocation =
            'Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)}';

        // 天気情報取得
        newWeather = await _getWeather(
          position.latitude,
          position.longitude,
        );
      } else {
        newLocation = '権限なし';
        newWeather = '権限なし';
      }
    } on TimeoutException {
      newLocation = 'タイムアウト';
      newWeather = 'タイムアウト';
      debugPrint('位置情報取得タイムアウト');
    } catch (e) {
      newLocation = '取得エラー';
      newWeather = '取得エラー';
      debugPrint('外部データ取得エラー: $e');
    } // end try-catch

    // 状態を更新し、UIを再描画する
    if (mounted) {
      setState(() {
        locationString = newLocation;
        weatherString = newWeather;
      }); // end setState
    }
  } // end _loadLocationAndWeather

  void _resetEntry() {
  setState(() {
    _currentStep = 0; // Step 1 に戻す
    _selectedMoodTags.clear(); // タグをクリア
    _moodScore = 5; // スコアをリセット
    _eventController.clear(); // イベントテキストをクリア
    _languageController.clear(); // 言語テキストをクリア
    
    // 位置情報と天気情報を再度「取得中」の状態にし、再取得をトリガー
    locationString = '位置情報取得中...';
    weatherString = '天気取得中...';
    _loadLocationAndWeather(); // 新しい記録のために非同期で再取得を開始
  });
} // end _resetEntry

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
  if (!_isStepValid()) {
    debugPrint('デバッグ: バリデーションに失敗し、保存処理が中止されました。'); // ★★★ 追加
    return;
  }
  
  debugPrint('デバッグ: バリデーション成功。データ構築に進みます。'); // ★★★ 追加

  // --- 3. データモデルの構築 ---
  final newRecord = Record(
    recordId: _uuid.v4(), // RecordモデルのIDフィールド名に修正
    recordDate: DateTime.now(), // 以前のコードにはありませんでしたが、Recordモデルに必要と仮定
    moodScore: _moodScore,
    eventText: _eventController.text,
    moodTags: _selectedMoodTags.toList(),
    selfAnalysis: _languageController.text,
    location: locationString, // 事前取得した値を使用
    weather: weatherString,   // 事前取得した値を使用
    ); 
  // --- 4. Isar への書き込み ---
  try {
    debugPrint('デバッグ: Isar書き込み処理開始...'); // ★★★ 追加

    await isar.writeTxn(() async {
    await isar.records.put(newRecord);
    });
    
    debugPrint('デバッグ: Isar書き込み処理完了！'); // ★★★ 追加    
    
    // 成功した場合
      if (mounted) {
        // ユーザーにフィードバック
        await ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記録を保存しました！')),
        ).closed;
        
        // ★★★ 修正: pop/push を削除し、画面をリセットする ★★★
        // 画面を閉じずに、Step 1 に戻す
        _resetEntry(); 
      }
  } catch (e) {
    debugPrint('デバッグ: データベース書き込みエラーが発生しました: $e'); // ★★★ 追加

    // 書き込みエラーが発生した場合
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データベース書き込みエラー: $e')));
    }
    return;
  } // End of try-catch

} // End of _saveEntry
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
