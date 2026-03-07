<?php
/**
 * CODE GO API - GET TOKEN
 * API endpoint: /api/get_token.php
 * Method: POST
 * 
 * Mô tả: Xác thực API key và secret để lấy access token
 * 
 * Request Body (JSON):
 * {
 *   "api_key": "codego_api_key_2025",
 *   "api_secret": "codego_secret_2025"
 * }
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Token generated successfully",
 *   "data": {
 *     "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
 *     "token_type": "Bearer",
 *     "expires_in": 86400
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "Invalid API credentials"
 * }
 */

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/helpers.php';

// Chỉ cho phép POST
requireMethod('POST');

// Lấy input từ request
$input = getJsonInput();

// Validate input
$api_key = $input['api_key'] ?? '';
$api_secret = $input['api_secret'] ?? '';

if (empty($api_key) || empty($api_secret)) {
    jsonResponse(false, 'API key and secret are required', null, 400);
}

// Sanitize input
$api_key = sanitizeInput($api_key);
$api_secret = sanitizeInput($api_secret);

// Hash secret để so sánh (vì trong DB secret được hash bằng MD5)
$hashed_secret = md5($api_secret);

// Kiểm tra API key và secret trong database
$stmt = $conn->prepare("
    SELECT id, api_key, api_secret, app_name, is_active 
    FROM app_api 
    WHERE api_key = ? AND api_secret = ? AND is_active = 1
    LIMIT 1
");

if (!$stmt) {
    error_log("Prepare failed: " . $conn->error);
    jsonResponse(false, 'Database error', null, 500);
}

$stmt->bind_param("ss", $api_key, $hashed_secret);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    jsonResponse(false, 'Invalid API credentials', null, 401);
}

$api_data = $result->fetch_assoc();
$stmt->close();

// Tạo JWT token
$token_payload = [
    'api_id' => $api_data['id'],
    'api_key' => $api_data['api_key'],
    'app_name' => $api_data['app_name']
];

// 100 năm = 100 * 365 * 24 * 60 * 60 = 3,153,600,000 giây
$token_expiry_100_years = 3153600000;
$access_token = generateJWT($token_payload, 'codego_secret_key_2025', $token_expiry_100_years);

// Trả về token
jsonResponse(true, 'Token generated successfully', [
    'access_token' => $access_token,
    'token_type' => 'Bearer',
    'expires_in' => $token_expiry_100_years
], 200);

?>
