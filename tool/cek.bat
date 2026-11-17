@echo off
REM ============================================================
REM  Cek cepat semua yang dibutuhkan aplikasi TemuKampus.
REM  Pakai: tool\cek.bat
REM ============================================================
setlocal enabledelayedexpansion

set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "PATH=%SDK%\platform-tools;%PATH%"

echo === 1. MySQL (database) ===
tasklist | findstr /i mysqld >nul && echo    [OK] mysqld jalan || echo    [X]  mysqld MATI - buka Laragon lalu Start All

echo.
echo === 2. Apache (website) ===
tasklist | findstr /i httpd >nul && echo    [OK] httpd jalan || echo    [X]  httpd MATI - buka Laragon lalu Start All

echo.
echo === 3. Website http://temukampus.test ===
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 8 'http://temukampus.test/api/v1/categories'; Write-Host ('   [OK] status ' + $r.StatusCode) } catch { Write-Host '   [X]  tidak bisa diakses' }"

echo.
echo === 4. Backend aplikasi port 8000 ===
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 8 'http://127.0.0.1:8000/api/v1/categories'; Write-Host ('   [OK] status ' + $r.StatusCode) } catch { Write-Host '   [X]  MATI - jalankan tool\serve.bat lalu biarkan terbuka' }"

echo.
echo === 5. HP terhubung ===
adb devices

echo.
echo === 6. Penerusan port ke HP (adb reverse) ===
adb reverse --list
echo    (harus ada baris: tcp:8000 tcp:8000)

echo.
echo Selesai. Kalau ada [X], perbaiki dulu sebelum menjalankan tool\run_phone.bat
pause
