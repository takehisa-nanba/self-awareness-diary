# アプリケーション設計書: 自己覚知日記

## 概要
このアプリケーションは、ユーザーが日々の気分、出来事、自己分析を記録する自己覚知日記です。Gemini APIを利用したAI分析を統合し、精神的な安定性に関する洞察を提供し、気分の傾向や個人の成長を視覚化するための様々なツールを提供します。有料と無料のティアで機能を差別化したフリーミアムモデルを採用しています。

## 実装済みの機能 (現状)

### コア機能
- **日記エントリー:** ユーザーは以下の項目を含む日次エントリーを記録できます:
    - `recordDate`: エントリーの日付と時刻。
    - `moodTags`: 気分に関連するタグのリスト。
    - `moodScore`: ユーザーの気分を表す数値スコア。
    - `eventText`: その日の出来事の記述。
    - `selfAnalysis`: ユーザー自身の感情に関する個人的な反省や分析。
    - `location`: 位置情報データ（有効な場合）。
    - `weather`: 記録された場所の天気データ。
    - `latitude`, `longitude`: 地理座標。

### AI統合 (Gemini)
- `GeminiService` for interaction with the Gemini API.
- `aiStabilityScore`: An AI-generated score indicating mental stability, derived from diary content.
- `aiAnalysisReason`: AI's reasoning or explanation for the stability score.
- Comparison of `moodScore` with `aiStabilityScore` to highlight self-perception gaps.

### User Interface & Navigation
- **`RootScreen`:** Main application shell with bottom navigation.
- **`WriteScreen`:** Interface for creating new diary entries, potentially guided steps (`write_steps`).
- **`HistoryScreen`:** Displays past diary entries, likely with calendar view (`table_calendar`).
- **`AnalysisScreen`:** Provides visual analysis of mood data using charts (`fl_chart`).
- **`SettingsScreen`:** Application settings and configurations.
- **`record_detail_screen.dart`:** Screen to view detailed information of a specific diary entry.
- **`location_edit_screen.dart`:** Screen for managing location settings.
- **`ai_assistant_screen.dart`:** (Likely a placeholder or basic implementation) for AI interaction.
- **App Shell & Widgets:** Reusable UI components like `AppShell`, `ExtendedFabNavigator`, `HorizontalMoodSelector`, `LocationStatusBar`, etc.

### Data Management
- **Local Storage:** Uses Isar database (`isar`, `isar_flutter_libs`) for efficient local data persistence.
- **Repositories:** `DiaryRepository` interface and `IsarDiaryRepository` implementation for data abstraction.

### External Services
- **Location Service:** `LocationService` (using `geolocator`, `geocoding`) for fetching location data.
- **Weather Service:** `WeatherService` (using `http`) for fetching weather information.
- **Environment Management:** `EnvironmentCoordinator` to manage external services.

### State Management
- Uses `Provider` for managing application state across various components (`AppStateProvider`, `WriteProvider`, `HistoryProvider`, `AnalysisProvider`, `SettingsProvider`).

### Utilities & Theming
- `intl` for date formatting and localization (`flutter_localizations`).
- `.env` file for environment variable management (`flutter_dotenv`).
- `app_theme.dart` for defining the application's visual theme.

## 提案された機能ティアと実装計画

### 目標
既存のAI統合、より深い洞察、パーソナライズされたユーザー体験に焦点を当て、無料および有料サブスクリプションティア間で機能を差別化することにより、アプリケーションの価値提案を向上させる。

### 機能ティア

#### **無料版 (Free)**
- **コア日記機能:**
    - 気分、出来事、自己分析を記録。
    - 基本的なムードタグ。
    - カレンダー履歴表示。
    - 基本的な月次気分傾向分析。
- **広告:**
    - 画面下部に常時表示されるバナー広告。
    - 月次AI分析へのアクセスには動画広告の視聴が必要。

#### **月額150円プラン (Tier 1)**
- **無料版の全機能、ただし広告なし。**
- **強化されたAI分析:**
    - **無制限のAI分析:** 制限なくいつでもAI分析にアクセス可能。
    - **相関分析:** 気分、出来事、タグ、場所、天気間の相関関係をAIが特定。
        - *例:* 「『仕事』タグが付いている日は、気分スコアが平均15%低い傾向があります。」
        - *例:* 「雨の日は、気分がより沈みがちになるようです。」
- **高度なムードタグ管理:**
    - **カスタムタグ作成:** ユーザーが独自のムードタグを作成、編集、削除可能。
    - **タグのグループ化:** タグをカテゴリ（例：「仕事」、「プライベート」、「健康」）に整理。
- **データエクスポート:**
    - 日記データをCSVまたはJSON形式でエクスポート。

#### **月額300円プラン (Tier 2)**
- **Tier 1の全機能。**
- **AIアシスタント機能:**
    - **対話による深掘り:** 日記エントリー後、AIアシスタントが「なぜそう感じましたか？」や「この出来事から何を学びましたか？」といった問いかけで対話的に関与。
    - **過去との関連付け:** 「1ヶ月前のあの日も似た気持ちでしたね。何か共通点はありますか？」のように、過去の記録と関連付けて示唆を与える。
    - **ポジティブな側面の発見:** 記録からポジティブな側面や成長の兆しをAIがフィードバック。
- **高度なデータ視覚化とレポート:**
    - **週次・年次レポート:** より長期間にわたる包括的な傾向分析レポート。
    - **気分ヒートマップ:** カレンダー上で気分の変動を色分け表示。
    - **タグ相関マップ:** タグがどの程度一緒に使用されるかをグラフィカルに表示。
- **自動クラウドバックアップと同期:**
    - 複数のデバイス間でのデータ同期と自動クラウドバックアップ。
- **パーソナライゼーションとリマインダー:**
    - **テーマのカスタマイズ:** アプリのテーマカラーとフォントを完全に制御。
    - **リマインダー通知:** 日記のエントリーを促すためのカスタマイズ可能な日次リマインダー。

---

## 現在の計画とサブタスク

**重要なお知らせ:**

環境の問題により`firebase_vertex_ai`パッケージの追加に繰り返し失敗したため、当初の予定を変更します。
Firebase AI SDKの統合は一旦見送り、既存の`google_generative_ai`パッケージを利用してAIアシスタント機能の実装を進めます。

セキュリティ面については、将来的には自前のバックエンドプロキシを構築する（C案）方針で対応します。

当面の目標は、**月額300円プラン (Tier 2)** の**AIアシスタント**機能から実装を開始することです。

**TODOs:**
1.  **`google_generative_ai`の利用を継続:** `GeminiService`は引き続き`google_generative_ai`パッケージを利用する。
2.  **`ai_assistant_screen.dart`の実装:** 対話フローと文脈に応じた応答に焦点を当て、対話型AIアシスタントのUIとコアロジックを開発する。
3.  **`GeminiService`の強化:** マルチターンの会話とAIアシスタントのためのより複雑なプロンプトをサポートするメソッドを追加する。
4.  **AIアシスタントと`WriteProvider`の連携:** 日記作成ワークフロー内でAIアシスタント機能を統合し、リアルタイムのフィードバックと考察のプロンプトを提供する。
5.  **（将来的に）カスタムバックエンドプロキシの構築を計画:** アプリのセキュリティを確保するため、別途バックエンドサービスを構築する計画を立てる。