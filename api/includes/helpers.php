<?php
/**
 * CODE GO API - HELPER FUNCTIONS
 * Các hàm tiện ích dùng chung cho API
 */

// ============================================
// JWT TOKEN FUNCTIONS
// ============================================

/**
 * Tạo JWT token
 * @param array $payload Dữ liệu cần encode
 * @param string $secret Secret key để sign token
 * @param int $expiry Thời gian hết hạn (seconds)
 * @return string JWT token
 */
function generateJWT($payload, $secret = 'codego_secret_key_2025', $expiry = 86400) {
    $header = [
        'typ' => 'JWT',
        'alg' => 'HS256'
    ];
    
    $payload['iat'] = time();
    $payload['exp'] = time() + $expiry;
    
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(json_encode($header)));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(json_encode($payload)));
    
    $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secret, true);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
}

/**
 * Verify và decode JWT token
 * @param string $token JWT token
 * @param string $secret Secret key để verify
 * @return array|false Payload nếu hợp lệ, false nếu không hợp lệ
 */
function verifyJWT($token, $secret = 'codego_secret_key_2025') {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return false;
    }
    
    list($base64UrlHeader, $base64UrlPayload, $base64UrlSignature) = $parts;
    
    // Verify signature
    $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secret, true);
    $base64UrlSignatureCheck = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    if ($base64UrlSignature !== $base64UrlSignatureCheck) {
        return false;
    }
    
    // Decode payload
    $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $base64UrlPayload)), true);
    
    // Check expiry
    if (isset($payload['exp']) && $payload['exp'] < time()) {
        return false;
    }
    
    return $payload;
}

// ============================================
// VALIDATION FUNCTIONS
// ============================================

/**
 * Validate email
 * @param string $email
 * @return bool
 */
function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Validate username (chỉ cho phép chữ, số, dấu gạch dưới, độ dài 3-50)
 * @param string $username
 * @return bool
 */
function isValidUsername($username) {
    return preg_match('/^[a-zA-Z0-9_]{3,50}$/', $username) === 1;
}

/**
 * Validate password (tối thiểu 6 ký tự)
 * @param string $password
 * @return bool
 */
function isValidPassword($password) {
    return strlen($password) >= 6;
}

// ============================================
// RESPONSE FUNCTIONS
// ============================================

/**
 * Trả về JSON response
 * @param bool $success
 * @param string $message
 * @param mixed $data
 * @param int $httpCode
 */
function jsonResponse($success, $message, $data = null, $httpCode = 200) {
    // Clear any previous output
    if (ob_get_level() > 0) {
        ob_end_clean();
    }
    
    // Clear any headers that might have been sent
    if (!headers_sent()) {
        http_response_code($httpCode);
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-cache, must-revalidate');
    }
    
    $response = [
        'success' => $success,
        'message' => $message
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PARTIAL_OUTPUT_ON_ERROR);
    exit;
}

/**
 * Trả về lỗi validation
 * @param array $errors
 */
function validationError($errors) {
    jsonResponse(false, 'Validation failed', ['errors' => $errors], 400);
}

// ============================================
// SECURITY FUNCTIONS
// ============================================

/**
 * Hash password
 * @param string $password
 * @return string
 */
function hashPassword($password) {
    return password_hash($password, PASSWORD_BCRYPT);
}

/**
 * Verify password
 * @param string $password
 * @param string $hash
 * @return bool
 */
function verifyPassword($password, $hash) {
    return password_verify($password, $hash);
}

/**
 * Sanitize input
 * @param string $input
 * @return string
 */
function sanitizeInput($input) {
    return htmlspecialchars(strip_tags(trim($input)), ENT_QUOTES, 'UTF-8');
}

/**
 * Get client IP address
 * @return string
 */
function getClientIP() {
    $ipaddress = '';
    if (isset($_SERVER['HTTP_CLIENT_IP']))
        $ipaddress = $_SERVER['HTTP_CLIENT_IP'];
    else if(isset($_SERVER['HTTP_X_FORWARDED_FOR']))
        $ipaddress = $_SERVER['HTTP_X_FORWARDED_FOR'];
    else if(isset($_SERVER['HTTP_X_FORWARDED']))
        $ipaddress = $_SERVER['HTTP_X_FORWARDED'];
    else if(isset($_SERVER['HTTP_FORWARDED_FOR']))
        $ipaddress = $_SERVER['HTTP_FORWARDED_FOR'];
    else if(isset($_SERVER['HTTP_FORWARDED']))
        $ipaddress = $_SERVER['HTTP_FORWARDED'];
    else if(isset($_SERVER['REMOTE_ADDR']))
        $ipaddress = $_SERVER['REMOTE_ADDR'];
    else
        $ipaddress = 'UNKNOWN';
    return $ipaddress;
}

// ============================================
// REQUEST FUNCTIONS
// ============================================

/**
 * Get JSON input từ request body
 * @return array
 */
function getJsonInput() {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        jsonResponse(false, 'Invalid JSON format', null, 400);
    }
    
    return $data ?: [];
}

/**
 * Get request method
 * @return string
 */
function getRequestMethod() {
    return $_SERVER['REQUEST_METHOD'] ?? 'GET';
}

/**
 * Require specific HTTP method
 * @param string|array $methods
 */
function requireMethod($methods) {
    $method = getRequestMethod();
    $allowed = is_array($methods) ? $methods : [$methods];
    
    if (!in_array($method, $allowed)) {
        jsonResponse(false, 'Method not allowed', null, 405);
    }
}

?>
