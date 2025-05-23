<?php
// CORSヘッダーを設定して、クロスオリジンからのリクエストを許可します
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");


// OPTIONSメソッドの場合は、ヘッダーのみを返して終了します（プリフライトリクエスト対応）
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}

// 許可するメールアドレスのリスト（約400件のダミーデータ）
// 将来的にはこの部分をデータベースからの取得処理に置き換えます
$allowed_emails = [
    "user1@example.com", "user2@example.com", "user3@example.com", "user4@example.com", "user5@example.com", "user6@example.com", "user7@example.com", "user8@example.com", "user9@example.com", "user10@example.com",
    "user11@example.com", "user12@example.com", "user13@example.com", "user14@example.com", "user15@example.com", "user16@example.com", "user17@example.com", "user18@example.com", "user19@example.com", "user20@example.com",
    "user21@example.com", "user22@example.com", "user23@example.com", "user24@example.com", "user25@example.com", "user26@example.com", "user27@example.com", "user28@example.com", "user29@example.com", "user30@example.com",
    "user31@example.com", "user32@example.com", "user33@example.com", "user34@example.com", "user35@example.com", "user36@example.com", "user37@example.com", "user38@example.com", "user39@example.com", "user40@example.com",
    "user41@example.com", "user42@example.com", "user43@example.com", "user44@example.com", "user45@example.com", "user46@example.com", "user47@example.com", "user48@example.com", "user49@example.com", "user50@example.com",
    "user51@example.com", "user52@example.com", "user53@example.com", "user54@example.com", "user55@example.com", "user56@example.com", "user57@example.com", "user58@example.com", "user59@example.com", "user60@example.com",
    "user61@example.com", "user62@example.com", "user63@example.com", "user64@example.com", "user65@example.com", "user66@example.com", "user67@example.com", "user68@example.com", "user69@example.com", "user70@example.com",
    "user71@example.com", "user72@example.com", "user73@example.com", "user74@example.com", "user75@example.com", "user76@example.com", "user77@example.com", "user78@example.com", "user79@example.com", "user80@example.com",
    "user81@example.com", "user82@example.com", "user83@example.com", "user84@example.com", "user85@example.com", "user86@example.com", "user87@example.com", "user88@example.com", "user89@example.com", "user90@example.com",
    "user91@example.com", "user92@example.com", "user93@example.com", "user94@example.com", "user95@example.com", "user96@example.com", "user97@example.com", "user98@example.com", "user99@example.com", "user100@example.com",
    "user101@example.com", "user102@example.com", "user103@example.com", "user104@example.com", "user105@example.com", "user106@example.com", "user107@example.com", "user108@example.com", "user109@example.com", "user110@example.com",
    "user111@example.com", "user112@example.com", "user113@example.com", "user114@example.com", "user115@example.com", "user116@example.com", "user117@example.com", "user118@example.com", "user119@example.com", "user120@example.com",
    "user121@example.com", "user122@example.com", "user123@example.com", "user124@example.com", "user125@example.com", "user126@example.com", "user127@example.com", "user128@example.com", "user129@example.com", "user130@example.com",
    "user131@example.com", "user132@example.com", "user133@example.com", "user134@example.com", "user135@example.com", "user136@example.com", "user137@example.com", "user138@example.com", "user139@example.com", "user140@example.com",
    "user141@example.com", "user142@example.com", "user143@example.com", "user144@example.com", "user145@example.com", "user146@example.com", "user147@example.com", "user148@example.com", "user149@example.com", "user150@example.com",
    "user151@example.com", "user152@example.com", "user153@example.com", "user154@example.com", "user155@example.com", "user156@example.com", "user157@example.com", "user158@example.com", "user159@example.com", "user160@example.com",
    "user161@example.com", "user162@example.com", "user163@example.com", "user164@example.com", "user165@example.com", "user166@example.com", "user167@example.com", "user168@example.com", "user169@example.com", "user170@example.com",
    "user171@example.com", "user172@example.com", "user173@example.com", "user174@example.com", "user175@example.com", "user176@example.com", "user177@example.com", "user178@example.com", "user179@example.com", "user180@example.com",
    "user181@example.com", "user182@example.com", "user183@example.com", "user184@example.com", "user185@example.com", "user186@example.com", "user187@example.com", "user188@example.com", "user189@example.com", "user190@example.com",
    "user191@example.com", "user192@example.com", "user193@example.com", "user194@example.com", "user195@example.com", "user196@example.com", "user197@example.com", "user198@example.com", "user199@example.com", "user200@example.com",
    "user201@example.com", "user202@example.com", "user203@example.com", "user204@example.com", "user205@example.com", "user206@example.com", "user207@example.com", "user208@example.com", "user209@example.com", "user210@example.com",
    "user211@example.com", "user212@example.com", "user213@example.com", "user214@example.com", "user215@example.com", "user216@example.com", "user217@example.com", "user218@example.com", "user219@example.com", "user220@example.com",
    "user221@example.com", "user222@example.com", "user223@example.com", "user224@example.com", "user225@example.com", "user226@example.com", "user227@example.com", "user228@example.com", "user229@example.com", "user230@example.com",
    "user231@example.com", "user232@example.com", "user233@example.com", "user234@example.com", "user235@example.com", "user236@example.com", "user237@example.com", "user238@example.com", "user239@example.com", "user240@example.com",
    "user241@example.com", "user242@example.com", "user243@example.com", "user244@example.com", "user245@example.com", "user246@example.com", "user247@example.com", "user248@example.com", "user249@example.com", "user250@example.com",
    "user251@example.com", "user252@example.com", "user253@example.com", "user254@example.com", "user255@example.com", "user256@example.com", "user257@example.com", "user258@example.com", "user259@example.com", "user260@example.com",
    "user261@example.com", "user262@example.com", "user263@example.com", "user264@example.com", "user265@example.com", "user266@example.com", "user267@example.com", "user268@example.com", "user269@example.com", "user270@example.com",
    "user271@example.com", "user272@example.com", "user273@example.com", "user274@example.com", "user275@example.com", "user276@example.com", "user277@example.com", "user278@example.com", "user279@example.com", "user280@example.com",
    "user281@example.com", "user282@example.com", "user283@example.com", "user284@example.com", "user285@example.com", "user286@example.com", "user287@example.com", "user288@example.com", "user289@example.com", "user290@example.com",
    "user291@example.com", "user292@example.com", "user293@example.com", "user294@example.com", "user295@example.com", "user296@example.com", "user297@example.com", "user298@example.com", "user299@example.com", "user300@example.com",
    "user301@example.com", "user302@example.com", "user303@example.com", "user304@example.com", "user305@example.com", "user306@example.com", "user307@example.com", "user308@example.com", "user309@example.com", "user310@example.com",
    "user311@example.com", "user312@example.com", "user313@example.com", "user314@example.com", "user315@example.com", "user316@example.com", "user317@example.com", "user318@example.com", "user319@example.com", "user320@example.com",
    "user321@example.com", "user322@example.com", "user323@example.com", "user324@example.com", "user325@example.com", "user326@example.com", "user327@example.com", "user328@example.com", "user329@example.com", "user330@example.com",
    "user331@example.com", "user332@example.com", "user333@example.com", "user334@example.com", "user335@example.com", "user336@example.com", "user337@example.com", "user338@example.com", "user339@example.com", "user340@example.com",
    "user341@example.com", "user342@example.com", "user343@example.com", "user344@example.com", "user345@example.com", "user346@example.com", "user347@example.com", "user348@example.com", "user349@example.com", "user350@example.com",
    "user351@example.com", "user352@example.com", "user353@example.com", "user354@example.com", "user355@example.com", "user356@example.com", "user357@example.com", "user358@example.com", "user359@example.com", "user360@example.com",
    "user361@example.com", "user362@example.com", "user363@example.com", "user364@example.com", "user365@example.com", "user366@example.com", "user367@example.com", "user368@example.com", "user369@example.com", "user370@example.com",
    "user371@example.com", "user372@example.com", "user373@example.com", "user374@example.com", "user375@example.com", "user376@example.com", "user377@example.com", "user378@example.com", "user379@example.com", "user380@example.com",
    "user381@example.com", "user382@example.com", "user383@example.com", "user384@example.com", "user385@example.com", "user386@example.com", "user387@example.com", "user388@example.com", "user389@example.com", "user390@example.com",
    "user391@example.com", "user392@example.com", "user393@example.com", "user394@example.com", "user395@example.com", "user396@example.com", "user397@example.com", "user398@example.com", "k_kaki@frappu.co.jp", "decovervoice@gmail.com",
];

// POSTリクエスト以外はエラーを返します
if ($_SERVER['REQUEST_METHOD'] != 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['status' => 'error', 'message' => 'POSTメソッドでリクエストしてください。']);
    exit;
}

// リクエストボディからJSONデータを取得します
$json_data = file_get_contents('php://input');
$data = json_decode($json_data);

// emailがリクエストに含まれているかチェックします
if (!isset($data->email)) {
    http_response_code(400); // Bad Request
    echo json_encode(['status' => 'error', 'message' => 'Eメールアドレスが含まれていません。']);
    exit;
}

$email = $data->email;

// Eメールアドレスがリストに存在するかチェックします
if (in_array($email, $allowed_emails, true)) {
    // 存在する場合
    http_response_code(200); // OK
    echo json_encode(['status' => 'success', 'message' => 'Eメールアドレスは有効です。']);
} else {
    // 存在しない場合
    http_response_code(404); // Not Found
    echo json_encode(['status' => 'error', 'message' => 'Eメールアドレスが見つかりません。']);
}

?>