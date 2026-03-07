<?php
/**
 * CODE GO API - RATE APP
 * API endpoint: /api/rate_app.php
 * Method: POST
 * 
 * Mô tả: Đánh giá app (1-5 sao) kèm nhận xét và ảnh
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php)
 * - Content-Type: multipart/form-data
 * 
 * Request Body (Form Data):
 * - user_id: int (required)
 * - rating: int (required, 1-5)
 * - comment: string (optional)
 * - app_version: string (optional)
 * - platform: string (optional: android, ios, web)
 * - device_info: string (optional)
 * - images[]: file[] (optional, multiple image files, max 5 images, max 5MB each)
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Rating submitted successfully",
 *   "data": {
 *     "rating_id": 1,
 *     "user_id": 1,
 *     "rating": 5,
 *     "comment": "App rất hay, dễ sử dụng",
 *     "created_at": 1640000000
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "Invalid rating value"
 * }
 */

// Bật error reporting để debug
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Bắt đầu output buffering để catch errors
if (ob_get_level() == 0) {
    ob_start();
}

try {
    require_once __DIR__ . '/includes/config.php';
    require_once __DIR__ . '/includes/helpers.php';
    
    // Kiểm tra xem $conn đã được tạo chưa
    if (!isset($conn) || $conn === null) {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Database connection not initialized', ['error' => 'Variable $conn is not set after loading config.php'], 500);
    }
    
    // Kiểm tra xem connection có hoạt động không
    if ($conn->connect_error) {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, 'Database connection error', [
            'error' => $conn->connect_error,
            'error_code' => $conn->connect_errno
        ], 500);
    }
} catch (Exception $e) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Error loading includes: ' . $e->getMessage(), ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()], 500);
} catch (Error $e) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Fatal error loading includes: ' . $e->getMessage(), ['error' => $e->getMessage(), 'file' => $e->getFile(), 'line' => $e->getLine()], 500);
}

// Chỉ cho phép POST
try {
    requireMethod('POST');
} catch (Exception $e) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Method error: ' . $e->getMessage(), null, 405);
}

// Kiểm tra Authorization header
$headers = getallheaders();
$auth_header = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (empty($auth_header) || !preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Authorization token required', null, 401);
}

$token = $matches[1];
$token_data = verifyJWT($token, 'codego_secret_key_2025');

if (!$token_data) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Invalid or expired token', null, 401);
}

// Lấy input từ request (hỗ trợ cả JSON và Form Data)
$user_id = 0;
$rating = 0;
$comment = null;
$app_version = null;
$platform = null;
$device_info = null;

// Kiểm tra xem là multipart/form-data hay JSON
$content_type = $_SERVER['CONTENT_TYPE'] ?? '';
if (strpos($content_type, 'multipart/form-data') !== false) {
    // Form Data
    $user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    $rating = isset($_POST['rating']) ? intval($_POST['rating']) : 0;
    $comment = isset($_POST['comment']) ? trim($_POST['comment']) : null;
    $app_version = isset($_POST['app_version']) ? trim($_POST['app_version']) : null;
    $platform = isset($_POST['platform']) ? trim($_POST['platform']) : null;
    $device_info = isset($_POST['device_info']) ? trim($_POST['device_info']) : null;
} else {
    // JSON
    $input = getJsonInput();
    $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
    $rating = isset($input['rating']) ? intval($input['rating']) : 0;
    $comment = isset($input['comment']) ? trim($input['comment']) : null;
    $app_version = isset($input['app_version']) ? trim($input['app_version']) : null;
    $platform = isset($input['platform']) ? trim($input['platform']) : null;
    $device_info = isset($input['device_info']) ? trim($input['device_info']) : null;
}

if ($user_id <= 0) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['user_id' => 'User ID is required and must be a positive integer']);
}

if ($rating < 1 || $rating > 5) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['rating' => 'Rating must be between 1 and 5']);
}

// Sanitize inputs
$comment = $comment !== null && $comment !== '' ? sanitizeInput($comment) : null;
$app_version = $app_version !== null && $app_version !== '' ? sanitizeInput($app_version) : null;
$platform = $platform !== null && $platform !== '' ? sanitizeInput($platform) : null;
$device_info = $device_info !== null && $device_info !== '' ? sanitizeInput($device_info) : null;

// Validate platform nếu có
if ($platform !== null && !in_array(strtolower($platform), ['android', 'ios', 'web'])) {
    $platform = null;
}

// Kiểm tra user có tồn tại không
$stmt = $conn->prepare("
    SELECT user_id 
    FROM codego_users 
    WHERE user_id = ? AND is_active = 1
    LIMIT 1
");

if (!$stmt) {
    $error = $conn->error;
    error_log("Prepare failed: " . $error);
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Database error', ['error' => $error, 'type' => 'prepare_failed'], 500);
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'User not found', null, 404);
}

$stmt->close();

// Xử lý upload ảnh (nếu có)
$uploaded_images = [];
$max_images = 5;
$max_size = 5 * 1024 * 1024; // 5MB per image
$allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
$allowed_extensions = ['jpg', 'jpeg', 'png', 'gif'];

// Tạo thư mục uploads nếu chưa có
$upload_dir = __DIR__ . '/uploads/ratings/';
if (!file_exists($upload_dir)) {
    if (!mkdir($upload_dir, 0755, true)) {
        error_log("Failed to create upload directory: $upload_dir");
    }
}

// Xử lý upload nhiều ảnh
if (isset($_FILES['images']) && is_array($_FILES['images']['name'])) {
    $file_count = count($_FILES['images']['name']);
    
    // Giới hạn số lượng ảnh
    if ($file_count > $max_images) {
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        jsonResponse(false, "Maximum $max_images images allowed", null, 400);
    }
    
    for ($i = 0; $i < $file_count; $i++) {
        if ($_FILES['images']['error'][$i] === UPLOAD_ERR_OK) {
            $file = [
                'name' => $_FILES['images']['name'][$i],
                'type' => $_FILES['images']['type'][$i],
                'tmp_name' => $_FILES['images']['tmp_name'][$i],
                'size' => $_FILES['images']['size'][$i],
            ];
            
            // Validate file type
            $file_ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            if (!in_array($file['type'], $allowed_types) || !in_array($file_ext, $allowed_extensions)) {
                continue; // Skip invalid files
            }
            
            // Validate file size
            if ($file['size'] > $max_size) {
                continue; // Skip oversized files
            }
            
            // Generate unique filename
            $timestamp = time();
            $random = mt_rand(1000, 9999);
            $new_filename = 'rating_' . $user_id . '_' . $timestamp . '_' . $random . '.' . $file_ext;
            $upload_path = $upload_dir . $new_filename;
            
            // Upload file
            if (move_uploaded_file($file['tmp_name'], $upload_path)) {
                $image_url = 'https://codego.io.vn/api/uploads/ratings/' . $new_filename;
                $uploaded_images[] = $image_url;
            }
        }
    }
}

// Kiểm tra user đã đánh giá chưa (chỉ cho phép 1 đánh giá)
$stmt = $conn->prepare("
    SELECT rating_id 
    FROM app_ratings 
    WHERE user_id = ?
    LIMIT 1
");

if ($stmt) {
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        // Update existing rating
        $existing_rating = $result->fetch_assoc();
        $rating_id = $existing_rating['rating_id'];
        $stmt->close();
        
        // Xóa ảnh cũ nếu có
        $stmt_old = $conn->prepare("SELECT images FROM app_ratings WHERE rating_id = ? LIMIT 1");
        if ($stmt_old) {
            $stmt_old->bind_param("i", $rating_id);
            $stmt_old->execute();
            $result_old = $stmt_old->get_result();
            if ($result_old->num_rows > 0) {
                $old_data = $result_old->fetch_assoc();
                if (!empty($old_data['images'])) {
                    $old_images = json_decode($old_data['images'], true);
                    if (is_array($old_images)) {
                        foreach ($old_images as $old_url) {
                            $old_filename = basename(parse_url($old_url, PHP_URL_PATH));
                            $old_file_path = $upload_dir . $old_filename;
                            if (file_exists($old_file_path)) {
                                @unlink($old_file_path);
                            }
                        }
                    }
                }
            }
            $stmt_old->close();
        }
        
        // Update rating
        $updated_at = time();
        $images_json = !empty($uploaded_images) ? json_encode($uploaded_images) : null;
        
        $stmt = $conn->prepare("
            UPDATE app_ratings 
            SET rating = ?, 
                comment = ?, 
                app_version = ?, 
                platform = ?, 
                device_info = ?,
                images = ?,
                updated_at = ?
            WHERE rating_id = ? AND user_id = ?
        ");
        
        if (!$stmt) {
            $error = $conn->error;
            error_log("Prepare failed for update: " . $error);
            if (ob_get_level() > 0) {
                ob_end_clean();
            }
            jsonResponse(false, 'Database error', ['error' => $error], 500);
        }
        
        // bind_param: i (rating), s (comment), s (app_version), s (platform), s (device_info), s (images_json), i (updated_at), i (rating_id), i (user_id)
        // Tổng: 9 tham số -> "isssssiii"
        $stmt->bind_param("isssssiii", $rating, $comment, $app_version, $platform, $device_info, $images_json, $updated_at, $rating_id, $user_id);
        
        if (!$stmt->execute()) {
            $error = $stmt->error;
            error_log("Execute failed for update: " . $error);
            $stmt->close();
            if (ob_get_level() > 0) {
                ob_end_clean();
            }
            jsonResponse(false, 'Failed to update rating', ['error' => $error], 500);
        }
        
        $stmt->close();
        
        // Lấy rating đã cập nhật
        $stmt = $conn->prepare("
            SELECT rating_id, user_id, rating, comment, app_version, platform, device_info, images, created_at, updated_at
            FROM app_ratings 
            WHERE rating_id = ?
            LIMIT 1
        ");
        
        if ($stmt) {
            $stmt->bind_param("i", $rating_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $rating_data = $result->fetch_assoc();
            $stmt->close();
            
            if ($rating_data) {
                $rating_data['rating_id'] = intval($rating_data['rating_id']);
                $rating_data['user_id'] = intval($rating_data['user_id']);
                $rating_data['rating'] = intval($rating_data['rating']);
                $rating_data['created_at'] = intval($rating_data['created_at']);
                $rating_data['updated_at'] = intval($rating_data['updated_at']);
                // Parse images JSON
                if (!empty($rating_data['images'])) {
                    $rating_data['images'] = json_decode($rating_data['images'], true);
                } else {
                    $rating_data['images'] = [];
                }
            }
            
            if (ob_get_level() > 0) {
                ob_end_clean();
            }
            jsonResponse(true, 'Rating updated successfully', $rating_data, 200);
        }
    } else {
        $stmt->close();
    }
}

// Insert new rating
$created_at = time();
$updated_at = $created_at;
$is_visible = 1;
$images_json = !empty($uploaded_images) ? json_encode($uploaded_images) : null;

$stmt = $conn->prepare("
    INSERT INTO app_ratings (
        user_id, rating, comment, app_version, platform, device_info, images, is_visible, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
");

if (!$stmt) {
    $error = $conn->error;
    error_log("Prepare failed for insert: " . $error);
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Database error', ['error' => $error], 500);
}

$stmt->bind_param("iisssssiii", $user_id, $rating, $comment, $app_version, $platform, $device_info, $images_json, $is_visible, $created_at, $updated_at);

if (!$stmt->execute()) {
    $error = $stmt->error;
    error_log("Execute failed for insert: " . $error);
    $stmt->close();
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Failed to submit rating', ['error' => $error], 500);
}

$rating_id = $stmt->insert_id;
$stmt->close();

// Lấy rating vừa tạo
$stmt = $conn->prepare("
    SELECT rating_id, user_id, rating, comment, app_version, platform, device_info, images, created_at, updated_at
    FROM app_ratings 
    WHERE rating_id = ?
    LIMIT 1
");

if ($stmt) {
    $stmt->bind_param("i", $rating_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $rating_data = $result->fetch_assoc();
    $stmt->close();
    
    if ($rating_data) {
        $rating_data['rating_id'] = intval($rating_data['rating_id']);
        $rating_data['user_id'] = intval($rating_data['user_id']);
        $rating_data['rating'] = intval($rating_data['rating']);
        $rating_data['created_at'] = intval($rating_data['created_at']);
        $rating_data['updated_at'] = intval($rating_data['updated_at']);
        // Parse images JSON
        if (!empty($rating_data['images'])) {
            $rating_data['images'] = json_decode($rating_data['images'], true);
        } else {
            $rating_data['images'] = [];
        }
    }
    
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(true, 'Rating submitted successfully', $rating_data, 200);
} else {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(true, 'Rating submitted successfully', [
        'rating_id' => $rating_id,
        'user_id' => $user_id,
        'rating' => $rating,
        'comment' => $comment,
        'created_at' => $created_at
    ], 200);
}

?>
