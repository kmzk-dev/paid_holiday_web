// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // ★ 追加: ロケールデータ初期化のため
import 'screens/input_screen.dart';
import 'screens/confirm_screen.dart';
import 'screens/complete_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- google_fontsをインポート


// main関数をasyncに変更し、initializeDateFormattingを呼び出す
Future<void> main() async { // ★ async に変更
  WidgetsFlutterBinding.ensureInitialized(); // Flutterエンジンとのバインディングを保証
  await initializeDateFormatting('ja_JP', null); // ★ 追加: 日本語ロケールのデータを初期化
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '有給休暇申請フォーム',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ja', 'JP'),
      ],
      locale: const Locale('ja', 'JP'),
      theme: ThemeData(
        textTheme: GoogleFonts.sawarabiGothicTextTheme( // <--- Google Fontsを使用
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => InputScreen(),
        '/confirm': (context) => ConfirmScreen(),
        '/complete': (context) => CompleteScreen(),
      },
    );
  }
}