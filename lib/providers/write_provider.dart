// lib/providers/write_provider.dart

import 'package:flutter/material.dart'; // ChangeNotifierのために必要
import 'package:uuid/uuid.dart';
import '../../domain/models/diary_record.dart';
import 'history_provider.dart';
import 'settings_provider.dart';
import '../services/environment_coordinator.dart';
import '../services/gemini_service.dart';
import '../../domain/repositories/diary_repository.dart';

/// 日記作成プロセス全体の状態を管理するプロバイダークラス。
///
/// ユーザーの入力データ、ステップの進行状況、環境データの取得、
/// AIとの連携（深掘り質問生成、心の安定度分析）、および日記の保存を担当します。
class WriteProvider with ChangeNotifier {
  /// 現在の日記作成ステップ (0:タグ選択, 1:気分/出来事入力, 2:自己分析)。
  int _currentStep = 0;
  int get currentStep => _currentStep;

  /// 更新対象の日記レコードのIsar ID。これがnullでない場合、更新モードと判断する。
  /// 更新対象の日記レコードのIsar ID。これがnullでない場合、更新モードと判断する。
  int? isarId;

  // 連携するProvider
  /// 履歴プロバイダーへの参照。日記保存後に履歴を更新するために使用。
  HistoryProvider? _historyProvider;

  /// 設定プロバイダーへの参照。サブスクリプションティアの確認などに使用。
  SettingsProvider? _settingsProvider;

  /// 環境データ（位置情報、天気）を調整するためのコーディネーターサービス。
  final EnvironmentCoordinator _environmentCoordinator;

  /// Gemini AIサービス。深掘り質問の生成や心の安定度分析に使用。
  final GeminiService _geminiService;

  /// 日記レコードを保存するためのリポジトリ。
  final DiaryRepository _diaryRepository;

  // 入力データ
  /// ユーザーが選択した気分のスコア。
  int moodScore = 5;

  /// ユーザーが選択した気分タグのリスト。
  List<String> selectedTags = [];

  /// ユーザーが入力した出来事のテキスト。
  String eventText = "";

  /// ユーザーが入力した自己分析のテキスト。
  String selfAnalysisText = "";

  /// AIによって生成された深掘り質問。
  String reflectionQuestion = "";

  // 位置・天気データ
  /// 一時的に格納される現在の場所情報。
  String? tempLocation;

  /// 一時的に格納される現在の天気情報。
  String? tempWeather;

  /// 一時的に格納される現在の緯度。
  double? tempLat;

  /// 一時的に格納される現在の経度。
  double? tempLng;

  /// AIが深掘り質問を生成中かどうかを示すフラグ。
  bool isGenerating = false;

  /// 日記を保存中かどうかを示すフラグ。
  bool isSaving = false;

  /// [WriteProvider] のコンストラクタ。
  ///
  /// 依存する環境コーディネーター、Geminiサービス、日記リポジトリを受け取ります。
  WriteProvider(
    this._environmentCoordinator,
    this._geminiService,
    this._diaryRepository,
  );

  /// 連携する他のプロバイダー ([HistoryProvider], [SettingsProvider]) を登録します。
  ///
  /// 主に [MultiProvider] の `builder` 関数から呼び出されます。
  void updateProviders(HistoryProvider history, SettingsProvider settings) {
    _historyProvider = history;
    _settingsProvider = settings;
    notifyListeners();
  }

  /// 既存の日記レコードを編集するために、プロバイダーの状態を初期化します。
  ///
  /// [record] 編集対象の [DiaryRecord] オブジェクト。
  /// 既存の日記レコードを編集するために、プロバイダーの状態を初期化します。
  ///
  /// [record] 編集対象の [DiaryRecord] オブジェクト。
  void initForEdit(DiaryRecord record) {
    _currentStep = 2; // 自己分析ステップから開始
    isarId = record.isarId; // 編集対象レコードのIsar IDを保持
    moodScore = record.moodScore;
    selectedTags = List.from(record.moodTags);
    eventText = record.eventText;
    selfAnalysisText = record.selfAnalysis ?? "";
    tempLocation = record.location;
    tempWeather = record.weather;
    tempLat = record.latitude;
    tempLng = record.longitude;
    reflectionQuestion = ""; // 編集時はAI質問をクリア
    notifyListeners();
  }

  /// 環境コーディネーターを通じて、最新の位置情報と天気データを取得します。
  ///
  /// データ取得中はローディング表示を行い、完了後にUIを更新します。
  Future<void> fetchEnvironmentData() async {
    // UIに「取得中」と表示するのは、まだデータが何もない初回のみ
    if (tempLocation == null) {
      tempLocation = "位置情報取得中...";
      notifyListeners();
    }

    // Coordinatorに問い合わせる。キャッシュ管理はCoordinatorの責任。
    try {
      final data = await _environmentCoordinator.fetchFullData();

      // 取得したデータでUIを更新
      tempLocation = data.location;
      tempWeather = data.weather;
      tempLat = data.latitude;
      tempLng = data.longitude;
    } catch (e) {
      debugPrint("識別依頼エラー: $e");
      tempLocation = "位置情報取得失敗";
    } finally {
      notifyListeners();
    }
  }

  /// 日記作成の次のステップへ進みます。
  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  /// 日記作成の前のステップへ戻ります。
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// Gemini AIを使用して、ユーザーの出来事とタグに基づいた深掘り質問を生成します。
  ///
  /// 生成中は `isGenerating` フラグを `true` に設定し、UIにローディング状態を通知します。
  Future<void> prepareReflection() async {
    if (eventText.isEmpty) return;

    isGenerating = true;
    notifyListeners();

    try {
      reflectionQuestion = await _geminiService.generateReflectionQuestion(
        eventText: eventText,
        tags: selectedTags.join(', '),
      );
    } catch (e) {
      reflectionQuestion = "その出来事は、あなたにとってどんな意味がありましたか？"; // エラー時のフォールバック
      debugPrint("Gemini Error: $e");
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  /// 入力されたデータと取得した環境データ、AI分析結果を統合して、
  /// 日記レコードを保存または更新します。
  ///
  /// `isarId` がnullでない場合は更新、nullの場合は新規保存を行います。
  Future<void> save() async {
    isSaving = true;
    notifyListeners();

    try {
      int? aiScore;
      String? aiReason;

      // Tier 2ユーザーで、かつ自己分析が5文字以上の場合のみAI分析を実行
      if (_settingsProvider?.currentTier == SubscriptionTier.tier2 &&
          selfAnalysisText.length >= 5) {
        try {
          final analysis = await _geminiService.analyzeStability(
            selfAnalysisText,
          );
          aiScore = analysis['score'];
          aiReason = analysis['reason'];
        } catch (e) {
          debugPrint("AI Analysis Error: $e");
        }
      }

      DiaryRecord record;
      if (isarId != null) {
        // 更新モードの場合: 既存のレコードをデータベースから取得し、変更されたフィールドを更新する
        final existingRecord = await _diaryRepository.getRecordByIsarId(isarId!);
        if (existingRecord != null) {
          // 既存レコードのIDと記録日時を維持しつつ、編集された内容で新しいDiaryRecordオブジェクトを作成
          record = DiaryRecord(
            isarId: isarId,
            recordId: existingRecord.recordId, // 既存のrecordIdを維持
            recordDate: existingRecord.recordDate, // 記録日時は更新しない
            moodTags: List.from(selectedTags),
            moodScore: moodScore,
            eventText: eventText,
            selfAnalysis: selfAnalysisText,
            aiStabilityScore: aiScore,
            aiAnalysisReason: aiReason,
            location: tempLocation,
            weather: tempWeather,
            latitude: tempLat,
            longitude: tempLng,
          );
        } else {
          // IDがあるのにレコードが見つからない場合は例外をスロー
          throw Exception("Record with isarId $isarId not found for update.");
        }
      } else {
        // 新規作成モードの場合: 新しいレコードとしてDiaryRecordオブジェクトを作成
        record = DiaryRecord(
          recordId: const Uuid().v4(), // 一意なUUIDを生成
          recordDate: DateTime.now(), // 現在の日時を記録日時とする
          moodTags: List.from(selectedTags),
          moodScore: moodScore,
          eventText: eventText,
          selfAnalysis: selfAnalysisText,
          aiStabilityScore: aiScore,
          aiAnalysisReason: aiReason,
          location: tempLocation,
          weather: tempWeather,
          latitude: tempLat,
          longitude: tempLng,
        );
      }

      // DiaryRepositoryを介してレコードを保存または更新
      await _diaryRepository.saveRecord(record);
      debugPrint(
        "日記${isarId == null ? '保存' : '更新'}完了: ${record.recordId}", // ログ出力
      );

      // 履歴画面をリフレッシュ
      _historyProvider?.refreshHistory();

      _reset(); // フォームの状態をリセット
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// 日記作成フォームのすべての入力状態を初期値にリセットします。
  /// 日記作成フォームのすべての入力状態を初期値にリセットします。
  void _reset() {
    _currentStep = 0;
    isarId = null; // 更新IDをクリア
    moodScore = 5;
    selectedTags = [];
    eventText = "";
    selfAnalysisText = "";
    reflectionQuestion = "";
    notifyListeners();
    debugPrint("WriteProvider：入力内容はリセットされました。");
  }

  /// リスナーに状態の変更を通知します。
  void notify() {
    notifyListeners();
  }
}
