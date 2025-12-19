import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 追加
import 'package:provider/provider.dart';
import 'services/isar_service.dart';
import 'services/gemini_service.dart';
import 'providers/write_provider.dart';
import 'providers/history_provider.dart';
import 'ui/screens/write_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/analysis_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 各種サービスの初期化
  await dotenv.load(fileName: ".env"); // .envを読み込み
  await IsarService.init();
  
  // dotenvからAPIキーを取得
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  geminiService = GeminiService(apiKey); 

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WriteProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
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
        '/': (context) => const WriteScreen(),
        '/history': (context) => const HistoryScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}