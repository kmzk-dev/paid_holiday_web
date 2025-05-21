<?php
// send_mail.php

header('Content-Type: application/json; charset=UTF-8'); // Flutterへのレスポンス用
header("Access-Control-Allow-Origin: *"); // 本番ではドメイン指定を推奨
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ★★★ 実際の宛先メールアドレスを指定 ★★★
$to_email = "decovervoice@gmail.com";

// 日本語処理の基本設定 (できるだけスクリプトの早い段階で設定)
mb_language("Japanese");
mb_internal_encoding("UTF-8"); // PHP内部の文字列エンコーディングをUTF-8に

$json_data = file_get_contents('php://input');
$data = json_decode($json_data, true);

if ($data === null) {
    echo json_encode(['status' => 'error', 'message' => '無効なJSONデータです。']);
    http_response_code(400);
    exit();
}

$name = isset($data['name']) ? trim($data['name']) : '';
$department = isset($data['department']) ? trim($data['department']) : '';
$applicant_email = isset($data['email']) ? trim($data['email']) : '';
$selected_entries_raw = isset($data['selected_entries']) && is_array($data['selected_entries']) ? $data['selected_entries'] : [];
$total_duration_raw = isset($data['total_duration']) ? $data['total_duration'] : 0;

// --- サニタイズ (FILTER_SANITIZE_STRINGは非推奨なので、ここでは基本的なtrimのみ。必要に応じて他のサニタイズ方法を検討) ---
// 注意: FILTER_SANITIZE_STRING は PHP 8.1 で非推奨になりました。
// htmlspecialcharsを使うか、より適切なフィルタを選択してください。
// 今回はプレーンテキストメールなので、過度なサニタイズは文字化けの調査中は避けます。
$name = filter_var($name, FILTER_UNSAFE_RAW); // 必要に応じて変更
$department = filter_var($department, FILTER_UNSAFE_RAW); // 必要に応じて変更
$applicant_email = filter_var($applicant_email, FILTER_SANITIZE_EMAIL);


if (!empty($applicant_email) && !filter_var($applicant_email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'error', 'message' => '無効なメールアドレス形式です。']);
    http_response_code(400);
    exit();
}

if (empty($name) || empty($department) || empty($applicant_email) || empty($selected_entries_raw)) {
    echo json_encode(['status' => 'error', 'message' => '必須項目が不足しています。']);
    http_response_code(400);
    exit();
}

$entries_string_lines = [];
foreach ($selected_entries_raw as $entry) {
    if (isset($entry['date']) && isset($entry['duration'])) {
        $date_str = filter_var($entry['date'], FILTER_UNSAFE_RAW); // YYYY-MM-DD
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date_str)) {
            continue;
        }
        $duration_val = filter_var($entry['duration'], FILTER_VALIDATE_FLOAT);
        if ($duration_val !== false && $duration_val > 0) {
            // 本文では「日」という文字もUTF-8で正しく扱われるはず
            $entries_string_lines[] = "- 日付: " . $date_str . ", 期間: " . number_format($duration_val, 1) . "日";
        }
    }
}

if (empty($entries_string_lines)) {
    echo json_encode(['status' => 'error', 'message' => '有効な申請日情報がありません。']);
    http_response_code(400);
    exit();
}
$entries_for_mail = implode("\n", $entries_string_lines);

$total_duration = filter_var($total_duration_raw, FILTER_VALIDATE_FLOAT);
if ($total_duration === false || $total_duration < 0) {
    $total_duration = 0.0;
}
$total_duration_for_mail = number_format($total_duration, 1) . "日";

// --- メール件名と本文の作成 ---
// ★★★ 件名のエンコード ★★★
$subject_original = "【WEB申請】" . $name . "様より申請がありました";
$subject_encoded = mb_encode_mimeheader($subject_original, "UTF-8", "B", "\r\n"); // "B"はBase64エンコード

// 本文 (htmlspecialcharsを削除し、UTF-8文字列としてそのまま使用)
$body = "以下の内容で申請がありました。\n\n"
      . "氏名: " . $name . "\n"
      . "配属先: " . $department . "\n"
      . "メールアドレス: " . $applicant_email . "\n\n"
      . "申請日詳細:\n"
      . $entries_for_mail . "\n\n"
      . "合計日数: " . $total_duration_for_mail . "\n\n"
      . "-------------------------------------\n"
      . "送信日時: " . date("Y-m-d H:i:s") . "\n"
      . "送信元IP: " . (isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : 'N/A') . "\n";

// --- メールヘッダーの設定 ---
$from_address = "no-reply@" . (isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : 'your-lolipop-domain.com');

$headers = "From: " . $from_address . "\r\n";
$headers .= "Reply-To: " . mb_encode_mimeheader($name, "UTF-8", "B", "\r\n") . "<" . $applicant_email . ">\r\n"; // Reply-Toの名前部分もエンコード
$headers .= "Content-Type: text/plain; charset=UTF-8\r\n"; // メール本文のエンコーディングを指定
$headers .= "Content-Transfer-Encoding: 8bit\r\n"; // 8bitで転送 (UTF-8の場合に適している)
$headers .= "MIME-Version: 1.0\r\n";
$headers .= "Message-ID: <" . md5(uniqid(microtime(), true)) . "@" . (isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : 'your-lolipop-domain.com') . ">\r\n";
$headers .= "Date: " . date("r") . "\r\n";


// mb_send_mail を使用 (件名はエンコード済みのものを渡す)
if (mb_send_mail($to_email, $subject_original, $body, $headers)) {
    echo json_encode(['status' => 'success', 'message' => 'メールが送信されました。']);
} else {
    error_log("Mail send failed to: $to_email, Subject: $subject_original, From: $from_address");
    echo json_encode(['status' => 'error', 'message' => 'メールの送信に失敗しました。']);
    http_response_code(500);
}
?>