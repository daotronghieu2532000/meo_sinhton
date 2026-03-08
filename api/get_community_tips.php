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

    // Tự động nhận diện Base URL (http/https + domain + path)
    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http");
    $current_dir = str_replace('get_community_tips.php', '', $_SERVER['REQUEST_URI']);
    $base_url = $protocol . "://" . $_SERVER['HTTP_HOST'] . $current_dir;

    // Lấy IP của người dùng để kiểm tra trạng thái LIKE
    $ip_address = $_SERVER['REMOTE_ADDR'];
    
    // Chỉ lấy STATUS = 1 (Đã duyệt) + Kiểm tra Like
    $sql = "SELECT t.*, (SELECT id FROM tip_likes WHERE tip_id = t.id AND ip_address = '$ip_address' LIMIT 1) as my_like 
            FROM community_tips t 
            WHERE t.status = 1 
            ORDER BY t.created_at DESC";
    $result = $conn->query($sql);

    $tips = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $img = $row['image_url'];
            $is_liked = $row['my_like'] ? true : false;

            // Xử lý fallback cho các bản ghi cũ có prefix 'api/'
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
                'likes_count' => (int)$row['likes_count'],
                'is_liked' => $is_liked,
                'steps' => json_decode($row['steps'] ?? '[]'),
                'image_url' => $img ? $base_url . $img : null,
                'country_code' => $row['country_code'] ?? 'VN',
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
