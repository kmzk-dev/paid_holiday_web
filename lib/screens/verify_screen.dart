import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // --- 注意 ---
  // このURLは、ご自身のサーバーに合わせて修正してください。
  // 例: 'https://YOUR_DOMAIN/path/to/verify_email_api.php'
  final String _apiUrl = 'https://fillmee.bambina.jp/api/paid_holiday_api/verify_email_api.php';

  Future<void> _verifyEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Eメールアドレスを入力してください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _emailController.text,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        // 認証成功時、入力画面に遷移
        // pushReplacementNamedを使い、この画面に戻れないようにする
        if (mounted) {
          Navigator.pushReplacementNamed(
            context, 
            '/',
            arguments: _emailController.text,);
        }
      } else {
        // 認証失敗時、エラーメッセージを表示
        setState(() {
          _errorMessage = responseBody['message'] ?? '不明なエラーが発生しました。';
        });
      }
    } catch (e) {
      // 通信エラーなど
      setState(() {
        _errorMessage = 'APIへの接続に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eメール認証'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  '利用するEメールアドレスを入力してください',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Eメールアドレス',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _verifyEmail,
                        child: const Text('認証'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}