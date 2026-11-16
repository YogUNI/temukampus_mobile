@echo off
REM ============================================================
REM  Menjalankan app di HP fisik lewat USB.
REM  Wajib: HP tercolok + USB debugging aktif.
REM  Pakai: tool\run_phone.bat  [serial]
REM ============================================================
setlocal enabledelayedexpansion

set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "PATH=%SDK%\platform-tools;%PATH%"

set "SERIAL=%~1"

if "%SERIAL%"=="" (
  for /f "skip=1 tokens=1,2" %%a in ('adb devices') do (
    if "%%b"=="device" if "!SERIAL!"=="" set "SERIAL=%%a"
  )
)

if "%SERIAL%"=="" (
  echo [X] Tidak ada HP terdeteksi. Cek:
  echo     - kabel USB tersambung
  echo     - USB debugging aktif ^(Opsi Pengembang^)
  echo     - dialog "Allow USB debugging" sudah diterima
  adb devices
  exit /b 1
)

echo [i] HP: %SERIAL%

REM Port 8000 laptop diteruskan ke 127.0.0.1:8000 DI DALAM HP.
REM Tanpa ini app menampilkan "Koneksi internet terputus", karena HP tidak
REM bisa menjangkau IP laptop (firewall jaringan).
adb -s %SERIAL% reverse --remove-all >nul 2>&1
adb -s %SERIAL% reverse tcp:8000 tcp:8000
echo [i] Reverse aktif:
adb -s %SERIAL% reverse --list

echo.
echo [i] Menjalankan flutter run...
cd /d "%~dp0.."
flutter run -d %SERIAL% --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1

endlocal
