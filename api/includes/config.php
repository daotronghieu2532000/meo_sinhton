<?php
/**
 * CODE GO API - DATABASE CONFIGURATION
 * 
 * HƯỚNG DẪN:
 * 1. Copy file này thành config.php
 * 2. Điền thông tin database từ hosting của bạn
 * 3. Đảm bảo file config.php không được commit lên git (thêm vào .gitignore)
 */

// ============================================
// DATABASE CONFIGURATION
// ============================================

// Thông tin database từ hosting Interdata
$db_host = 'localhost'; // Thường là 'localhost' hoặc IP của MySQL server
$db_username = 'codego_user'; // Tên user database
$db_password = 'Daotronghieu2000'; // Mật khẩu database
$db_name = 'codego'; // Tên database (đã tạo từ setup_database.sql - tên mặc định: codego)

// ============================================
// FALLBACK DATABASE CONFIGURATION
// ============================================
// Fallback credentials nếu kết nối chính thất bại
$db_fallback_username = 'codego';
$db_fallback_password = 'Daotronghieu2000';
$db_fallback_name = 'codego';

// ============================================
// KẾT NỐI DATABASE
// ============================================

// Tạo kết nối MySQLi với fallback
// Khởi tạo $conn = null để tránh undefined variable
$conn = null;
$connection_log = [];

// Thử kết nối primary
$temp_conn = @new mysqli($db_host, $db_username, $db_password, $db_name);

// Kiểm tra kết nối, nếu thất bại thì thử fallback
if ($temp_conn->connect_error) {
    $connection_log[] = [
        'attempt' => 'Primary',
        'host' => $db_host,
        'username' => $db_username,
        'database' => $db_name,
        'error_code' => $temp_conn->connect_errno,
        'error_message' => $temp_conn->connect_error
    ];
    
    // Thử kết nối với fallback credentials
    $temp_conn = @new mysqli($db_host, $db_fallback_username, $db_fallback_password, $db_fallback_name);
    
    // Nếu vẫn thất bại
    if ($temp_conn->connect_error) {
        $connection_log[] = [
            'attempt' => 'Fallback',
            'host' => $db_host,
            'username' => $db_fallback_username,
            'database' => $db_fallback_name,
            'error_code' => $temp_conn->connect_errno,
            'error_message' => $temp_conn->connect_error
        ];
        
        // Log chi tiết
        error_log("Database connection failed - Primary: " . json_encode($connection_log[0]));
        error_log("Database connection failed - Fallback: " . json_encode($connection_log[1]));
        
        // Clear any output buffer
        if (ob_get_level() > 0) {
            ob_end_clean();
        }
        
        // Set headers
        if (!headers_sent()) {
            http_response_code(500);
            header('Content-Type: application/json; charset=utf-8');
        }
        
        // Trả về JSON và dừng script
        echo json_encode([
            'success' => false,
            'message' => 'Database connection error',
            'debug' => [
                'primary_connection' => [
                    'host' => $db_host,
                    'username' => $db_username,
                    'database' => $db_name,
                    'error_code' => $connection_log[0]['error_code'],
                    'error_message' => $connection_log[0]['error_message']
                ],
                'fallback_connection' => [
                    'host' => $db_host,
                    'username' => $db_fallback_username,
                    'database' => $db_fallback_name,
                    'error_code' => $connection_log[1]['error_code'],
                    'error_message' => $connection_log[1]['error_message']
                ],
                'common_issues' => [
                    'check_host' => 'Kiểm tra $db_host có đúng không (thường là "localhost")',
                    'check_username' => 'Kiểm tra username có đúng không',
                    'check_password' => 'Kiểm tra password có đúng không',
                    'check_database' => 'Kiểm tra database name có tồn tại không',
                    'check_user_permissions' => 'Kiểm tra user có quyền truy cập database không'
                ]
            ]
        ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    } else {
        // Fallback thành công
        $conn = $temp_conn;
        error_log("Database connection: Using fallback credentials successfully");
    }
} else {
    // Primary connection thành công
    $conn = $temp_conn;
    error_log("Database connection: Primary connection successful");
}

// Đảm bảo $conn đã được set
if ($conn === null) {
    // Clear any output buffer
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    
    // Set headers
    if (!headers_sent()) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
    }
    
    echo json_encode([
        'success' => false,
        'message' => 'Database connection not established',
        'debug' => 'Connection variable is null after initialization'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Thiết lập charset UTF-8
$conn->set_charset("utf8mb4");

// Thiết lập timezone (tùy chọn)
date_default_timezone_set('Asia/Ho_Chi_Minh');

// ============================================
// OPTIONAL: Tạo connection riêng cho Code Go (nếu cần)
// ============================================
// Nếu bạn muốn dùng connection riêng cho Code Go API
$codego_conn = $conn; // Hoặc tạo connection mới nếu cần

// ============================================
// SECURITY NOTES
// ============================================
// - KHÔNG commit file config.php lên git
// - Sử dụng mật khẩu mạnh cho database
// - Giới hạn quyền của database user (chỉ SELECT, INSERT, UPDATE, DELETE)
// - Thường xuyên backup database
// ============================================

?>
