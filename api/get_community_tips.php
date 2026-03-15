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
    $base_url = $protocol . "://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . '/';
    $base_url = str_replace('//', '/', $base_url);
    $base_url = str_replace(':/', '://', $base_url);

    $user_id = isset($_GET['user_id']) ? $conn->real_escape_string($_GET['user_id']) : '';
    $ip_address = $_SERVER['REMOTE_ADDR'];
    
    // Câu lệnh SQL kiểm tra trạng thái Like dựa trên user_id hoặc IP
    if (!empty($user_id)) {
        $like_check_subquery = "SELECT id FROM tip_likes WHERE tip_id = t.id AND (user_id = '$user_id' OR ip_address = '$ip_address') LIMIT 1";
    } else {
        $like_check_subquery = "SELECT id FROM tip_likes WHERE tip_id = t.id AND ip_address = '$ip_address' LIMIT 1";
    }

    $sql = "SELECT t.*, ($like_check_subquery) as my_like 
            FROM community_tips t 
            WHERE t.status = 1 
            ORDER BY t.created_at DESC";
    
    $result = $conn->query($sql);

    $tips = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $img = $row['image_url'];
            $is_liked = $row['my_like'] ? true : false;

            // Xử lý ảnh (Hỗ trợ cả đơn lẻ và mảng JSON)
            $images = [];
            $img_raw = $row['image_url'];
            if ($img_raw) {
                $decoded = json_decode($img_raw, true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                    foreach ($decoded as $path) {
                        $images[] = $base_url . $path;
                    }
                } else {
                    $images[] = $base_url . $img_raw;
                }
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
                'image_url' => !empty($images) ? $images[0] : null, // Giữ lại cho tương thích cũ
                'images' => $images, // Mảng ảnh mới
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
