<?php
/**
 * CODE GO API - GET COMMUNITY TIPS (Approved only)
 */

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

header('Content-Type: application/json; charset=utf-8');

try {
    require_once __DIR__ . '/includes/config.php';
    
    if (!$conn) {
        throw new Exception("Database connection failed");
    }

    // Chỉ lấy STATUS = 1 (Đã duyệt)
    $sql = "SELECT * FROM community_tips WHERE status = 1 ORDER BY created_at DESC";
    $result = $conn->query($sql);

    $tips = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $tips[] = [
                'id' => (int)$row['id'],
                'user_id' => $row['user_id'] ? (int)$row['user_id'] : null,
                'title' => $row['title'],
                'content' => $row['content'],
                'category' => $row['category'],
                'author_name' => $row['author_name'] ?? 'Ẩn danh',
                'likes_count' => (int)$row['likes_count'],
                'steps' => json_decode($row['steps'] ?? '[]'),
                'created_at' => $row['created_at']
            ];
        }
    }

    echo json_encode([
        'success' => true,
        'data' => $tips
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
