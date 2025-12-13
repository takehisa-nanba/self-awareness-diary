import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

const double kAppHeaderH = 66.0;  // カスタムヘッダーの高さ
const double kFabMarginTop = 5.0; // ナビゲーターボタンの微調整用

class AppShell extends StatelessWidget {
  final Widget child;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppShell({
    super.key,
    required this.child,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  void _navigateToScreen(BuildContext context, int index) {
    String routeName;
    switch (index) {
      case 0: 
        routeName = '/'; 
        // ホームに戻るときは、ルートスタックをクリアして最上部に移動
        Navigator.of(context).popUntil((route) => route.isFirst);
        // 現在のルートが '/' でない場合にのみプッシュ
        if (ModalRoute.of(context)?.settings.name != routeName) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                routeName, 
                (Route<dynamic> route) => false // 全てのルートを削除
            );
        }
      return;
      case 1:
        routeName = '/history';
        break;
      case 2:
        routeName = '/analysis';
        break;
      case 3:
        routeName = '/settings';
        break;
      default:
        return;
    }
    if (ModalRoute.of(context)?.settings.name == routeName) {
      // 何もしない
      return;
    }
    // ここでは単純な画面遷移 (pushNamed) を使用
    Navigator.of(context).pushNamed(routeName); 
  }

  @override
  Widget build(BuildContext context) {
    
    final double safePaddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      // AppBarを削除し、bodyのStackでカスタムヘッダーを構築
      body: Stack(
        children: [
          // 1. メインコンテンツ (NewEntryScreen) - ヘッダーの高さ分下にずらす
          Padding(
            // カスタムヘッダーの高さ(56.0)分、コンテンツ全体を下にずらす
            padding: EdgeInsets.only(top: kAppHeaderH + safePaddingTop), 
            child: child,
          ),
          
          // 2. カスタムヘッダーエリアの構築 (L2: タイトル)
          Positioned(
            left: 0,
            right: 0,
            top: safePaddingTop, 
            child: Container(
              height: kAppHeaderH, 
              color: Colors.orange.shade700, 
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row( // Row を使ってナビゲーターとタイトルを分離する
                children: [
                   // (ナビゲーターが Positioned で上にあるため、スペース確保のために SizedBox を入れる)
                   const SizedBox(width: 56.0 + 16.0), // ナビゲーターの幅(約56px) + 左側のマージン(16px) 
                   
                   // アプリ名 (L2) を中央に寄せるために Expanded でラップ
                   Expanded(
                     child: Text(
                       '自己覚知日記', 
                       textAlign: TextAlign.center, // テキストを中央寄せ
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         color: Colors.white,
                       ),
                     ),
                   ),
                   const SizedBox(width: 56.0), // 右側にも同じ幅のスペースを確保
                ],
              ),
            ),
          ),
          
          // 3. ナビゲーター (L3: 最前面) を左端に固定
          Positioned(
            left: 16.0, 
            top: safePaddingTop + kFabMarginTop, 
            child: ExtendedFabNavigator(
              onNavigationSelected: (index) => _navigateToScreen(context, index),
            ),
          ),
        ],
      ),
      
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}