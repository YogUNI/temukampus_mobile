# Panduan Memulai Proyek TemuKampus Mobile (Flutter)

Dokumen ini adalah panduan praktis untuk Yoga (maintainer) dalam membuat dan mengonfigurasi proyek baru **TemuKampus Mobile**.

---

## 1. Perintah Membuat Proyek Flutter Baru

Buka PowerShell / Terminal di luar folder web (misalnya di folder dev kamu):
```powershell
# Contoh di C:\laragon\www atau di folder project kamu
cd C:\laragon\www
flutter create --org id.ac.mercubuana.temukampus --platforms android,ios temukampus_mobile
cd temukampus_mobile
```

---

## 2. Salin Paket Dokumentasi ini ke Proyek Baru

Salin seluruh file dari folder `docs/mobile/` di repo web ke root folder `temukampus_mobile/`:

```powershell
# Salin file AGENTS.md ke root folder proyek mobile
cp C:\laragon\www\temukampus\docs\mobile\AGENTS.md C:\laragon\www\temukampus_mobile\AGENTS.md

# Buat folder docs di proyek mobile dan salin semua dokumen
mkdir C:\laragon\www\temukampus_mobile\docs
cp C:\laragon\www\temukampus\docs\mobile\01-MOBILE-PRD.md C:\laragon\www\temukampus_mobile\docs\01-MOBILE-PRD.md
cp C:\laragon\www\temukampus\docs\mobile\02-MOBILE-ARCHITECTURE.md C:\laragon\www\temukampus_mobile\docs\02-MOBILE-ARCHITECTURE.md
cp C:\laragon\www\temukampus\docs\mobile\03-API-CONTRACT.md C:\laragon\www\temukampus_mobile\docs\03-API-CONTRACT.md
cp C:\laragon\www\temukampus\docs\mobile\04-MOBILE-DESIGN-SYSTEM.md C:\laragon\www\temukampus_mobile\docs\04-MOBILE-DESIGN-SYSTEM.md
```

---

## 3. Begitu Folder `temukampus_mobile` Dibuka di Antigravity

Saat kamu membuka folder `temukampus_mobile` di Antigravity, **Antigravity akan otomatis membaca file `AGENTS.md` dan folder `docs/`**.

Antigravity langsung mengetahui:
1. Konteks penuh TemuKampus (Mahasiswa UMB, NIM 11 digit, kode prodi `415` TI / `418` SI, pendaftaran berbayar manual + kode unik 3 digit).
2. Desain token visual lengkap (Cobalt Blue `#2447F5`, motif Tiket Notch, bayangan stiker, font Plus Jakarta Sans & Bricolage Grotesque).
3. Kontrak REST API dengan backend Laravel 13 (Sanctum bearer token, format multipart upload bukti bayar, scanner panitia).
4. Arsitektur folder Flutter Clean Architecture (Riverpod + Dio + GoRouter).

Semuanya langsung berada dalam **1 alur (1 jalur) dan 100% konsisten dengan versi web!**

