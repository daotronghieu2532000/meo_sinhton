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
-- Cấu trúc bảng cho bảng `codego_users`
--

CREATE TABLE `codego_users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `mobile` varchar(20) DEFAULT NULL,
  `total_points` int(11) DEFAULT 0,
  `current_streak` int(11) DEFAULT 0,
  `longest_streak` int(11) DEFAULT 0,
  `level` int(11) DEFAULT 1,
  `country` varchar(2) DEFAULT 'VN',
  `device_token` varchar(255) DEFAULT NULL,
  `platform` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` int(11) NOT NULL,
  `updated_at` int(11) NOT NULL,
  `last_login` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `codego_users`
--

INSERT INTO `codego_users` (`user_id`, `username`, `email`, `password`, `name`, `avatar`, `mobile`, `total_points`, `current_streak`, `longest_streak`, `level`, `country`, `device_token`, `platform`, `is_active`, `created_at`, `updated_at`, `last_login`) VALUES
(1, 'hieuhieu', 'trongh138@gmail.com', '$2y$10$/y56FcQiP13wm9cmN4x72.cI9mHJQSD4efMJO1WvgVjvEHxV5TtxC', 'Linh Yêu', 'https://codego.io.vn/api/uploads/avatars/user_1_1768450932.jpg', NULL, 1435, 1, 1, 5, 'VN', NULL, NULL, 1, 1768446104, 1772904576, 1772904576),
(2, 'Ethan Walker', 'ethan.walker.dev@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Ethan Walker', NULL, NULL, 5000, 30, 45, 10, 'US', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(3, 'Oliver Smith', 'oliver.smith.uk@mail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Oliver Smith', NULL, NULL, 4500, 25, 40, 9, 'GB', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(4, 'Haruto Tanaka', 'haruto.tnk.jp@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Haruto Tanaka', NULL, NULL, 3800, 20, 35, 8, 'JP', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(5, 'Min-jun Park', 'minjun.park.kr@mail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Min-jun Park', NULL, NULL, 3200, 18, 30, 7, 'KR', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(6, 'Lukas Müller', 'lukas.mueller.de@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Lukas Müller', NULL, NULL, 2800, 15, 28, 6, 'DE', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(7, 'Lucas Martin', 'lucas.martin.fr@mail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Lucas Martin', NULL, NULL, 2400, 12, 25, 6, 'FR', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(8, 'Arjun Patel', 'arjun.patel.in@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Arjun Patel', NULL, NULL, 2000, 10, 22, 5, 'IN', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(9, 'Gabriel Santos', 'gabriel.santos.br@mail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Gabriel Santos', NULL, NULL, 1800, 8, 20, 5, 'BR', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(10, 'Noah Thompson', 'noah.thompson.ca@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Noah Thompson', NULL, NULL, 1500, 7, 18, 4, 'CA', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(11, 'Jack Wilson', 'jack.wilson.au@mail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Jack Wilson', NULL, NULL, 1200, 5, 15, 4, 'AU', NULL, NULL, 1, 1768451230, 1768451467, NULL),
(24, 'quy', NULL, '$2y$10$XD3X8ZfpiDoKiaSjb71ELehG7lndqMqdNobAW8XSQK/bOEFEISGR2', NULL, NULL, NULL, 0, 0, 0, 1, 'VN', NULL, NULL, 1, 1768550827, 1768550827, NULL),
(25, 'tronghieu', NULL, '$2y$10$Hmg9m9IVIMjqUzsMeNydl.qnArhdWmuW8/sPs3FBSPfFLSMCmZto2', NULL, 'https://codego.io.vn/api/uploads/avatars/user_25_1768571142.jpg', NULL, 320, 2, 2, 1, 'VN', NULL, NULL, 1, 1768571121, 1768619882, NULL),
(26, 'ongtrumbdsvietnam', NULL, '$2y$10$Y1E5wQ2tTt4KU1OV.Ca9buMnqKnbtzGwa6UyY.u5Qw/ucQmKFlM3u', NULL, 'https://codego.io.vn/api/uploads/avatars/user_26_1768571401.jpg', NULL, 1370, 3, 3, 1, 'VN', NULL, NULL, 1, 1768571292, 1770219876, 1768571292),
(27, 'hieu123', NULL, '$2y$10$2V8mPWnIFbjDFWWuAmMRl.yUh9OzoITKg7dkVB/xQVUH5Zkc8oGtG', NULL, NULL, NULL, 0, 0, 0, 1, 'VN', NULL, NULL, 1, 1768672057, 1768672057, NULL);

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `codego_users`
--
ALTER TABLE `codego_users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `idx_total_points` (`total_points`),
  ADD KEY `idx_country` (`country`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `codego_users`
--
ALTER TABLE `codego_users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
