// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 追加
import 'package:provider/provider.dart';
import 'services/environment_coordinator.dart';
import 'services/isar_service.dart';
import 'services/gemini_service.dart';
import 'providers/write_provider.dart';
import 'providers/history_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/write_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/analysis_screen.dart';
import 'ui/screens/root_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'services/location_service.dart';
import 'services/weather_service.dart';

void main() async {
  // これを一番上に追加（通信系のエラーでデバッガーが落ちるのを防ぐ）
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("【エラー捕捉】: ${details.exception}");
  };

  WidgetsFlutterBinding.ensureInitialized();

  // 1. 各種設定の読み込み
  await dotenv.load(fileName: ".env");
  final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final weatherKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // 2. 実働スタッフ（サービス）の準備
  // ★重要: インスタンスを作成し、その「同じインスタンス」を初期化する
  isarService = IsarService(); 
  await isarService.init(); // staticなIsarService.init()ではなく、インスタンスのinitを呼ぶ

  locationService = LocationService(mapsKey);
  weatherService = WeatherService(weatherKey);
  geminiService = GeminiService(geminiKey);

  // 3. 店長（コーディネーター）を任命
  // ★重要: 初期化済みの isarService を渡す
  environmentCoordinator = EnvironmentCoordinator(
    locationService, 
    weatherService, 
    isarService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        // HistoryProvider に依存する WriteProvider を作成
        ChangeNotifierProxyProvider<HistoryProvider, WriteProvider>(
          create: (_) => WriteProvider(),
          update: (_, history, write) => write!..update(history),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自己覚知日記',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // ルーティング設定
      initialRoute: '/',
      routes: {
        // 2. '/' を WriteScreen から RootScreen に変更
        '/': (context) => const RootScreen(), 
        '/write': (context) => const WriteScreen(), // 必要なら個別ルートも残す
        '/history': (context) => const HistoryScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/settings': (context) => const SettingsScreen(),      },
    );
  }
}