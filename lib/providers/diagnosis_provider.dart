// lib/providers/diagnosis_provider.dart

import 'package:flutter/material.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart';
import 'package:self_awareness_diary/services/isar_service.dart'; // 本物のIsarServiceをインポート

/// 性格診断の質問リスト、回答の収集、およびUserProfileへの保存ロジックを管理するプロバイダー。
class DiagnosisProvider with ChangeNotifier {
  // 性格診断のための質問（例：構造）
  // 実際のアプリでは、これらはより詳細になり、設定から読み込まれる可能性があります
  final List<String> _questions = List.generate(
    53,
    (index) => '質問 ${index + 1}: 次の記述にどの程度同意しますか？',
  );

  // 質問リストのゲッター
  List<String> get questions => _questions;

  // 質問に対するユーザーの回答
  final List<int> _answers = []; // 回答はスケール（例：1〜5）であると仮定

  // 回答リストのゲッター
  List<int> get answers => _answers;

  // 現在のユーザープロファイル
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  final IsarService _isarService; // データベース操作のための依存関係

  // コンストラクタ。IsarServiceを受け取り、初期化時にプロファイルを読み込む。
  DiagnosisProvider(this._isarService) {
    // 初期化時に既存のプロファイルを読み込む
    _loadUserProfile();
  }

  // Isarからユーザープロファイルを読み込む
  Future<void> _loadUserProfile() async {
    _userProfile = await _isarService.getUserProfile();
    notifyListeners(); // プロファイル読み込み完了をUIに通知
  }

  /// リストに回答を追加する
  ///
  /// [answer] 追加する回答値（例：1〜5の整数）。
  void addAnswer(int answer) {
    // 回答数が質問数を超えない場合のみ追加
    if (_answers.length < _questions.length) {
      _answers.add(answer); // 回答リストに追加
      // 全ての回答が収集されたら、回答を処理する
      if (_answers.length == _questions.length) {
        _processAnswers();
      }
      notifyListeners(); // 回答リストの変更をUIに通知
    }
  }

  /// 収集された回答を処理し、スコアを計算する
  Future<void> _processAnswers() async {
    // 実際のスコア計算ロジックのためのプレースホルダー
    // これには、回答をエゴグラムスコア（CP, NP, A, FC, AC）にマッピングすることが含まれる
    // デモンストレーションのために、ダミースコアを作成する
    final cpScore = _calculateEgoGramScore(_answers, 'CP');
    final npScore = _calculateEgoGramScore(_answers, 'NP');
    final aScore = _calculateEgoGramScore(_answers, 'A');
    final fcScore = _calculateEgoGramScore(_answers, 'FC');
    final acScore = _calculateEgoGramScore(_answers, 'AC');

    // 現在のグリットレベルを計算する（プレースホルダー）
    // これは、スコアの分散またはバランスから導き出すことができる
    final grit = _calculateGritLevel(
      cpScore,
      npScore,
      aScore,
      fcScore,
      acScore,
    );

    // 新しいUserProfileを作成または更新する
    final newProfile = UserProfile(
      cp: cpScore,
      np: npScore,
      a: aScore,
      fc: fcScore,
      ac: acScore,
      lastDiagnosisDate: DateTime.now(), // 診断日を現在日時に設定
      currentGritLevel: grit, // 計算されたグリットレベルを設定
    );

    // 新しいプロファイルをIsarに保存する
    await _isarService.saveUserProfile(newProfile);
    _userProfile = newProfile; // プロバイダーのプロファイルを更新
    _answers.clear(); // 処理後に回答リストをクリアする
    notifyListeners(); // プロファイル更新と回答クリアをUIに通知
  }

  /// エゴグラムスコア計算のためのプレースホルダー関数。
  ///
  /// [answers] ユーザーの回答リスト。
  /// [type] 計算するエゴグラムのタイプ（'CP', 'NP', 'A', 'FC', 'AC'）。
  /// 戻り値：計算されたスコア（0〜99の範囲）。
  int _calculateEgoGramScore(List<int> answers, String type) {
    // 例：事前に定義された質問タイプに基づいて回答を合計する
    // 実際のアプリでは、このロジックは複雑で、53の質問のマッピングに基づくだろう
    int score = 0;
    for (int i = 0; i < answers.length; i++) {
      // ダミーロジック：質問インデックスとタイプに基づいてスコアを割り当てる
      if ((i % 5) == 0 && type == 'CP') score += answers[i];
      if ((i % 5) == 1 && type == 'NP') score += answers[i];
      if ((i % 5) == 2 && type == 'A') score += answers[i];
      if ((i % 5) == 3 && type == 'FC') score += answers[i];
      if ((i % 5) == 4 && type == 'AC') score += answers[i];
    }
    return score % 100; // デモンストレーションのために0〜99のスコアを返す
  }

  /// グリットレベル計算のためのプレースホルダー関数。
  ///
  /// [cp], [np], [a], [fc], [ac] は各エゴグラムスコア。
  /// 戻り値：計算されたグリットレベル。
  double _calculateGritLevel(int cp, int np, int a, int fc, int ac) {
    // 例：スコアの分散またはバランスに基づいた簡単な計算
    // より高い分散またはバランスは、より高いグリット/自己認識を示す可能性がある
    double average = (cp + np + a + fc + ac) / 5.0; // スコアの平均値
    // 各スコアと平均値の絶対差の合計を平均値で割る（分散のようなもの）
    double variance =
        ((cp - average).abs() +
            (np - average).abs() +
            (a - average).abs() +
            (fc - average).abs() +
            (ac - average).abs()) /
        5.0;
    return variance; // グリットレベルの代理として分散を使用する
  }

  /// 診断を開始するメソッド（例：ボタン押下から）。
  void startDiagnosis() {
    _answers.clear(); // もしあれば、以前の回答をクリアする
    notifyListeners();
    // 実際のアプリでは、質問を表示する画面にナビゲートし
    // 各回答に対して addAnswer() を呼び出す。
    debugPrint(
      "Diagnosis started. Please answer 53 questions.",
    ); // print -> debugPrint
  }

  /// ユーザープロファイルをリセットするメソッド。
  Future<void> resetUserProfile() async {
    await _isarService.clearUserProfile(); // Isarからプロファイルをクリア
    _userProfile = null; // プロバイダーのプロファイルをnullにリセット
    _answers.clear(); // 回答リストをクリア
    notifyListeners(); // UIにリセットを通知
  }
}
