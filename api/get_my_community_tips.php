<?php
/**
 * CODE GO API - GET MY COMMUNITY TIPS (By IP Address)
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

    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http");
    $current_dir = str_replace('get_my_community_tips.php', '', $_SERVER['REQUEST_URI']);
    $base_url = $protocol . "://" . $_SERVER['HTTP_HOST'] . $current_dir;

    $ip_address = $_SERVER['REMOTE_ADDR'];
    
    // Lấy bài viết của chính IP này (tất cả trạng thái)
    $stmt = $conn->prepare("SELECT * FROM community_tips WHERE ip_address = ? ORDER BY created_at DESC");
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param("s", $ip_address);
    $stmt->execute();
    $result = $stmt->get_result();

    $tips = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $img = $row['image_url'];

            if ($img && strpos($img, 'api/') === 0) {
                $img = str_replace('api/', '', $img);
            }
            
            $tips[] = [
                'id' => (int)$row['id'],
                'user_id' => $row['user_id'] ? (int)$row['user_id'] : null,
                'title' => $row['title'],
                'content' => $row['content'],
                'category' => $row['category'],
                'author_name' => $row['author_name'] ?? 'Ẩn danh',
                'status' => (int)$row['status'], // Trạng thái bài viết: 0=Chờ, 1=Đã duyệt, 2=Từ chối (hoặc tùy quy ước)
                'likes_count' => (int)$row['likes_count'],
                'steps' => json_decode($row['steps'] ?? '[]'),
                'image_url' => $img ? $base_url . $img : null,
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
