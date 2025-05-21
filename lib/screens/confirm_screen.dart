import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'input_screen.dart'; // FormData と SelectedDateEntry を利用するため
import '../widgets/responsive_layout.dart'; // 作成したレスポンシブレイアウトウィジェット

class ConfirmScreen extends StatelessWidget {
  final String _emailScriptUrl = 'https://fillmee.bambina.jp/api/paid_holiday_api/paid_holiday_api.php'; // PHPスクリプトのURL

  // メール本文と件名を生成するヘルパー関数
  Map<String, String> _generateEmailContent(FormData data) {
    final DateFormat formatter = DateFormat('yyyy/MM/dd');
    final DateFormat timestampFormatter = DateFormat('yyyyMMddHHmmss');
    final String submissionTimestamp = timestampFormatter.format(DateTime.now());

    // 1. ID生成 (メールアドレスの先頭3文字 + タイムスタンプ)
    String emailPrefix = data.email.length >= 3 ? data.email.substring(0, 3) : data.email;
    emailPrefix = emailPrefix.toUpperCase(); // 大文字に統一
    final String uniqueId = '$emailPrefix-$submissionTimestamp';

    // 2. 件名生成
    final String subject = '[有給休暇申請 ID: $uniqueId] ${data.name}様より申請がありました';

    // 3. 本文生成
    String entriesString = data.selectedEntries.map((entry) {
      return "- 日付: ${formatter.format(entry.date)}, 期間: ${entry.duration.toStringAsFixed(1)}日";
    }).join("\n");

    String remarksContent = '';
    if (data.remarks.isNotEmpty) {
      remarksContent = "備考:\n${data.remarks}\n\n";
    }

    final String description = """
      以下の内容で有給休暇の申請がありました。

      -------------------------------------
      申請ID: $uniqueId
      申請者氏名: ${data.name}
      配属先: ${data.department}
      メールアドレス: ${data.email}
      -------------------------------------

      申請日詳細:
      $entriesString

      合計日数: ${data.totalDuration.toStringAsFixed(1)}日

      ${remarksContent}-------------------------------------
      申請日時: ${DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())}
      """; // Email body ends here

    return {
      'reply_to': data.email,
      'subject': subject,
      'description': description.trim(), // 前後の余分な空白を削除
    };
  }

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
      // ★★★ 送信ボタン押下時にメール内容を生成 ★★★
      final emailDetails = _generateEmailContent(data);

      final response = await http.post(
        Uri.parse(_emailScriptUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // ★★★ PHPへ渡すJSONデータを変更 ★★★
        body: jsonEncode(<String, String>{
          'reply_to': emailDetails['reply_to']!,
          'subject': emailDetails['subject']!,
          'description': emailDetails['description']!,
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
      Navigator.pop(context); // ローディングダイアログを閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              softWrap: isMultiline, // trueの場合、複数行表示を適切に行う
            )
          ),
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
          
          // ★★★ 備考欄の表示を追加 (空でない場合のみ) ★★★
          if (formData.remarks.isNotEmpty) ...[
            SizedBox(height: 10),
            _buildInfoRow('備考:', formData.remarks, isMultiline: true),
          ],

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
           // ★ 前回の修正で追加したセーフティエリア用のSizedBox (ListViewの最後に配置)
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('確認画面')),
      body: ResponsiveLayout(child: mainContent),
    );
  }
}