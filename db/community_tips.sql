-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Máy chủ: localhost:3306
-- Thời gian đã tạo: Th3 15, 2026 lúc 02:08 PM
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
(4, NULL, 'Ngã xuống nước siết', 'cô tình trượt ngã xuống sông chảy siết', 'experience', 'HÙng Cường', '2026-03-07 11:56:58', 1, 9, '14.177.213.79', '[\"bình tĩnh\",\"thay vì bơi ngược \",\"hãy bơi ngang theo dòng nước\"]', 'uploads/community/69ad2111cf439.jpg', 'VN'),
(8, NULL, 'cách để buộc dây giày con bướm', 'bạn đã chán những kiểu buộc giày nhàm chán', 'tip', 'Anh tên là Bằng', '2026-03-08 06:29:51', 1, 1, '14.177.213.79', '[\"mở youtube \",\"xem và làm theo\",\"chúc bạn thành công \"]', 'uploads/community/69ad2273644be.jpg', 'VN'),
(9, NULL, 'làm sao để học giỏi', 'bạn học quá kém , suốt ngày điểm kém ', 'tip', 'Anh bán xôi', '2026-03-08 06:30:05', 1, 1, '14.177.213.79', '[\"chơi ít thôi \",\"tránh xa điện thoại , làm bạn với sách vở \",\"chúc bạn thành công \"]', 'uploads/community/69ad20ba5c1fb.png', 'VN'),
(11, NULL, 'hì hì', 'hí hí', 'experience', 'Hiếu', '2026-03-15 06:11:19', 0, 0, '14.177.213.79', '[\"học\",\"hochicj\",\"học\"]', 'uploads/community/69b64d86c8efe.jpg', 'VN');

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
