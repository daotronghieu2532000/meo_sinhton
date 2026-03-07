<?php
/**
 * CODE GO API - UPDATE DEVICE TOKEN
 * API endpoint: /api/update_device_token.php
 * Method: POST
 * 
 * Mô tả: Cập nhật FCM device token cho user
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: application/json
 * 
 * Request Body (JSON):
 * {
 *   "user_id": 1,
 *   "device_token": "fcm_token_here",
 *   "platform": "android"  // android, ios
 * }
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Device token updated successfully"
 * }
 */

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/helpers.php';

// Enable output buffering
ob_start();

header('Content-Type: application/json; charset=utf-8');

try {
    // Kiểm tra method
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        jsonResponse(false, 'Method not allowed', null, 405);
        exit;
    }

    // Đọc JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        jsonResponse(false, 'Invalid JSON input', null, 400);
        exit;
    }

    // Validate required fields
    $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
    $device_token = isset($input['device_token']) ? trim($input['device_token']) : '';
    $platform = isset($input['platform']) ? trim($input['platform']) : 'android';

    if ($user_id <= 0) {
        jsonResponse(false, 'user_id is required and must be positive', null, 400);
        exit;
    }

    if (empty($device_token)) {
        jsonResponse(false, 'device_token is required', null, 400);
        exit;
    }

    // Validate platform
    if (!in_array($platform, ['android', 'ios'])) {
        $platform = 'android';
    }

    // Kiểm tra user tồn tại
    $stmt = $conn->prepare("SELECT user_id FROM codego_users WHERE user_id = ?");
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        $stmt->close();
        jsonResponse(false, 'User not found', null, 404);
        exit;
    }
    $stmt->close();

    $now = time();

    // Kiểm tra device token đã tồn tại chưa
    $stmt = $conn->prepare("
        SELECT id FROM device_tokens 
        WHERE user_id = ? AND device_token = ?
    ");
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $stmt->bind_param("is", $user_id, $device_token);
    $stmt->execute();
    $result = $stmt->get_result();
    $exists = $result->num_rows > 0;
    $stmt->close();

    if ($exists) {
        // Cập nhật existing token
        $stmt = $conn->prepare("
            UPDATE device_tokens 
            SET platform = ?, is_active = 1, updated_at = ?, last_used_at = ?
            WHERE user_id = ? AND device_token = ?
        ");
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("siiis", $platform, $now, $now, $user_id, $device_token);
        $stmt->execute();
        $stmt->close();
    } else {
        // Insert new token
        $stmt = $conn->prepare("
            INSERT INTO device_tokens 
            (user_id, device_token, platform, is_active, created_at, updated_at, last_used_at)
            VALUES (?, ?, ?, 1, ?, ?, ?)
        ");
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("issiii", $user_id, $device_token, $platform, $now, $now, $now);
        $stmt->execute();
        $stmt->close();
    }

    // Cập nhật device_token trong codego_users (backward compatibility)
    $stmt = $conn->prepare("
        UPDATE codego_users 
        SET device_token = ?, platform = ?, updated_at = ?
        WHERE user_id = ?
    ");
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $stmt->bind_param("ssii", $device_token, $platform, $now, $user_id);
    $stmt->execute();
    $stmt->close();

    // Deactivate old tokens của user này (giữ lại token hiện tại)
    $stmt = $conn->prepare("
        UPDATE device_tokens 
        SET is_active = 0 
        WHERE user_id = ? AND device_token != ?
    ");
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $stmt->bind_param("is", $user_id, $device_token);
    $stmt->execute();
    $stmt->close();

    ob_end_clean();
    jsonResponse(true, 'Device token updated successfully');

} catch (Exception $e) {
    ob_end_clean();
    error_log("Update device token error: " . $e->getMessage());
    jsonResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
