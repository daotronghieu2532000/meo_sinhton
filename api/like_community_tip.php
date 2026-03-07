<?php
/**
 * CODE GO API - LIKE COMMUNITY TIP
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

    if ($tip_id <= 0) {
        throw new Exception("ID bài viết không hợp lệ");
    }

    $sql = "UPDATE community_tips SET likes_count = likes_count + 1 WHERE id = $tip_id AND status = 1";

    if ($conn->query($sql) && $conn->affected_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Đã thả tim thành công'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        throw new Exception("Không thể thả tim bài viết này");
    }

} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
