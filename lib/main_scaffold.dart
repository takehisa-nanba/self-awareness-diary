// lib/main_scaffold.dart
import 'package:myapp/screens/settings_screen.dart';

import 'screens/new_entry_screen.dart';
import 'package:flutter/material.dart';

// 【TODO: 画面ファイルを作成したら、コメントアウトを外す】
import 'screens/history_screen.dart';
import 'screens/ai_assistant_screen.dart';
// import 'screens/settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0; // 現在選択されているタブのインデックス

  // 画面リストの定義 (今回は仮のTextで代用)
  static final List<Widget> _widgetOptions = <Widget>[
    const HistoryScreen(), // Index 0: 履歴/タイムライン画面を正式に設定
    const AIAssistantScreen(), // Index 1: AI Assistant画面を正式に設定
    const SettingsScreen(), // Index 2: Settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------
      // Body: 選択されたタブの画面を表示
      // ------------------------------------
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // ------------------------------------
      // FAB: 新規記録作成へのクイックアクセス (F-1)
      // FloatingActionButtonLocation.endFloat に変更
      // ------------------------------------
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewEntryScreen(), // 新規入力画面へ遷移
            ),
          );
        },
        tooltip: '新規記録',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ------------------------------------
      // BottomNavigationBar: シンプルな構造に戻す
      // ------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // 履歴/ホーム (F-3)
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '記録',
          ),
          // AIアシスト (F-7)
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AIアシスト',
          ),
          // 設定
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: _selectedIndex,
        // 選択されていないアイコンの色を調整（Optional: テーマによって自動で色がつく場合もあります）
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
