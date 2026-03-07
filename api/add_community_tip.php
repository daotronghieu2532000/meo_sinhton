<?php
/**
 * CODE GO API - ADD COMMUNITY TIP (With rate limiting & moderation)
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

    $title = isset($data['title']) ? $conn->real_escape_string($data['title']) : '';
    $content = isset($data['content']) ? $conn->real_escape_string($data['content']) : '';
    $category = isset($data['category']) ? $conn->real_escape_string($data['category']) : 'general';
    $author_name = isset($data['author_name']) ? $conn->real_escape_string($data['author_name']) : 'Ẩn danh';
    $user_id = isset($data['user_id']) ? (int)$data['user_id'] : null;
    $steps_json = isset($data['steps']) ? $data['steps'] : '[]'; // JSON string
    $ip_address = $_SERVER['REMOTE_ADDR'];

    if (empty($title) || empty($content)) {
        throw new Exception("Tiêu đề và nội dung không được để trống");
    }

    // 1. Kiểm tra giới hạn 5 bài / ngày (theo IP or user_id)
    $sql_check = "SELECT COUNT(*) as total FROM community_tips 
                  WHERE (user_id = " . ($user_id ? $user_id : "NULL") . " OR ip_address = '$ip_address') 
                  AND created_at >= CURDATE()";
    $result_check = $conn->query($sql_check);
    $row_check = $result_check->fetch_assoc();
    
    if ($row_check['total'] >= 5) {
        throw new Exception("Bạn đã đạt giới hạn chia sẻ 5 mẹo trong ngày hôm nay. Hãy quay lại vào ngày mai nhé!");
    }

    // 2. Chèn dữ liệu mới với status = 0 (Chờ duyệt)
    $stmt = $conn->prepare("INSERT INTO community_tips (user_id, title, content, category, author_name, ip_address, status, steps) VALUES (?, ?, ?, ?, ?, ?, 0, ?)");
    $stmt->bind_param("issssss", $user_id, $title, $content, $category, $author_name, $ip_address, $steps_json);

    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Cảm ơn bạn! Mẹo của bạn đã được gửi và đang chờ xét duyệt.',
            'id' => $stmt->insert_id
        ], JSON_UNESCAPED_UNICODE);
    } else {
        throw new Exception("Lỗi khi thêm dữ liệu: " . $conn->error);
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
