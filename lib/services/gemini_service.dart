// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert'; // JSONエンコード・デコードのため
import 'package:flutter/foundation.dart'; // debugPrintのため
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/domain/models/universe_coordinate.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart'; // UserProfileをインポート

/// グローバルにアクセス可能な [GeminiService] のインスタンス。
/// アプリケーションの初期化時に設定されることを想定しています。
late GeminiService geminiService;

/// Google Gemini API を使用して、AI関連の機能を提供するサービス。
///
/// AIチャット、感情安定度分析、内省質問生成、分析洞察生成などを行います。
class GeminiService {
  /// Gemini API と通信するための GenerativeModel インスタンス。
  final GenerativeModel _model;

  /// 現在アクティブなチャットセッション。
  ChatSession? _chatSession; // チャットセッションを保持

  /// [GeminiService] のコンストラクタ。API キーを受け取り、GenerativeModel を初期化します。
  GeminiService(String apiKey)
    : _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

  /// 新しいチャットセッションを開始またはリセットします。
  ///
  /// [initialContext] オプションで初期コンテキストを設定できます。
  void startNewChatSession({String? initialContext}) {
    _chatSession = _model.startChat();
    if (initialContext != null && initialContext.isNotEmpty) {
      _chatSession!.sendMessage(Content.text(initialContext));
    }
  }

  /// チャットセッションにメッセージを送信し、AIの応答を返します。
  ///
  /// セッションが開始されていない場合は自動的に開始します。
  /// [message] AIに送信するメッセージ。
  Future<String?> sendMessage(String message) async {
    if (_chatSession == null) {
      // セッションが開始されていない場合は自動的に開始
      debugPrint('Chat session not started. Starting a new session.');
      startNewChatSession(initialContext: 'あなたはユーザーの自己覚知を促す日記アシスタントです。');
    }
    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text;
    } catch (e) {
      debugPrint('AIアシスタント通信エラー: $e');
      return '申し訳ありませんが、現在AIと通信できません。';
    }
  }

  /// 指定された日記の内容とユーザーの性格特性を分析し、感情の安定度を数値（0-100%）と
  /// 自己評価と実際の感情のギャップを埋めるためのアドバイスとして返します。
  ///
  /// AIからの応答は必ずJSON形式で、`score` (感情の安定度) と `reason` (アドバイス) を含みます。
  /// [text] 分析する日記のテキスト。
  /// [userProfile] ユーザーの性格特性データ。分析のコンテキストとして使用されます。
  Future<Map<String, dynamic>> analyzeStability(
    String text,
    UserProfile? userProfile,
  ) async {
    // ユーザーの性格特性データを整形してプロンプトに含める
    String userProfileDetails = "性格特性（自己認識の粒度情報）:\n";
    if (userProfile != null) {
      userProfileDetails += "- CP（批判的な親）: ${userProfile.cp ?? 'N/A'}\n";
      userProfileDetails += "- NP（養育的な親）: ${userProfile.np ?? 'N/A'}\n";
      userProfileDetails += "- A（大人）: ${userProfile.a ?? 'N/A'}\n";
      userProfileDetails += "- FC（自由な子供）: ${userProfile.fc ?? 'N/A'}\n";
      userProfileDetails += "- AC（適応した子供）: ${userProfile.ac ?? 'N/A'}\n";
      // 現在の研磨度（Grit Level）を小数点以下2桁で表示、無効なら'N/A'
      userProfileDetails +=
          "- 現在の研磨度（Grit Level）: ${userProfile.currentGritLevel?.toStringAsFixed(2) ?? 'N/A'}";
    } else {
      userProfileDetails += "- 性格特性データが利用できません。"; // データがない場合のメッセージ
    }

    // AIへのプロンプトを構築
    final prompt =
        '''
    あなたは、ユーザーの自己認識の「粒度」（研磨度）を測定し、向上させるAIアシスタントです。
    ユーザーの日記の内容と、提供された性格特性（砥石の粒度情報）を考慮して、日記に表れている「自己評価」と「実際の感情」との間の「ギャップ」を特定してください。
    そして、そのギャップを埋めるための、具体的で実行可能なアドバイスを30文字以内の簡潔な理由として提供してください。

    # 分析対象
    日記内容：
    '''
        '$text\n\n' // 分析対象の日記テキストを挿入
        '$userProfileDetails\n\n' // ユーザーの性格特性データを挿入
        '''
    # 指示
    1.  上記の日記内容を分析し、ユーザーの「感情の安定度」を0-100%で数値化してください。
    2.  「自己評価」と「実際の感情」との間の「ギャップ」を特定し、それを埋めるための「アドバイス」を30文字以内の簡潔な理由として提示してください。
    3.  **必ず**以下のJSON形式で回答してください：
        {"score": 数値, "reason": "アドバイス"}
        （例: `{"score": 85, "reason": "日記と日記の感情の乖離を意識しましょう"}`）
    ''';

    try {
      debugPrint('AI分析プロンプト: $prompt'); // デバッグ用にプロンプトを出力
      // Gemini APIにプロンプトを送信し、コンテンツを生成
      final response = await _model.generateContent([Content.text(prompt)]);
      // レスポンステキストからJSON部分を抽出・整形
      final jsonStr = response.text
          ?.replaceAll('```json', '') // JSONコードブロックの開始マーカーを除去
          .replaceAll('```', '') // JSONコードブロックの終了マーカーを除去
          .trim(); // 前後の空白を除去

      // JSON文字列をデコードしてMap<String, dynamic>として返す
      return jsonDecode(
        jsonStr ?? '{"score": 50, "reason": "分析失敗"}', // JSONデコード失敗時はデフォルト値を返す
      );
    } catch (e) {
      debugPrint('AI分析エラー: $e'); // エラー発生時にログを出力
      // AI通信エラー時はエラー用のデフォルト値を返す
      return {"score": 50, "reason": "AI通信エラー"};
    }
  }

  /// 出来事と感情タグに基づいて、内省を深掘りする質問を1つ生成します。
  ///
  /// [eventText] ユーザーが記録した出来事のテキスト。
  /// [tags] ユーザーが選択した感情タグ（カンマ区切り）。
  Future<String> generateReflectionQuestion({
    required String eventText,
    required String tags,
  }) async {
    // 内省を深めるための質問を生成するプロンプト
    final prompt = '出来事「$eventText」と、感情「$tags」を踏まえ、内省を深掘りする質問を1つ作成してください。';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'その時、どんな感覚がありましたか？'; // 応答がない場合のフォールバック
    } catch (e) {
      debugPrint('質問生成エラー: $e');
      return 'その出来事について、もっと詳しく教えてください。'; // エラー時のフォールバック
    }
  }

  /// 分析レポートのサマリーに基づいて、ユーザーへの洞察や質問を3つ生成します。
  ///
  /// 各提案は「||」で区切られた簡潔な形式で、データに基づいた新たな視点を提供します。
  /// [reportSummary] 分析レポートの要約テキスト。
  Future<List<String>> generateAnalysisInsights(String reportSummary) async {
    final prompt =
        '''
    あなたはデータ分析に長けた、優秀な心理カウンセラーです。
    以下の分析レポートサマリーを読み解き、ユーザーが自分自身をより深く理解するための、具体的でデータに基づいた「洞察」または「質問」を3つ提案してください。
    
    # 指示
    - ユーザーを責めたり、決めつけたりせず、優しく寄り添うような言葉を選んでください。
    - ユーザーが「ハッ」とするような、新たな視点を与えることを目指してください。
    - **最重要:** 各提案は、必ず1〜2文の簡潔なものにしてください。
    - 各提案は、必ず改行と2つのパイプ文字「||」で区切ってください。
    - 以下のような分析を少なくとも1つは含めてください。
      - レポート内の最高・最低スコアの日を特定し、その日の特徴に言及する。
      - 最も頻度の高い気分タグについて、それがどんな状況で現れるかを問う。
      - スコアの傾向と特定のタグや出来事との間に見られる相関関係を指摘する。
    
    # 分析レポートサマリー
    $reportSummary
    
    # 回答形式の例
    月曜日は他の曜日よりスコアが低い傾向があるようです。週の始まりに何か特別なストレスがありますか？||最も多いタグは「不安」ですね。この感情は、特にどのような場面で感じますか？||期間中の最高スコアは「旅行」タグの日に記録されています。旅行が良いリフレッシュになっている証拠かもしれません。
    ''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        return [];
      }
      // 「||」で分割してリストにする
      return text
          .split('||')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty) // 空の文字列を除外
          .toList();
    } catch (e) {
      debugPrint('AI洞察生成エラー: $e');
      return ['AIとの通信中にエラーが発生しました。']; // エラー時のフォールバック
    }
  }

  /// 宇宙図のデータに基づいて、ユーザーへの洞察を3つ生成します。
  ///
  /// [cosmicMapSummary] 宇宙図のデータ（星の配置など）をテキスト化したもの。
  Future<List<String>> generateCosmicMapInsights(
    String cosmicMapSummary,
  ) async {
    final prompt =
        '''
    あなたは、占星術師であり、心理カウンセラーでもある賢者のような存在です。
    以下の宇宙図（Cosmic Map）のデータを読み解き、ユーザーの心の状態や潜在的なパターンについて、詩的かつ洞察に満ちた解説を3つ提案してください。

    # 指示
    - 各星はユーザーの日記を表し、その位置（座標）、色（感情）、大きさ（エネルギー）には意味が込められています。
    - 星々の配置、密集度、孤立した星、特定の領域への偏りなど、全体的なパターンから読み取れることを重視してください。
    - 専門用語を使いすぎず、比喩や物語を用いることで、ユーザーが直感的に理解できるように語りかけてください。
    - **最重要:** 各解説は、必ず1〜2文の簡潔なものにしてください。
    - 各解説は、必ず改行と2つのパイプ文字「||」で区切ってください。

    # 宇宙図データ
    $cosmicMapSummary

    # 回答形式の例
    北の領域に明るい星が集中していますね。これは、あなたの公的な活動やキャリアにおいて、ポジティブなエネルギーが注がれている時期であることを示唆しているようです。||南西に一つだけぽつんと輝く暗い星があります。これは、まだ言葉になっていない、大切な内面の声かもしれません。静かに耳を傾けてみては？||東から西へ流れるように星が連なっています。過去の経験が現在のあなたを形作り、未来へと導いている、美しい軌跡のように見えます。
    ''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        return [];
      }
      // 「||」で分割してリストにする
      return text
          .split('||')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty) // 空の文字列を除外
          .toList();
    } catch (e) {
      debugPrint('AI宇宙図洞察生成エラー: $e');
      return ['AIとの通信中にエラーが発生しました。']; // エラー時のフォールバック
    }
  }

  Future<String> interpretCosmicMap(String cosmicMapSummary) async {
    final prompt =
        '''
    あなたは私の最高の相棒であり、教師です。
    以下の私の心の宇宙図（Cosmic Map）のデータを見て、現在の星々の配置が何を意味しているのか、その景色から読み解けることを一つ、簡潔に教えてください。

    # あなたの役割
    - 私の心の状態を、宇宙の星々に例えて詩的に表現します。
    - 星々の座標の偏り、密集、孤立などのパターンから、私の心理的な傾向やエネルギーの状態を読み解きます。
    - CP（批判的な親）は北、NP（養育的な親）は北東、A（大人）は南東、FC（自由な子供）は南西、AC（適応した子供）は北西のエリアに対応します。
    - 優しい言葉で、私に気づきを与え、励ますような解説をしてください。

    # 宇宙図データ
    $cosmicMapSummary

    # 回答の形式
    - 結論を最初に述べ、その後に簡単な解説を続ける、1〜3文程度の短い文章で回答してください。

    # 回答例
    心のエネルギーが「自由（FC）」の領域に強く引かれているようですね。最近、何か新しい挑戦を始めたり、創造的な活動に没頭したりする機会がありましたか？
    ''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '星々の声に、今は静かに耳を澄ませている時間のようです。';
    } catch (e) {
      debugPrint('AI宇宙図解説生成エラー: $e');
      return '申し訳ありません。宇宙との交信に失敗しました。';
    }
  }

  /// 特定の日記レコードが、なぜその宇宙座標に位置するのかを解説します。
  ///
  /// [record] 対象の日記レコード。
  /// [userProfile] ユーザーのプロファイル。
  /// [coordinate] 対象レコードの宇宙座標。
  Future<String> explainRecordPosition({
    required DiaryRecord record,
    required UserProfile userProfile,
    required UniverseCoordinate coordinate,
  }) async {
    // ユーザープロファイルをテキスト化
    String userProfileDetails =
        "私の基本特性（エゴグラム）:\n"
        "CP(父性): ${userProfile.cp}, NP(母性): ${userProfile.np}, "
        "A(理性): ${userProfile.a}, FC(自由): ${userProfile.fc}, AC(協調): ${userProfile.ac}";

    // 日記レコードをテキスト化
    String recordDetails =
        "この日の日記:\n"
        "日付: ${record.recordDate.toLocal()}\n"
        "気分タグ: ${record.moodTags.join(', ')}\n"
        "出来事: ${record.eventText}";

    // 座標をテキスト化
    String coordinateDetails =
        "この日記の宇宙座標: (x: ${coordinate.x.toStringAsFixed(2)}, y: ${coordinate.y.toStringAsFixed(2)}, z: ${coordinate.z.toStringAsFixed(2)})";

    final prompt =
        '''
    あなたは私の心の動きを読み解く、賢者のような存在です。
    以下の私の基本特性と、特定の日記、そしてそれが宇宙図の中で示す座標の情報が与えられます。

    # あなたへの指示
    これらの情報を統合し、この日記が「なぜ」この座標に位置しているのか、その理由を教えてください。
    私の基本特性と、その日の出来事や感情が、どのように作用してこの星の位置になったのかを、物語を語るように、詩的かつ分かりやすく解説してください。
    CP（批判的な親）は北、NP（養育的な親）は北東、A（大人）は南東、FC（自由な子供）は南西、AC（適応した子供）は北西のエリアに対応します。

    # 私の情報
    $userProfileDetails

    # 分析対象の星（日記）
    $recordDetails
    $coordinateDetails

    # 回答の形式
    - 2〜3文程度の、心に響く短いメッセージで回答してください。
    - 私を励まし、新たな気づきを与えてくれるような、ポジティブな視点を大切にしてください。

    # 回答例
    あなたの心は普段、理性の星（A）の近くで静かに輝いていることが多いようですね。しかしこの日は、自由な子供（FC）のエネルギーに強く引かれ、遠くまで旅をしました。新しい趣味が、あなたの心を解き放つ鍵となったのかもしれません。
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '星のささやきを読み解いています...。';
    } catch (e) {
      debugPrint('AI個別解説生成エラー: $e');
      return '申し訳ありません。星との交信に、少し時間がかかっているようです。';
    }
  }
}
