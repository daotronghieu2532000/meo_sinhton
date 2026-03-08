<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
require_once 'includes/config.php';

try {
    // Tự động nhận diện Base URL (http/https + domain + path)
    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http");
    $current_dir = str_replace('get_top_tips.php', '', $_SERVER['REQUEST_URI']);
    $base_url = $protocol . "://" . $_SERVER['HTTP_HOST'] . $current_dir;
    
    // Lấy IP của người dùng để kiểm tra trạng thái LIKE
    $ip_address = $_SERVER['REMOTE_ADDR'];

    // Get Top 10 tips by likes_count (Approved only) + Check Like
    $sql = "SELECT t.*, (SELECT id FROM tip_likes WHERE tip_id = t.id AND ip_address = '$ip_address' LIMIT 1) as my_like 
            FROM community_tips t 
            WHERE t.status = 1 
            ORDER BY t.likes_count DESC, t.created_at DESC LIMIT 10";
    $result = $conn->query($sql);

    $tips = [];

    if ($result && $result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $img = $row['image_url'];
            $is_liked = $row['my_like'] ? true : false;

            // Xử lý fallback cho các bản ghi cũ có prefix 'api/'
            if ($img && strpos($img, 'api/') === 0) {
                $img = str_replace('api/', '', $img);
            }
            $tips[] = [
                'id' => (int)$row['id'],
                'title' => $row['title'],
                'content' => $row['content'],
                'author_name' => $row['author_name'] ?? 'Anonymous',
                'category' => $row['category'],
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
