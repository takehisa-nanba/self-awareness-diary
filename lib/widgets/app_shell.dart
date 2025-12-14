import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

const double kAppHeaderH = 66.0;  // カスタムヘッダーの高さ
const double kFabMarginTop = 5.0; // ナビゲーターボタンの微調整用

class AppShell extends StatelessWidget {
  final Widget child;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showNavigator; // ★★★ 修正1: ナビゲーター表示フラグを追加 ★★★
  final String? title;      // ★★★ 修正2: タイトルを外部から渡せるようにする ★★★
  final PreferredSizeWidget? customHeader; // ★★★ 修正1: customHeader 引数を追加 ★★★
  

  const AppShell({
    super.key,
    required this.child,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showNavigator = true, // ★★★ デフォルトを true に設定 ★★★
    this.title = '自己覚知日記', // ★★★ デフォルトを設定 ★★★
    this.customHeader, // ★★★ customHeader を受け入れる ★★★
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
    final double navigatorWidth = showNavigator ? (56.0 + 5.0) : 0.0;
    final double customHeaderHeight = customHeader?.preferredSize.height ?? 0.0;
    final double totalHeaderHeight = kAppHeaderH  + customHeaderHeight;

    return Scaffold(
      // AppBarを削除し、bodyのStackでカスタムヘッダーを構築
      body: Stack(
        children: [
          // 1. メインコンテンツ (WriteScreen) - ヘッダーの高さ分下にずらす
          Padding(
            padding: EdgeInsets.only(top: totalHeaderHeight - safePaddingTop), 
            child: child,
          ),

          // ★★★ 修正2: Z-Index調整のため、ナビゲーターを最初に配置（最背面） ★★★
          // ナビゲーターはカスタムヘッダーの下に潜り込む
          // 2. AppShell のカスタムヘッダーエリア (L2: 固定タイトル)
          Positioned(
            left: 0,
            right: 0,
            top: safePaddingTop, 
            child: Container(
              height: kAppHeaderH, 
              color: Colors.orange.shade700, 
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                children: [
                  SizedBox(width: navigatorWidth), 
                  
                  Expanded(
                    child: Text(
                      title!, 
                      textAlign: TextAlign.center, 
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: navigatorWidth),
                ],
              ),
            ),
          ),
            
          // 3. customHeader（ステップ表示） (AppShellヘッダーより後に配置され、Z-Indexが上)
          if (customHeader != null)
            Positioned(
              left: 0,
              right: 0,
              top: safePaddingTop + kAppHeaderH, // ナビゲーターと重ならないように調整
              child: customHeader!,
            ),
          if (showNavigator)
            Positioned(
              left: 5.0, 
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