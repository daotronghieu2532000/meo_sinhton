-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Máy chủ: localhost:3306
-- Thời gian đã tạo: Th3 08, 2026 lúc 12:18 PM
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
-- Cấu trúc bảng cho bảng `community_tips`
--

CREATE TABLE `community_tips` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `author_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` tinyint(4) DEFAULT 0 COMMENT '0: pending, 1: approved, 2: rejected',
  `likes_count` int(11) DEFAULT 0,
  `ip_address` varchar(45) DEFAULT NULL,
  `steps` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`steps`)),
  `image_url` varchar(255) DEFAULT NULL,
  `country_code` varchar(5) DEFAULT 'VN'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `community_tips`
--

INSERT INTO `community_tips` (`id`, `user_id`, `title`, `content`, `category`, `author_name`, `created_at`, `status`, `likes_count`, `ip_address`, `steps`, `image_url`, `country_code`) VALUES
(1, NULL, 'lũ miền trung', 'jsjsbxnnx', 'first_aid', 'Hiếu', '2026-03-07 11:30:36', 0, 1, NULL, NULL, NULL, 'VN'),
(2, NULL, 'bhihj', 'bjsjw xhs', 'feedback', 'hiếu', '2026-03-07 11:43:44', 1, 11, '14.177.213.79', NULL, NULL, 'VN'),
(3, NULL, 'Dò rỉ gas', 'Nghi ngờ rò rỉ gas', 'first_aid', 'Huy Hoàng', '2026-03-07 11:53:57', 1, 5, '14.177.213.79', NULL, NULL, 'VN'),
(4, NULL, 'Ngã xuống nước siết', 'cô tình trượt ngã xuống sông chảy siết', 'experience', 'HÙng Cường', '2026-03-07 11:56:58', 1, 9, '14.177.213.79', '[\"bình tĩnh\",\"thay vì bơi ngược \",\"hãy bơi ngang theo dòng nước\"]', NULL, 'VN'),
(5, NULL, 'tìm nước sạch', 'Tìm nước sạch nơi hoang dã', 'experience', 'HLinh', '2026-03-07 14:45:27', 1, 21, '14.177.213.79', '[\"khi lạc trong rừng hãy bình tĩnh\",\"đi theo động vật hoang dã để tìm thấy nguồn nước\"]', 'api/uploads/community/69ac3a07a4830.jpg', 'VN');

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `community_tips`
--
ALTER TABLE `community_tips`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `community_tips`
--
ALTER TABLE `community_tips`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
