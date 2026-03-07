<?php
/**
 * CODE GO API - GET USER INFO
 * API endpoint: /api/get_user_info.php
 * Method: POST
 * 
 * Mô tả: Lấy thông tin chi tiết của user
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: application/json
 * 
 * Request Body (JSON):
 * {
 *   "user_id": 1
 * }
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "User info retrieved successfully",
 *   "data": {
 *     "user_id": 1,
 *     "username": "john_doe",
 *     "email": "john@example.com",
 *     "name": "John Doe",
 *     "avatar": "https://codego.io.vn/api/uploads/avatars/user_1_1234567890.jpg",
 *     "total_points": 100,
 *     "current_streak": 5,
 *     "longest_streak": 10,
 *     "level": 3,
 *     "country": "VN",
 *     "created_at": 1705123456,
 *     "last_login": 1705123456
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "User not found"
 * }
 */

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/helpers.php';

// Chỉ cho phép POST
requireMethod('POST');

// Kiểm tra Authorization header
$headers = getallheaders();
$auth_header = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (empty($auth_header) || !preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
    jsonResponse(false, 'Authorization token required', null, 401);
}

$token = $matches[1];
$token_data = verifyJWT($token, 'codego_secret_key_2025');

if (!$token_data) {
    jsonResponse(false, 'Invalid or expired token', null, 401);
}

// Lấy input từ request
$input = getJsonInput();

$user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;

if ($user_id <= 0) {
    jsonResponse(false, 'User ID is required', null, 400);
}

// Lấy thông tin user
$stmt = $conn->prepare("
    SELECT user_id, username, email, password, name, avatar, 
           total_points, current_streak, longest_streak, level, country, 
           is_active, created_at, updated_at, last_login
    FROM codego_users 
    WHERE user_id = ? AND is_active = 1
    LIMIT 1
");

if (!$stmt) {
    error_log("Prepare failed: " . $conn->error);
    jsonResponse(false, 'Database error', null, 500);
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    jsonResponse(false, 'User not found', null, 404);
}

$user = $result->fetch_assoc();
$stmt->close();

// Xóa password khỏi response
unset($user['password']);

// Trả về thông tin user
jsonResponse(true, 'User info retrieved successfully', $user, 200);

?>
