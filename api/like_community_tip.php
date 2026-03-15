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
    $user_id = isset($data['user_id']) ? $conn->real_escape_string($data['user_id']) : '';
    $ip_address = $_SERVER['REMOTE_ADDR'];

    if ($tip_id <= 0) {
        throw new Exception("ID bài viết không hợp lệ");
    }

    // 1. Kiểm tra xem User này đã thích bài viết này chưa
    // Thử truy vấn với user_id trước, nếu lỗi thì fallback về ip_address
    $is_liked = false;
    $check_sql = "";
    
    if (!empty($user_id)) {
        $check_sql = "SELECT id FROM tip_likes WHERE tip_id = $tip_id AND (user_id = '$user_id' OR ip_address = '$ip_address')";
        $check_result = @$conn->query($check_sql);
        
        // Nếu query lỗi (do chưa có cột user_id), dùng IP
        if (!$check_result) {
            $check_sql = "SELECT id FROM tip_likes WHERE tip_id = $tip_id AND ip_address = '$ip_address'";
            $check_result = $conn->query($check_sql);
        }
    } else {
        $check_sql = "SELECT id FROM tip_likes WHERE tip_id = $tip_id AND ip_address = '$ip_address'";
        $check_result = $conn->query($check_sql);
    }
    
    if ($check_result && $check_result->num_rows > 0) {
        // ĐÃ THÍCH -> HÀNH ĐỘNG: UNLIKE
        if (!empty($user_id)) {
            // Xóa bằng cả 2 để chắc chắn
            $conn->query("DELETE FROM tip_likes WHERE tip_id = $tip_id AND (user_id = '$user_id' OR ip_address = '$ip_address')");
        } else {
            $conn->query("DELETE FROM tip_likes WHERE tip_id = $tip_id AND ip_address = '$ip_address'");
        }
        $conn->query("UPDATE community_tips SET likes_count = GREATEST(0, likes_count - 1) WHERE id = $tip_id");
        $is_liked = false;
        $message = "Đã bỏ thích bài viết";
    } else {
        // CHƯA THÍCH -> HÀNH ĐỘNG: LIKE
        // Thử insert với user_id, nếu lỗi thì insert chỉ với IP
        $stmt = @$conn->prepare("INSERT INTO tip_likes (tip_id, ip_address, user_id) VALUES (?, ?, ?)");
        if ($stmt) {
            $stmt->bind_param("iss", $tip_id, $ip_address, $user_id);
            $stmt->execute();
            $stmt->close();
        } else {
            // Fallback: chỉ insert IP
            $stmt = $conn->prepare("INSERT INTO tip_likes (tip_id, ip_address) VALUES (?, ?)");
            $stmt->bind_param("is", $tip_id, $ip_address);
            $stmt->execute();
            $stmt->close();
        }
        
        $conn->query("UPDATE community_tips SET likes_count = likes_count + 1 WHERE id = $tip_id");
        $is_liked = true;
        $message = "Đã thả tim thành công";
    }

    // 4. Trả về kết quả
    $count_res = $conn->query("SELECT likes_count FROM community_tips WHERE id = $tip_id");
    $count_row = $count_res->fetch_assoc();
    $new_count = (int)$count_row['likes_count'];

    echo json_encode([
        'success' => true,
        'is_liked' => $is_liked,
        'new_likes_count' => $new_count,
        'message' => $message,
        'debug' => [
            'user_id' => $user_id,
            'tip_id' => $tip_id,
            'ip' => $ip_address,
            'last_query' => $check_sql
        ]
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    error_log("LIKE_ERROR: " . $e->getMessage());
    echo json_encode([
        'success' => false, 
        'message' => $e->getMessage(),
        'error_detail' => $conn->error ?? 'No DB error'
    ], JSON_UNESCAPED_UNICODE);
}
?>
