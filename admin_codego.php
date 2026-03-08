<?php
session_start();
error_reporting(E_ALL);
ini_set('display_errors', 0);

// Mã băm của mật khẩu "1974" (Tạo bằng password_hash('1974', PASSWORD_DEFAULT))
$hashed_password = '$2y$10$CeOn7Kk2aLpU6UXwee9D2eVzVAHc3fIDp0BgtFe0HQ4gmRYkn0NYW'; 

$action = isset($_GET['action']) ? $_GET['action'] : 'home';

// Danh sách các trang yêu cầu đăng nhập
$protected_actions = ['manage_tips', 'app_codego', 'manage_ratings', 'manage_reports', 'manage_users'];

if (in_array($action, $protected_actions) && !isset($_SESSION['admin_logged_in'])) {
    $redirect_action = $action;
    $action = 'login';
}

// Đăng nhập
if ($action == 'login' && $_SERVER['REQUEST_METHOD'] == 'POST') {
    $password = $_POST['password'] ?? '';
    $redirect = $_POST['redirect'] ?? 'home';
    
    if (password_verify($password, $hashed_password)) {
        $_SESSION['admin_logged_in'] = true;
        header("Location: ?action=" . $redirect);
        exit;
    } else {
        $login_error = "Mật khẩu không chính xác.";
        $redirect_action = $redirect;
    }
}

// Đăng xuất
if ($action == 'logout') {
    unset($_SESSION['admin_logged_in']);
    header("Location: ?action=app_mxh");
    exit;
}

// Cập nhật trạng thái bài viết (Duyệt/Từ chối)
if ($action == 'change_status' && isset($_SESSION['admin_logged_in'])) {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    $status = isset($_GET['status']) ? (int)$_GET['status'] : 0;
    
    if ($id > 0) {
        $config_path = __DIR__ . '/api/includes/config.php';
        if (file_exists($config_path)) {
            require_once $config_path;
            if ($conn) {
                $stmt = $conn->prepare("UPDATE community_tips SET status = ? WHERE id = ?");
                $stmt->bind_param("ii", $status, $id);
                $stmt->execute();
            }
        }
    }
    header("Location: ?action=manage_tips");
    exit;
}

// Xóa bài viết
if ($action == 'delete_tip' && isset($_SESSION['admin_logged_in'])) {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id > 0) {
        $config_path = __DIR__ . '/api/includes/config.php';
        if (file_exists($config_path)) {
            require_once $config_path;
            if ($conn) {
                $stmt = $conn->prepare("DELETE FROM community_tips WHERE id = ?");
                $stmt->bind_param("i", $id);
                $stmt->execute();
            }
        }
    }
    header("Location: ?action=manage_tips");
    exit;
}

// Lưu/Cập nhật bài viết
if ($action == 'save_tip' && isset($_SESSION['admin_logged_in']) && $_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    $title = $_POST['title'] ?? '';
    $content = $_POST['content'] ?? '';
    $author_name = $_POST['author_name'] ?? 'Admin';
    $category = $_POST['category'] ?? 'tip';
    $status = isset($_POST['status']) ? (int)$_POST['status'] : 1;
    
    // Xử lý Steps
    $steps_array = isset($_POST['steps']) ? $_POST['steps'] : [];
    
    // Lọc các bước rỗng để tránh rác DB
    $filtered_steps = array_filter($steps_array, function($value) {
        return trim($value) !== '';
    });
    // Re-index array
    $filtered_steps = array_values($filtered_steps);
    $steps_json = json_encode($filtered_steps, JSON_UNESCAPED_UNICODE);

    $config_path = __DIR__ . '/api/includes/config.php';
    if (file_exists($config_path)) {
        require_once $config_path;
        if ($conn) {
            
            // Xử lý Upload Ảnh
            $image_url_query = "";
            $image_param = null;
            $has_new_image = false;
            
            if (isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
                $target_dir = __DIR__ . "/api/uploads/community/";
                if (!file_exists($target_dir)) {
                    mkdir($target_dir, 0777, true);
                }
                $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
                $new_filename = uniqid() . '.' . $file_extension;
                $target_file = $target_dir . $new_filename;
                
                if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
                    $image_url = 'uploads/community/' . $new_filename; 
                    $has_new_image = true;
                }
            }

            if ($id > 0) {
                // Sửa
                if ($has_new_image) {
                    $stmt = $conn->prepare("UPDATE community_tips SET title=?, content=?, author_name=?, category=?, status=?, steps=?, image_url=? WHERE id=?");
                    $stmt->bind_param("ssssissi", $title, $content, $author_name, $category, $status, $steps_json, $image_url, $id);
                } else {
                    $stmt = $conn->prepare("UPDATE community_tips SET title=?, content=?, author_name=?, category=?, status=?, steps=? WHERE id=?");
                    $stmt->bind_param("ssssisi", $title, $content, $author_name, $category, $status, $steps_json, $id);
                }
                $stmt->execute();
            } else {
                // Thêm mới
                $ip = $_SERVER['REMOTE_ADDR'];
                $image_db = $has_new_image ? $image_url : null;
                $stmt = $conn->prepare("INSERT INTO community_tips (title, content, author_name, category, status, ip_address, steps, image_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                $stmt->bind_param("ssssisss", $title, $content, $author_name, $category, $status, $ip, $steps_json, $image_db);
                $stmt->execute();
            }
        }
    }
    header("Location: ?action=manage_tips");
    exit;
}

?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CodeGo - Quản Lý Hệ Sinh Thái Ứng Dụng</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        body { background-color: #f4f6f9; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .navbar { background: linear-gradient(135deg, #0d6efd, #0dcaf0); }
        .app-card {
            border: none;
            border-radius: 15px;
            transition: all 0.3s ease;
            cursor: pointer;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            background: white;
            overflow: hidden;
            display: block;
            text-decoration: none;
            color: inherit;
        }
        .app-card:hover { transform: translateY(-5px); box-shadow: 0 10px 20px rgba(0,0,0,0.1); }
        .app-icon { font-size: 3rem; margin: 20px 0; color: #0d6efd; }
        .status-badge { font-size: 0.8rem; padding: 5px 10px; border-radius: 20px; font-weight: 500; }
        .table-tips img { border-radius: 8px; max-width: 100px; }
        td { vertical-align: middle; }
    </style>
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-dark shadow-sm">
    <div class="container">
        <a class="navbar-brand fw-bold" href="?action=home"><i class="fa-solid fa-layer-group"></i> CodeGo Ecosystem</a>
        <?php if(isset($_SESSION['admin_logged_in'])): ?>
            <div class="d-flex">
                <a href="?action=logout" class="btn btn-outline-light btn-sm"><i class="fas fa-sign-out-alt"></i> Khóa cửa</a>
            </div>
        <?php endif; ?>
    </div>
</nav>

<div class="container py-5">
    <?php if ($action == 'home'): ?>
        <!-- DANH SÁCH APP -->
        <div class="mb-4">
            <h2 class="fw-bold mb-1">Các dự án hiện tại</h2>
            <p class="text-muted">Lựa chọn ứng dụng để truy cập chức năng quản trị tương ứng.</p>
        </div>
        
        <div class="row g-4">
            <!-- Code Go -->
            <div class="col-md-4 col-sm-6">
                <a class="app-card text-center p-4 border" href="?action=app_codego">
                    <i class="fa-solid fa-code app-icon text-primary"></i>
                    <h5 class="fw-bold">Code Go</h5>
                </a>
            </div>
            
            <!-- Text to Sounds -->
            <div class="col-md-4 col-sm-6">
                <a class="app-card text-center p-4 border" href="javascript:void(0)">
                    <i class="fa-solid fa-file-audio app-icon text-success"></i>
                    <h5 class="fw-bold">Text to Sounds</h5>
                </a>
            </div>
            
            <!-- Bé vui học tập -->
            <div class="col-md-4 col-sm-6">
                <a class="app-card text-center p-4 border" href="javascript:void(0)">
                    <i class="fa-solid fa-graduation-cap app-icon text-warning"></i>
                    <h5 class="fw-bold">Bé vui học tập</h5>
                </a>
            </div>
            
            <!-- Chăm sóc thú cưng -->
            <div class="col-md-4 col-sm-6">
                <a class="app-card text-center p-4 border" href="javascript:void(0)">
                    <i class="fa-solid fa-cat app-icon text-danger"></i>
                    <h5 class="fw-bold">Chăm sóc thú cưng</h5>
                </a>
            </div>

            <!-- MXH: Share Tips and Tricks -->
            <div class="col-md-4 col-sm-6">
                <a class="app-card text-center p-4 border shadow-sm" href="?action=app_mxh">
                    <i class="fa-solid fa-fire app-icon text-info"></i>
                    <h5 class="fw-bold">MXH : Share Tips and Tricks</h5>
                    <span class="badge bg-primary mt-2">Đang phát triển năng động</span>
                </a>
            </div>
        </div>
        
    <?php elseif ($action == 'app_codego'): ?>
        <!-- QUẢN LÝ APP CODE GO -->
        <nav aria-label="breadcrumb">
          <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="?action=home">Home</a></li>
            <li class="breadcrumb-item active">Code Go</li>
          </ol>
        </nav>
        
        <h3 class="mb-4"><i class="fa-solid fa-code text-primary"></i>  Code Go Dashboard</h3>
        <div class="row g-4">
            <!-- Xem đánh giá -->
            <div class="col-md-4">
                <div class="card shadow-sm border-0 rounded-4 h-100">
                    <div class="card-body p-4 text-center">
                        <i class="fa-solid fa-star text-warning fa-3x mb-3"></i>
                        <h5 class="fw-bold">Xem đánh giá</h5>
                        <p class="text-muted small">Quản lý nhận xét và đánh giá app (app_ratings)</p>
                        <a href="?action=manage_ratings" class="btn btn-primary rounded-pill w-100 mt-2">Quản lý</a>
                    </div>
                </div>
            </div>
            <!-- Báo lỗi -->
            <div class="col-md-4">
                <div class="card shadow-sm border-0 rounded-4 h-100">
                    <div class="card-body p-4 text-center">
                        <i class="fa-solid fa-bug text-danger fa-3x mb-3"></i>
                        <h5 class="fw-bold">Báo lỗi</h5>
                        <p class="text-muted small">Kiểm tra lỗi, góp ý từ người dùng (app_reports)</p>
                        <a href="?action=manage_reports" class="btn btn-primary rounded-pill w-100 mt-2">Quản lý</a>
                    </div>
                </div>
            </div>
            <!-- User -->
            <div class="col-md-4">
                <div class="card shadow-sm border-0 rounded-4 h-100">
                    <div class="card-body p-4 text-center">
                        <i class="fa-solid fa-users text-success fa-3x mb-3"></i>
                        <h5 class="fw-bold">Người dùng</h5>
                        <p class="text-muted small">Quản lý tài khoản và thông tin (codego_users)</p>
                        <a href="?action=manage_users" class="btn btn-primary rounded-pill w-100 mt-2">Quản lý</a>
                    </div>
                </div>
            </div>
        </div>

    <?php elseif ($action == 'app_mxh'): ?>
        <!-- QUẢN LÝ APP MXH -->
        <nav aria-label="breadcrumb">
          <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="?action=home">Home</a></li>
            <li class="breadcrumb-item active">MXH : Share Tips and Tricks</li>
          </ol>
        </nav>
        
        <h3 class="mb-4"><i class="fa-solid fa-fire text-info"></i>  MXH : Share Tips and Tricks</h3>
        <div class="row">
            <div class="col-md-6">
                <div class="card shadow-sm border-0 rounded-4">
                    <div class="card-body p-4 d-flex align-items-center justify-content-between">
                        <div>
                            <h5 class="fw-bold mb-1">Duyệt Tips and Tricks</h5>
                            <p class="text-muted mb-0">Quản lý các bài viết của cộng đồng (yêu cầu mật khẩu).</p>
                        </div>
                        <a href="?action=manage_tips" class="btn btn-primary rounded-pill px-4 shadow-sm">
                            Truy cập <i class="fa-solid fa-arrow-right ms-2"></i>
                        </a>
                    </div>
                </div>
            </div>
        </div>

    <?php elseif ($action == 'login'): ?>
        <!-- ĐĂNG NHẬP -->
        <div class="row justify-content-center mt-5">
            <div class="col-md-5">
                <div class="card border-0 shadow-lg rounded-4 overflow-hidden">
                    <div class="card-header bg-primary text-white text-center py-4 border-0">
                        <i class="fa-solid fa-shield-halved fa-3x mb-3"></i>
                        <h4 class="mb-0">Khu vực bảo mật</h4>
                        <small>Vui lòng nhập mật khẩu cấp độ Admin</small>
                    </div>
                    <div class="card-body p-4">
                        <?php if (isset($login_error)): ?>
                            <div class="alert alert-danger" role="alert">
                                <i class="fa-solid fa-triangle-exclamation"></i> <?= $login_error ?>
                            </div>
                        <?php endif; ?>
                        
                        <form method="POST" action="?action=login">
                            <input type="hidden" name="redirect" value="<?= isset($redirect_action) ? htmlspecialchars($redirect_action) : 'home' ?>">
                            <div class="mb-4">
                                <label class="form-label fw-bold">Mã xác thực</label>
                                <input type="password" name="password" class="form-control form-control-lg bg-light" placeholder="••••••••" required autofocus>
                            </div>
                            <button type="submit" class="btn btn-primary btn-lg w-100 rounded-pill mb-2 shadow">Mở khóa hệ thống</button>
                            <a href="?action=home" class="btn btn-light btn-lg w-100 rounded-pill">Quay lại</a>
                        </form>
                    </div>
                </div>
            </div>
        </div>

    <?php elseif ($action == 'manage_tips' && isset($_SESSION['admin_logged_in'])): ?>
        <!-- DANH SÁCH BÀI DUYỆT CỦA CỘNG ĐỒNG -->
        <nav aria-label="breadcrumb" class="d-flex justify-content-between align-items-center mb-4">
          <ol class="breadcrumb mb-0">
            <li class="breadcrumb-item"><a href="?action=home">Home</a></li>
            <li class="breadcrumb-item"><a href="?action=app_mxh">MXH : Share Tips and Tricks</a></li>
            <li class="breadcrumb-item active">Duyệt bài đăng</li>
          </ol>
        </nav>

        <div class="card border-0 shadow-sm rounded-4">
            <div class="card-header bg-white border-0 pt-4 pb-0 d-flex justify-content-between align-items-center">
                <h4 class="fw-bold mb-0 text-primary"><i class="fa-solid fa-list-check"></i> Quản lý bài đăng cộng đồng</h4>
                <a href="?action=form_tip" class="btn btn-primary btn-sm rounded-pill"><i class="fa-solid fa-plus"></i> Thêm bài viết mới</a>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover table-borderless table-tips align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>#</th>
                                <th>Thông tin bài</th>
                                <th>Người đăng</th>
                                <th>Ảnh đính kèm</th>
                                <th>Trạng thái</th>
                                <th>Thao tác</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $config_path = __DIR__ . '/api/includes/config.php';
                            if (file_exists($config_path)) {
                                require_once $config_path;
                                // Ưu tiên chưa duyệt (0) lên đầu, tiếp theo là Đã duyệt (1), cuối cùng là Từ chối (2)
                                $sql = "SELECT * FROM community_tips ORDER BY CASE WHEN status = 0 THEN 0 WHEN status = 1 THEN 1 ELSE 2 END, created_at DESC";
                                $result = $conn->query($sql);
                                
                                if ($result && $result->num_rows > 0) {
                                    while ($row = $result->fetch_assoc()) {
                                        // Gán nhãn cho Status hiện tại
                                        $stt_class = 'bg-secondary';
                                        $stt_text = 'Unknown';
                                        
                                        if ($row['status'] == 0) {
                                            $stt_class = 'bg-warning text-dark';
                                            $stt_text = 'Chờ duyệt';
                                        } elseif ($row['status'] == 1) {
                                            $stt_class = 'bg-success';
                                            $stt_text = 'Đã công khai';
                                        } elseif ($row['status'] == 2) {
                                            $stt_class = 'bg-danger';
                                            $stt_text = 'Bị từ chối';
                                        }

                                        // URL ảnh (nếu lưu trong public_html/api/uploads/...)
                                        $img_url = '';
                                        if (!empty($row['image_url'])) {
                                            // Xử lý vì file admin này nằm ngang hàng với thư mục api
                                            $img_path = str_replace('api/', '', $row['image_url']);
                                            $img_url = "api/" . $img_path; // Cập nhật gốc tĩnh API là thư mục con
                                        }

                                        echo '<tr>';
                                        echo '<td><span class="text-muted fw-bold">ID '.$row['id'].'</span></td>';
                                        echo '<td>
                                                <h6 class="fw-bold mb-1">'.htmlspecialchars($row['title']).'</h6>
                                                <p class="mb-0 text-muted" style="font-size: 0.85rem; max-width: 300px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">'.htmlspecialchars($row['content']).'</p>
                                                <span class="badge bg-light text-dark border mt-2">'.htmlspecialchars($row['category']).'</span>
                                              </td>';
                                        echo '<td>
                                                <strong>'.htmlspecialchars($row['author_name']).'</strong><br>
                                                <small class="text-muted"><i class="fa-solid fa-clock"></i> '.date('d/m/Y H:i', strtotime($row['created_at'])).'</small><br>
                                                <small class="text-muted"><i class="fa-solid fa-globe"></i> '.htmlspecialchars($row['ip_address']).'</small>
                                              </td>';
                                        echo '<td>';
                                        if ($img_url) {
                                            echo '<a href="'.$img_url.'" target="_blank"><img src="'.$img_url.'" alt="ảnh" class="img-thumbnail"></a>';
                                        } else {
                                            echo '<span class="text-muted fst-italic"><small>Không có ảnh</small></span>';
                                        }
                                        echo '</td>';
                                        echo '<td><span class="badge '.$stt_class.'">'.$stt_text.'</span></td>';
                                        
                                        // Các nút thao tác
                                        echo '<td><div class="d-flex flex-wrap gap-1">';
                                        if ($row['status'] != 1) {
                                            echo '<a href="?action=change_status&id='.$row['id'].'&status=1" class="btn btn-success btn-sm" title="Duyệt"><i class="fa-solid fa-check"></i></a>';
                                        }
                                        if ($row['status'] != 2) {
                                            echo '<a href="?action=change_status&id='.$row['id'].'&status=2" class="btn btn-warning btn-sm" title="Từ chối"><i class="fa-solid fa-ban"></i></a>';
                                        }
                                        echo '<a href="?action=form_tip&id='.$row['id'].'" class="btn btn-primary btn-sm" title="Sửa"><i class="fa-solid fa-pen-to-square"></i></a>';
                                        echo '<a href="?action=delete_tip&id='.$row['id'].'" class="btn btn-danger btn-sm" title="Xóa" onclick="return confirm(\'Bạn có chắc chắn muốn xóa bài viết này không?\');"><i class="fa-solid fa-trash"></i></a>';
                                        echo '</div></td>';
                                        
                                        echo '</tr>';
                                    }
                                } else {
                                    echo '<tr><td colspan="6" class="text-center py-4">Chưa có bài viết nào!</td></tr>';
                                }
                            } else {
                                echo '<tr><td colspan="6" class="text-center text-danger">Không thể kết nối CSDL (Sai đường dẫn đến thư mục API). Vui lòng đảm bảo đặt file này ngang hàng với thư mục api/</td></tr>';
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    <?php elseif ($action == 'form_tip' && isset($_SESSION['admin_logged_in'])): ?>
        <!-- FORM THÊM / SỬA BÀI VIẾT -->
        <?php
        $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        $tip = ['title' => '', 'content' => '', 'author_name' => '', 'category' => 'tip', 'status' => 1, 'image_url' => '', 'steps' => '[]'];
        
        if ($id > 0) {
            $config_path = __DIR__ . '/api/includes/config.php';
            if (file_exists($config_path)) {
                require_once $config_path;
                if ($conn) {
                    $stmt = $conn->prepare("SELECT * FROM community_tips WHERE id = ?");
                    $stmt->bind_param("i", $id);
                    $stmt->execute();
                    $result = $stmt->get_result();
                    if ($result->num_rows > 0) {
                        $tip = $result->fetch_assoc();
                    }
                }
            }
        }
        
        $steps_arr = [];
        if (!empty($tip['steps'])) {
            $parsed = json_decode($tip['steps'], true);
            if (is_array($parsed)) $steps_arr = $parsed;
        }
        ?>
        <nav aria-label="breadcrumb" class="mb-4">
          <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="?action=home">Home</a></li>
            <li class="breadcrumb-item"><a href="?action=manage_tips">Duyệt bài đăng</a></li>
            <li class="breadcrumb-item active"><?= $id > 0 ? 'Chỉnh sửa bài viết' : 'Thêm mới' ?></li>
          </ol>
        </nav>
        
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card border-0 shadow-sm rounded-4">
                    <div class="card-header bg-white border-0 pt-4 pb-0">
                        <h4 class="fw-bold mb-0 text-primary">
                            <i class="fa-solid <?= $id > 0 ? 'fa-pen-to-square' : 'fa-plus' ?>"></i> 
                            <?= $id > 0 ? 'Sửa bài viết (ID: '.$id.')' : 'Tạo bài viết mới' ?>
                        </h4>
                    </div>
                    <div class="card-body p-4">
                        <form method="POST" action="?action=save_tip" enctype="multipart/form-data">
                            <input type="hidden" name="id" value="<?= $id ?>">
                            
                            <div class="mb-3">
                                <label class="form-label fw-bold">Tiêu đề bài viết <span class="text-danger">*</span></label>
                                <input type="text" name="title" class="form-control bg-light" placeholder="Ví dụ: Cách tạo lửa bằng pin và giấy bạc" value="<?= htmlspecialchars($tip['title']) ?>" required>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label fw-bold">Mô tả ngắn tình huống <span class="text-danger">*</span></label>
                                <textarea name="content" class="form-control bg-light" rows="3" placeholder="Mở bài dẫn dắt tình huống..." required><?= htmlspecialchars($tip['content']) ?></textarea>
                            </div>
                            
                            <!-- BẮT ĐẦU KHU VỰC STEPS DYNAMIC -->
                            <div class="mb-4 p-3 bg-light border rounded">
                                <label class="form-label fw-bold mb-3"><i class="fa-solid fa-list-ol text-primary"></i> Các bước thực hiện</label>
                                <div id="steps-container">
                                    <?php if (count($steps_arr) > 0): ?>
                                        <?php foreach ($steps_arr as $index => $step_text): ?>
                                            <div class="step-item d-flex gap-2 mb-2">
                                                <input type="text" name="steps[]" class="form-control" placeholder="Bước <?= $index + 1 ?>" value="<?= htmlspecialchars($step_text) ?>">
                                                <button type="button" class="btn btn-outline-danger px-3 btn-remove-step"><i class="fa-solid fa-minus"></i></button>
                                            </div>
                                        <?php endforeach; ?>
                                    <?php else: ?>
                                        <div class="step-item d-flex gap-2 mb-2">
                                            <input type="text" name="steps[]" class="form-control" placeholder="Bước 1 (Có thể bỏ trống, hoặc xoá)">
                                            <button type="button" class="btn btn-outline-danger px-3 btn-remove-step"><i class="fa-solid fa-minus"></i></button>
                                        </div>
                                    <?php endif; ?>
                                </div>
                                <button type="button" id="btn-add-step" class="btn btn-sm btn-outline-primary mt-2"><i class="fa-solid fa-plus"></i> Thêm bước mới</button>
                            </div>
                            <!-- KẾT THÚC KHU VỰC STEPS DYNAMIC -->
                            
                            <div class="mb-4 p-3 bg-light border rounded">
                                <label class="form-label fw-bold"><i class="fa-solid fa-image text-success"></i> Ảnh minh họa</label>
                                <?php if (!empty($tip['image_url'])): ?>
                                    <div class="mb-2">
                                        <?php 
                                            $img_path = str_replace('api/', '', $tip['image_url']);
                                            $full_img_url = "api/" . $img_path;
                                        ?>
                                        <img src="<?= $full_img_url ?>" alt="Current Image" class="img-thumbnail" style="max-height: 150px;">
                                        <div class="text-muted small mt-1">Ảnh hiện tại đang sử dụng</div>
                                    </div>
                                <?php endif; ?>
                                <input class="form-control" type="file" name="image" accept="image/*">
                                <div class="form-text">Tải lên file ảnh mới nếu muốn thay đổi. Nếu để trống sẽ giữ nguyên ảnh cũ.</div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label class="form-label fw-bold">Tác giả</label>
                                    <input type="text" name="author_name" class="form-control bg-light" value="<?= htmlspecialchars($tip['author_name']) ?>" required>
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label class="form-label fw-bold">Danh mục phân loại</label>
                                    <select name="category" class="form-select bg-light">
                                        <option value="tip" <?= $tip['category'] == 'tip' ? 'selected' : '' ?>>Mẹo sinh tồn</option>
                                        <option value="experience" <?= $tip['category'] == 'experience' ? 'selected' : '' ?>>Kinh nghiệm</option>
                                        <option value="first_aid" <?= $tip['category'] == 'first_aid' ? 'selected' : '' ?>>Sơ cứu</option>
                                        <option value="feedback" <?= $tip['category'] == 'feedback' ? 'selected' : '' ?>>Góp ý App</option>
                                        <option value="other" <?= $tip['category'] == 'other' ? 'selected' : '' ?>>Khác</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mb-4">
                                <label class="form-label fw-bold">Trạng thái hiển thị DB</label>
                                <select name="status" class="form-select bg-light">
                                    <option value="0" <?= $tip['status'] == 0 ? 'selected' : '' ?>>Chờ duyệt (Màu vàng - Chờ review)</option>
                                    <option value="1" <?= $tip['status'] == 1 ? 'selected' : '' ?>>Công khai (Màu xanh - Hiển thị lên App)</option>
                                    <option value="2" <?= $tip['status'] == 2 ? 'selected' : '' ?>>Từ chối (Màu đỏ - Xóa ẩn)</option>
                                </select>
                            </div>
                            
                            <div class="d-flex justify-content-end gap-2 border-top pt-4">
                                <a href="?action=manage_tips" class="btn btn-light rounded-pill px-4">Hủy thao tác</a>
                                <button type="submit" class="btn btn-primary rounded-pill px-5 fw-bold shadow-sm">Lưu Bài Viết</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
        
        <script>
            // JS để xử lý thêm bớt input Text(Steps)
            document.addEventListener("DOMContentLoaded", function () {
                const container = document.getElementById("steps-container");
                const btnAdd = document.getElementById("btn-add-step");

                btnAdd.addEventListener("click", function () {
                    const stepCount = container.children.length + 1;
                    const div = document.createElement("div");
                    div.className = "step-item d-flex gap-2 mb-2";
                    div.innerHTML = `
                        <input type="text" name="steps[]" class="form-control" placeholder="Nhập thêm Bước ${stepCount}">
                        <button type="button" class="btn btn-outline-danger px-3 btn-remove-step"><i class="fa-solid fa-minus"></i></button>
                    `;
                    container.appendChild(div);
                });

                container.addEventListener("click", function (e) {
                    // Cho phép ấn vào icon hoặc btn đều xóa được
                    if (e.target.classList.contains("btn-remove-step") || e.target.closest(".btn-remove-step")) {
                        const item = e.target.closest(".step-item");
                        if(item) {
                            item.remove();
                        }
                    }
                });
            });
        </script>

    <?php elseif ($action == 'manage_ratings' && isset($_SESSION['admin_logged_in'])): ?>
        <!-- QUẢN LÝ ĐÁNH GIÁ (APP_RATINGS) -->
        <nav aria-label="breadcrumb" class="mb-4">
          <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="?action=home">Home</a></li>
            <li class="breadcrumb-item"><a href="?action=app_codego">Code Go</a></li>
            <li class="breadcrumb-item active">Đánh giá người dùng</li>
          </ol>
        </nav>
        <div class="card border-0 shadow-sm rounded-4">
            <div class="card-header bg-white border-0 pt-4 pb-0">
                <h4 class="fw-bold mb-0 text-warning"><i class="fa-solid fa-star"></i> Đánh giá người dùng</h4>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>#</th>
                                <th>Người dùng</th>
                                <th>Đánh giá</th>
                                <th>Comment</th>
                                <th>Phiên bản/Thiết bị</th>
                                <th>Thời gian</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $config_path = __DIR__ . '/api/includes/config.php';
                            if (file_exists($config_path)) {
                                require_once $config_path;
                                $sql = "SELECT r.*, u.username FROM app_ratings r LEFT JOIN codego_users u ON r.user_id = u.user_id ORDER BY r.created_at DESC";
                                $result = $conn->query($sql);
                                if ($result && $result->num_rows > 0) {
                                    while ($row = $result->fetch_assoc()) {
                                        echo '<tr>';
                                        echo '<td>'.$row['rating_id'].'</td>';
                                        echo '<td>'.htmlspecialchars($row['username'] ?? 'Khách').'</td>';
                                        echo '<td><b class="text-warning">'.$row['rating'].' ★</b></td>';
                                        echo '<td>'.htmlspecialchars($row['comment'] ?? '').'</td>';
                                        echo '<td><small>App: '.$row['app_version'].' <br/> OS: '.$row['platform'].'</small></td>';
                                        echo '<td><small>'.date('d/m/Y H:i', $row['created_at']).'</small></td>';
                                        echo '</tr>';
                                    }
                                } else {
                                    echo '<tr><td colspan="6" class="text-center py-4">Chưa có đánh giá nào.</td></tr>';
                                }
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    <?php elseif ($action == 'manage_reports' && isset($_SESSION['admin_logged_in'])): ?>
        <!-- QUẢN LÝ BÁO LỖI (APP_REPORTS) -->
        <nav aria-label="breadcrumb" class="mb-4">
          <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="?action=home">Home</a></li>
            <li class="breadcrumb-item"><a href="?action=app_codego">Code Go</a></li>
            <li class="breadcrumb-item active">Báo lỗi & Góp ý</li>
          </ol>
        </nav>
        <div class="card border-0 shadow-sm rounded-4">
            <div class="card-header bg-white border-0 pt-4 pb-0">
                <h4 class="fw-bold mb-0 text-danger"><i class="fa-solid fa-bug"></i> Báo cáo lỗi & Góp ý</h4>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Mã</th>
                                <th>Loại báo cáo</th>
                                <th>Người báo cáo</th>
                                <th>Mô tả chi tiết</th>
                                <th>Độ ưu tiên</th>
                                <th>Thời gian</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $config_path = __DIR__ . '/api/includes/config.php';
                            if (file_exists($config_path)) {
                                require_once $config_path;
                                $sql = "SELECT r.*, u.username FROM app_reports r LEFT JOIN codego_users u ON r.user_id = u.user_id ORDER BY r.created_at DESC";
                                $result = $conn->query($sql);
                                if ($result && $result->num_rows > 0) {
                                    while ($row = $result->fetch_assoc()) {
                                        $sev_color = $row['severity'] == 'critical' ? 'danger' : ($row['severity'] == 'high' ? 'warning' : 'secondary');
                                        echo '<tr>';
                                        echo '<td>'.$row['report_id'].'</td>';
                                        echo '<td><span class="badge bg-dark">'.$row['report_type'].'</span></td>';
                                        echo '<td>'.htmlspecialchars($row['username'] ?? 'Ẩn danh').'</td>';
                                        echo '<td><b>'.htmlspecialchars($row['title']).'</b><br><small class="text-muted">'.htmlspecialchars($row['description']).'</small></td>';
                                        echo '<td><span class="badge bg-'.$sev_color.'">'.$row['severity'].'</span></td>';
                                        echo '<td><small>'.date('d/m/Y H:i', $row['created_at']).'</small></td>';
                                        echo '</tr>';
                                    }
                                } else {
                                    echo '<tr><td colspan="6" class="text-center py-4">Chưa có báo cáo nào.</td></tr>';
                                }
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    <?php elseif ($action == 'manage_users' && isset($_SESSION['admin_logged_in'])): ?>
        <!-- QUẢN LÝ USER (CODEGO_USERS) -->
        <nav aria-label="breadcrumb" class="mb-4">
          <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="?action=home">Home</a></li>
            <li class="breadcrumb-item"><a href="?action=app_codego">Code Go</a></li>
            <li class="breadcrumb-item active">Quản lý người dùng</li>
          </ol>
        </nav>
        <div class="card border-0 shadow-sm rounded-4">
            <div class="card-header bg-white border-0 pt-4 pb-0">
                <h4 class="fw-bold mb-0 text-success"><i class="fa-solid fa-users"></i> Danh sách User</h4>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>ID</th>
                                <th>Tài khoản</th>
                                <th>Level & Điểm</th>
                                <th>Chuỗi học (Streaks)</th>
                                <th>Quốc gia</th>
                                <th>Ngày tham gia</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $config_path = __DIR__ . '/api/includes/config.php';
                            if (file_exists($config_path)) {
                                require_once $config_path;
                                $sql = "SELECT * FROM codego_users ORDER BY created_at DESC";
                                $result = $conn->query($sql);
                                if ($result && $result->num_rows > 0) {
                                    while ($row = $result->fetch_assoc()) {
                                        echo '<tr>';
                                        echo '<td>'.$row['user_id'].'</td>';
                                        echo '<td><b>'.htmlspecialchars($row['username']).'</b><br>'.htmlspecialchars($row['email'] ?? '').'</td>';
                                        echo '<td><b>Lv '.$row['level'].'</b> ('.$row['total_points'].' đ)</td>';
                                        echo '<td>🔥 Hiện tại: '.$row['current_streak'].' <br>🎖️ Tối đa: '.$row['longest_streak'].'</td>';
                                        echo '<td>'.$row['country'].'</td>';
                                        echo '<td><small>'.date('d/m/Y', $row['created_at']).'</small></td>';
                                        echo '</tr>';
                                    }
                                } else {
                                    echo '<tr><td colspan="6" class="text-center py-4">Chưa có user nào.</td></tr>';
                                }
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    <?php endif; ?>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
