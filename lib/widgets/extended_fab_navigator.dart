// lib/widgets/extended_fab_navigator.dart

import 'package:flutter/material.dart';

class ExtendedFabNavigator extends StatefulWidget {
  final Function(int index) onNavigationSelected;
  
  const ExtendedFabNavigator({
    super.key, 
    required this.onNavigationSelected,
  });

  @override
  State<ExtendedFabNavigator> createState() => _ExtendedFabNavigatorState();
}

class _ExtendedFabNavigatorState extends State<ExtendedFabNavigator> with SingleTickerProviderStateMixin {
  
  // アニメーションコントローラーとアニメーション定義
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // FABが展開されているかどうか
  bool _isOpen = false; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController( 
      vsync: this, 
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  // 開閉ロジック
  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward(); // アニメーション再生
      } else {
        _animationController.reverse(); // アニメーション逆再生
      }
    });
  }

  // サブボタンウィジェットの作成
  Widget _buildSubButton(IconData icon, String tooltip, int index, double delay) {
    return ScaleTransition(
      scale: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: FloatingActionButton( // サブボタンはsmallサイズ
          heroTag: null,
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          tooltip: tooltip,
          onPressed: () {
            _toggle(); // 閉じる
            widget.onNavigationSelected(index); // 遷移実行
          },
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // Columnを使って、上から下へ要素を積み上げる
    return Column(
      mainAxisSize: MainAxisSize.min, // コンテンツのサイズに合わせる
      crossAxisAlignment: CrossAxisAlignment.start, // 左寄せにする
      children: <Widget>[
        // 1. メインボタン (開閉用) を Column の最上部に配置
        FloatingActionButton(
          heroTag: null,
          mini: false, 
          onPressed: _toggleOpen,
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animation,
          ),
        ),

        // 2. サブボタンたち (展開アニメーション) - 下方向に展開
        // ★★★ 修正: 展開時にのみ表示されるようにする ★★★
        if (_isOpen) ...[
          const SizedBox(height: 8), // メインボタンとの間にスペース
          // サブボタンのリストを積み上げる
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubButton(Icons.create, '新規記録', 0, 0.4), // 遷移先は '/'
              const SizedBox(height: 10),
              // 修正: 展開方向が下向きになったため、サブボタン間のスペースを追加
              _buildSubButton(Icons.history, '履歴', 1, 0.3),
              const SizedBox(height: 10),
              _buildSubButton(Icons.analytics_outlined, '分析', 2, 0.2),
              const SizedBox(height: 10),
              _buildSubButton(Icons.settings, '設定', 3, 0.1),
            ],
          ),
        ],
      ],
    ); 
  }
}
