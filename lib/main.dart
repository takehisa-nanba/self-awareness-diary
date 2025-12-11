// lib/main.dart

import 'package:flutter/material.dart';
import 'package:isar/isar.dart'; // DBを使う
import 'package:path_provider/path_provider.dart'; // 保存場所を探す
import 'package:intl/date_symbol_data_local.dart'; // 日付のローカライズ用
import 'main_scaffold.dart'; // ★ ここを修正: アプリの骨組み（ナビゲーション）
import 'models/diary_entry.dart'; // 設計図を読み込む
import 'models/record.dart'; // ★★★ 新しいモデルをインポート ★★★

// アプリのどこからでもアクセスできる「金庫」の変数
late Isar isar;

void main() async {
  // 1. おまじない（アプリの準備ができるまで待つ）
  WidgetsFlutterBinding.ensureInitialized();

  // 2. スマホの中の「書類保存フォルダ」の場所を探す
  final dir = await getApplicationDocumentsDirectory();

  // 3. その場所に「金庫（Isar）」を開く
  // 以前作った設計図 (RecordSchema) を渡します
  isar = await Isar.open(
    [RecordSchema], // 新しいモデルのスキーマを渡す
    directory: dir.path,
  );

  // 日付のローカライズを初期化（日本語対応）
  await initializeDateFormatting('ja_JP');

  // 4. 準備ができたらアプリを起動
  runApp(const MyApp());
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
      home: const MainScaffold(),
    );
  }
}
