import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'input_screen.dart'; // FormData と SelectedDateEntry を利用するため
import '../widgets/responsive_layout.dart'; // 作成したレスポンシブレイアウトウィジェット

class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({super.key});
  final String _emailScriptUrl = 'https://fillmee.bambina.jp/api/paid_holiday_api/paid_holiday_api.php';

  // メール本文と件名、IDを生成するヘルパー関数
  Map<String, String> _generateEmailContent(FormData data) { // 戻り値の型はそのまま Map<String, String> でOK
    final DateFormat formatter = DateFormat('yyyy/MM/dd');
    final DateFormat timestampFormatter = DateFormat('yyyyMMddHHmmss');
    final String submissionTimestamp = timestampFormatter.format(DateTime.now());

    String emailPrefix = data.email.length >= 3 ? data.email.substring(0, 3) : data.email;
    emailPrefix = emailPrefix.toUpperCase();
    final String uniqueId = '$emailPrefix-$submissionTimestamp'; // このIDをCompleteScreenに渡したい

    final String subject = '[有給休暇申請 ID: $uniqueId] ${data.name}様より申請がありました';

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

$remarksContent-------------------------------------
申請日時: ${DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())}
""";

    return {
      'reply_to': data.email,
      'subject': subject,
      'description': description.trim(),
      'uniqueId': uniqueId, // ★★★ IDをマップに追加 ★★★
    };
  }

  Future<void> _submitData(BuildContext context, FormData data) async {
    showDialog(
      // ... (ローディングダイアログ部分は変更なし)
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
      final emailDetails = _generateEmailContent(data);
      final response = await http.post(
        Uri.parse(_emailScriptUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'reply_to': emailDetails['reply_to']!,
          'subject': emailDetails['subject']!,
          'description': emailDetails['description']!,
        }),
      );
      // ignore:use_build_context_synchronously
      Navigator.pop(context); // ローディングダイアログを閉じる

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          // ★★★ CompleteScreenへ引数を渡す ★★★
          Navigator.pushNamedAndRemoveUntil(
            // ignore:use_build_context_synchronously
            context,
            '/complete',
            (route) => false,
            arguments: {
              'uniqueId': emailDetails['uniqueId']!, // 生成したID
              'applicantEmail': data.email,         // 申請者のメールアドレス
            },
          );
        } else {
          // ignore:use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メール送信に失敗しました: ${responseBody['message'] ?? 'サーバーエラー'}')),
          );
        }
      } else {
        // ignore:use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メール送信リクエストエラー: ${response.statusCode}, Body: ${response.body}')),
        );
      }
    } catch (e) {
      // ignore:use_build_context_synchronously
      Navigator.pop(context);
      // ignore:use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }
  // ... (_buildInfoRowとbuildメソッドは変更なし)
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
              softWrap: isMultiline, 
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
          
          if (formData.remarks.isNotEmpty) ...[
            SizedBox(height: 10),
            _buildInfoRow('備考:', formData.remarks, isMultiline: true),
          ],

          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _submitData(context, formData),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15.0),
              textStyle: TextStyle(fontSize: 16)
            ),
            child: Text('投稿する'),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('入力画面に戻る'),
          ),
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