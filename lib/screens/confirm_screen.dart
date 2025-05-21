import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'input_screen.dart'; // FormData と SelectedDateEntry を利用するため
import '../widgets/responsive_layout.dart'; // 作成したレスポンシブレイアウトウィジェット

class ConfirmScreen extends StatelessWidget {
  final String _emailScriptUrl = 'https://fillmee.bambina.jp/api/paid_holiday_api/paid_holiday_api.php'; // ★★★ PHPスクリプトのURLを指定 ★★★

  Future<void> _submitData(BuildContext context, FormData data) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("送信中..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final List<Map<String, dynamic>> entriesForJson = data.selectedEntries.map((entry) {
        return {
          'date': DateFormat('yyyy-MM-dd').format(entry.date),
          'duration': entry.duration,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_emailScriptUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': data.name,
          'department': data.department,
          'email': data.email,
          'selected_entries': entriesForJson,
          'total_duration': data.totalDuration,
        }),
      );

      Navigator.pop(context); // ローディングダイアログを閉じる

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          Navigator.pushNamedAndRemoveUntil(context, '/complete', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メール送信に失敗しました: ${responseBody['message'] ?? 'サーバーエラー'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メール送信リクエストエラー: ${response.statusCode}, Body: ${response.body}')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FormData formData = ModalRoute.of(context)!.settings.arguments as FormData;
    final DateFormat displayFormatter = DateFormat('yyyy/MM/dd');

    Widget mainContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          Text('以下の内容で送信します。よろしいですか？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          _buildInfoRow('氏名:', formData.name),
          _buildInfoRow('配属先:', formData.department),
          _buildInfoRow('メールアドレス:', formData.email),
          SizedBox(height: 15),
          Text('申請日詳細:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (formData.selectedEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('  日付が選択されていません', style: TextStyle(fontSize: 16)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: formData.selectedEntries.length,
              itemBuilder: (context, index) {
                final entry = formData.selectedEntries[index];
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
                  child: Text(
                    '${displayFormatter.format(entry.date)} (${entry.duration.toStringAsFixed(1)}日)',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          SizedBox(height: 10),
          _buildInfoRow('合計日数:', '${formData.totalDuration.toStringAsFixed(1)}日'),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _submitData(context, formData),
            child: Text('投稿する'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15.0),
              textStyle: TextStyle(fontSize: 16)
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('入力画面に戻る'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('確認画面')),
      body: ResponsiveLayout(child: mainContent),
    );
  }
}