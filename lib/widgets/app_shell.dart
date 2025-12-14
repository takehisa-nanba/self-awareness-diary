// lib/widgets/app_shell.dart (修正版)

import 'package:flutter/material.dart';
import 'extended_fab_navigator.dart';

const double kAppHeaderH = 66.0; // カスタムヘッダーの高さ
const double kFabMarginTop = 5.0; // ナビゲーターボタンの微調整用

class AppShell extends StatelessWidget {
	final Widget child;
	final Widget? floatingActionButton;
	final FloatingActionButtonLocation? floatingActionButtonLocation;
	final bool showNavigator;
	final String? title; 		
	final PreferredSizeWidget? customHeader;
	

	const AppShell({
		super.key,
		required this.child,
		this.floatingActionButton,
		this.floatingActionButtonLocation,
		this.showNavigator = true,
		this.title = '自己覚知日記',
		this.customHeader,
	});

	void _navigateToScreen(BuildContext context, int index) {
		String routeName;
		switch (index) {
			case 0: 
				routeName = '/'; 
				Navigator.of(context).popUntil((route) => route.isFirst);
				if (ModalRoute.of(context)?.settings.name != routeName) {
						Navigator.of(context).pushNamedAndRemoveUntil(
								routeName, 
								(Route<dynamic> route) => false
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
			return;
		}
		Navigator.of(context).pushNamed(routeName); 
	}

	@override
	Widget build(BuildContext context) {
		
		final double safePaddingTop = MediaQuery.of(context).padding.top;
		final double navigatorWidth = showNavigator ? (56.0 + 5.0) : 0.0;
		final double customHeaderHeight = customHeader?.preferredSize.height ?? 0.0;
		final double totalHeaderHeight = kAppHeaderH + customHeaderHeight;

		return Scaffold(
			// AppBarを削除し、bodyのStackでカスタムヘッダーを構築
			body: Stack(
				children: [
					// 1. メインコンテンツ (WriteScreen) - ヘッダーの高さ分下にずらす
					Padding(
            // ★★★ 修正1: コンテンツの開始位置を修正し、重なりを解消 ★★★
						padding: EdgeInsets.only(top: totalHeaderHeight + safePaddingTop), 
						child: child,
					),

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
						
					// 3. customHeader（ステップ表示） 
					if (customHeader != null)
						Positioned(
							left: 0,
							right: 0,
							top: safePaddingTop + kAppHeaderH, 
							child: customHeader!,
						),
            
					// 4. ナビゲーターボタン (メインヘッダーの上に重ねる)
					if (showNavigator)
						Positioned(
							left: 5.0, 
              // メインヘッダーと同じ top 位置 (safePaddingTop) から少しずらす
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