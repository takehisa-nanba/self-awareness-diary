// lib/services/gemini_service.dart (新規作成)

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .envからキーを読み込む

// ★★★ TODO: モデルの具体的な指示（プロンプト）の定義場所 ★★★
// ここに、AIの役割（コーチ、教師など）と、出力形式を定義します。

class GeminiService {
  final GenerativeModel _model;

  // コンストラクタでAPIキーを安全に読み込み、モデルを初期化
  GeminiService()
      : _model = GenerativeModel(
          // .envファイルからAPIキーを読み込む
          apiKey: dotenv.env['GEMINI_API_KEY']!,
          // F-7 (質問生成) に適したモデルを選択
          model: 'gemini-2.5-flash', 
        );

  // ★★★ F-7: AI質問アシスト機能の実装 ★★★
  Future<String> generateReflectionQuestion({
    required String moodTags,
    required String eventText,
    required int moodScore,
    required String location,
    required String weather,
  }) async {
    // ユーザーの記録データに基づいて、AIに問いかけるプロンプトを作成します。
    final userRecordData = '''
感情タグ: $moodTags
気分スコア: $moodScore / 10
出来事: $eventText
場所: $location
天気: $weather
''';

    // 教師役の指示: ユーザーの内省を深めるための「行動」に焦点を当てた質問を生成
    // このシステムプロンプトが、AIの「知性」の質を決定します。
    final systemInstruction = '''
あなたは、ユーザーの自己覚知を支援する優秀なライフコーチです。
ユーザーが記録した「出来事」と「感情タグ」に基づき、「なぜそう感じたか？」ではなく、
【その感情に対しユーザーが取った具体的な行動や反応】、および【その行動の適切性】
に焦点を当てた、深く内省を促す質問を日本語で一つだけ生成してください。
質問の長さは最大2文とし、質問以外の余計な挨拶や説明は一切含めないでください。
''';

    final prompt = [
      Content.system(systemInstruction),
      Content.text('ユーザーの記録データ:\n$userRecordData\n\nこの記録に対する内省の質問を生成してください。'),
    ];

    try {
      final response = await _model.generateContent(prompt);
      
      // 結果が空でないことを確認し、整形して返す
      if (response.text?.isNotEmpty == true) {
        return response.text!.trim();
      } else {
        return "AIからの質問生成に失敗しました。";
      }
    } catch (e) {
      print("Gemini API Error: $e");
      return "AI機能の呼び出し中にエラーが発生しました。APIキーまたはネットワークを確認してください。";
    }
  }

  // ★★★ F-9: AIテクニカル分析機能の実装（ダミーメソッドの場所を確保） ★★★
  Future<String> analyzeTrendData(List<dynamic> trendData) async {
    // TODO: 後続タスクで、時系列データやタグ相関データを基に高度な分析ロジックを実装
    await Future.delayed(const Duration(seconds: 1)); // 仮の遅延
    return "【TODO: 高度なAIテクニカル分析結果をここに表示します】";
  }
}

// サービスをどこからでも呼び出せるように公開
final geminiService = GeminiService();