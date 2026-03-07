# Script to update app icon
Write-Host "Updating app icon..." -ForegroundColor Green

# Remove old icons
Write-Host "Removing old icons..." -ForegroundColor Yellow
Remove-Item "android\app\src\main\res\mipmap-*\ic_launcher.png" -Force -ErrorAction SilentlyContinue
Remove-Item "android\app\src\main\res\drawable\ic_launcher_foreground.png" -Force -ErrorAction SilentlyContinue
Remove-Item "android\app\src\main\res\drawable\ic_launcher_background.png" -Force -ErrorAction SilentlyContinue

# Update Flutter packages
Write-Host "Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

# Generate new icons
Write-Host "Generating new app icons..." -ForegroundColor Yellow
dart run flutter_launcher_icons

# Clean build
Write-Host "Cleaning build cache..." -ForegroundColor Yellow
flutter clean

Write-Host "Icon update complete!" -ForegroundColor Green
Write-Host "Please rebuild your app to see the new icon." -ForegroundColor Cyan
Write-Host "Run: flutter build apk (for Android) or flutter build ios (for iOS)" -ForegroundColor Cyan
