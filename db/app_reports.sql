-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Máy chủ: localhost:3306
-- Thời gian đã tạo: Th3 08, 2026 lúc 01:51 PM
-- Phiên bản máy phục vụ: 10.6.19-MariaDB
-- Phiên bản PHP: 8.4.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `codego`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `app_reports`
--

CREATE TABLE `app_reports` (
  `report_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL COMMENT 'NULL nếu anonymous',
  `report_type` varchar(50) NOT NULL COMMENT 'bug, feature, content, other',
  `title` varchar(255) NOT NULL COMMENT 'Tiêu đề báo cáo',
  `description` text NOT NULL COMMENT 'Mô tả chi tiết',
  `severity` varchar(20) DEFAULT 'medium' COMMENT 'low, medium, high, critical',
  `status` varchar(20) DEFAULT 'pending' COMMENT 'pending, reviewing, resolved, rejected',
  `app_version` varchar(20) DEFAULT NULL COMMENT 'Phiên bản app',
  `platform` varchar(10) DEFAULT NULL COMMENT 'android, ios, web',
  `device_info` varchar(255) DEFAULT NULL COMMENT 'Thông tin thiết bị',
  `screenshot_url` varchar(500) DEFAULT NULL COMMENT 'URL ảnh screenshot (deprecated, dùng images thay thế)',
  `images` text DEFAULT NULL COMMENT 'JSON array chứa URLs của các ảnh đã upload',
  `admin_response` text DEFAULT NULL COMMENT 'Phản hồi từ admin',
  `created_at` int(11) NOT NULL,
  `updated_at` int(11) NOT NULL,
  `resolved_at` int(11) DEFAULT NULL COMMENT 'Thời gian giải quyết'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `app_reports`
--
ALTER TABLE `app_reports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_report_type` (`report_type`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_severity` (`severity`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `app_reports`
--
ALTER TABLE `app_reports`
  MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Ràng buộc đối với các bảng kết xuất
--

--
-- Ràng buộc cho bảng `app_reports`
--
ALTER TABLE `app_reports`
  ADD CONSTRAINT `fk_app_reports_user_id` FOREIGN KEY (`user_id`) REFERENCES `codego_users` (`user_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
