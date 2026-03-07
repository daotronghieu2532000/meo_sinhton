<?php
require_once __DIR__ . '/includes/config.php';

if (!$conn) {
    die("Kết nối thất bại");
}

// 1. Cập nhật bảng community_tips: thêm status, likes_count, ip_address
$sql1 = "ALTER TABLE community_tips 
        ADD COLUMN IF NOT EXISTS status TINYINT DEFAULT 0 COMMENT '0: pending, 1: approved, 2: rejected',
        ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS ip_address VARCHAR(45),
        ADD COLUMN IF NOT EXISTS steps JSON,
        ADD COLUMN IF NOT EXISTS image_url VARCHAR(255),
        ADD COLUMN IF NOT EXISTS country_code VARCHAR(5) DEFAULT 'VN';";

// 2. Tạo bảng community_comments
$sql2 = "CREATE TABLE IF NOT EXISTS community_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tip_id INT NOT NULL,
    user_id INT,
    author_name VARCHAR(100),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tip_id) REFERENCES community_tips(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_comment (tip_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";

$res1 = $conn->query($sql1);
$res2 = $conn->query($sql2);

echo json_encode([
    'success' => true,
    'update_tips' => $res1,
    'create_comments' => $res2,
    'message' => 'Đã cập nhật cấu trúc database cho hệ thống xét duyệt và bình luận.'
]);
?>
