import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart'; // 作成したレスポンシブレイアウトウィジェット

class CompleteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget mainContent = Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              '申請が完了しました。',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text('入力画面に戻る'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15.0),
                textStyle: TextStyle(fontSize: 16)
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('投稿完了')),
      body: ResponsiveLayout(child: mainContent),
    );
  }
}