@echo off
REM Flutter ????? - CMD ??
echo ?? Flutter ?????
echo.

set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
set PUB_HOSTED_URL=https://pub.flutter-io.cn
setx FLUTTER_STORAGE_BASE_URL "https://storage.flutter-io.cn"
setx PUB_HOSTED_URL "https://pub.flutter-io.cn"

echo 1?? ???????
echo.

echo 2?? ?? Flutter...
C:\src\flutter\bin\flutter.bat --no-version-check --version
echo.

echo 3?? ????...
C:\src\flutter\bin\flutter.bat --disable-analytics
echo.

echo 4?? Doctor ??...
C:\src\flutter\bin\flutter.bat doctor

echo.
echo ? ?????
echo ????? Android Studio??? cd ?????? flutter pub get
pause
