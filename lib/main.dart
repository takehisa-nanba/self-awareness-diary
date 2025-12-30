// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // 日付のローカライズを初期化するために必要
import 'package:myapp/providers/mood_tag_provider.dart';
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
import 'package:myapp/core/constants/app_theme.dart'; // アプリケーションのテーマ定義
import 'package:myapp/data/repositories/isar_diary_repository.dart'; // IsarRepositoryの実装
import 'package:myapp/domain/repositories/diary_repository.dart'; // Repositoryの抽象
import 'package:myapp/providers/analysis_provider.dart';
import 'package:myapp/ui/screens/brand_splash_screen.dart';
import 'package:myapp/services/developer_service.dart';

/// アプリケーションのエントリーポイント。
///
/// 環境変数のロード、各種サービスの初期化、Provider の設定、
/// およびアプリケーションのルートウィジェットの実行を行います。
void main() async {
  // アプリケーションレベルのエラーを捕捉
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("【エラー捕捉】: ${details.exception}");
  };

  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // 日付フォーマットのローカライズを初期化

  // .envファイルから環境変数を読み込み
  await dotenv.load(fileName: ".env");
  final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final weatherKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // サービスのインスタンス化と初期化
  isarService = IsarService();
  await isarService.init(); // Isar データベースの初期化

  locationService = LocationService(mapsKey);
  weatherService = WeatherService(weatherKey);
  geminiService = GeminiService(geminiKey);

  // サービスをまとめるコーディネーター
  environmentCoordinator = EnvironmentCoordinator(
    locationService,
    weatherService,
    isarService,
  );

  runApp(
    MultiProvider(
      providers: [
        // Repository層
        Provider<DiaryRepository>(
          create: (_) => IsarDiaryRepository(isarService),
        ),
        Provider<GeminiService>(create: (_) => geminiService),
        // Provider層
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(
          create: (context) => HistoryProvider(context.read<DiaryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AnalysisProvider(context.read<DiaryRepository>(), geminiService),
        ),
        ChangeNotifierProxyProvider<HistoryProvider, SettingsProvider>(
          create: (context) =>
              SettingsProvider(isarService, context.read<DiaryRepository>()),
          update: (_, history, settings) => settings!
            ..setHistoryProvider(
              history,
            ), // HistoryProviderをSettingsProviderに注入
        ),
        ChangeNotifierProvider(
          create: (context) =>
              MoodTagProvider(context.read<SettingsProvider>()),
        ),
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
          update: (_, history, settings, write) => write!
            ..updateProviders(history, settings), // 連携ProviderをWriteProviderに注入
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

/// アプリケーションのルートウィジェット。
///
/// アプリのテーマ設定、国際化対応、および初期画面の決定を行います。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自己覚知日記',
      theme: lightTheme, // アプリケーションのライトテーマを適用
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ja', ''),
      ], // サポートするロケール
      home: const InitialScreenWrapper(), // アプリの最初の画面
    );
  }
}

/// アプリケーションの初回起動状態に基づいて表示する画面を切り替えるウィジェット。
///
/// 初回起動の場合は [BrandSplashScreen] を、それ以外の場合は [RootScreen] を表示します。
class InitialScreenWrapper extends StatelessWidget {
  const InitialScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // _loadSettingsが完了するのを待つ
        if (settings.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ), // 設定読み込み中はローディングを表示
          );
        }
        // 初回起動かどうかで表示画面を切り替え
        return settings.isFirstLaunch
            ? const BrandSplashScreen()
            : const RootScreen();
      },
    );
  }
}
