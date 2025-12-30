// lib/core/constants/app_theme.dart

import 'package:flutter/material.dart';

/// アプリケーションのライトテーマを定義します。
///
/// Material 3 のデザインシステムを使用し、カスタムの [ColorScheme] と [AppBarTheme] を設定します。
final ThemeData lightTheme = ThemeData(
  useMaterial3: true, // Material 3 のデザインを有効化
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF98FB98), // ミントグリーンをシードカラーとして使用
    brightness: Brightness.light, // ライトテーマ
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true, // アプリバーのタイトルを中央に配置
    elevation: 0, // アプリバーの影をなくす
    backgroundColor: Colors.transparent, // 背景色を透明に
    foregroundColor: Colors.black87, // 前景色（アイコンやテキストの色）
    titleTextStyle: TextStyle(
      color: ThemeData.light().colorScheme.onSurface,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
);
