@echo off
echo Updating Flutter packages...
flutter pub get

echo.
echo Generating app icons from new icon...
dart run flutter_launcher_icons

echo.
echo Cleaning build cache...
flutter clean

echo.
echo Done! Please rebuild your app to see the new icon.
echo Run: flutter build apk (for Android) or flutter build ios (for iOS)
pause
