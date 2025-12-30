import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'root_screen.dart';

class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen> {
  final List<String> _lines = [
    'あなたらしさは、あなたの中に。🪨',
    'じぶんを磨く、こころがわかる。💎',
    '「じぶんを磨く日記帳」',
  ];
  final List<String> _displayedLines = ['', '', ''];
  int _currentLine = 0;
  int _currentChar = 0;
  Timer? _timer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentLine < 2) {
          final runes = _lines[_currentLine].runes.toList();
          if (_currentChar < runes.length) {
            _displayedLines[_currentLine] += String.fromCharCode(
              runes[_currentChar],
            );
            _currentChar++;
          } else {
            _timer?.cancel();
            Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                _currentLine++;
                _currentChar = 0;
                _startAnimation();
              }
            });
          }
        } else {
          _displayedLines[2] = _lines[2];
          _timer?.cancel();
          Timer(const Duration(milliseconds: 1500), _navigateToHome);
        }
      });
    });
  }

  void _navigateToHome() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    context.read<SettingsProvider>().completeFirstLaunch();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RootScreen(),
        transitionDuration: const Duration(milliseconds: 1500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final angle = animation.value * 1.57; // 手前に開くように正の角度に変更
          final opacity = 1.0 - animation.value;

          return Stack(
            children: [
              child,
              if (animation.status != AnimationStatus.completed)
                Opacity(
                  opacity: opacity,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.centerLeft,
                    child: const _SplashScreenContent(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF2E7D32);

    return GestureDetector(
      onTap: _navigateToHome,
      child: Scaffold(
        backgroundColor: const Color(0xFF98FB98),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedText(
                text: _displayedLines[0],
                style: const TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 16),
              _AnimatedText(
                text: _displayedLines[1],
                style: const TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 40),
              AnimatedOpacity(
                opacity: _displayedLines[2].isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _lines[2],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _AnimatedText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(text, key: ValueKey<String>(text), style: style),
    );
  }
}

class _SplashScreenContent extends StatelessWidget {
  const _SplashScreenContent();

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFF98FB98),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'あなたらしさは、あなたの中に。🪨',
              style: const TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'じぶんを磨く、こころがわかる。💎',
              style: const TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 40),
            Text(
              '「じぶんを磨く日記帳」',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
