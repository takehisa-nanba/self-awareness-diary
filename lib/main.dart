import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 使用するため残します
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 使用するため残します
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // 使用するため残します

// プロジェクト固有のインポート
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
import 'package:self_awareness_diary/providers/subscription_provider.dart';
import 'package:self_awareness_diary/services/cosmic_interpretation_service.dart';

import 'package:self_awareness_diary/domain/use_cases/get_universe_interpretation_use_case.dart';
import 'package:self_awareness_diary/domain/use_cases/save_diary_entry_use_case.dart';

// グローバル変数の定義
late GeminiService geminiService;
late CosmicInterpretationService cosmicInterpretationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 各種初期化処理 (ここで import された機能を使います)
  try {
    await dotenv.load(fileName: ".env");
    await MobileAds.instance.initialize();
    await initializeDateFormatting();
  } catch (e) {
    debugPrint("初期化エラー: $e");
  }

  // 2. サービスのインスタンス化 (adService などの定義)
  final adService = AdService();
  isarService = IsarService();
  await isarService.init();

  final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final weatherKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  geminiService = GeminiService(geminiKey);
  cosmicInterpretationService = CosmicInterpretationService(isarService);
  
  locationService = LocationService(mapsKey);
  weatherService = WeatherService(weatherKey);
  environmentCoordinator = EnvironmentCoordinator(
    locationService,
    weatherService,
    isarService,
  );

  runApp(
    MultiProvider(
      providers: [
        // Foundational Services
        Provider<AdService>(create: (_) => adService),
        Provider<DiaryRepository>(create: (_) => IsarDiaryRepository(isarService)),
        Provider<GeminiService>(create: (_) => geminiService),
        Provider<CosmicInterpretationService>(create: (_) => cosmicInterpretationService),
        Provider<EnvironmentCoordinator>(create: (_) => environmentCoordinator),
        Provider<IsarService>(create: (_) => isarService),

        // Independent State Notifiers
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (context) => HistoryProvider(context.read<DiaryRepository>())),
        ChangeNotifierProvider(create: (context) => DiagnosisProvider(context.read<IsarService>())),

        // Dependent Providers
        ChangeNotifierProxyProvider<DiagnosisProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider.empty(),
          update: (_, diagnosis, previous) => previous!..updateTier(diagnosis.userProfile, isarService: isarService),
        ),
        ChangeNotifierProxyProvider<DiagnosisProvider, SettingsProvider>(
          create: (context) => SettingsProvider(context.read<IsarService>(), context.read<DiaryRepository>()),
          update: (_, diagnosis, settings) => settings!..updateDiagnosisStatus(diagnosis.userProfile != null),
        ),
        ProxyProvider<SubscriptionProvider, GetUniverseInterpretationUseCase>(
          update: (_, subscription, _) => GetUniverseInterpretationUseCase(geminiService, subscription),
        ),
        ProxyProvider5<DiaryRepository, GeminiService, AdService, SubscriptionProvider, DiagnosisProvider, SaveDiaryEntryUseCase>(
          update: (_, diaryRepo, gemini, adSvc, subscription, diagnosis, _) =>
              SaveDiaryEntryUseCase(diaryRepo, gemini, adSvc, subscription, diagnosis),
        ),
        ChangeNotifierProxyProvider4<SettingsProvider, DiagnosisProvider, SubscriptionProvider, GetUniverseInterpretationUseCase, AnalysisProvider>(
          create: (_) => AnalysisProvider(),
          update: (_, settings, diagnosis, subscription, useCase, analysis) => analysis!
            ..updateProviders(
              diaryRepository: settings.diaryRepository,
              geminiService: geminiService,
              getUniverseInterpretationUseCase: useCase,
              settings: settings,
              diagnosis: diagnosis,
              subscription: subscription,
            ),
        ),
        ChangeNotifierProxyProvider<HistoryProvider, LocationProvider>(
          create: (context) => LocationProvider(context.read<IsarService>()),
          update: (_, history, location) => location!..setHistoryProvider(history),
        ),
        ChangeNotifierProvider(create: (context) => MoodTagProvider(context.read<SettingsProvider>())),
        ChangeNotifierProxyProvider5<HistoryProvider, SettingsProvider, SubscriptionProvider, SaveDiaryEntryUseCase, AdService, WriteProvider>(
          create: (_) => WriteProvider(),
          update: (_, history, settings, subscription, useCase, adSvc, write) =>
              write!..updateProviders(
                history: history,
                settings: settings,
                subscription: subscription,
                environmentCoordinator: environmentCoordinator,
                geminiService: geminiService,
                adService: adSvc,
                saveDiaryEntryUseCase: useCase,
              ),
        ),
        ChangeNotifierProvider(create: (context) => DeveloperService(context.read<DiaryRepository>())),
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
      home: const InitialScreenWrapper(),
    );
  }
}

class InitialScreenWrapper extends StatelessWidget {
  const InitialScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (context, diagnosis, child) {
        if (diagnosis.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return diagnosis.userProfile == null ? const BrandSplashScreen() : const RootScreen();
      },
    );
  }
}