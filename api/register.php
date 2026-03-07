<?php
/**
 * CODE GO API - USER REGISTRATION
 * API endpoint: /api/register.php
 * Method: POST
 * 
 * Mô tả: Đăng ký tài khoản người dùng mới
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: application/json
 * 
 * Request Body (JSON):
 * {
 *   "username": "john_doe",
 *   "email": "john@example.com",  // optional
 *   "password": "password123",
 *   "name": "John Doe",  // optional
 *   "country": "VN",  // optional, default: VN
 *   "device_token": "fcm_device_token_here",  // optional, for FCM notifications
 *   "platform": "android"  // optional: android, ios
 * }
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "User registered successfully",
 *   "data": {
 *     "user_id": 1,
 *     "username": "john_doe",
 *     "email": "john@example.com",
 *     "name": "John Doe",
 *     "total_points": 0,
 *     "current_streak": 0,
 *     "longest_streak": 0,
 *     "level": 1,
 *     "country": "VN",
 *     "created_at": 1705123456
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "Username already exists"
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

// Validate required fields
$username = $input['username'] ?? '';
$password = $input['password'] ?? '';
$email = $input['email'] ?? null;
$name = $input['name'] ?? null;
$country = $input['country'] ?? 'VN';
$device_token = $input['device_token'] ?? null;
$platform = $input['platform'] ?? null;

// Validate username
if (empty($username)) {
    validationError(['username' => 'Username is required']);
}

if (!isValidUsername($username)) {
    validationError(['username' => 'Username must be 3-50 characters and contain only letters, numbers, and underscores']);
}

// Validate password
if (empty($password)) {
    validationError(['password' => 'Password is required']);
}

if (!isValidPassword($password)) {
    validationError(['password' => 'Password must be at least 6 characters']);
}

// Validate email nếu có
if (!empty($email) && !isValidEmail($email)) {
    validationError(['email' => 'Invalid email format']);
}

// Sanitize inputs
$username = sanitizeInput($username);
$email = $email ? sanitizeInput($email) : null;
$name = $name ? sanitizeInput($name) : null;
$country = sanitizeInput($country);
$country = strlen($country) === 2 ? strtoupper($country) : 'VN';
$device_token = $device_token ? sanitizeInput($device_token) : null;
$platform = $platform ? sanitizeInput($platform) : null;

// Validate platform nếu có
if ($platform && !in_array(strtolower($platform), ['android', 'ios'])) {
    $platform = null;
}

// Kiểm tra username đã tồn tại chưa
$stmt = $conn->prepare("SELECT user_id FROM codego_users WHERE username = ? LIMIT 1");
if (!$stmt) {
    error_log("Prepare failed: " . $conn->error);
    jsonResponse(false, 'Database error', null, 500);
}

$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $stmt->close();
    jsonResponse(false, 'Username already exists', null, 409);
}
$stmt->close();

// Kiểm tra email đã tồn tại chưa (nếu có email)
if (!empty($email)) {
    $stmt = $conn->prepare("SELECT user_id FROM codego_users WHERE email = ? LIMIT 1");
    if (!$stmt) {
        error_log("Prepare failed: " . $conn->error);
        jsonResponse(false, 'Database error', null, 500);
    }
    
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $stmt->close();
        jsonResponse(false, 'Email already exists', null, 409);
    }
    $stmt->close();
}

// Hash password
$hashed_password = hashPassword($password);

// Tạo user mới
$created_at = time();
$updated_at = time();

$stmt = $conn->prepare("
    INSERT INTO codego_users 
    (username, email, password, name, country, total_points, current_streak, longest_streak, level, is_active, created_at, updated_at) 
    VALUES (?, ?, ?, ?, ?, 0, 0, 0, 1, 1, ?, ?)
");

if (!$stmt) {
    error_log("Prepare failed: " . $conn->error);
    jsonResponse(false, 'Database error', null, 500);
}

$stmt->bind_param("sssssii", $username, $email, $hashed_password, $name, $country, $created_at, $updated_at);

if (!$stmt->execute()) {
    error_log("Execute failed: " . $stmt->error);
    $stmt->close();
    jsonResponse(false, 'Failed to create user', null, 500);
}

$user_id = $conn->insert_id;
$stmt->close();

// Lưu device token nếu có (cho FCM notifications)
if ($device_token && $platform) {
    $stmt = $conn->prepare("
        INSERT INTO device_tokens (user_id, device_token, platform, is_active, created_at, updated_at, last_used_at)
        VALUES (?, ?, ?, 1, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
            platform = VALUES(platform),
            is_active = 1,
            updated_at = VALUES(updated_at),
            last_used_at = VALUES(last_used_at)
    ");
    if ($stmt) {
        $stmt->bind_param("issiii", $user_id, $device_token, $platform, $created_at, $created_at, $created_at);
        $stmt->execute();
        $stmt->close();
    }
    
    // Cập nhật device_token và platform trong bảng users
    $stmt = $conn->prepare("
        UPDATE codego_users 
        SET device_token = ?, platform = ?
        WHERE user_id = ?
    ");
    if ($stmt) {
        $stmt->bind_param("ssi", $device_token, $platform, $user_id);
        $stmt->execute();
        $stmt->close();
    }
}

// Tạo user token (JWT) - giống như login
try {
    $user_token_payload = [
        'user_id' => $user_id,
        'username' => $username,
        'email' => $email ?? ''
    ];

    // 100 năm = 100 * 365 * 24 * 60 * 60 = 3,153,600,000 giây
    $token_expiry_100_years = 3153600000;
    $user_token = generateJWT($user_token_payload, 'codego_secret_key_2025', $token_expiry_100_years);

    // Trả về thông tin user với user_token (không trả về password)
    jsonResponse(true, 'User registered successfully', [
        'user_token' => $user_token,
        'user_id' => $user_id,
        'username' => $username,
        'email' => $email,
        'name' => $name,
        'total_points' => 0,
        'current_streak' => 0,
        'longest_streak' => 0,
        'level' => 1,
        'country' => $country,
        'created_at' => $created_at
    ], 201);
} catch (Exception $e) {
    error_log("Error generating token in register: " . $e->getMessage());
    // Vẫn trả về user data dù không có token
    jsonResponse(true, 'User registered successfully (token generation failed)', [
        'user_id' => $user_id,
        'username' => $username,
        'email' => $email,
        'name' => $name,
        'total_points' => 0,
        'current_streak' => 0,
        'longest_streak' => 0,
        'level' => 1,
        'country' => $country,
        'created_at' => $created_at
    ], 201);
}

?>
