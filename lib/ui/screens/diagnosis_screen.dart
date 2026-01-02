// lib/ui/screens/diagnosis_screen.dart

import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/diagnosis_provider.dart';
import '../widgets/universe_background.dart';
import 'root_screen.dart'; // For navigation after diagnosis

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

  @override
  Widget build(BuildContext context) {
    final diagnosisProvider = context.watch<DiagnosisProvider>();
    final questions = diagnosisProvider.questions;

    return Scaffold(
      extendBodyBehindAppBar: true, // Make body content extend behind app bar
      appBar: AppBar(
        title: _DiagnosisAppBarTitle(
          currentPage: _currentPage,
          totalQuestions: questions.length,
        ),
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        toolbarHeight: kToolbarHeight * 1.5, // Increase AppBar height
      ),
      body: Stack(
        children: [
          // Integrate UniverseBackground
          const UniverseBackground(),
          // Constellation Progress Bar at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ConstellationProgressBar(
              totalQuestions: questions.length,
              answeredQuestions: diagnosisProvider.answers.length,
              currentQuestionIndex: _currentPage,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top:
                  AppBar().preferredSize.height +
                  20 +
                  20, // AppBar height + Progress bar height + some spacing
              bottom:
                  40 +
                  56 +
                  20, // Bottom navigation height (approx) + FAB height + spacing
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: questions.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final question = questions[index]['question']!;
                return _QuestionCard(
                  question: question,
                  onAnswer: (answer) {
                    diagnosisProvider.addAnswer(answer);
                    _nextQuestion(diagnosisProvider.questions.length);
                  },
                );
              },
            ),
          ),
          // Navigation buttons (Previous/Next)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  FloatingActionButton.small(
                    heroTag: 'prevBtn',
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                    child: const Icon(Icons.arrow_back),
                  )
                else
                  const SizedBox.shrink(),
                if (_currentPage == questions.length - 1)
                  FloatingActionButton.small(
                    heroTag: 'finishBtn',
                    onPressed: () {
                      // Call processAnswers and navigate
                      diagnosisProvider.processAnswers();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const RootScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.check),
                  )
                else
                  FloatingActionButton.small(
                    heroTag: 'nextBtn',
                    onPressed: () {
                      // If not the last question, ensure an answer is selected before proceeding.
                      // For now, we allow next even if no answer, will add validation later.
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                    child: const Icon(Icons.arrow_forward),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextQuestion(int totalQuestions) {
    if (_currentPage < totalQuestions - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Last question handled by the "Finish" button
    }
  }
} // Closes _DiagnosisScreenState

class _QuestionCard extends StatelessWidget {
  final String question;
  final Function(int) onAnswer;

  const _QuestionCard({required this.question, required this.onAnswer});

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
                color: Colors.white.withAlpha(
                  (255 * 0.05).round(),
                ), // Background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(
                    0xFF4FD1C5,
                  ).withAlpha((255 * 0.3).round()), // Border
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    question,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => onAnswer(1), // はい
                              child: const Text('はい'),
                            ),
                          ),
                          const SizedBox(width: 8), // Spacing between buttons
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  onAnswer(-1), // いいえ (Negative contribution)
                              child: const Text('いいえ'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Spacing between rows
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => onAnswer(0), // どちらでもない (Neutral)
                              child: const Text('どちらでもない'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
        height: 20, // Height for the progress bar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(totalQuestions, (index) {
            Color dotColor;
            if (index < answeredQuestions) {
              dotColor = Theme.of(
                context,
              ).colorScheme.primary; // Lit (answered)
            } else if (index == currentQuestionIndex) {
              dotColor = Theme.of(context).colorScheme.primary.withAlpha(
                (255 * 0.5).round(),
              ); // Current question (dimmed)
            } else {
              dotColor = Colors.white24; // Unlit
            }

            return Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                width: 4, // Width of each dot
                height: 4, // Height of each dot
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
