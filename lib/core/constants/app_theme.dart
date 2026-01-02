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

/// アプリケーションの宇宙テーマを定義します。
///
/// Material 3 のデザインシステムを使用し、カスタムの [ColorScheme] と [AppBarTheme] を設定します。
final ThemeData universeTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4FD1C5), // Mint Green as "light of life" accent
    onPrimary: Colors.black,
    primaryContainer: Color(0xFF1A1B41), // Deep purple for containers
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF0B1026), // Deep blue for secondary elements
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF0B1026),
    onSecondaryContainer: Colors.white,
    tertiary: Color(0xFF1A1B41),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF1A1B41),
    onTertiaryContainer: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    errorContainer: Color(0xFFB00020),
    onErrorContainer: Colors.white,
    // Deprecated 'background' and 'onBackground' are now handled by 'surface' and 'onSurface'
    surface: Color(
      0xFF000511,
    ), // Deep abyss color as the primary surface/background
    onSurface: Colors.white, // Text on the deep abyss surface
    surfaceContainer: Color(
      0xFF0B1026,
    ), // Original 'surface' (deep blue) now as a container variant
    surfaceContainerHighest: Color(
      0xFF1A1B41,
    ), // Deep purple for highest containers (replaces surfaceVariant)
    onSurfaceVariant: Colors.white, // Keep this
    outline: Colors.white30,
    shadow: Colors.black,
    inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: Color(0xFF4FD1C5),
    surfaceTint: Color(0xFF4FD1C5),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor:
        Colors.transparent, // Background will be handled by UniverseBackground
    foregroundColor:
        Colors.white, // Text and icons should be white on dark background
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  // Text theme adjustments for dark mode readability
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    bodySmall: TextStyle(color: Colors.white54),
    headlineLarge: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.white70),
    headlineSmall: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white70),
    titleSmall: TextStyle(color: Colors.white54),
    labelLarge: TextStyle(color: Colors.white),
    labelMedium: TextStyle(color: Colors.white70),
    labelSmall: TextStyle(color: Colors.white54),
    displayLarge: TextStyle(color: Colors.white),
    displayMedium: TextStyle(color: Colors.white70),
    displaySmall: TextStyle(color: Colors.white54),
  ),
);
