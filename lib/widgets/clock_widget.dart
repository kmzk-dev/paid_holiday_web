import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // pubspec.yaml に intl パッケージを追加してください

class ClockWidget extends StatefulWidget {
  const ClockWidget({Key? key}) : super(key: key);

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late DateTime _currentTime;
  Timer? _timer; // Timerを nullable に変更

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) { // ウィジェットがまだツリーにあるか確認
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // nullable なので ?. を使用
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Figmaの画像に合わせたフォーマット例 (秒も表示する動的な時計として)
    String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(_currentTime);
    return Text(
      formattedTime,
      style: TextStyle(
        fontSize: 28, // 少し大きめのフォントサイズ
        color: Colors.grey[700], // 落ち着いた色
        fontWeight: FontWeight.w300, // やや細めのウェイト
      ),
    );
  }
}