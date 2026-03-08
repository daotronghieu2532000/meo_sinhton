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
-- Cấu trúc bảng cho bảng `tip_likes`
--

CREATE TABLE `tip_likes` (
  `id` int(11) NOT NULL,
  `tip_id` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `tip_likes`
--

INSERT INTO `tip_likes` (`id`, `tip_id`, `ip_address`, `created_at`) VALUES
(3, 5, '14.177.213.79', '2026-03-08 03:30:03'),
(5, 4, '14.177.213.79', '2026-03-08 03:30:06'),
(6, 3, '14.177.213.79', '2026-03-08 04:17:15');

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `tip_likes`
--
ALTER TABLE `tip_likes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_like` (`tip_id`,`ip_address`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `tip_likes`
--
ALTER TABLE `tip_likes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Ràng buộc đối với các bảng kết xuất
--

--
-- Ràng buộc cho bảng `tip_likes`
--
ALTER TABLE `tip_likes`
  ADD CONSTRAINT `tip_likes_ibfk_1` FOREIGN KEY (`tip_id`) REFERENCES `community_tips` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
