// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'dart:convert';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception("GEMINI_API_KEY is not found in .env file");
    }

    _model = GenerativeModel(
      apiKey: apiKey,
      model: 'gemini-2.5-flash', 
      systemInstruction: Content.system('''
        あなたは、ユーザーの自己覚知を支援する優秀なライフコーチです。
        ユーザーが記録した「出来事」と「感情タグ」に基づき、「なぜそう感じたか？」ではなく、
        【その感情に対しユーザーが取った具体的な行動や反応】、および【その行動の適切性】
        に焦点を当てた、深く内省を促す質問を日本語で一つだけ生成してください。
        質問の長さは最大2文とし、質問以外の余計な挨拶や説明は一切含めないでください。
        '''),
    );
  }

  Future<String> generateReflectionQuestion({
    required String moodTags,
    required String eventText,
    required int moodScore,
    required String location,
    required String weather,
  }) async {
    final userRecordData = '''
      感情タグ: $moodTags
      気分スコア: $moodScore / 10
      出来事: $eventText
      場所: $location
      天気: $weather
      ''';

    final prompt = [
      Content.text('ユーザーの記録データ:\n$userRecordData\n\nこの記録に対する内省の質問を生成してください。'),
    ];

    try {
      final response = await _model.generateContent(prompt);
      
      if (response.text?.isNotEmpty == true) {
        return response.text!.trim();
      } else {
        return "AIからの質問生成に失敗しました。";
      }
    } catch (e) {
      // ★★★ 修正箇所: logをprintに戻す ★★★
      print("Gemini API Error: $e"); 
      return "AI機能の呼び出し中にエラーが発生しました。APIキーまたはネットワークを確認してください。";
    }
  }
  Future<Map<String, dynamic>> analyzeStability(String text) async {
    if (text.trim().isEmpty) {
      return {"score": 50, "reason": "文章が入力されていないため分析できません。"};
    }

    final prompt = [
      Content.text("""
        あなたは優れた心理カウンセラーとして、以下の日記の文章から執筆者の「メンタルの安定度」を0〜100の数値で分析してください。

        【分析の視点】
        - 自分の状況を客観的に見ているか、多角的な視点があるか。
        - 感情に飲み込まれず、落ち着いた言葉選びができているか。
        - 焦り、強い自己否定、極端な決めつけ（白黒思考）がないか。

        【対象の文章】
        $text

        【出力形式】
        必ず以下のJSON形式のみで回答してください。挨拶や説明は不要です。
        {"score": 85, "reason": "客観的に状況を把握できており、非常に安定しています。"}
        """),
    ];

    try {
      final response = await _model.generateContent(prompt);
      final textResponse = response.text ?? '';
      
      // JSON部分を抽出
      final jsonStart = textResponse.indexOf('{');
      final jsonEnd = textResponse.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = textResponse.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      
      return {"score": 50, "reason": "分析データの解析に失敗しました。"};
    } catch (e) {
      print("AI Stability Analysis Error: $e");
      return {"score": 50, "reason": "AI分析中にエラーが発生しました。"};
    }
  }

  Future<String> analyzeTrendData(List<dynamic> trendData) async {
    await Future.delayed(const Duration(seconds: 1)); 
    return "【TODO: 高度なAIテクニカル分析結果をここに表示します】";
  }
}

final geminiService = GeminiService();