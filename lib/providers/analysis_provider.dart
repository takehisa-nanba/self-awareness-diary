// lib/providers/analysis_provider.dart

import 'package:flutter/material.dart';
import 'package:self_awareness_diary/domain/mappers/cosmic_map_to_prompt_mapper.dart';
import 'package:self_awareness_diary/domain/models/diary_record.dart';
import 'package:self_awareness_diary/providers/settings_provider.dart';
import '../domain/models/analysis_report.dart';
import '../domain/repositories/diary_repository.dart';
import '../services/gemini_service.dart';
import '../domain/mappers/ai_report_to_prompt_mapper.dart';
import 'diagnosis_provider.dart'; // DiagnosisProvider をインポート

/// 分析グラフに表示するデータの種類を定義する列挙型。
enum AnalysisDataType { mood, pressure, temperature, polishing }

/// 分析画面の状態管理を行うプロバイダー。
///
/// 日付範囲の指定、日記データの集計、分析レポートの生成、
/// およびAIによる洞察の取得といった機能を提供します。
class AnalysisProvider extends ChangeNotifier {
  final DiaryRepository _diaryRepository;
  final GeminiService _geminiService;
  SettingsProvider? _settingsProvider; // SettingsProviderへの参照
  DiagnosisProvider? _diagnosisProvider; // DiagnosisProviderへの参照を追加

  // --- 状態 ---
  /// 現在グラフに表示すべきデータの種類の集合。
  final Set<AnalysisDataType> activeDataTypes = {AnalysisDataType.mood};

  /// [AnalysisProvider] のコンストラクタ。
  ///
  /// 依存関係を受け取り、初期の日付範囲（過去7日間）を設定します。
  AnalysisProvider(this._diaryRepository, this._geminiService) {
    // 初期表示として過去7日間で設定
    final now = DateTime.now();
    // 日付を正規化
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final startOfPeriod = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final initialRange = DateTimeRange(start: startOfPeriod, end: endOfToday);
    changeDateRange(initialRange);
  }

  /// SettingsProviderのインスタンスを更新します。
  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
  }

  /// DiagnosisProviderのインスタンスを更新します。
  void updateDiagnosisProvider(DiagnosisProvider diagnosis) {
    _diagnosisProvider = diagnosis;
  }

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  AnalysisReport? _report;
  bool _isLoading = false;

  // AI洞察用の状態
  bool _isAiLoading = false;
  List<String> _aiInsights = [];
  // 宇宙図用のAI洞察の状態を追加
  bool _isCosmicMapAiLoading = false;
  List<String> _cosmicMapInsights = [];

  /// 現在選択されている分析対象の日付範囲。
  DateTimeRange get dateRange => _dateRange;

  /// 生成された分析レポート。
  AnalysisReport? get report => _report;

  /// 日記データの読み込み中かどうかを示すフラグ。
  bool get isLoading => _isLoading;

  /// チャート用AIが洞察を生成中かどうかを示すフラグ。
  bool get isAiLoading => _isAiLoading;

  /// AIによって生成されたチャート用の洞察のリスト。
  List<String> get aiInsights => _aiInsights;

  /// 宇宙図用AIが洞察を生成中かどうかを示すフラグ。
  bool get isCosmicMapAiLoading => _isCosmicMapAiLoading;

  /// AIによって生成された宇宙図用の洞察のリスト。
  List<String> get cosmicMapInsights => _cosmicMapInsights;

  /// 手動で特定の記録のAI安定度分析を実行します。
  ///
  /// [record] 分析対象の日記レコード。
  /// 戻り値: 分析結果が反映された更新済みのDiaryRecord。
  /// 例外: 分析対象のテキストがない場合、Exceptionをスローします。
  Future<DiaryRecord> performManualAnalysis(DiaryRecord record) async {
    // 自己分析テキストがない場合はエラーとする
    if (record.selfAnalysis == null || record.selfAnalysis!.isEmpty) {
      throw Exception("分析対象のテキストがありません。");
    }

    // DiagnosisProviderからUserProfileを取得
    final userProfile = _diagnosisProvider?.userProfile;

    // GeminiServiceのanalyzeStabilityメソッドを呼び出し、
    // 日記テキストとUserProfile（あれば）を渡してAI分析を実行する
    final analysisResult = await _geminiService.analyzeStability(
      record.selfAnalysis!,
      userProfile, // UserProfileオブジェクトを引数として渡す
    );

    // 分析結果でレコードを更新
    final updatedRecord = record.copyWith(
      aiStabilityScore: analysisResult['score'], // 分析スコアを設定
      aiAnalysisReason: analysisResult['reason'], // 分析理由（アドバイス）を設定
    );

    // DBに保存
    await _diaryRepository.saveRecord(updatedRecord);

    // 利用回数を記録（SettingsProvider経由）
    await _settingsProvider?.recordManualAnalysis();

    notifyListeners(); // データ更新をUIに通知
    return updatedRecord; // 更新されたレコードを返す
  }

  /// 分析対象の新しい日付範囲を設定し、データの再集計とAIの洞察取得を行います。
  ///
  /// [newRange] 新しい日付範囲。
  Future<void> changeDateRange(DateTimeRange newRange) async {
    _dateRange = newRange;
    _isLoading = true;
    _isAiLoading = true;
    _isCosmicMapAiLoading = true; // ローディング開始
    _aiInsights = [];
    _cosmicMapInsights = []; // クリア
    notifyListeners();

    final records = await _diaryRepository.getRecordsInDateRange(
      newRange.start,
      newRange.end,
    );

    final currentUserProfile = _diagnosisProvider?.userProfile;

    if (currentUserProfile == null) {
      debugPrint(
        "Warning: UserProfile is null in AnalysisProvider.changeDateRange.",
      );
      _report = null;
      _isLoading = false;
      _isAiLoading = false;
      _isCosmicMapAiLoading = false; // ローディング終了
      notifyListeners();
      return;
    }

    _report = AnalysisReport(
      records: records,
      dateRange: newRange,
      userProfile: currentUserProfile,
    );
    _isLoading = false;
    notifyListeners();

    // 両方のAI洞察を並行して取得
    await Future.wait([fetchAiInsights(), fetchCosmicMapInsights()]);
  }

  /// 現在の分析レポートを基に、チャート用のAIによる洞察を非同期で取得します。
  Future<void> fetchAiInsights() async {
    if (_report == null) {
      _isAiLoading = false;
      notifyListeners();
      return;
    }

    final summary = AiReportToPromptMapper.toPrompt(_report!);
    // エラーハンドリングをtry-catchで行う
    try {
      final insights = await _geminiService.generateAnalysisInsights(summary);
      _aiInsights = insights;
    } catch (e) {
      _aiInsights = ['チャートの分析中にエラーが発生しました。'];
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }

  /// 現在の分析レポートを基に、宇宙図用のAIによる洞察を非同期で取得します。
  Future<void> fetchCosmicMapInsights() async {
    if (_report == null) {
      _isCosmicMapAiLoading = false;
      notifyListeners();
      return;
    }

    // CosmicMap用のプロンプトを生成
    final summary = CosmicMapToPromptMapper.toPrompt(_report!);
    // エラーハンドリングをtry-catchで行う
    try {
      final insights = await _geminiService.generateCosmicMapInsights(summary);
      _cosmicMapInsights = insights;
    } catch (e) {
      _cosmicMapInsights = ['宇宙図の解説生成中にエラーが発生しました。'];
    } finally {
      _isCosmicMapAiLoading = false;
      notifyListeners();
    }
  }

  /// グラフに表示するデータタイプを切り替えます。
  ///
  /// [dataType] 切り替えるデータタイプ。
  void toggleDataType(AnalysisDataType dataType) {
    // 既にアクティブなデータタイプの場合
    if (activeDataTypes.contains(dataType)) {
      // moodは常に必要なので削除しない
      if (dataType != AnalysisDataType.mood) {
        activeDataTypes.remove(dataType); // データタイプを非アクティブにする
      }
    } else {
      // アクティブでないデータタイプの場合
      activeDataTypes.add(dataType); // データタイプをアクティブにする
    }
    notifyListeners(); // データタイプの変更をUIに通知
  }
}
