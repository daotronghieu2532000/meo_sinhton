# meo_sinhton

Ứng dụng mobile offline chia sẻ mẹo sinh tồn và mẹo cuộc sống.

## AdMob đã tích hợp

- Banner đáy trang (cao 60px, full width): `ca-app-pub-6241798695005922/2859953548`
- Rewarded để tắt quảng cáo 1 giờ: `ca-app-pub-6241798695005922/3703784436`
- Mục xem rewarded nằm trong phần Cài đặt.

## Cấu hình AdMob App ID

Android dùng placeholder `ADMOB_APP_ID` trong:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `android/gradle.properties`

iOS dùng key `GADApplicationIdentifier` trong:

- `ios/Runner/Info.plist`

Lưu ý: hiện project đang để **test App ID** để có thể chạy ngay. Trước khi phát hành, thay bằng App ID thật của bạn trong AdMob.
