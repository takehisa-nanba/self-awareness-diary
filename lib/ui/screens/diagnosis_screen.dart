// lib/ui/screens/diagnosis_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/diagnosis_provider.dart';
import '../widgets/universe_background.dart';
import 'root_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 指定したページ（設問）へスクロールする内部メソッド
  void _jumpToQuestion(int index) {
    if (index < 0) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisProvider = context.watch<DiagnosisProvider>();
    final questions = diagnosisProvider.questions;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _DiagnosisAppBarTitle(
          currentPage: _currentPage,
          totalQuestions: questions.length,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: kToolbarHeight * 1.5,
      ),
      body: Stack(
        children: [
          const UniverseBackground(),
          
          // 進捗バー
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ConstellationProgressBar(
              totalQuestions: questions.length,
              answeredQuestions: diagnosisProvider.answeredCount,
              currentQuestionIndex: _currentPage,
            ),
          ),

          // 質問カード（PageView）
          Padding(
            padding: const EdgeInsets.only(top: 100, bottom: 120),
            child: PageView.builder(
              controller: _pageController,
              itemCount: questions.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final question = questions[index]['question']!;
                return _QuestionCard(
                  question: question,
                  questionIndex: index,
                  onAnswer: (answer) {
                    diagnosisProvider.addAnswer(index, answer);
                    // 最後でなければ自動で次へ
                    if (index < questions.length - 1) {
                      _jumpToQuestion(index + 1);
                    }
                  },
                );
              },
            ),
          ),

          // ナビゲーションボタン
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 戻るボタン
                if (_currentPage > 0)
                  FloatingActionButton.small(
                    heroTag: 'prevBtn',
                    onPressed: () => _jumpToQuestion(_currentPage - 1),
                    child: const Icon(Icons.arrow_back),
                  )
                else
                  const SizedBox.shrink(),

                // 完了 または 次へボタン
                if (_currentPage == questions.length - 1)
                  FloatingActionButton.small(
                    heroTag: 'finishBtn',
                    onPressed: () async {
                      // 1. 非同期処理の前に必要なオブジェクトを取得しておく
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      if (!diagnosisProvider.isAllAnswered) {
                        final targetIndex = diagnosisProvider.firstUnansweredIndex;
                        await _pageController.animateToPage(
                          targetIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                        // 2. await の後は必ずチェック
                        if (!context.mounted) return;
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('未回答の設問があります')),
                        );
                      } else {
                        // 3. showDialog の前にもチェックを入れる（他ブランチに await があるため）
                        if (!context.mounted) return;
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('お疲れ様でした。'),
                            content: const Text('すべての設問を確定します。\nよろしいですか？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('キャンセル')),
                              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('はい（確定）')),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await diagnosisProvider.processAnswers();
                          // 4. 遷移の前にも必ずチェック
                          if (!context.mounted) return;
                          navigator.pushReplacement(
                            MaterialPageRoute(builder: (_) => const RootScreen()),
                          );
                        }
                      }
                    },
                    child: const Icon(Icons.check),
                  )
                else
                  FloatingActionButton.small(
                    heroTag: 'nextBtn',
                    onPressed: () => _jumpToQuestion(_currentPage + 1),
                    child: const Icon(Icons.arrow_forward),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final String question;
  final int questionIndex;
  final Function(int) onAnswer;

  const _QuestionCard({
    required this.question,
    required this.questionIndex,
    required this.onAnswer,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  int? _localSelected;

  @override
  void initState() {
    super.initState();
    // プロバイダーから既存の回答を取得して初期状態に反映
    final provider = context.read<DiagnosisProvider>();
    if (widget.questionIndex < provider.answers.length) {
      _localSelected = provider.answers[widget.questionIndex];
    }
  }

  ButtonStyle _getButtonStyle(int value) {
    final theme = Theme.of(context);
    final isSelected = _localSelected == value;
    return ElevatedButton.styleFrom(
      foregroundColor: isSelected ? theme.colorScheme.onPrimary : Colors.white,
      backgroundColor: isSelected 
          ? theme.colorScheme.primary 
          : Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4FD1C5).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildAnswerButton('はい', 1),
                  const SizedBox(height: 12),
                  _buildAnswerButton('いいえ', -1),
                  const SizedBox(height: 12),
                  _buildAnswerButton('どちらでもない', 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String label, int value) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: _getButtonStyle(value),
        onPressed: () {
          setState(() => _localSelected = value);
          widget.onAnswer(value);
        },
        child: Text(label),
      ),
    );
  }
}

class _ConstellationProgressBar extends StatelessWidget {
  final int totalQuestions;
  final int answeredQuestions;
  final int currentQuestionIndex;

  const _ConstellationProgressBar({
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.currentQuestionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(totalQuestions, (index) {
            Color dotColor;
            if (index < answeredQuestions) {
              dotColor = Theme.of(context).colorScheme.primary;
            } else if (index == currentQuestionIndex) {
              dotColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
            } else {
              dotColor = Colors.white24;
            }

            return Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DiagnosisAppBarTitle extends StatelessWidget {
  final int currentPage;
  final int totalQuestions;

  const _DiagnosisAppBarTitle({
    required this.currentPage,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '性格診断',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${currentPage + 1}/$totalQuestions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}