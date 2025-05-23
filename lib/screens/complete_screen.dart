// complete_screen.dart (修正後、url_launcher関連を削除)
import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart'; // 作成したレスポンシブレイアウトウィジェット

class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? uniqueId = args?['uniqueId'];
    final String? applicantEmail = args?['applicantEmail'];

    Widget mainContent = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(Icons.check_circle_outline, color: Colors.green, size: 80), //
            SizedBox(height: 20),
            Text(
              '申請が完了しました。',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), //
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),

            if (uniqueId != null) ...[
              Text(
                '申請ID:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SelectableText(
                uniqueId,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '上記の申請IDをお控えください。',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              Text(
                'このIDは、申請内容の確認、変更、またはキャンセルを行う際に必要となります。',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
            ],

            Divider(),
            SizedBox(height: 20),

            Text(
              '今後の流れについて',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildInfoListItem(
              icon: Icons.email_outlined,
              text: applicantEmail != null
                  ? 'ご入力いただいたメールアドレス ($applicantEmail) 宛に、3営業日以内に受付完了のメールをお送りします。'
                  : '受付完了のメールを3営業日以内にお送りします。',
            ),
            SizedBox(height: 10),
            _buildInfoListItem(
              icon: Icons.help_outline,
              text: '上記期間を過ぎてもメールが届かない場合は、お手数ですが下記の連絡先までお問い合わせください。',
            ),
            SizedBox(height: 25),

            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '連絡先情報',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                    ),
                    SizedBox(height: 12),
                    _buildContactRow( // 修正：BuildContext context を削除
                      icon: Icons.business_outlined,
                      label: '担当部署:',
                      value: '人事部 勤怠管理課',
                    ),
                    _buildContactRow( // 修正：BuildContext context を削除
                      icon: Icons.alternate_email,
                      label: 'メール:',
                      value: 'hr-attendance@example.com',
                    ),
                    _buildContactRow( // 修正：BuildContext context を削除
                      icon: Icons.phone_outlined,
                      label: '電話番号:',
                      value: '03-1234-5678',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); //
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15.0), //
                textStyle: TextStyle(fontSize: 16) //
              ),
              child: Text('入力画面に戻る'),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('申請完了'),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveLayout(child: mainContent),
    );
  }

  Widget _buildInfoListItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, height: 1.4))),
      ],
    );
  }

  // 連絡先表示用のヘルパーウィジェット (修正版)
  Widget _buildContactRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          SizedBox(width: 8),
          Text('$label ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text( // InkWell と関連スタイルを削除
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}