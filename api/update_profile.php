<?php
/**
 * CODE GO API - UPDATE USER PROFILE
 * API endpoint: /api/update_profile.php
 * Method: POST
 * 
 * Mô tả: Cập nhật thông tin profile của user (name, email)
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: application/json
 * 
 * Request Body (JSON):
 * {
 *   "user_id": 1,
 *   "name": "John Doe",  // optional
 *   "email": "john@example.com"  // optional
 * }
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Profile updated successfully",
 *   "data": {
 *     "user_id": 1,
 *     "name": "John Doe",
 *     "email": "john@example.com"
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "User not found"
 * }
 */

// Bật error reporting để debug
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Bắt đầu output buffering để catch errors
if (ob_get_level() == 0) {
    ob_start();
}

try {
    require_once __DIR__ . '/includes/config.php';
    require_once __DIR__ . '/includes/helpers.php';
    
    // Kiểm tra xem $conn đã được tạo chưa
    if (!isset($conn) || $conn === null) {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Database connection not initialized', ['error' => 'Variable $conn is not set after loading config.php'], 500);
    }
    
    // Kiểm tra xem connection có hoạt động không
    if ($conn->connect_error) {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Database connection error', [
            'error' => $conn->connect_error,
            'error_code' => $conn->connect_errno
        ], 500);
    }
} catch (Exception $e) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Error loading includes: ' . $e->getMessage(), ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()], 500);
} catch (Error $e) {
    // Catch PHP 7+ Error (không phải Exception)
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Fatal error loading includes: ' . $e->getMessage(), ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()], 500);
}

// Chỉ cho phép POST
try {
    requireMethod('POST');
} catch (Exception $e) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Method error: ' . $e->getMessage(), null, 405);
}

// Kiểm tra Authorization header
$headers = getallheaders();
$auth_header = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (empty($auth_header) || !preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Authorization token required', null, 401);
}

$token = $matches[1];
$token_data = verifyJWT($token, 'codego_secret_key_2025');

if (!$token_data) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Invalid or expired token', null, 401);
}

// Lấy input từ request
$input = getJsonInput();

// Validate required fields
$user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
$name = isset($input['name']) ? trim($input['name']) : null;
$email = isset($input['email']) ? trim($input['email']) : null;

if ($user_id <= 0) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['user_id' => 'User ID is required and must be a positive integer']);
}

// Kiểm tra ít nhất một field cần update
if ($name === null && $email === null) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['name' => 'At least one field (name or email) must be provided']);
}

// Validate email nếu có
if ($email !== null && $email !== '' && !isValidEmail($email)) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['email' => 'Invalid email format']);
}

// Sanitize inputs
$name = $name !== null && $name !== '' ? sanitizeInput($name) : null;
$email = $email !== null && $email !== '' ? sanitizeInput($email) : null;

// Kiểm tra user có tồn tại không
$stmt = $conn->prepare("
    SELECT user_id, username, email, name 
    FROM codego_users 
    WHERE user_id = ? AND is_active = 1
    LIMIT 1
");

if (!$stmt) {
    $error = $conn->error;
    error_log("Prepare failed: " . $error);
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Database error', ['error' => $error, 'type' => 'prepare_failed'], 500);
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'User not found', null, 404);
}

$user = $result->fetch_assoc();
$stmt->close();

// Kiểm tra email đã tồn tại chưa (nếu đang update email)
if ($email !== null && $email !== '' && $email !== $user['email']) {
    $stmt = $conn->prepare("
        SELECT user_id FROM codego_users 
        WHERE email = ? AND user_id != ? AND is_active = 1
        LIMIT 1
    ");
    
    if ($stmt) {
        $stmt->bind_param("si", $email, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $stmt->close();
            if (ob_get_level() > 0) {
                ob_end_clean();
            }
            jsonResponse(false, 'Email already exists', null, 409);
        }
        $stmt->close();
    }
}

// Build UPDATE query động
$update_fields = [];
$update_values = [];
$types = '';

if ($name !== null && $name !== '') {
    $update_fields[] = "name = ?";
    $update_values[] = $name;
    $types .= 's';
}

if ($email !== null && $email !== '') {
    $update_fields[] = "email = ?";
    $update_values[] = $email;
    $types .= 's';
}

if (empty($update_fields)) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'No fields to update', null, 400);
}

// Thêm updated_at
$update_fields[] = "updated_at = ?";
$update_values[] = time();
$types .= 'i';

// Thêm user_id vào cuối cho WHERE clause
$update_values[] = $user_id;
$types .= 'i';

$sql = "UPDATE codego_users SET " . implode(", ", $update_fields) . " WHERE user_id = ?";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    $error = $conn->error;
    error_log("Prepare failed for update: " . $error);
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Database error', ['error' => $error, 'type' => 'update_prepare_failed'], 500);
}

$stmt->bind_param($types, ...$update_values);

if (!$stmt->execute()) {
    $error = $stmt->error;
    error_log("Execute failed for update: " . $error);
    $stmt->close();
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Database error', ['error' => $error, 'type' => 'update_execute_failed'], 500);
}

$stmt->close();

// Lấy thông tin user đã cập nhật
$stmt = $conn->prepare("
    SELECT user_id, username, email, name, avatar, 
           total_points, current_streak, longest_streak, level, country
    FROM codego_users 
    WHERE user_id = ?
    LIMIT 1
");

if ($stmt) {
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $updated_user = $result->fetch_assoc();
    $stmt->close();
    
    // Đảm bảo các field numeric là int
    if ($updated_user) {
        $updated_user['user_id'] = intval($updated_user['user_id']);
        $updated_user['total_points'] = intval($updated_user['total_points'] ?? 0);
        $updated_user['current_streak'] = intval($updated_user['current_streak'] ?? 0);
        $updated_user['longest_streak'] = intval($updated_user['longest_streak'] ?? 0);
        $updated_user['level'] = intval($updated_user['level'] ?? 1);
    }
    
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(true, 'Profile updated successfully', $updated_user, 200);
} else {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(true, 'Profile updated successfully', [
        'user_id' => $user_id,
        'name' => $name ?? $user['name'],
        'email' => $email ?? $user['email']
    ], 200);
}

?>
