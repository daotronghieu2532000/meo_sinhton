<?php
/**
 * CODE GO API - REPORT APP
 * API endpoint: /api/report_app.php
 * Method: POST
 * 
 * Mô tả: Báo cáo vấn đề/lỗi/đề xuất tính năng cho app
 * 
 * Headers:
 * - Authorization: Bearer {access_token} (từ get_token.php) - Optional (cho phép anonymous)
 * - Content-Type: multipart/form-data
 * 
 * Request Body (Form Data):
 * - user_id: int (optional, có thể null nếu anonymous)
 * - report_type: string (required: bug, feature, content, other)
 * - title: string (required)
 * - description: string (required)
 * - severity: string (optional: low, medium, high, critical)
 * - app_version: string (optional)
 * - platform: string (optional: android, ios, web)
 * - device_info: string (optional)
 * - images[]: file[] (optional, multiple image files, max 5 images, max 5MB each)
 * 
 * Response Success:
 * {
 *   "success": true,
 *   "message": "Report submitted successfully",
 *   "data": {
 *     "report_id": 1,
 *     "user_id": 1,
 *     "report_type": "bug",
 *     "title": "App bị crash khi mở bài tập",
 *     "status": "pending",
 *     "created_at": 1640000000
 *   }
 * }
 * 
 * Response Error:
 * {
 *   "success": false,
 *   "message": "Title is required"
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

// Kiểm tra Authorization header (optional - cho phép anonymous reports)
$user_id = null;
$headers = getallheaders();
$auth_header = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (!empty($auth_header) && preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
    $token = $matches[1];
    $token_data = verifyJWT($token, 'codego_secret_key_2025');
    
    if ($token_data && isset($token_data['user_id'])) {
        $user_id = intval($token_data['user_id']);
    }
}

// Lấy input từ request (hỗ trợ cả JSON và Form Data)
$report_type = '';
$title = '';
$description = '';
$severity = 'medium';
$app_version = null;
$platform = null;
$device_info = null;
$screenshot_url = null;

// Kiểm tra xem là multipart/form-data hay JSON
$content_type = $_SERVER['CONTENT_TYPE'] ?? '';
if (strpos($content_type, 'multipart/form-data') !== false) {
    // Form Data
    if ($user_id === null && isset($_POST['user_id'])) {
        $user_id = intval($_POST['user_id']);
        if ($user_id <= 0) {
            $user_id = null;
        }
    }
    $report_type = isset($_POST['report_type']) ? trim($_POST['report_type']) : '';
    $title = isset($_POST['title']) ? trim($_POST['title']) : '';
    $description = isset($_POST['description']) ? trim($_POST['description']) : '';
    $severity = isset($_POST['severity']) ? trim($_POST['severity']) : 'medium';
    $app_version = isset($_POST['app_version']) ? trim($_POST['app_version']) : null;
    $platform = isset($_POST['platform']) ? trim($_POST['platform']) : null;
    $device_info = isset($_POST['device_info']) ? trim($_POST['device_info']) : null;
    $screenshot_url = isset($_POST['screenshot_url']) ? trim($_POST['screenshot_url']) : null;
} else {
    // JSON
    $input = getJsonInput();
    if ($user_id === null && isset($input['user_id'])) {
        $user_id = intval($input['user_id']);
        if ($user_id <= 0) {
            $user_id = null;
        }
    }
    $report_type = isset($input['report_type']) ? trim($input['report_type']) : '';
    $title = isset($input['title']) ? trim($input['title']) : '';
    $description = isset($input['description']) ? trim($input['description']) : '';
    $severity = isset($input['severity']) ? trim($input['severity']) : 'medium';
    $app_version = isset($input['app_version']) ? trim($input['app_version']) : null;
    $platform = isset($input['platform']) ? trim($input['platform']) : null;
    $device_info = isset($input['device_info']) ? trim($input['device_info']) : null;
    $screenshot_url = isset($input['screenshot_url']) ? trim($input['screenshot_url']) : null;
}

if (empty($report_type)) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['report_type' => 'Report type is required']);
}

if (!in_array(strtolower($report_type), ['bug', 'feature', 'content', 'other'])) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['report_type' => 'Report type must be: bug, feature, content, or other']);
}

if (empty($title)) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['title' => 'Title is required']);
}

if (empty($description)) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    validationError(['description' => 'Description is required']);
}

// Sanitize inputs
$report_type = sanitizeInput($report_type);
$title = sanitizeInput($title);
$description = sanitizeInput($description);
$severity = sanitizeInput($severity);
$app_version = $app_version !== null && $app_version !== '' ? sanitizeInput($app_version) : null;
$platform = $platform !== null && $platform !== '' ? sanitizeInput($platform) : null;
$device_info = $device_info !== null && $device_info !== '' ? sanitizeInput($device_info) : null;
$screenshot_url = $screenshot_url !== null && $screenshot_url !== '' ? sanitizeInput($screenshot_url) : null;

// Validate severity
if (!in_array(strtolower($severity), ['low', 'medium', 'high', 'critical'])) {
    $severity = 'medium';
}

// Validate platform nếu có
if ($platform !== null && !in_array(strtolower($platform), ['android', 'ios', 'web'])) {
    $platform = null;
}

// Kiểm tra user có tồn tại không (nếu có user_id)
if ($user_id !== null && $user_id > 0) {
    $stmt = $conn->prepare("
        SELECT user_id 
        FROM codego_users 
        WHERE user_id = ? AND is_active = 1
        LIMIT 1
    ");
    
    if ($stmt) {
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            $stmt->close();
            // Nếu user không tồn tại, cho phép report như anonymous
            $user_id = null;
        } else {
            $stmt->close();
        }
    }
}

// Xử lý upload ảnh (nếu có)
$uploaded_images = [];
$max_images = 5;
$max_size = 5 * 1024 * 1024; // 5MB per image
$allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
$allowed_extensions = ['jpg', 'jpeg', 'png', 'gif'];

// Tạo thư mục uploads nếu chưa có
$upload_dir = __DIR__ . '/uploads/reports/';
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
            $report_prefix = $user_id !== null ? 'user_' . $user_id : 'anon';
            $new_filename = 'report_' . $report_prefix . '_' . $timestamp . '_' . $random . '.' . $file_ext;
            $upload_path = $upload_dir . $new_filename;
            
            // Upload file
            if (move_uploaded_file($file['tmp_name'], $upload_path)) {
                $image_url = 'https://codego.io.vn/api/uploads/reports/' . $new_filename;
                $uploaded_images[] = $image_url;
            }
        }
    }
}

// Insert new report
$created_at = time();
$updated_at = $created_at;
$status = 'pending';
$images_json = !empty($uploaded_images) ? json_encode($uploaded_images) : null;

$stmt = $conn->prepare("
    INSERT INTO app_reports (
        user_id, report_type, title, description, severity, 
        status, app_version, platform, device_info, screenshot_url, images,
        created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
");

if (!$stmt) {
    $error = $conn->error;
    error_log("Prepare failed for insert: " . $error);
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Database error', ['error' => $error], 500);
}

$stmt->bind_param("issssssssssii", 
    $user_id, $report_type, $title, $description, $severity, 
    $status, $app_version, $platform, $device_info, $screenshot_url, $images_json,
    $created_at, $updated_at
);

if (!$stmt->execute()) {
    $error = $stmt->error;
    error_log("Execute failed for insert: " . $error);
    $stmt->close();
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(false, 'Failed to submit report', ['error' => $error], 500);
}

$report_id = $stmt->insert_id;
$stmt->close();

// Lấy report vừa tạo
$stmt = $conn->prepare("
    SELECT report_id, user_id, report_type, title, description, severity, 
           status, app_version, platform, device_info, screenshot_url, images,
           created_at, updated_at
    FROM app_reports 
    WHERE report_id = ?
    LIMIT 1
");

if ($stmt) {
    $stmt->bind_param("i", $report_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $report_data = $result->fetch_assoc();
    $stmt->close();
    
    if ($report_data) {
        $report_data['report_id'] = intval($report_data['report_id']);
        $report_data['user_id'] = $report_data['user_id'] !== null ? intval($report_data['user_id']) : null;
        $report_data['created_at'] = intval($report_data['created_at']);
        $report_data['updated_at'] = intval($report_data['updated_at']);
        // Parse images JSON
        if (!empty($report_data['images'])) {
            $report_data['images'] = json_decode($report_data['images'], true);
        } else {
            $report_data['images'] = [];
        }
    }
    
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(true, 'Report submitted successfully', $report_data, 200);
} else {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    jsonResponse(true, 'Report submitted successfully', [
        'report_id' => $report_id,
        'user_id' => $user_id,
        'report_type' => $report_type,
        'title' => $title,
        'status' => $status,
        'created_at' => $created_at
    ], 200);
}

?>
