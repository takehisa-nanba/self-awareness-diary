// lib/core/constants/app_theme.dart

import 'package:flutter/material.dart';

// アプリのライトテーマを定義
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(
      128,
      77,
      228,
      77,
    ), // ユーザー指定の鮮やかな緑 (透明度0.5を適用)
    brightness: Brightness.light,
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent, // AppBarの背景を透明にする
    foregroundColor: Colors.black87, // AppBarのアイコンやアクションボタンの色
    titleTextStyle: TextStyle(
      // タイトルテキストのスタイルを定義
      color: ThemeData.light().colorScheme.onSurface, // テーマの文字色を使用
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
);

// ダークテーマが必要な場合はここに追加
// final ThemeData darkTheme = ThemeData(
//   useMaterial3: true,
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: const Color(0xFFA8D6B7),
//     brightness: Brightness.dark,
//   ),
// );
