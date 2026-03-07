<?php
/**
 * CODE GO API - TEST DATABASE CONNECTION
 * 
 * File này để test kết nối database và xem chi tiết lỗi
 * Truy cập: https://codego.io.vn/api/test_connection.php
 */

// Tắt tất cả output và error display
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Bắt đầu output buffering NGAY từ đầu
ob_start();

// Set header JSON
header('Content-Type: application/json; charset=utf-8');

// Thử include config.php để dùng cùng thông tin
try {
    require_once __DIR__ . '/includes/config.php';
    // Nếu config.php đã có $conn, dùng luôn
    if (isset($conn) && $conn instanceof mysqli && !$conn->connect_error) {
        // Database đã kết nối thành công từ config.php
        $results['config_connection'] = [
            'status' => 'SUCCESS',
            'message' => 'Database đã được kết nối thành công từ config.php',
            'host' => $db_host ?? 'unknown',
            'database' => $db_name ?? 'unknown'
        ];
    }
} catch (Exception $e) {
    // Nếu không include được, dùng thông tin trực tiếp
}

// Thông tin database từ config (hoặc fallback)
$db_host = $db_host ?? 'localhost';
$db_username = $db_username ?? 'codego_user';
$db_password = $db_password ?? 'Daotronghieu2000';
$db_name = $db_name ?? 'codego';

// Fallback credentials
$db_fallback_username = $db_fallback_username ?? 'codego';
$db_fallback_password = $db_fallback_password ?? 'Daotronghieu2000';
$db_fallback_name = $db_fallback_name ?? 'codego';

$results = [
    'note' => 'Get Token thành công nghĩa là database đang hoạt động! File này chỉ để kiểm tra chi tiết.'
];

// Test 1: Kết nối Primary
$results['test_1_primary'] = [
    'description' => 'Test kết nối với Primary credentials',
    'host' => $db_host,
    'username' => $db_username,
    'database' => $db_name,
    'password_set' => !empty($db_password) ? 'Yes' : 'No'
];

$conn1 = @new mysqli($db_host, $db_username, $db_password, $db_name);
if ($conn1->connect_error) {
    $results['test_1_primary']['status'] = 'FAILED';
    $results['test_1_primary']['error_code'] = $conn1->connect_errno;
    $results['test_1_primary']['error_message'] = $conn1->connect_error;
    
    // Phân tích lỗi
    $error_analysis = [];
    if ($conn1->connect_errno == 1045) {
        $error_analysis[] = 'Lỗi 1045: Access denied - Sai username hoặc password';
    } elseif ($conn1->connect_errno == 1049) {
        $error_analysis[] = 'Lỗi 1049: Unknown database - Database "' . $db_name . '" không tồn tại';
    } elseif ($conn1->connect_errno == 2002) {
        $error_analysis[] = 'Lỗi 2002: Cannot connect to MySQL server - Host "' . $db_host . '" không thể kết nối';
    } else {
        $error_analysis[] = 'Lỗi khác: ' . $conn1->connect_error;
    }
    $results['test_1_primary']['error_analysis'] = $error_analysis;
} else {
    $results['test_1_primary']['status'] = 'SUCCESS';
    $results['test_1_primary']['charset'] = $conn1->character_set_name();
    $conn1->close();
}

// Test 2: Kết nối Fallback
$results['test_2_fallback'] = [
    'description' => 'Test kết nối với Fallback credentials',
    'host' => $db_host,
    'username' => $db_fallback_username,
    'database' => $db_fallback_name,
    'password_set' => !empty($db_fallback_password) ? 'Yes' : 'No'
];

$conn2 = @new mysqli($db_host, $db_fallback_username, $db_fallback_password, $db_fallback_name);
if ($conn2->connect_error) {
    $results['test_2_fallback']['status'] = 'FAILED';
    $results['test_2_fallback']['error_code'] = $conn2->connect_errno;
    $results['test_2_fallback']['error_message'] = $conn2->connect_error;
    
    // Phân tích lỗi
    $error_analysis = [];
    if ($conn2->connect_errno == 1045) {
        $error_analysis[] = 'Lỗi 1045: Access denied - Sai username hoặc password';
    } elseif ($conn2->connect_errno == 1049) {
        $error_analysis[] = 'Lỗi 1049: Unknown database - Database "' . $db_fallback_name . '" không tồn tại';
    } elseif ($conn2->connect_errno == 2002) {
        $error_analysis[] = 'Lỗi 2002: Cannot connect to MySQL server - Host "' . $db_host . '" không thể kết nối';
    } else {
        $error_analysis[] = 'Lỗi khác: ' . $conn2->connect_error;
    }
    $results['test_2_fallback']['error_analysis'] = $error_analysis;
} else {
    $results['test_2_fallback']['status'] = 'SUCCESS';
    $results['test_2_fallback']['charset'] = $conn2->character_set_name();
    
    // Test query
    $test_query = $conn2->query("SELECT 1 as test");
    if ($test_query) {
        $results['test_2_fallback']['query_test'] = 'SUCCESS';
    } else {
        $results['test_2_fallback']['query_test'] = 'FAILED: ' . $conn2->error;
    }
    
    // Kiểm tra bảng app_api có tồn tại không
    $table_check = $conn2->query("SHOW TABLES LIKE 'app_api'");
    if ($table_check && $table_check->num_rows > 0) {
        $results['test_2_fallback']['app_api_table'] = 'EXISTS';
        
        // Đếm số lượng API keys
        $count_query = $conn2->query("SELECT COUNT(*) as count FROM app_api");
        if ($count_query) {
            $count_row = $count_query->fetch_assoc();
            $results['test_2_fallback']['api_keys_count'] = $count_row['count'];
        }
    } else {
        $results['test_2_fallback']['app_api_table'] = 'NOT EXISTS';
    }
    
    $conn2->close();
}

// Test 3: Kết nối không chọn database (để test username/password)
$results['test_3_no_database'] = [
    'description' => 'Test kết nối với Primary username/password (không chọn database)',
    'host' => $db_host,
    'username' => $db_username,
    'password_set' => !empty($db_password) ? 'Yes' : 'No'
];

$conn3 = @new mysqli($db_host, $db_username, $db_password);
if ($conn3->connect_error) {
    $results['test_3_no_database']['status'] = 'FAILED';
    $results['test_3_no_database']['error_code'] = $conn3->connect_errno;
    $results['test_3_no_database']['error_message'] = $conn3->connect_error;
} else {
    $results['test_3_no_database']['status'] = 'SUCCESS';
    $results['test_3_no_database']['message'] = 'Username và password đúng, nhưng có thể database không tồn tại';
    
    // Liệt kê databases
    $db_list = $conn3->query("SHOW DATABASES");
    $databases = [];
    if ($db_list) {
        while ($row = $db_list->fetch_assoc()) {
            $databases[] = $row['Database'];
        }
    }
    $results['test_3_no_database']['available_databases'] = $databases;
    $results['test_3_no_database']['target_database_exists'] = in_array($db_name, $databases) ? 'YES' : 'NO';
    
    $conn3->close();
}

// Tổng kết
$results['summary'] = [
    'primary_connection' => $results['test_1_primary']['status'] ?? 'UNKNOWN',
    'fallback_connection' => $results['test_2_fallback']['status'] ?? 'UNKNOWN',
    'username_password_valid' => $results['test_3_no_database']['status'] ?? 'UNKNOWN',
    'recommendation' => []
];

if ($results['test_1_primary']['status'] === 'FAILED' && $results['test_2_fallback']['status'] === 'FAILED') {
    if ($results['test_3_no_database']['status'] === 'SUCCESS') {
        $results['summary']['recommendation'][] = 'Username và password đúng, nhưng database "' . $db_name . '" không tồn tại';
        $results['summary']['recommendation'][] = 'Vui lòng tạo database hoặc sử dụng một trong các database có sẵn: ' . implode(', ', $databases ?? []);
    } else {
        $results['summary']['recommendation'][] = 'Username hoặc password không đúng';
        $results['summary']['recommendation'][] = 'Vui lòng kiểm tra lại thông tin đăng nhập trong file config.php';
    }
} elseif ($results['test_2_fallback']['status'] === 'SUCCESS') {
    $results['summary']['recommendation'][] = 'Kết nối thành công với Fallback credentials';
    $results['summary']['recommendation'][] = 'Có thể sử dụng Fallback credentials làm Primary';
}

// Xóa mọi output không mong muốn
ob_clean();

// Trả về JSON
echo json_encode($results, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

// Kết thúc output buffering
ob_end_flush();

?>
