import 'package:flutter/material.dart';
import '../widgets/app_shell.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: '分析',
      child: Center(
        child: Text('分析画面（開発中）'),
      ),
    );
  }
}