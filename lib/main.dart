// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/record.dart'; // ★★★ Recordモデルのインポート ★★★

import 'screens/write_screen.dart'; // 記録画面
import 'screens/history_screen.dart'; // 履歴画面
import 'screens/analysis_screen.dart'; // 分析画面
import 'screens/settings_screen.dart'; // 設定画面
void main() async {
// 1. Flutterエンジンの初期化を待つ
  WidgetsFlutterBinding.ensureInitialized(); 

  // ★★★ 3. システムUIスタイルを設定 ★★★
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    // システムナビゲーションバーの色をオレンジに設定
    systemNavigationBarColor: Colors.orange.shade700, 
    // ナビゲーションバーのアイコンの色を白に設定
    systemNavigationBarIconBrightness: Brightness.light, 
    // ステータスバー（上部）の色もオレンジに設定（ヘッダーと一体化させるため）
    statusBarColor: Colors.orange.shade700,
    statusBarIconBrightness: Brightness.light, 
    statusBarBrightness: Brightness.dark, // iOS向け
  ));

  // 日付のローカライズ初期化// ★★★ 2. 追記: ロケールデータの初期化 ★★★
  try {
    // HistoryScreenで指定されている 'ja_JP' の日付フォーマットデータをロードする
    await initializeDateFormatting('ja_JP', null);
  } catch (e) {
    debugPrint('デバッグ: ロケールデータの初期化に失敗: $e');
  }

  // ★★★ 2. dotenv の初期化を完了させる (Isarより先に実行) ★★★
  try {
    await dotenv.load(fileName: ".env"); 
    debugPrint('デバッグ: .env ロード成功');
  } catch (e) {
    debugPrint('デバッグ: .env ロード失敗: $e');
  }

  // 3. Isarの初期化
  await initializeIsar();
  
  // 画面の向きを縦固定にする
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 4. アプリ起動
  runApp(const MyApp());
}

// アプリのどこからでもアクセスできる「金庫」の変数
late Isar isar;

// ★★★ 追記/確認: Isarを初期化する関数 ★★★
Future<void> initializeIsar() async {
  final dir = await getApplicationSupportDirectory();
  isar = await Isar.open(
    [RecordSchema], 
    directory: dir.path,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Awareness Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
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
