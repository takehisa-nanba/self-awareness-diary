// lib/providers/diagnosis_provider.dart

import 'package:flutter/material.dart';
import 'package:self_awareness_diary/domain/models/user_profile.dart';
import 'package:self_awareness_diary/services/isar_service.dart'; // 本物のIsarServiceをインポート

/// 性格診断の質問リスト、回答の収集、およびUserProfileへの保存ロジックを管理するプロバイダー。
class DiagnosisProvider with ChangeNotifier {
  // 性格診断のための質問（例：構造）
  // 実際のアプリでは、これらはより詳細になり、設定から読み込まれる可能性があります
  final List<Map<String, String>> _questions = [
    // CP (Critical Parent - 批判的親) - 11 questions
    {'question': '他人の間違いがとても気になる方だ。', 'egoState': 'CP'},
    {'question': '規律やルールは守るべきだと思う。', 'egoState': 'CP'},
    {'question': '人に厳しく接することがよくある。', 'egoState': 'CP'},
    {'question': '物事を完璧にこなしたいと常に思う。', 'egoState': 'CP'},
    {'question': '自分の意見をはっきりと言う方だ。', 'egoState': 'CP'},
    {'question': '努力や忍耐は成功に不可欠だと思う。', 'egoState': 'CP'},
    {'question': '無責任な行動は許せない。', 'egoState': 'CP'},
    {'question': '人を指導することに抵抗がない。', 'egoState': 'CP'},
    {'question': 'やるべきことは最後までやり遂げる。', 'egoState': 'CP'},
    {'question': '自分の考えが正しいと信じている。', 'egoState': 'CP'},
    {'question': '時間には正確でありたい。', 'egoState': 'CP'},

    // NP (Nurturing Parent - 養育的親) - 11 questions
    {'question': '人の気持ちを察することが得意だ。', 'egoState': 'NP'},
    {'question': '困っている人を見ると助けたくなる。', 'egoState': 'NP'},
    {'question': '人を励まし、元気づけることが多い。', 'egoState': 'NP'},
    {'question': '優しい言葉をかけるように心がけている。', 'egoState': 'NP'},
    {'question': '相手の意見を尊重するようにしている。', 'egoState': 'NP'},
    {'question': '人の面倒を見るのが好きだ。', 'egoState': 'NP'},
    {'question': '誰かのために尽くすことに喜びを感じる。', 'egoState': 'NP'},
    {'question': '人を許すことは大切だと思う。', 'egoState': 'NP'},
    {'question': '人のはなしをじっくり聞くことができる。', 'egoState': 'NP'},
    {'question': '争いごとは避けたい方だ。', 'egoState': 'NP'},
    {'question': '周囲の雰囲気を和ませる役割をすることが多い。', 'egoState': 'NP'},

    // A (Adult - 大人の自分) - 11 questions
    {'question': '物事を論理的に考えることが好きだ。', 'egoState': 'A'},
    {'question': '感情に流されず、冷静に判断できる。', 'egoState': 'A'},
    {'question': '事実に基づいて行動する方だ。', 'egoState': 'A'},
    {'question': '計画を立ててから行動に移す。', 'egoState': 'A'},
    {'question': '問題解決のために情報を集める。', 'egoState': 'A'},
    {'question': '状況を客観的に分析できる。', 'egoState': 'A'},
    {'question': '効率を重視して物事を進める。', 'egoState': 'A'},
    {'question': '損得を考えて行動することがよくある。', 'egoState': 'A'},
    {'question': '自分の意見を根拠に基づいて説明できる。', 'egoState': 'A'},
    {'question': '現実的な解決策を導き出すのが得意だ。', 'egoState': 'A'},
    {'question': '感情的な議論は苦手だ。', 'egoState': 'A'},

    // FC (Free Child - 自由な子ども) - 10 questions
    {'question': '自分の感情を素直に表現する方だ。', 'egoState': 'FC'},
    {'question': '楽しいことにはすぐに飛びつく。', 'egoState': 'FC'},
    {'question': '好奇心旺盛で、新しいことに挑戦するのが好きだ。', 'egoState': 'FC'},
    {'question': '面白いと思ったらすぐに行動する。', 'egoState': 'FC'},
    {'question': '遊びや趣味に夢中になることが多い。', 'egoState': 'FC'},
    {'question': '枠にとらわれず自由に発想する。', 'egoState': 'FC'},
    {'question': '自分の感情に正直に行動する。', 'egoState': 'FC'},
    {'question': '気分転換が上手だ。', 'egoState': 'FC'},
    {'question': '退屈なことは苦手だ。', 'egoState': 'FC'},
    {'question': 'ユーモアのセンスがあると言われる。', 'egoState': 'FC'},

    // AC (Adapted Child - 順応した子ども) - 10 questions
    {'question': '人の期待に応えようと努力する。', 'egoState': 'AC'},
    {'question': '周囲の意見に合わせて自分の行動を変えることがある。', 'egoState': 'AC'},
    {'question': '人に嫌われることを恐れる。', 'egoState': 'AC'},
    {'question': '自分の気持ちを抑えることがある。', 'egoState': 'AC'},
    {'question': '人の顔色をうかがう方だ。', 'egoState': 'AC'},
    {'question': '場の空気を読むことが得意だ。', 'egoState': 'AC'},
    {'question': '決断を人に委ねることがよくある。', 'egoState': 'AC'},
    {'question': '人の頼みを断るのが苦手だ。', 'egoState': 'AC'},
    {'question': '他人に合わせて行動することが多い。', 'egoState': 'AC'},
    {'question': '批判されると落ち込みやすい。', 'egoState': 'AC'},
  ];

  // 質問リストのゲッター
  List<Map<String, String>> get questions => _questions;

  // 質問に対するユーザーの回答
  final List<int?> _answers = List.filled(53, null); // 回答は質問インデックスと回答値のリストで保持

  // 回答リストのゲッター
  List<int?> get answers => _answers;

  // 現在のユーザープロファイル
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  final IsarService _isarService; // データベース操作のための依存関係

  // コンストラクタ。IsarServiceを受け取り、初期化時にプロファイルを読み込む。
  DiagnosisProvider(this._isarService) {
    // 初期化時に既存のプロファイルを読み込む
    _loadUserProfile();
  }

  // Isarからユーザープロファイルを読み込む
  Future<void> _loadUserProfile() async {
    _isLoading = true;
    notifyListeners(); // UIにローディング開始を通知

    _userProfile = await _isarService.getUserProfile();
    _isLoading = false;
    notifyListeners(); // プロファイル読み込み完了とUIに通知
  }

  /// 質問インデックスと回答値を受け取り、リストに回答を追加する。
  ///
  /// [index] 回答する質問のインデックス。
  /// [value] 追加する回答値（例：1, -1, 0）。
  void addAnswer(int index, int value) {
    if (index >= 0 && index < _answers.length) {
      _answers[index] = value; // 回答をリストに格納
      debugPrint(
        'addAnswer: index=$index, value=$value, _answers.length=${_answers.length}',
      );
      notifyListeners(); // 回答リストの変更をUIに通知
    } else {
      debugPrint('Error: Index out of bounds in addAnswer: $index');
    }
  }

  /// 収集された回答を処理し、スコアを計算する
  Future<void> processAnswers() async {
    if (!isAllAnswered) return; // 未回答の質問がある場合は処理を中断

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
    _answers.fillRange(0, _answers.length, null); // 処理後に回答リストをクリアする
    notifyListeners(); // プロファイル更新と回答クリアをUIに通知
  }

  /// エゴグラムスコア計算のためのプレースホルダー関数。
  ///
  /// [answers] ユーザーの回答リスト。
  /// [type] 計算するエゴグラムのタイプ（'CP', 'NP', 'A', 'FC', 'AC'）。
  /// 戻り値：計算されたスコア（0〜100の範囲）。
  int _calculateEgoGramScore(List<int?> answers, String type) {
    int egoStateTotalScore = 0;
    int questionCountForEgoState = 0;

    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i]['egoState'] == type) {
        questionCountForEgoState++;
        egoStateTotalScore += (answers[i] ?? 0); // 回答がない場合は0とする
      }
    }

    if (questionCountForEgoState == 0) return 50; // 該当する質問がない場合は中央値

    // スコアを0-100の範囲に正規化
    // 回答は -1, 0, 1 なので、質問数 * -1 から 質問数 * 1 の範囲
    final double minPossibleScore = -questionCountForEgoState.toDouble();
    final double maxPossibleScore = questionCountForEgoState.toDouble();

    // 現在の合計スコアを0-1に正規化
    final double normalizedToZeroOne =
        (egoStateTotalScore - minPossibleScore) /
        (maxPossibleScore - minPossibleScore);

    // 0-100にスケーリング
    return (normalizedToZeroOne * 100).round().clamp(0, 100);
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

  /// 性格診断が完了しているかどうかを判定するゲッター。
  bool get isAllAnswered => !_answers.contains(null);

  /// 未回答の最初の質問のインデックスを返す。全て回答済みであれば-1を返す。
  int get firstUnansweredIndex => _answers.indexOf(null);

  /// 回答済みの質問の数を返すゲッター。
  int get answeredCount => _answers.where((e) => e != null).length;

  /// 診断を開始するメソッド（例：ボタン押下から）。
  void startDiagnosis() {
    _answers.fillRange(0, _answers.length, null); // もしあれば、以前の回答をクリアする
    notifyListeners();
    // 実際のアプリでは、質問を表示する画面にナビゲートし
    // 各回答に対して addAnswer() を呼び出す。
    debugPrint(
      "Diagnosis started. Please answer ${_questions.length} questions.",
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
