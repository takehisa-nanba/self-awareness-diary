import 'package:flutter/material.dart';
import '../widgets/app_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const AppShell(title: '設定', child: Center(child: Text('設定画面（準備中）')));
  }
}