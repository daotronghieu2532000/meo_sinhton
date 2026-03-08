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
    $image_url = '';

    // Xử lý Upload ảnh (nếu có)
    if (isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
        $target_dir = __DIR__ . "/uploads/community/";
        if (!file_exists($target_dir)) {
            mkdir($target_dir, 0777, true);
        }
        
        $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
        $new_filename = uniqid() . '.' . $file_extension;
        $target_file = $target_dir . $new_filename;
        
        if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
            // Lưu đường dẫn tính từ thư mục api để get_community_tips.php dễ xử lý
            $image_url = 'uploads/community/' . $new_filename; 
        }
    }

    // Tự động suy diễn Quốc gia từ IP (Sử dụng IP-API)
    $country_code = 'VN'; // Mặc định
    try {
        if ($ip_address !== '127.0.0.1' && $ip_address !== '::1' && !empty($ip_address)) {
            $ip_details = json_decode(file_get_contents("http://ip-api.com/json/{$ip_address}?fields=status,countryCode"));
            if ($ip_details && $ip_details->status === 'success') {
                $country_code = $ip_details->countryCode;
            }
        }
    } catch (Exception $e) {
        // Lỗi gọi API thì cứ để mặc định VN
    }

    if (empty($title) || empty($content)) {
        throw new Exception("Tiêu đề và nội dung không được để trống");
    }

    // 1. Kiểm tra giới hạn 5 bài / ngày (theo IP or user_id)
    $sql_check = "SELECT COUNT(*) as total FROM community_tips 
                  WHERE (user_id = " . ($user_id ? $user_id : "NULL") . " OR ip_address = '$ip_address') 
                  AND DATE(created_at) = CURDATE()";
    $result_check = $conn->query($sql_check);
    if (!$result_check) {
        throw new Exception("Lỗi truy vấn kiểm tra limits: " . $conn->error);
    }
    $row_check = $result_check->fetch_assoc();
    
    if ($row_check['total'] >= 5) {
        throw new Exception("Bạn đã đạt giới hạn chia sẻ 5 mẹo trong ngày hôm nay. Hãy quay lại vào ngày mai nhé!");
    }

    // 2. Chèn dữ liệu mới với status = 0 (Chờ duyệt)
    $stmt = $conn->prepare("INSERT INTO community_tips (user_id, title, content, category, author_name, ip_address, status, steps, image_url, country_code) VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?)");
    
    if (!$stmt) {
        throw new Exception("Lỗi prepare statement: " . $conn->error);
    }

    // 9 tham số => chuỗi là 'issssssss' (1 'i' và 8 's')
    $stmt->bind_param("issssssss", $user_id, $title, $content, $category, $author_name, $ip_address, $steps_json, $image_url, $country_code);

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
