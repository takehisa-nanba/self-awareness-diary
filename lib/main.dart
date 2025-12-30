// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 追加
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myapp/providers/mood_tag_provider.dart'; // Add this import
import 'services/environment_coordinator.dart';
import 'services/isar_service.dart';
import 'services/gemini_service.dart';
import 'providers/write_provider.dart';
import 'providers/history_provider.dart';
import 'providers/app_state_provider.dart';
import 'package:myapp/providers/settings_provider.dart';
import 'package:myapp/ui/screens/root_screen.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/weather_service.dart';
import 'package:myapp/core/constants/app_theme.dart';
import 'package:myapp/data/repositories/isar_diary_repository.dart';
import 'package:myapp/domain/repositories/diary_repository.dart';
import 'package:myapp/providers/analysis_provider.dart';
import 'package:myapp/ui/screens/brand_splash_screen.dart';
import 'package:myapp/services/developer_service.dart';

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
        Provider<GeminiService>(
          create: (_) => geminiService, // 既存のgeminiServiceインスタンスを提供
        ),
        // UseCase層はAnalysisProviderに統合されたため不要
        // Provider<GetMonthlyMoodDataUseCase>(
        //   create: (context) => GetMonthlyMoodDataUseCase(
        //     context.read<DiaryRepository>(),
        //   ),
        // ),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(
          create: (context) => HistoryProvider(context.read<DiaryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AnalysisProvider(context.read<DiaryRepository>(), geminiService),
        ),
        // SettingsProvider に HistoryProvider を渡す
        ChangeNotifierProxyProvider<HistoryProvider, SettingsProvider>(
          create: (context) =>
              SettingsProvider(isarService, context.read<DiaryRepository>()),
          update: (_, history, settings) =>
              settings!..setHistoryProvider(history),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              MoodTagProvider(context.read<SettingsProvider>()),
        ),
        // WriteProvider に HistoryProvider と SettingsProvider を渡す
        ChangeNotifierProxyProvider2<
          HistoryProvider,
          SettingsProvider,
          WriteProvider
        >(
          create: (context) => WriteProvider(
            environmentCoordinator,
            geminiService,
            context.read<DiaryRepository>(),
          ),
          update: (_, history, settings, write) =>
              write!..updateProviders(history, settings),
        ),
        // 開発者向けサービス
        ChangeNotifierProvider(
          create: (context) =>
              DeveloperService(context.read<DiaryRepository>()),
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
      theme: lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ja', '')],
      home: const InitialScreenWrapper(), // 起動画面の振り分け
    );
  }
}

class InitialScreenWrapper extends StatelessWidget {
  const InitialScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // _loadSettingsが完了するのを待つため、一瞬ローディング画面を出す
        // ただし、このアーキテクチャでは一瞬で終わるのでほぼ見えない
        if (settings.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return settings.isFirstLaunch
            ? const BrandSplashScreen()
            : const RootScreen();
      },
    );
  }
}
