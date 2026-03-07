<?php
require_once __DIR__ . '/includes/config.php';

if (!$conn) {
    die("Kết nối thất bại: " . $conn->connect_error);
}

$sql = "CREATE TABLE IF NOT EXISTS community_tips (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100),
    author_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";

if ($conn->query($sql) === TRUE) {
    echo json_encode(['success' => true, 'message' => "Bảng 'community_tips' đã được tạo hoặc đã tồn tại."]);
} else {
    echo json_encode(['success' => false, 'message' => "Lỗi tạo bảng: " . $conn->error]);
}
?>
