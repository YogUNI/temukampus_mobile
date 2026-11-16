@echo off
REM ============================================================
REM  Menjalankan emulator TemuKampus TANPA Android Studio.
REM  Pakai: klik dua kali, atau dari terminal:  tool\emulator.bat
REM ============================================================
setlocal enabledelayedexpansion

set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "AVD=temukampus_api35"
set "PATH=%SDK%\platform-tools;%SDK%\emulator;%PATH%"

if not exist "%SDK%\emulator\emulator.exe" (
  echo [X] Android SDK tidak ditemukan di "%SDK%".
  exit /b 1
)

REM --- Lock basi -------------------------------------------------
REM Kalau emulator sebelumnya mati tidak wajar, file lock tertinggal dan
REM emulator berikutnya gagal start ("The emulator process ... has terminated").
REM findstr dipanggil dengan path penuh: kalau PATH memuat git-bash, `find`
REM akan memakai find Unix dan baris ini gagal.
tasklist /FI "IMAGENAME eq qemu-system-x86_64.exe" 2>nul | "%SystemRoot%\System32\findstr.exe" /I "qemu-system" >nul
if errorlevel 1 (
  if exist "%USERPROFILE%\.android\avd\%AVD%.avd\multiinstance.lock" (
    del /q "%USERPROFILE%\.android\avd\%AVD%.avd\multiinstance.lock" 2>nul
    echo [i] Lock basi dihapus.
  )
)

echo [i] Menjalankan AVD %AVD% ...
start "Emulator TemuKampus" "%SDK%\emulator\emulator.exe" -avd %AVD% -no-snapshot -no-boot-anim -gpu swiftshader_indirect -no-audio -memory 4096 -cores 4

echo [i] Menunggu Android selesai boot (biasanya 30-70 detik)...
set /a TRIES=0

:wait_boot
set "BOOT="
for /f "usebackq delims=" %%i in (`adb shell getprop sys.boot_completed 2^>nul`) do set "BOOT=%%i"
if "%BOOT%"=="1" goto ready
set /a TRIES+=1
if %TRIES% GEQ 60 goto failed
REM `ping` dipakai sebagai jeda karena `timeout` butuh konsol interaktif
ping -n 4 127.0.0.1 >nul
goto wait_boot

:failed
echo [X] Belum selesai boot setelah ~3 menit.
echo     Cek jendela "Emulator TemuKampus". Kalau ada error, tutup semuanya lalu:
echo       taskkill /F /IM qemu-system-x86_64.exe
echo       del "%USERPROFILE%\.android\avd\%AVD%.avd\multiinstance.lock"
endlocal
exit /b 1

:ready
echo.
echo [OK] Emulator siap:
adb devices
echo.
echo Langkah berikutnya:
echo   1^) Backend : cd C:\laragon\www\temukampus ^&^& php artisan serve --host=0.0.0.0 --port=8000
echo   2^) App     : cd C:\Users\%USERNAME%\temukampus_mobile ^&^& flutter run -d emulator-5554
echo.
endlocal
exit /b 0
