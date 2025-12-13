// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ★★★ 追記 ★★★
import 'package:isar/isar.dart'; // DBを使う
import 'package:myapp/screens/new_entry_screen.dart';
import 'package:path_provider/path_provider.dart'; // 保存場所を探す
import 'models/record.dart'; // ★★★ 新しいモデルをインポート ★★★

void main() async {
// 1. Flutterエンジンの初期化を待つ
  WidgetsFlutterBinding.ensureInitialized(); 

  // ★★★ 2. dotenv の初期化を完了させる (Isarより先に実行) ★★★
  try {
    await dotenv.load(fileName: ".env"); 
    debugPrint('デバッグ: .env ロード成功');
  } catch (e) {
    debugPrint('デバッグ: .env ロード失敗: $e');
  }

  // 3. Isarの初期化
  await initializeIsar();

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
      // ★ ここを修正: アプリの骨組み MainScaffold をホーム画面にする
      home: const NewEntryScreen(),
    );
  }
}
