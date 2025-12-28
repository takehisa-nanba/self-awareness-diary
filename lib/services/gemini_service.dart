// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

late GeminiService geminiService;

class GeminiService {
  final GenerativeModel _model;
  ChatSession? _chatSession; // チャットセッションを保持

  GeminiService(String apiKey)
    : _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

  /// 新しいチャットセッションを開始またはリセットします。
  /// オプションで初期コンテキストを設定できます。
  void startNewChatSession({String? initialContext}) {
    _chatSession = _model.startChat();
    if (initialContext != null && initialContext.isNotEmpty) {
      _chatSession!.sendMessage(Content.text(initialContext));
    }
  }

  /// チャットセッションにメッセージを送信し、AIの応答を返します。
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

  // 分析用
  Future<Map<String, dynamic>> analyzeStability(String text) async {
    final prompt =
        '''
    以下の日記を分析し、感情の安定度を0-100%で数値化してください。
    また、その理由を30文字以内で一言添えてください。
    必ず以下のJSON形式で回答してください：
    {"score": 数値, "reason": "理由"}

    内容：$text
    ''';

    try {
      debugPrint('AI分析プロンプト: $prompt');
      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonStr = response.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(jsonStr ?? '{"score": 50, "reason": "分析失敗"}');
    } catch (e) {
      debugPrint('AI分析エラー: $e');
      return {"score": 50, "reason": "AI通信エラー"};
    }
  }

    // 内省質問生成用
    Future<String> generateReflectionQuestion({
      required String eventText,
      required String tags,
    }) async {
      final prompt = '出来事「$eventText」と、感情「$tags」を踏まえ、内省を深掘りする質問を1つ作成してください。';
  
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        return response.text ?? 'その時、どんな感覚がありましたか？';
      } catch (e) {
        debugPrint('質問生成エラー: $e');
        return 'その出来事について、もっと詳しく教えてください。';
      }
    }
  
      /// 分析レポートからAIの洞察を生成する
      Future<List<String>> generateAnalysisInsights(String reportSummary) async {
        final prompt = '''
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
          return text.split('||').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } catch (e) {
          debugPrint('AI洞察生成エラー: $e');
          return ['AIとの通信中にエラーが発生しました。'];
        }
      }
    }
