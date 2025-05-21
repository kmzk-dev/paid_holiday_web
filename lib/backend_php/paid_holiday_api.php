<?php
// paid_holiday_api.php (修正後)

header('Content-Type: application/json; charset=UTF-8'); // Flutterへのレスポンス用
header("Access-Control-Allow-Origin: *"); // 本番ではドメイン指定を推奨
header("Access-Control-Allow-Methods: POST, OPTIONS"); //
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With"); //

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { //
    http_response_code(200); //
    exit(); //
}

// ★★★ 実際の宛先メールアドレスを指定 ★★★
$to_email = "decovervoice@gmail.com"; //

// 日本語処理の基本設定
mb_language("Japanese"); //
mb_internal_encoding("UTF-8"); // PHP内部の文字列エンコーディングをUTF-8に

$json_data = file_get_contents('php://input'); //
$data = json_decode($json_data, true); //

if ($data === null) { //
    echo json_encode(['status' => 'error', 'message' => '無効なJSONデータです。']); //
    http_response_code(400); //
    exit(); //
}

// --- Flutterから送信されるデータを取得 ---
$reply_to_email = isset($data['reply_to']) ? trim($data['reply_to']) : '';
$subject_from_flutter = isset($data['subject']) ? trim($data['subject']) : '';
$description_from_flutter = isset($data['description']) ? trim($data['description']) : '';

// --- 必須項目のバリデーション ---
if (empty($reply_to_email) || !filter_var($reply_to_email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'error', 'message' => '返信先メールアドレスが無効または指定されていません。']);
    http_response_code(400);
    exit();
}

if (empty($subject_from_flutter)) {
    echo json_encode(['status' => 'error', 'message' => '件名が指定されていません。']);
    http_response_code(400);
    exit();
}

if (empty($description_from_flutter)) {
    echo json_encode(['status' => 'error', 'message' => '本文が指定されていません。']);
    http_response_code(400);
    exit();
}

// --- メールヘッダーの設定 ---
$from_address = "no-reply@" . (isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : 'your-lolipop-domain.com'); //

$headers = "From: " . $from_address . "\r\n"; //
// Reply-Toヘッダーには、申請者のメールアドレス（reply_to_email）のみを設定
$headers .= "Reply-To: " . $reply_to_email . "\r\n";
$headers .= "Content-Type: text/plain; charset=UTF-8\r\n"; // メール本文のエンコーディングを指定
$headers .= "Content-Transfer-Encoding: 8bit\r\n"; // 8bitで転送 (UTF-8の場合に適している)
$headers .= "MIME-Version: 1.0\r\n"; //
// Message-IDとDateヘッダーは引き続きPHP側で生成
$headers .= "Message-ID: <" . md5(uniqid(microtime(), true)) . "@" . (isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : 'your-lolipop-domain.com') . ">\r\n"; //
$headers .= "Date: " . date("r") . "\r\n"; //


// mb_send_mail を使用。件名と本文はFlutterから受け取ったものをそのまま使用
// mb_send_mail は内部で件名を適切にエンコードするため、PHP側での subject の mb_encode_mimeheader は不要
if (mb_send_mail($to_email, $subject_from_flutter, $description_from_flutter, $headers)) { //
    echo json_encode(['status' => 'success', 'message' => 'メールが送信されました。']); //
} else {
    // エラーログにはFlutterから受け取った件名を記録
    error_log("Mail send failed to: $to_email, Subject: $subject_from_flutter, From: $from_address"); //
    echo json_encode(['status' => 'error', 'message' => 'メールの送信に失敗しました。']); //
    http_response_code(500); //
}
?>