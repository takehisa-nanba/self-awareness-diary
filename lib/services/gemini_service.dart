// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

late GeminiService geminiService;

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash', 
          apiKey: apiKey,
        );

  // 分析用
  Future<Map<String, dynamic>> analyzeStability(String text) async {
    final prompt = '''
    以下の日記を分析し、感情の安定度を0-100%で数値化してください。
    また、その理由を30文字以内で一言添えてください。
    必ず以下のJSON形式で回答してください：
    {"score": 数値, "reason": "理由"}

    内容：$text
    ''';

    try {
      debugPrint('AI分析プロンプト: $prompt');
      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim();
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
}