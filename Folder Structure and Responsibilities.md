**📝 Self Awareness Diary: リファクタリング・マスタープラン**
🏗 フォルダ構造と責務の定義
Plaintext

lib/
 ├── main.dart                  # アプリの起動、全Providerの注入、初期化管理
 ├── core/
 │    └── constants/            # アプリ全体の定数（AppTheme, ヘッダー高さ, 乖離しきい値等）
 ├── models/                    # 【Domain】純粋なデータ構造とビジネスルール
 │    ├── record.dart           # 記録モデル。乖離判定ロジック(isGapLarge)等もここに実装
 │    └── mood_tag.dart         # 感情タグのクラス定義とカテゴリ定義
 ├── services/                  # 【Infrastructure】外界(DB, AI, GPS)との通信・具象化
 │    ├── isar_service.dart     # Isar DB操作の専門家（Open/Save/Delete）
 │    ├── gemini_service.dart   # Gemini API通信とJSONパースの専門家
 │    └── location_service.dart # 位置情報・OpenWeatherAPI通信の専門家
 ├── providers/                 # 【Application】UIとServiceを繋ぐ司令塔（状態管理）
 │    ├── write_provider.dart   # 記録プロセスの状態（ステップ、入力値）と保存手順の管理
 │    ├── history_provider.dart # 履歴データの取得、日付Map化、カレンダー制御
 │    └── user_provider.dart    # ユーザーのプラン状態(Standard/Premium)とタグ解放の管理
 ├── ui/                        # 【Presentation】表示に関するものすべて
 │    ├── screens/              # 画面単位のWidget（Write, History, Analysis, etc.）
 │    │    └── write_steps/     # 記録画面における各ステップ(1〜3)の構成部品
 │    └── widgets/              # 共通部品（AppShell, LocationStatusBar, Navigator等）
 └── data/
      └── mood_tag_list.dart    # タグのデータ実体（allMoodTags）の定義


🛠 3つの重要リファクタリング・ルール
1. 「バケツリレー」の禁止
親Widgetから子Widgetへ引数でデータを渡すのをやめ、子Widgetが直接 context.read<T>() や context.watch<T>() でProviderから必要な情報を受け取るように統一します。

2. 「二重ロジック」の廃止
UI側のボタンの中に書かれている「保存の手順」や「AI分析の判定」をすべて削除し、Provider 側に一任します。UIは「メソッドを呼ぶ」ことと「結果を待つ（Loadingを出す）」ことだけに集中します。

3. 「専門家へのアクセス」の統一
各ファイルから isar などのグローバル変数や main.dart を直接インポートせず、必ず services/ 配下の専門家クラスを介してデータを取得するように依存関係を整理します。