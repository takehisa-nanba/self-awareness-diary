import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

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

late GeminiService geminiService;
late CosmicInterpretationService cosmicInterpretationService;

void main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("【グローバルエラー捕捉】: ${details.exception}");
  };

  WidgetsFlutterBinding.ensureInitialized();

  try {
    MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("【エラー】Mobile Ads SDKの初期化に失敗しました: $e");
  }

  try {
    await initializeDateFormatting();
  } catch (e) {
    debugPrint("【エラー】日付フォーマットの初期化に失敗しました: $e");
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("【エラー】環境変数の読み込みに失敗しました: $e");
  }

  final mapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final weatherKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  final adService = AdService();
  isarService = IsarService();
  await isarService.init();

  locationService = LocationService(mapsKey);
  weatherService = WeatherService(weatherKey);
  geminiService = GeminiService(geminiKey);
  cosmicInterpretationService = CosmicInterpretationService(isarService);

  environmentCoordinator = EnvironmentCoordinator(
    locationService,
    weatherService,
    isarService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<DiaryRepository>(
          create: (_) => IsarDiaryRepository(isarService),
        ),
        Provider<GeminiService>(create: (_) => geminiService),
        Provider<CosmicInterpretationService>(
          create: (_) => cosmicInterpretationService,
        ),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(
          create: (context) => HistoryProvider(context.read<DiaryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => DiagnosisProvider(isarService),
        ),

        ChangeNotifierProxyProvider<DiagnosisProvider, SubscriptionProvider>(
          create: (context) => SubscriptionProvider(
            isarService,
            context.read<DiagnosisProvider>().userProfile,
          ),
          update: (_, diagnosis, subscription) =>
              subscription!..updateTier(diagnosis.userProfile),
        ),

        ChangeNotifierProxyProvider<DiagnosisProvider, SettingsProvider>(
          create: (context) =>
              SettingsProvider(isarService, context.read<DiaryRepository>()),
          update: (_, diagnosis, settings) =>
              settings!..updateDiagnosisStatus(diagnosis.userProfile != null),
        ),

        ChangeNotifierProxyProvider3<
          SettingsProvider,
          DiagnosisProvider,
          SubscriptionProvider,
          AnalysisProvider
        >(
          create: (context) =>
              AnalysisProvider(context.read<DiaryRepository>(), geminiService),
          update: (_, settings, diagnosis, subscription, analysis) => analysis!
            ..updateSettings(settings)
            ..updateDiagnosisProvider(diagnosis)
            ..updateSubscription(subscription),
        ),

        ChangeNotifierProxyProvider<HistoryProvider, LocationProvider>(
          create: (context) => LocationProvider(isarService),
          update: (_, history, location) =>
              location!..setHistoryProvider(history),
        ),

        ChangeNotifierProvider(
          create: (context) =>
              MoodTagProvider(context.read<SettingsProvider>()),
        ),

        // ★ 修正：WriteProvider の ProxyProvider4 化
        ChangeNotifierProxyProvider4<
          HistoryProvider,
          SettingsProvider,
          DiagnosisProvider,
          SubscriptionProvider,
          WriteProvider
        >(
          create: (context) => WriteProvider(
            environmentCoordinator,
            geminiService,
            context.read<DiaryRepository>(),
            adService,
          ),
          update: (_, history, settings, diagnosis, subscription, write) =>
              write!
                ..updateProviders(history, settings, diagnosis, subscription),
        ),

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return diagnosis.userProfile == null
            ? const BrandSplashScreen()
            : const RootScreen();
      },
    );
  }
}
