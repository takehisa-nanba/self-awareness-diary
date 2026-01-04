import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// プロジェクト固有のインポート (package:self_awareness_diary/ 形式を使用)
import 'package:self_awareness_diary/providers/location_provider.dart';
import 'package:self_awareness_diary/providers/mood_tag_provider.dart';
import 'package:self_awareness_diary/services/ad_service.dart';
import 'package:self_awareness_diary/services/environment_coordinator.dart';
import 'package:self_awareness_diary/services/isar_service.dart';
import 'package:self_awareness_diary/services/gemini_service.dart';
import 'package:self_awareness_diary/providers/write_provider.dart';
import 'package:self_awareness_diary/providers/history_provider.dart';
import 'package:self_awareness_diary/providers/app_state_provider.dart';
import 'package:self_awareness_diary/providers/settings_provider.dart';
import 'package:self_awareness_diary/ui/screens/root_screen.dart';
import 'package:self_awareness_diary/services/location_service.dart';
import 'package:self_awareness_diary/services/weather_service.dart';
import 'package:self_awareness_diary/core/constants/app_theme.dart';
import 'package:self_awareness_diary/data/repositories/isar_diary_repository.dart';
import 'package:self_awareness_diary/domain/repositories/diary_repository.dart';
import 'package:self_awareness_diary/providers/analysis_provider.dart';
import 'package:self_awareness_diary/ui/screens/brand_splash_screen.dart';
import 'package:self_awareness_diary/services/developer_service.dart';
import 'package:self_awareness_diary/providers/diagnosis_provider.dart';
import 'package:self_awareness_diary/providers/subscription_provider.dart'; // SubscriptionProviderをインポート
import 'package:self_awareness_diary/services/cosmic_interpretation_service.dart'; // Import CosmicInterpretationService

late GeminiService geminiService;
late CosmicInterpretationService cosmicInterpretationService;
void main() async {
  // アプリケーションレベルのエラーを捕捉
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint(
      "【グローバルエラー捕捉】: ${details.exception} (スタックトレース: ${details.stack})",
    );
  };

  WidgetsFlutterBinding.ensureInitialized();

  try {
    MobileAds.instance.initialize(); // Google Mobile Ads SDKを初期化
  } catch (e) {
    debugPrint("【エラー】Mobile Ads SDKの初期化に失敗しました: $e");
  }

  try {
    await initializeDateFormatting(); // 日付フォーマットのローカライズを初期化
  } catch (e) {
    debugPrint("【エラー】日付フォーマットの初期化に失敗しました: $e");
  }

  // .envファイルから環境変数を読み込み
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("【エラー】環境変数の読み込みに失敗しました (.env): $e");
  }
  final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final weatherKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // サービスのインスタンス化と初期化
  final adService = AdService(); // AdServiceをインスタンス化
  isarService = IsarService();
  try {
    await isarService.init(); // Isar データベースの初期化
  } catch (e) {
    debugPrint("【エラー】Isarデータベースの初期化に失敗しました: $e");
  }

  locationService = LocationService(mapsKey);
  weatherService = WeatherService(weatherKey);
  geminiService = GeminiService(geminiKey);
  cosmicInterpretationService = CosmicInterpretationService(
    isarService,
  ); // Instantiate CosmicInterpretationService

  // サービスをまとめるコーディネーター
  environmentCoordinator = EnvironmentCoordinator(
    locationService,
    weatherService,
    isarService,
  );

  try {
    runApp(
      MultiProvider(
        providers: [
          // Repository層
          Provider<DiaryRepository>(
            create: (_) => IsarDiaryRepository(isarService),
          ),
          Provider<GeminiService>(create: (_) => geminiService),
          Provider<CosmicInterpretationService>(
            create: (_) => cosmicInterpretationService,
          ),
          // Provider層
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(
            create: (context) =>
                HistoryProvider(context.read<DiaryRepository>()),
          ),
          // DiagnosisProviderを定義（UserProfileを管理するため）
          ChangeNotifierProvider(
            create: (context) =>
                DiagnosisProvider(isarService), // IsarServiceを渡す
          ),
          // SubscriptionProviderをDiagnosisProviderに依存させて追加
          ChangeNotifierProxyProvider<DiagnosisProvider, SubscriptionProvider>(
            create: (context) =>
                SubscriptionProvider(isarService, context.read<DiagnosisProvider>().userProfile),
            update: (_, diagnosis, subscription) =>
                subscription!..updateTier(diagnosis.userProfile),
          ),
          // SettingsProviderをDiagnosisProviderの後に定義
          ChangeNotifierProxyProvider<
            DiagnosisProvider,
            SettingsProvider
          >(
            create: (context) =>
                SettingsProvider(isarService, context.read<DiaryRepository>()),
            update: (_, diagnosis, settings) =>
                settings!..updateDiagnosisStatus(diagnosis.userProfile != null),
          ),
          ChangeNotifierProxyProvider2<
            SettingsProvider,
            DiagnosisProvider,
            AnalysisProvider
          >(
            create: (context) => AnalysisProvider(
              context.read<DiaryRepository>(),
              geminiService,
            ),
            update: (_, settings, diagnosis, analysis) => analysis!
              ..updateSettings(settings)
              ..updateDiagnosisProvider(diagnosis),
          ),
          // LocationProviderを追加。HistoryProviderに依存するためChangeNotifierProxyProviderを使用。
          ChangeNotifierProxyProvider<HistoryProvider, LocationProvider>(
            create: (context) => LocationProvider(isarService),
            update: (_, history, location) => location!
              ..setHistoryProvider(
                history,
              ), // LocationProviderにHistoryProviderを注入
          ),
          ChangeNotifierProvider(
            create: (context) =>
                MoodTagProvider(context.read<SettingsProvider>()),
          ),
          // WriteProviderの修正 (DiagnosisProviderも注入するため、ProxyProvider3に変更)
          ChangeNotifierProxyProvider3<
            // ProxyProvider2 -> ProxyProvider3
            HistoryProvider,
            SettingsProvider,
            DiagnosisProvider, // DiagnosisProviderを3番目の型引数として追加
            WriteProvider
          >(
            create: (context) => WriteProvider(
              environmentCoordinator,
              geminiService,
              context.read<DiaryRepository>(),
              adService, // AdServiceを注入
              context.read<DiagnosisProvider>(), // DiagnosisProviderを注入
            ),
            update: (_, history, settings, diagnosis, write) =>
                write! // diagnosis引数を追加
                  ..updateProviders(
                    history,
                    settings,
                    diagnosis,
                  ), // diagnosisも渡す
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
  } catch (e, stack) {
    debugPrint("【エラー】runApp()の実行中に致命的なエラーが発生しました: $e (スタックトレース: $stack)");
    // ここでエラー画面を表示するなどの代替処理も可能
  }
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
    return Consumer<DiagnosisProvider>(
      builder: (context, diagnosis, child) {
        // userProfileの読み込みが完了するのを待つ
        if (diagnosis.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ), // プロファイル読み込み中はローディングを表示
          );
        }
        // UserProfileが存在しない場合（未診断）はBrandSplashScreen -> DiagnosisScreen
        // UserProfileが存在する場合（診断済み）はRootScreenを直接表示
        return diagnosis.userProfile == null
            ? const BrandSplashScreen()
            : const RootScreen();
      },
    );
  }
}
