// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

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

  Future<String> analyzeTrendData(List<dynamic> trendData) async {
    await Future.delayed(const Duration(seconds: 1)); 
    return "【TODO: 高度なAIテクニカル分析結果をここに表示します】";
  }
}

final geminiService = GeminiService();