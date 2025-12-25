// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 追加
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'core/constants/app_theme.dart'; // app_theme.dartをインポート
import 'data/repositories/isar_diary_repository.dart'; // IsarDiaryRepositoryをインポート
import 'domain/repositories/diary_repository.dart'; // DiaryRepositoryインターフェースをインポート
import 'domain/use_cases/get_monthly_mood_data_use_case.dart'; // UseCaseをインポート
import 'providers/analysis_provider.dart'; // AnalysisProviderをインポート


void main() async {
  // これを一番上に追加（通信系のエラーでデバッガーが落ちるのを防ぐ）
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("【エラー捕捉】: ${details.exception}");
  };

  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

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
        // Repository層の提供
        Provider<DiaryRepository>(
          create: (_) => IsarDiaryRepository(isarService),
        ),
        // UseCase層の提供
        Provider<GetMonthlyMoodDataUseCase>(
          create: (context) => GetMonthlyMoodDataUseCase(
            context.read<DiaryRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(
          create: (context) => HistoryProvider(
            context.read<DiaryRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AnalysisProvider(
            context.read<GetMonthlyMoodDataUseCase>(),
          ),
        ),
        // SettingsProvider に HistoryProvider を渡す
        ChangeNotifierProxyProvider<HistoryProvider, SettingsProvider>(
          create: (context) => SettingsProvider(
            isarService,
            context.read<DiaryRepository>(),
          ),
          update: (_, history, settings) => settings!..setHistoryProvider(history),
        ),
        // WriteProvider に HistoryProvider を渡す
        ChangeNotifierProxyProvider<HistoryProvider, WriteProvider>(
          create: (context) => WriteProvider(
            environmentCoordinator,
            geminiService,
            context.read<DiaryRepository>(),
          ),
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
      theme: lightTheme, // app_theme.dartで定義したlightThemeを使用
      // ▼▼▼ ローカライズ設定 ▼▼▼
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), 
        Locale('ja', ''),
      ],
      // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲
      // ルーティング設定
      initialRoute: '/',
      routes: {
        '/': (context) => const RootScreen(), 
        '/write': (context) => const WriteScreen(),
        '/history': (context) => const HistoryScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/settings': (context) => const SettingsScreen(),      },
    );
  }
}