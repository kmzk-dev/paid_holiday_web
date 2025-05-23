// lib/widgets/responsive_layout.dart の変更案
import 'package:flutter/material.dart';
import 'clock_widget.dart'; // 作成した時計ウィジェットをインポート

class ResponsiveLayout extends StatelessWidget {
  final Widget child; // 各画面の主要コンテンツ

  const ResponsiveLayout({super.key, required this.child});

  static const double desktopBreakpoint = 853.0; // 旧768.0タブレット横向きを想定したブレークポイント
  // static const double contentCardWidth = 450.0; // 右側コンテンツがExpandedになるため、この固定幅は不要になる場合があります。

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < desktopBreakpoint) {
          // モバイル表示: 子ウィジェットをそのまま表示
          return child;
        } else {
          // デスクトップ/タブレット横表示
          double clockColumnWidth = constraints.maxWidth * 0.6; // 画面全体の横幅の40%を時計エリアの幅とする

          return Row(
            children: <Widget>[
              // 左側: 時計表示エリア (画面横幅の40%)
              SizedBox(
                width: clockColumnWidth,
                child: 
                //Container(
                  // color: Color(0xFFF5F5F5), // Figmaで見た背景色 (FSFSFS)
                  //child: 
                  Center(
                    child: ClockWidget(),
                  ),
                //),
              ),
              // 右側: メインコンテンツをカード表示 (画面横幅の残り60%)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0), // カードの周囲に余白を追加 (例: 24.0)
                  child: Material(
                    elevation: 2.0,
                    borderRadius: BorderRadius.circular(24.0),
                    color: Theme.of(context).cardColor.withAlpha((255 * 0.95).round()),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}