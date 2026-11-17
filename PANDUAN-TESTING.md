# Panduan Testing TemuKampus (dari nol setelah laptop dinyalakan)

Semua perintah di bawah dijalankan di **Command Prompt / PowerShell** (bukan di dalam app).
Urutannya penting: **database → website → backend aplikasi → HP → aplikasi**.

---

## Ringkasan: 3 hal yang harus hidup

| # | Yang harus hidup | Untuk apa | Cara menyalakan |
|---|---|---|---|
| 1 | MySQL + Apache (Laragon) | Website `http://temukampus.test` | Buka **Laragon → Start All** |
| 2 | Backend API port **8000** | Aplikasi HP mengambil data | `tool\serve.bat` (biarkan terbuka) |
| 3 | `adb reverse tcp:8000 tcp:8000` | HP bisa menghubungi laptop | otomatis oleh `tool\run_phone.bat` |

> **Penting:** nomor 2 dan 3 harus diulang **setiap kali laptop/HP di-restart atau kabel dicabut**.

---

## Langkah 1 — Nyalakan database & website

1. Buka **Laragon**.
2. Klik **Start All** (tombol paling kiri bawah).
3. Pastikan **Apache** dan **MySQL** berwarna hijau.
4. Uji di browser: buka `http://temukampus.test` → website harus tampil.

> Kalau halaman error "database connection", MySQL belum siap. Tunggu 20–30 detik lalu refresh.

---

## Langkah 2 — Nyalakan backend untuk aplikasi

Buka terminal di folder proyek aplikasi:

```
cd C:\Users\Axioo Pongo\temukampus_mobile
tool\serve.bat
```

Yang terjadi: server Laravel hidup di `http://0.0.0.0:8000`.

> **Jendela ini JANGAN ditutup** selama testing. Kalau ditutup, aplikasi akan bilang
> "Koneksi internet terputus".

---

## Langkah 3 — Cek semuanya sudah siap

Buka **terminal baru** (jangan tutup yang tadi), lalu:

```
cd C:\Users\Axioo Pongo\temukampus_mobile
tool\cek.bat
```

Yang harus muncul:

```
=== 1. MySQL (database) ===      [OK] mysqld jalan
=== 2. Apache (website) ===      [OK] httpd jalan
=== 3. Website ... ===            [OK] status 200
=== 4. Backend aplikasi ... ===   [OK] status 200
=== 5. HP terhubung ===           RRCW90530KJ   device
=== 6. Penerusan port ... ===     tcp:8000 tcp:8000
```

Kalau ada `[X]`, perbaiki dulu — lihat tabel masalah di bawah.

---

## Langkah 4 — Colok HP

1. Colok HP ke laptop dengan kabel USB.
2. Di HP: **Opsi Pengembang → USB debugging** harus aktif.
3. Kalau muncul dialog **"Allow USB debugging?"** → tekan **Allow** (centang "Always allow").
4. Cek: `adb devices` → harus `device` (bukan `unauthorized`).

> Kalau `unauthorized`: cabut-colok kabel, lalu terima dialognya lagi.
> Kalau dialog tidak muncul: `adb kill-server` lalu `adb devices`.

---

## Langkah 5 — Jalankan aplikasi di HP

```
cd C:\Users\Axioo Pongo\temukampus_mobile
tool\run_phone.bat
```

Skrip ini otomatis:
1. mendeteksi HP,
2. memasang `adb reverse tcp:8000 tcp:8000`,
3. menjalankan `flutter run` dengan alamat API yang benar.

Tunggu sampai muncul `Flutter run key commands` lalu aplikasi terbuka di HP.

---

## Alternatif: pakai emulator (tanpa HP)

```
cd C:\Users\Axioo Pongo\temukampus_mobile
tool\emulator.bat
```

Tunggu emulator selesai boot (muncul layar Android), lalu di terminal lain:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

> Emulator memakai `10.0.2.2` (alamat khusus untuk menghubungi laptop).
> HP fisik memakai `127.0.0.1` + `adb reverse`.

---

## Kalau ada masalah

| Gejala | Penyebab | Solusi |
|---|---|---|
| App: **"Koneksi internet terputus"** | `adb reverse` hilang (HP dicabut / adb restart) | `adb reverse tcp:8000 tcp:8000` lalu ulangi aksi |
| App: koneksi terputus, tapi reverse ada | Backend `:8000` mati | Jalankan `tool\serve.bat` lagi |
| `adb devices` kosong | Kabel/driver/USB debugging | Cek kabel, aktifkan USB debugging, terima dialog Allow |
| `adb devices` = `unauthorized` | Dialog izin belum diterima | `adb kill-server` → `adb devices` → terima dialog |
| Website 500 / database error | MySQL mati | Laragon → Start All, tunggu 30 detik |
| Website 404 semua halaman | Apache mati | Laragon → Start All |
| `Port 8000 sudah dipakai` | Server lama masih jalan | Pakai yang sudah jalan, atau tutup jendela lamanya |
| Gambar/poster tidak muncul | URL media salah host | Sudah ditangani otomatis oleh app; kalau masih, restart app |
| Aplikasi putih kosong setelah install | Build lama | `flutter clean` lalu `tool\run_phone.bat` |

---

## Akun uji

| Peran | Login | Sandi |
|---|---|---|
| Mahasiswa | NIM `41521000001` | `password` |
| Panitia (BEM FASILKOM) | NIM `41224000001` | `password` |
| Superadmin (web saja) | `superadmin@temukampus.test` | lihat `.env` (`SEED_SUPERADMIN_PASSWORD`) |

Untuk melihat **Panel Panitia** di aplikasi: login sebagai `41224000001` →
tab **Profil** → banner **MODE PANITIA AKTIF**.

---

## Perintah lain yang berguna

```bash
# Cek kode aplikasi (harus "No issues found!")
flutter analyze

# Jalankan semua tes aplikasi (harus semua hijau)
flutter test

# Build APK saja (tanpa menjalankan)
flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1

# Pasang APK yang sudah dibangun ke HP
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb reverse tcp:8000 tcp:8000
```

Untuk backend (website):

```bash
cd C:\laragon\www\temukampus
C:\laragon\bin\php\php-8.5.12-Win32-vs17-x64\php.exe artisan test
```

---

## Urutan singkat untuk dihafal

```
1. Laragon  → Start All
2. tool\serve.bat          (biarkan terbuka)
3. tool\cek.bat            (semua harus OK)
4. colok HP + Allow USB debugging
5. tool\run_phone.bat
```

Selesai. Kalau besok laptop dimatikan lagi, ulangi 5 langkah ini dari atas.
