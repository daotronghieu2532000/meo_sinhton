<?php
/**
 * CODE GO API - UPLOAD AVATAR
 * API endpoint: /api/upload_avatar.php
 * Method: POST
 * 
 * Mô tả: Upload ảnh đại diện cho user
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: multipart/form-data
 * 
 * Request Body (Form Data):
 * - user_id: int (required)
 * - avatar: file (required, image file: jpg, jpeg, png, gif, max 5MB)
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Avatar uploaded successfully",
 *   "data": {
 *     "user_id": 1,
 *     "avatar_url": "https://codego.io.vn/api/uploads/avatars/user_1_1234567890.jpg"
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "Invalid file type"
 * }
 */

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/helpers.php';

// Chỉ cho phép POST
requireMethod('POST');

// Kiểm tra Authorization header
$headers = getallheaders();
$auth_header = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (empty($auth_header) || !preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
    jsonResponse(false, 'Authorization token required', null, 401);
}

$token = $matches[1];
$token_data = verifyJWT($token, 'codego_secret_key_2025');

if (!$token_data) {
    jsonResponse(false, 'Invalid or expired token', null, 401);
}

// Kiểm tra user_id
$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

if ($user_id <= 0) {
    jsonResponse(false, 'User ID is required', null, 400);
}

// Kiểm tra file đã upload chưa
if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
    $error_msg = 'No file uploaded';
    if (isset($_FILES['avatar']['error'])) {
        switch ($_FILES['avatar']['error']) {
            case UPLOAD_ERR_INI_SIZE:
            case UPLOAD_ERR_FORM_SIZE:
                $error_msg = 'File size too large (max 5MB)';
                break;
            case UPLOAD_ERR_PARTIAL:
                $error_msg = 'File upload incomplete';
                break;
            case UPLOAD_ERR_NO_FILE:
                $error_msg = 'No file selected';
                break;
            default:
                $error_msg = 'File upload error';
        }
    }
    jsonResponse(false, $error_msg, null, 400);
}

$file = $_FILES['avatar'];

// Validate file type
$allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
$file_type = $file['type'];
$file_ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
$allowed_extensions = ['jpg', 'jpeg', 'png', 'gif'];

if (!in_array($file_type, $allowed_types) || !in_array($file_ext, $allowed_extensions)) {
    jsonResponse(false, 'Invalid file type. Allowed: JPG, JPEG, PNG, GIF', null, 400);
}

// Validate file size (max 5MB)
$max_size = 5 * 1024 * 1024; // 5MB
if ($file['size'] > $max_size) {
    jsonResponse(false, 'File size too large. Maximum: 5MB', null, 400);
}

// Kiểm tra user có tồn tại không
$stmt = $conn->prepare("SELECT user_id FROM codego_users WHERE user_id = ? LIMIT 1");
if (!$stmt) {
    error_log("Prepare failed: " . $conn->error);
    jsonResponse(false, 'Database error', null, 500);
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    jsonResponse(false, 'User not found', null, 404);
}
$stmt->close();

// Tạo thư mục uploads nếu chưa có
$upload_dir = __DIR__ . '/uploads/avatars/';
if (!file_exists($upload_dir)) {
    if (!mkdir($upload_dir, 0755, true)) {
        jsonResponse(false, 'Failed to create upload directory', null, 500);
    }
}

// Tạo tên file mới (user_id_timestamp.ext)
$timestamp = time();
$new_filename = 'user_' . $user_id . '_' . $timestamp . '.' . $file_ext;
$upload_path = $upload_dir . $new_filename;

// Upload file
if (!move_uploaded_file($file['tmp_name'], $upload_path)) {
    jsonResponse(false, 'Failed to upload file', null, 500);
}

// Tạo URL avatar
$avatar_url = 'https://codego.io.vn/api/uploads/avatars/' . $new_filename;

// Cập nhật avatar URL trong database
$updated_at = time();
$stmt = $conn->prepare("
    UPDATE codego_users 
    SET avatar = ?, updated_at = ?
    WHERE user_id = ?
");

if (!$stmt) {
    error_log("Prepare failed: " . $conn->error);
    // Xóa file đã upload nếu update DB thất bại
    @unlink($upload_path);
    jsonResponse(false, 'Database error', null, 500);
}

$stmt->bind_param("sii", $avatar_url, $updated_at, $user_id);

if (!$stmt->execute()) {
    error_log("Execute failed: " . $stmt->error);
    $stmt->close();
    // Xóa file đã upload nếu update DB thất bại
    @unlink($upload_path);
    jsonResponse(false, 'Failed to update avatar', null, 500);
}

$stmt->close();

// Xóa avatar cũ nếu có
$stmt = $conn->prepare("SELECT avatar FROM codego_users WHERE user_id = ? LIMIT 1");
if ($stmt) {
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $old_user = $result->fetch_assoc();
        if (!empty($old_user['avatar']) && $old_user['avatar'] !== $avatar_url) {
            // Extract filename từ URL
            $old_filename = basename(parse_url($old_user['avatar'], PHP_URL_PATH));
            $old_file_path = $upload_dir . $old_filename;
            if (file_exists($old_file_path)) {
                @unlink($old_file_path);
            }
        }
    }
    $stmt->close();
}

// Trả về kết quả
jsonResponse(true, 'Avatar uploaded successfully', [
    'user_id' => $user_id,
    'avatar_url' => $avatar_url
], 200);

?>
