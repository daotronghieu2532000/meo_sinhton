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


    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http");
    $base_url = $protocol . "://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . '/';
    // Đảm bảo không có dấu // nếu dirname trả về /
    $base_url = str_replace('//', '/', $base_url);
    $base_url = str_replace(':/', '://', $base_url);

    $user_id = isset($_GET['user_id']) ? $_GET['user_id'] : '';
    $ip_address = $_SERVER['REMOTE_ADDR'];
    
    // Ưu tiên tìm theo user_id, nếu không có thì tìm theo IP (để hỗ trợ bài cũ)
    if (!empty($user_id)) {
        $stmt = $conn->prepare("SELECT * FROM community_tips WHERE user_id = ? OR ip_address = ? ORDER BY created_at DESC");
        $stmt->bind_param("ss", $user_id, $ip_address);
    } else {
        $stmt = $conn->prepare("SELECT * FROM community_tips WHERE ip_address = ? ORDER BY created_at DESC");
        $stmt->bind_param("s", $ip_address);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();

    $tips = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
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
                'status' => (int)$row['status'],
                'likes_count' => (int)$row['likes_count'],
                'steps' => json_decode($row['steps'] ?? '[]'),
                'image_url' => !empty($images) ? $images[0] : null,
                'images' => $images,
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
