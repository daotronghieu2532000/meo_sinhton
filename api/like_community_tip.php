<?php
/**
 * CODE GO API - TOGGLE LIKE COMMUNITY TIP (Anti-spam/1 IP = 1 Like)
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

    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data) $data = $_POST;

    $tip_id = isset($data['tip_id']) ? (int)$data['tip_id'] : 0;
    // Lấy IP của người dùng thực tế
    $ip_address = $_SERVER['REMOTE_ADDR'];

    if ($tip_id <= 0) {
        throw new Exception("ID bài viết không hợp lệ");
    }

    // 1. Kiểm tra xem IP này đã thích bài viết này chưa
    $check_sql = "SELECT id FROM tip_likes WHERE tip_id = $tip_id AND ip_address = '$ip_address'";
    $check_result = $conn->query($check_sql);
    
    $is_liked = false;
    if ($check_result && $check_result->num_rows > 0) {
        // ĐÃ THÍCH -> HÀNH ĐỘNG: UNLIKE (Bỏ thích)
        $conn->query("DELETE FROM tip_likes WHERE tip_id = $tip_id AND ip_address = '$ip_address'");
        $conn->query("UPDATE community_tips SET likes_count = GREATEST(0, likes_count - 1) WHERE id = $tip_id");
        $is_liked = false;
        $message = "Đã bỏ thích bài viết";
    } else {
        // CHƯA THÍCH -> HÀNH ĐỘNG: LIKE (Thả tim)
        $conn->query("INSERT INTO tip_likes (tip_id, ip_address) VALUES ($tip_id, '$ip_address')");
        $conn->query("UPDATE community_tips SET likes_count = likes_count + 1 WHERE id = $tip_id");
        $is_liked = true;
        $message = "Đã thả tim thành công";
    }

    // Lấy số lượt thích mới nhất để trả về UI
    $count_res = $conn->query("SELECT likes_count FROM community_tips WHERE id = $tip_id");
    $count_row = $count_res->fetch_assoc();
    $new_count = (int)$count_row['likes_count'];

    echo json_encode([
        'success' => true,
        'is_liked' => $is_liked,
        'new_likes_count' => $new_count,
        'message' => $message
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
