<?php
/**
 * CODE GO API - USER LOGIN
 * API endpoint: /api/login.php
 * Method: POST
 * 
 * Mô tả: Đăng nhập người dùng và trả về user token
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: application/json
 * 
 * Request Body (JSON):
 * {
 *   "username": "john_doe",
 *   "password": "password123",
 *   "device_token": "fcm_device_token_here",  // optional
 *   "platform": "android"  // optional: android, ios
 * }
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Login successful",
 *   "data": {
 *     "user_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
 *     "user": {
 *       "user_id": 1,
 *       "username": "john_doe",
 *       "email": "john@example.com",
 *       "name": "John Doe",
 *       "avatar": null,
 *       "total_points": 100,
 *       "current_streak": 5,
 *       "longest_streak": 10,
 *       "level": 3,
 *       "country": "VN"
 *     }
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "Invalid credentials"
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
$username = $input['username'] ?? '';
$password = $input['password'] ?? '';
$device_token = $input['device_token'] ?? null;
$platform = $input['platform'] ?? null;

if (empty($username) || empty($password)) {
    validationError([
        'username' => empty($username) ? 'Username is required' : '',
        'password' => empty($password) ? 'Password is required' : ''
    ]);
}

// Sanitize inputs
$username = sanitizeInput($username);
$device_token = $device_token ? sanitizeInput($device_token) : null;
$platform = $platform ? sanitizeInput($platform) : null;

// Validate platform nếu có
if ($platform && !in_array(strtolower($platform), ['android', 'ios'])) {
    $platform = null;
}

// Tìm user theo username
try {
    $stmt = $conn->prepare("
        SELECT user_id, username, email, password, name, avatar, 
               total_points, current_streak, longest_streak, level, country, is_active
        FROM codego_users 
        WHERE username = ? AND is_active = 1
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

    $stmt->bind_param("s", $username);
    
    if (!$stmt->execute()) {
        $error = $stmt->error;
        error_log("Execute failed: " . $error);
        $stmt->close();
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Database error', ['error' => $error, 'type' => 'execute_failed'], 500);
    }
    
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        $stmt->close();
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Invalid credentials', null, 401);
    }

    $user = $result->fetch_assoc();
    $stmt->close();
    
    if (!$user) {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Failed to fetch user data', null, 500);
    }
} catch (Exception $e) {
    if (isset($stmt)) {
        $stmt->close();
    }
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    error_log("Error in user query: " . $e->getMessage());
    jsonResponse(false, 'Database error', ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()], 500);
}

// Verify password
if (!verifyPassword($password, $user['password'])) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Invalid credentials', null, 401);
}

// Cập nhật last_login
try {
    $last_login = time();
    $updated_at = time();
    $user_id = intval($user['user_id']); // Đảm bảo user_id là int
    
    if ($user_id <= 0) {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Invalid user ID', ['user_id' => $user['user_id']], 500);
    }

    $stmt = $conn->prepare("
        UPDATE codego_users 
        SET last_login = ?, updated_at = ?
        WHERE user_id = ?
    ");

    if (!$stmt) {
        $error = $conn->error;
        error_log("Prepare failed for update last_login: " . $error);
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Database error', ['error' => $error, 'type' => 'update_last_login_prepare'], 500);
    }
    
    $stmt->bind_param("iii", $last_login, $updated_at, $user_id);
    
    if (!$stmt->execute()) {
        $error = $stmt->error;
        error_log("Execute failed for update last_login: " . $error);
        $stmt->close();
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Database error', ['error' => $error, 'type' => 'update_last_login_execute'], 500);
    }
    
    $stmt->close();
} catch (Exception $e) {
    if (isset($stmt)) {
        $stmt->close();
    }
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    error_log("Error updating last_login: " . $e->getMessage());
    jsonResponse(false, 'Database error', ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()], 500);
}

// Cập nhật device token nếu có
if ($device_token && $platform) {
    try {
        // Kiểm tra xem device token đã tồn tại chưa
        $stmt = $conn->prepare("
            SELECT id FROM device_tokens 
            WHERE user_id = ? AND device_token = ?
            LIMIT 1
        ");
        
        if (!$stmt) {
            error_log("Prepare failed for device_tokens select: " . $conn->error);
            // Không throw error, chỉ log và tiếp tục
        } else {
            $stmt->bind_param("is", $user_id, $device_token);
            
            if (!$stmt->execute()) {
                error_log("Execute failed for device_tokens select: " . $stmt->error);
                $stmt->close();
            } else {
                $result = $stmt->get_result();
                
                if ($result->num_rows > 0) {
                    // Update existing token
                    $stmt->close();
                    $stmt = $conn->prepare("
                        UPDATE device_tokens 
                        SET platform = ?, is_active = 1, updated_at = ?, last_used_at = ?
                        WHERE user_id = ? AND device_token = ?
                    ");
                    if ($stmt) {
                        $stmt->bind_param("siiis", $platform, $updated_at, $updated_at, $user_id, $device_token);
                        if (!$stmt->execute()) {
                            error_log("Execute failed for device_tokens update: " . $stmt->error);
                        }
                        $stmt->close();
                    }
                } else {
                    // Insert new token
                    $stmt->close();
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
                        $stmt->bind_param("issiii", $user_id, $device_token, $platform, $updated_at, $updated_at, $updated_at);
                        if (!$stmt->execute()) {
                            error_log("Execute failed for device_tokens insert: " . $stmt->error);
                        }
                        $stmt->close();
                    }
                }
            }
        }
        
        // Cập nhật device_token và platform trong bảng users
        $stmt = $conn->prepare("
            UPDATE codego_users 
            SET device_token = ?, platform = ?
            WHERE user_id = ?
        ");
        if ($stmt) {
            $stmt->bind_param("ssi", $device_token, $platform, $user_id);
            if (!$stmt->execute()) {
                error_log("Execute failed for codego_users device_token update: " . $stmt->error);
            }
            $stmt->close();
        }
    } catch (Exception $e) {
        // Không throw error, chỉ log và tiếp tục
        error_log("Error updating device token: " . $e->getMessage());
    }
}

// Tạo user token (JWT)
try {
    $user_token_payload = [
        'user_id' => $user_id, // Dùng biến đã convert sang int
        'username' => $user['username'],
        'email' => $user['email'] ?? ''
    ];

    // 100 năm = 100 * 365 * 24 * 60 * 60 = 3,153,600,000 giây
    $token_expiry_100_years = 3153600000;
    $user_token = generateJWT($user_token_payload, 'codego_secret_key_2025', $token_expiry_100_years);

    // Trả về thông tin user (không trả về password)
    unset($user['password']);

    // Đảm bảo user_id là int trong response
    $user['user_id'] = $user_id;
    
    // Đảm bảo các field numeric là int
    $user['total_points'] = intval($user['total_points'] ?? 0);
    $user['current_streak'] = intval($user['current_streak'] ?? 0);
    $user['longest_streak'] = intval($user['longest_streak'] ?? 0);
    $user['level'] = intval($user['level'] ?? 1);

    // Clear output buffer trước khi trả về JSON
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(true, 'Login successful', [
        'user_token' => $user_token,
        'user' => $user,
        'last_login' => $last_login
    ], 200);
} catch (Exception $e) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    error_log("Error generating token or response: " . $e->getMessage());
    jsonResponse(false, 'Error processing login', [
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ], 500);
}

?>
