import 'package:flutter/material.dart';
import 'clock_widget.dart'; // 作成した時計ウィジェットをインポート

class ResponsiveLayout extends StatelessWidget {
  final Widget child; // 各画面の主要コンテンツ

  const ResponsiveLayout({Key? key, required this.child}) : super(key: key);

  static const double desktopBreakpoint = 768.0; // タブレット横向きを想定したブレークポイント
  static const double contentCardWidth = 450.0; // デスクトップ時の左側コンテンツカードの幅

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < desktopBreakpoint) {
          // モバイル表示: 子ウィジェットをそのまま表示
          return child;
        } else {
          // デスクトップ/タブレット横表示
          return Row(
            children: <Widget>[
              // 左側: メインコンテンツをカード表示
              SizedBox(
                width: contentCardWidth,
                child: Material( // Cardの代わりにMaterialで影や背景を調整しやすくする
                  elevation: 2.0, // 軽い影
                  color: Theme.of(context).cardColor, // 通常のカード背景色
                  child: child, // child は通常 Padding を含む想定
                ),
              ),
              // 右側: 時計表示エリア
              Expanded(
                child: Container(
                  color: Color(0xFFF5F5F5), // Figmaで見た背景色 (FSFSFS)
                  child: Center(
                    child: ClockWidget(),
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