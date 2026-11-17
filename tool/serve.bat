@echo off
REM ============================================================
REM  Menyalakan backend TemuKampus untuk aplikasi (port 8000).
REM  Biarkan jendela ini TERBUKA selama testing.
REM  Pakai: tool\serve.bat
REM ============================================================
setlocal

set "PHP=C:\laragon\bin\php\php-8.5.12-Win32-vs17-x64\php.exe"
set "WEB=C:\laragon\www\temukampus"

if not exist "%PHP%" (
  echo [X] PHP tidak ditemukan di %PHP%
  echo     Cek folder C:\laragon\bin\php\ lalu sesuaikan path di file ini.
  pause
  exit /b 1
)

echo [i] Mengecek port 8000...
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }"
if errorlevel 1 (
  echo [i] Port 8000 sudah dipakai - backend sepertinya sudah jalan.
  echo     Kalau app tetap error, tutup jendela lain yang menjalankan serve lalu ulangi.
  pause
  exit /b 0
)

echo [i] Menyalakan backend di http://0.0.0.0:8000
echo     JANGAN tutup jendela ini. Tekan Ctrl+C untuk berhenti.
echo.
cd /d "%WEB%"
"%PHP%" artisan serve --host=0.0.0.0 --port=8000
