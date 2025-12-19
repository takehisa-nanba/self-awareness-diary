import 'package:flutter/material.dart';

class ExtendedFabNavigator extends StatelessWidget {
  const ExtendedFabNavigator({super.key});

  void _navigate(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.menu, color: Colors.indigo),
      ),
      onSelected: (route) => _navigate(context, route),
      itemBuilder: (context) => [
        const PopupMenuItem(value: '/', child: Text('書く')),
        const PopupMenuItem(value: '/history', child: Text('履歴')),
        const PopupMenuItem(value: '/analysis', child: Text('分析')),
        const PopupMenuItem(value: '/settings', child: Text('設定')),
      ],
    );
  }
}