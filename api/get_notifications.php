<?php
/**
 * CODE GO API - GET NOTIFICATIONS
 * API endpoint: /api/get_notifications.php
 * Method: GET
 * 
 * Mô tả: Lấy danh sách notifications của user
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * 
 * Query Parameters:
 * - user_id: ID người dùng (required)
 * - limit: Số lượng notifications (default: 20, max: 100)
 * - offset: Offset cho pagination (default: 0)
 * - is_read: Lọc theo trạng thái đọc (0: chưa đọc, 1: đã đọc, null: tất cả)
 * - type: Lọc theo loại notification (optional)
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "data": {
 *     "total": 50,
 *     "unread_count": 5,
 *     "notifications": [
 *       {
 *         "id": 123,
 *         "type": "achievement",
 *         "title": "Thành tích mới!",
 *         "content": "Bạn đã hoàn thành bài học đầu tiên",
 *         "data": {...},
 *         "priority": "high",
 *         "is_read": 0,
 *         "created_at": 1705123456
 *       }
 *     ]
 *   }
 * }
 */

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/helpers.php';

// Enable output buffering
ob_start();

header('Content-Type: application/json; charset=utf-8');

try {
    // Kiểm tra method
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        jsonResponse(false, 'Method not allowed', null, 405);
        exit;
    }

    // Lấy query parameters
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 20;
    $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
    $is_read = isset($_GET['is_read']) ? ($_GET['is_read'] === 'null' ? null : intval($_GET['is_read'])) : null;
    $type = isset($_GET['type']) ? trim($_GET['type']) : null;

    if ($user_id <= 0) {
        jsonResponse(false, 'user_id is required and must be positive', null, 400);
        exit;
    }

    // Validate limit
    if ($limit < 1) $limit = 20;
    if ($limit > 100) $limit = 100;
    if ($offset < 0) $offset = 0;

    // Build WHERE clause
    $where_conditions = ["user_id = ?", "deleted_at IS NULL"];
    $params = [];
    $param_types = "i";

    if ($is_read !== null) {
        $where_conditions[] = "is_read = ?";
        $params[] = $is_read;
        $param_types .= "i";
    }

    if ($type !== null && !empty($type)) {
        $where_conditions[] = "type = ?";
        $params[] = $type;
        $param_types .= "s";
    }

    $where_clause = implode(" AND ", $where_conditions);

    // Đếm tổng số notifications
    $count_sql = "SELECT COUNT(*) as total FROM notification_mobile WHERE $where_clause";
    $stmt = $conn->prepare($count_sql);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    array_unshift($params, $user_id);
    $stmt->bind_param($param_types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    $total = $result->fetch_assoc()['total'];
    $stmt->close();

    // Đếm số notifications chưa đọc
    $unread_sql = "SELECT COUNT(*) as unread FROM notification_mobile WHERE user_id = ? AND is_read = 0 AND deleted_at IS NULL";
    $stmt = $conn->prepare($unread_sql);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $unread_count = $result->fetch_assoc()['unread'];
    $stmt->close();

    // Lấy danh sách notifications
    $sql = "SELECT id, type, title, content, data, priority, is_read, created_at 
            FROM notification_mobile 
            WHERE $where_clause 
            ORDER BY created_at DESC 
            LIMIT ? OFFSET ?";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $params[] = $limit;
    $params[] = $offset;
    $param_types .= "ii";
    $stmt->bind_param($param_types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();

    $notifications = [];
    while ($row = $result->fetch_assoc()) {
        $notifications[] = [
            'id' => intval($row['id']),
            'type' => $row['type'],
            'title' => $row['title'],
            'content' => $row['content'],
            'data' => !empty($row['data']) ? json_decode($row['data'], true) : null,
            'priority' => $row['priority'],
            'is_read' => intval($row['is_read']),
            'created_at' => intval($row['created_at']),
        ];
    }
    $stmt->close();

    ob_end_clean();
    jsonResponse(true, 'Notifications retrieved successfully', [
        'total' => intval($total),
        'unread_count' => intval($unread_count),
        'notifications' => $notifications,
    ]);

} catch (Exception $e) {
    ob_end_clean();
    error_log("Get notifications error: " . $e->getMessage());
    jsonResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
