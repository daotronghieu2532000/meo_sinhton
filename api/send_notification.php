<?php
/**
 * CODE GO API - SEND NOTIFICATION
 * API endpoint: /api/send_notification.php
 * Method: POST
 * 
 * Mô tả: Gửi push notification đến user qua FCM
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: application/json
 * 
 * Request Body (JSON):
 * {
 *   "user_id": 1,  // ID người dùng nhận notification
 *   "title": "Thông báo",
 *   "body": "Nội dung thông báo",
 *   "type": "achievement",  // achievement, lesson, exercise, streak, general
 *   "data": {  // optional, dữ liệu bổ sung
 *     "achievement_id": "first_lesson",
 *     "screen": "achievements"
 *   },
 *   "priority": "high"  // low, medium, high
 * }
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Notification sent successfully",
 *   "data": {
 *     "notification_id": 123,
 *     "fcm_sent": true
 *   }
 * }
 */

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/helpers.php';

// Enable output buffering để capture PHP errors
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
    $title = isset($input['title']) ? trim($input['title']) : '';
    $body = isset($input['body']) ? trim($input['body']) : '';
    $type = isset($input['type']) ? trim($input['type']) : 'general';
    $data = isset($input['data']) ? $input['data'] : [];
    $priority = isset($input['priority']) ? trim($input['priority']) : 'medium';

    if ($user_id <= 0) {
        jsonResponse(false, 'user_id is required and must be positive', null, 400);
        exit;
    }

    if (empty($title) || empty($body)) {
        jsonResponse(false, 'title and body are required', null, 400);
        exit;
    }

    // Validate priority
    if (!in_array($priority, ['low', 'medium', 'high'])) {
        $priority = 'medium';
    }

    // Validate type
    $allowed_types = ['achievement', 'lesson', 'exercise', 'streak', 'leaderboard', 'general'];
    if (!in_array($type, $allowed_types)) {
        $type = 'general';
    }

    // Lấy device token của user
    $stmt = $conn->prepare("
        SELECT device_token, platform 
        FROM device_tokens 
        WHERE user_id = ? AND is_active = 1
        ORDER BY last_used_at DESC
        LIMIT 1
    ");
    
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $device_data = $result->fetch_assoc();
    $stmt->close();

    if (!$device_data || empty($device_data['device_token'])) {
        // Lưu notification vào database nhưng không gửi FCM
        $stmt = $conn->prepare("
            INSERT INTO notification_mobile 
            (user_id, type, title, content, data, priority, is_read, push_sent, created_at)
            VALUES (?, ?, ?, ?, ?, ?, 0, 0, UNIX_TIMESTAMP())
        ");
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $data_json = json_encode($data, JSON_UNESCAPED_UNICODE);
        $stmt->bind_param("isssss", $user_id, $type, $title, $body, $data_json, $priority);
        $stmt->execute();
        $notification_id = $conn->insert_id;
        $stmt->close();

        jsonResponse(true, 'Notification saved but no device token found', [
            'notification_id' => $notification_id,
            'fcm_sent' => false
        ]);
        exit;
    }

    $device_token = $device_data['device_token'];
    $platform = $device_data['platform'] ?? 'android';

    // FCM Server Key - CẦN THAY BẰNG KEY THỰC TẾ TỪ FIREBASE CONSOLE
    // Lấy từ: Firebase Console > Project Settings > Cloud Messaging > Server Key
    $fcm_server_key = getenv('FCM_SERVER_KEY') ?: 'YOUR_FCM_SERVER_KEY_HERE';
    
    if ($fcm_server_key === 'YOUR_FCM_SERVER_KEY_HERE') {
        // Nếu chưa có FCM key, chỉ lưu vào database
        $stmt = $conn->prepare("
            INSERT INTO notification_mobile 
            (user_id, type, title, content, data, priority, is_read, push_sent, created_at)
            VALUES (?, ?, ?, ?, ?, ?, 0, 0, UNIX_TIMESTAMP())
        ");
        
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $data_json = json_encode($data, JSON_UNESCAPED_UNICODE);
        $stmt->bind_param("isssss", $user_id, $type, $title, $body, $data_json, $priority);
        $stmt->execute();
        $notification_id = $conn->insert_id;
        $stmt->close();

        jsonResponse(true, 'Notification saved but FCM server key not configured', [
            'notification_id' => $notification_id,
            'fcm_sent' => false
        ]);
        exit;
    }

    // Chuẩn bị FCM message
    $fcm_url = 'https://fcm.googleapis.com/fcm/send';
    
    $fcm_message = [
        'to' => $device_token,
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default',
            'badge' => 1,
        ],
        'data' => array_merge([
            'type' => $type,
            'user_id' => $user_id,
        ], $data),
        'priority' => $priority === 'high' ? 'high' : 'normal',
    ];

    // Gửi FCM request
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $fcm_url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: key=' . $fcm_server_key,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fcm_message));
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $fcm_response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curl_error = curl_error($ch);
    curl_close($ch);

    $fcm_sent = false;
    $fcm_error = null;

    if ($curl_error) {
        $fcm_error = "CURL Error: " . $curl_error;
    } elseif ($http_code === 200) {
        $fcm_result = json_decode($fcm_response, true);
        if (isset($fcm_result['success']) && $fcm_result['success'] == 1) {
            $fcm_sent = true;
        } elseif (isset($fcm_result['failure']) && $fcm_result['failure'] == 1) {
            $fcm_error = isset($fcm_result['results'][0]['error']) 
                ? $fcm_result['results'][0]['error'] 
                : 'FCM send failed';
        }
    } else {
        $fcm_error = "HTTP Error: " . $http_code;
    }

    // Lưu notification vào database
    $stmt = $conn->prepare("
        INSERT INTO notification_mobile 
        (user_id, type, title, content, data, priority, is_read, push_sent, created_at)
        VALUES (?, ?, ?, ?, ?, ?, 0, ?, UNIX_TIMESTAMP())
    ");
    
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $data_json = json_encode($data, JSON_UNESCAPED_UNICODE);
    $push_sent = $fcm_sent ? 1 : 0;
    $stmt->bind_param("isssssi", $user_id, $type, $title, $body, $data_json, $priority, $push_sent);
    $stmt->execute();
    $notification_id = $conn->insert_id;
    $stmt->close();

    // Cập nhật last_used_at cho device token
    $stmt = $conn->prepare("
        UPDATE device_tokens 
        SET last_used_at = UNIX_TIMESTAMP() 
        WHERE user_id = ? AND device_token = ?
    ");
    $stmt->bind_param("is", $user_id, $device_token);
    $stmt->execute();
    $stmt->close();

    // Clear output buffer và trả về response
    ob_end_clean();
    
    jsonResponse(true, $fcm_sent ? 'Notification sent successfully' : 'Notification saved but FCM send failed', [
        'notification_id' => $notification_id,
        'fcm_sent' => $fcm_sent,
        'fcm_error' => $fcm_error,
    ]);

} catch (Exception $e) {
    ob_end_clean();
    error_log("Send notification error: " . $e->getMessage());
    jsonResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
