# TemuKampus Mobile — Product Requirements Document (PRD)

| Metadata | Detail |
|---|---|
| Versi | 1.0 (Mobile Companion Release) |
| Platform | Android & iOS (Flutter 3.x / Dart 3.x) |
| Backend Core | Laravel 13 REST API (`temukampus`) via Laravel Sanctum |
| Target Pengguna | Mahasiswa Universitas Mercu Buana (UMB), Peserta Eksternal, Panitia Ormawa |
| Dokumen Terkait | `AGENTS.md`, `02-MOBILE-ARCHITECTURE.md`, `03-API-CONTRACT.md`, `04-MOBILE-DESIGN-SYSTEM.md` |

---

## 1. Latar Belakang & Visi Produk

### 1.1 Mengapa Mobile App?
Di lingkungan Universitas Mercu Buana, sebagian besar mahasiswa mengakses info kegiatan kemahasiswaan (seminar, lomba, workshop, pameran) melalui ponsel saat membuka tautan di grup WhatsApp atau Instagram.
Meskipun web TemuKampus sudah *mobile-first*, aplikasi native memberikan keunggulan kritis:
1. **Tiket Offline & QR Code Cepat:** Tiket dan QR code tersimpan di cache lokal, mahasiswa tidak perlu panik kehabisan sinyal internet saat mengantre di meja registrasi kampus.
2. **Kamera Terintegrasi:** Langsung jepret bukti transfer bank/QRIS tanpa repot membuka galeri bolak-balik.
3. **Pemindai Tiket Panitia (Mobile QR Scanner):** Panitia ormawa di hari-H cukup menggunakan kamera HP untuk memindai tiket peserta; validasi kehadiran tercatat instan dalam hitungan milidetik.
4. **Push Notification (v1.5):** Notifikasi instan saat bukti transfer disetujui panitia atau saat ada pengumuman mendesak.

### 1.2 Persona Pengguna Mobile
1. **Raka (Mahasiswa UMB, Peserta Utama):** Butuh cari acara sesuai jurusannya (Teknik Informatika), daftar dalam 1 menit, upload bukti bayar, dan menyimpan tiket QR di HP.
2. **Dina (Peserta Eksternal):** Mahasiswa kampus lain / masyarakat umum yang mendaftar acara publik tanpa membutuhkan NIM UMB.
3. **Kak Bima (Panitia / Admin Ormawa):** Bertugas di meja registrasi hari-H acara, menggunakan fitur kamera scanner untuk melakukan check-in peserta dengan cepat dan akurat.

---

## 2. Fitur & Katalog Layar (Screen Catalog)

```
┌────────────────────────────────────────────────────────┐
│                   TEMUKAMPUS MOBILE                    │
├──────────────────────────┬─────────────────────────────┤
│   Modul Mahasiswa        │   Modul Panitia (Admin)     │
├──────────────────────────┼─────────────────────────────┤
│ 1. Splash & Onboarding   │ 7. Scanner Check-In Hari-H │
│ 2. Autentikasi (NIM/Org) │    - Live Camera QR Scan    │
│ 3. Beranda & Jelajah     │    - Suara/Vibrasi Sukses   │
│ 4. Detail Acara & Syarat │    - Fallback Pencarian NIM │
│ 5. Pendaftaran & Bukti   │    - Counter Kehadiran      │
│ 6. Tiket Saya & QR Code  │                             │
│ 8. Profil & Ganti Sandi  │                             │
└──────────────────────────┴─────────────────────────────┘
```

---

### 2.1 Modul 1: Splash, Onboarding & Autentikasi

#### SCR-01: Splash Screen
- Logo TemuKampus dengan animasi halus (Tiket + Pin Lokasi).
- Pemeriksaan token otentikasi di `FlutterSecureStorage`:
  - Jika token valid -> Validasi profil -> Arahkan ke Beranda (`/home`).
  - Jika token kosong/kedaluwarsa -> Arahkan ke Onboarding / Login (`/login`).

#### SCR-02: Onboarding (Pertama Kali Buka)
- 3 slide carousel interaktif:
  1. *Temukan Acara Kampus:* Semua event ormawa UMB terpusat dalam satu genggaman.
  2. *Daftar Cepat Sekali Isi:* Data profil otomatis terhubung, bebas isi form berulang kali.
  3. *Tiket Digital Anti Ribet:* Simpan tiket ber-QR code dan tunjukkan saat hari-H.
- Tombol: "Mulai Sekarang" -> `/login`.

#### SCR-03: Masuk (Login)
- Input: Email / NIM dan Kata Sandi.
- Checkbox: "Ingat Saya".
- Link: "Lupa kata sandi?" -> SCR-05.
- Validasi instan: Format email/NIM wajib diisi.
- Error handling: Jika akun disuspend (`suspended`), tampilkan dialog peringatan berisi alasan dari admin kampus.

#### SCR-04: Pendaftaran Akun (Register)
- Toggle jenis akun: **Mahasiswa UMB** atau **Peserta Umum / Eksternal**.
- **Untuk Mahasiswa UMB:**
  - Input: Nama Lengkap, Email (disarankan email kampus/pribadi aktif), Nomor WhatsApp (08xx), NIM (11 Digit), Password & Konfirmasi.
  - **Live NIM Preview Widget:** Begitu pengguna mengetik 11 digit angka:
    - Digit 1–3 (`415`) -> Muncul badge otomatis *"Program Studi: Teknik Informatika"*.
    - Digit 4–5 (`24`) -> Muncul badge otomatis *"Angkatan: 2024"*.
  - Validasi ketat: Jika digit NIM tidak 11 karakter angka, tombol registrasi dinonaktifkan.
- **Untuk Peserta Eksternal:**
  - Input: Nama Lengkap, Email, Nomor WhatsApp, Nama Institusi / Universitas asal.

#### SCR-05: Lupa & Reset Kata Sandi
- Input email terdaftar -> Kirim tautan/kode reset ke email.
- Layar input token 6-digit & buat kata sandi baru.

#### SCR-06: Verifikasi Email (OTP / Kode 6 Angka)
- Sesuai fitur terbaru web (V2.4): Layar verifikasi kode 6 angka yang dikirimkan ke email pendaftar.
- Timer hitung mundur kirim ulang kode (60 detik).

---

### 2.2 Modul 2: Beranda & Eksplorasi Acara

#### SCR-07: Beranda (Home Dashboard)
- **Top Bar:** Greeting nama mahasiswa (*"Halo, Raka!"*), badge prodi (*"Teknik Informatika '24"*), dan ikon notifikasi/profil.
- **Search Header (Tiket Notch Style):** Kolom pencarian cepat dengan aksen tiket khas TemuKampus.
- **Filter Chips Cepat (Horizontal Scroll):**
  - `Semua`, `Gratis`, `Seminar`, `Ber-SKP`, `Workshop`, `Pelatihan`, `Cocok untuk Saya`.
- **Hero / Event Unggulan:** Carousel banner acara terbesar pekan ini dengan poster vertikal dan hard-shadow ("stiker" style).
- **Section "Segera Berlangsung":** List acara terdekat berdasarkan tanggal.
- **Section "Cocok Untuk Jurusanmu":** Khusus mahasiswa UMB, menampilkan acara yang fakultas/prodinya cocok dengan data NIM user.

#### SCR-08: Halaman Pencarian & Filter Mendalam (Explore)
- Filter dialog bottom sheet:
  - Kategori (Akademik, Seni & Budaya, Olahraga, Keorganisasian, Teknologi).
  - Format (Offline / Tatap Muka, Online / Daring, Hybrid).
  - Biaya (Semua, Gratis Saja, Berbayar Saja).
  - Poin SKP (Hanya yang ber-SKP).
  - Organisasi Penyelenggara (BEM, HIMA, UKM, dll).
- State: Shimmer loading, list kartu acara, empty state *"Acara tidak ditemukan. Coba ubah kata kunci atau filtermu."*

---

### 2.3 Modul 3: Detail Acara & Validasi Syarat

#### SCR-09: Detail Acara
- **Header:** Poster resolusi tinggi dengan tombol kembali dan tombol bagikan (Share link acara ke WhatsApp/Instagram).
- **Informasi Inti:**
  - Penyelenggara: Logo & nama Ormawa (dapat diklik menuju profil organisasi).
  - Judul Acara, Jadwal (Hari, Tanggal, Jam WIB), Lokasi (Ruang / Gedung Kampus Meruya/Menteng atau Link Daring).
  - Badges: `Gratis` / `Rp 25.000`, `SKP 2 Poin`, `Sertifikat`, `Khusus UMB`.
- **Informasi Kuota (Progress Bar):**
  - Menampilkan sisa kuota dengan warna sinyal oranye saat kuota menipis (`Sisa 5 tiket!`).
- **Deskripsi Lengkap:** Render Markdown aman (tata tertib, pembicara, fasilitas).
- **Bottom Action Bar (11 CTA States):**
  Mengikuti aturan ketat Web PRD §7.4.1:
  1. *Event dibatalkan* -> Banner merah "Acara ini telah dibatalkan".
  2. *Event sudah berakhir* -> Tombol abu-abu "Pendaftaran ditutup (acara selesai)".
  3. *Belum login* -> Tombol Cobalt "Masuk untuk Mendaftar".
  4. *Email belum terverifikasi* -> Tombol Amber "Verifikasi Email Terlebih Dahulu".
  5. *Profil belum lengkap* -> Tombol Amber "Lengkapi Profil (No. WhatsApp)".
  6. *Sudah punya tiket aktif* -> Tombol Hijau Mint "Lihat Tiket Saya".
  7. *Tidak Eligible (Syarat Tidak Cocok)* -> Tombol dinonaktifkan dengan pesan transparan: *"Acara ini khusus mahasiswa Fasilkom angkatan 2023–2024"*.
  8. *Pendaftaran belum dibuka* -> Tombol abu-abu "Dibuka pada [Tanggal]".
  9. *Pendaftaran ditutup* -> Tombol abu-abu "Pendaftaran ditutup".
  10. *Kuota penuh* -> Tombol merah muda "Kuota Penuh".
  11. *Eligible & Kuota Tersedia* -> Tombol Cobalt "Daftar Sekarang" (atau "Daftar & Bayar").

---

### 2.4 Modul 4: Formulir Pendaftaran & Alur Pembayaran Manual

#### SCR-10: Layar Pendaftaran & Instruksi Pembayaran
- **Data Pendaftar (Otomatis):**
  - Nama, NIM, Program Studi, Fakultas, No. WhatsApp (read-only dari profil akun).
- **Rincian Biaya (Untuk Event Berbayar):**
  - Harga Tiket: `Rp 25.000`
  - Kode Unik Transfer (3 Digit): `+ Rp 137`
  - **Total yang Wajib Ditransfer: `Rp 25.137`** (Ada tombol "Salin Nominal").
  - *Peringatan:* "Mohon transfer tepat sampai 3 digit terakhir agar verifikasi otomatis cepat."
- **Tujuan Pembayaran:**
  - Nomor Rekening Bank / E-Wallet + Nama Pemilik Rekening (Tombol "Salin Nomor Rekening").
  - Gambar QRIS (jika panitia mengunggah QRIS) -> Dapat di-tap untuk fullscreen atau disimpan ke galeri ponsel.
- **Unggah Bukti Transfer:**
  - Area unggah dengan kamera langsung atau ambil dari galeri.
  - Kompresi otomatis di sisi klien (maksimal 4 MB, format JPEG/PNG).
  - Preview thumbnail bukti bayar dengan tombol ganti foto.
- **Persetujuan Ketentuan:** Checkbox "Saya menyetujui data saya digunakan untuk keperluan kegiatan ini."
- **Tombol Kirim Pendaftaran:**
  - Menjalankan request multipart ke backend di dalam loading spinner yang elegan.
  - Mencegah double submit (tombol dinonaktifkan seketika setelah ditekan).

---

### 2.5 Modul 5: Tiket Saya & QR Code Peserta

#### SCR-11: Daftar Tiket Saya (`/my-tickets`)
- Tab Bar:
  - **Akan Datang** (Aktif)
  - **Menunggu Verifikasi** (`pending_verification` & `needs_revision`)
  - **Selesai** (Acara yang telah berlalu / sudah check-in)
  - **Dibatalkan** (`cancelled` / `rejected`)
- Tampilan Kartu Tiket: Desain notch setengah lingkaran di sisi kiri dan kanan dengan garis sobekan putus-putus.

#### SCR-12: Detail Tiket & QR Code (`/ticket/{code}`)
- **Header Status:** Stempel status resmi (Menunggu Verifikasi, Perlu Revisi, Terkonfirmasi, Ditolak).
- **QR Code Dinamis:**
  - Kode tiket unik: `TK-XXXXXX` (misal `TK-7F3KQ9`).
  - QR Code beresolusi tajam yang di-render lokal (`qr_flutter`).
  - Fitur screen brightness boost otomatis saat membuka layar tiket untuk mempermudah pemindaian.
- **Akses Khusus Peserta Terkonfirmasi (`confirmed`):**
  - Tombol **"Gabung Grup WhatsApp Peserta"** (Tautan grup WA terenkripsi yang baru terbuka saat tiket terkonfirmasi).
  - Tombol **"Buka Tautan Zoom / Google Meet"** (untuk acara online/hybrid).
  - Tombol **"Simpan ke Kalender HP"** (sinkronisasi ke Google Calendar / Apple Calendar).
- **Aksi Tiket Bersyarat:**
  - *Jika status `needs_revision`:* Tampil catatan alasan panitia (*"Bukti buram, mohon upload mutasi m-banking"*) + Tombol "Unggah Ulang Bukti Bayar".
  - *Jika status masih aktif dan acara belum mulai:* Tombol "Batalkan Tiket" dengan dialog konfirmasi.

---

### 2.6 Modul 6: Pemindai Tiket Panitia Hari-H (Mobile QR Scanner)

> **Catatan:** Fitur ini hanya muncul dan dapat diakses oleh user yang memiliki peran `admin` (panitia) pada organisasi penyelenggara acara.

#### SCR-13: Pemilih Acara Panitia (Event Gate Selector)
- Daftar acara aktif yang diselenggarakan oleh organisasi tempat panitia terdaftar.
- Memilih acara -> Membuka kamera scanner.

#### SCR-14: Kamera Scanner Kehadiran (Live QR Scanner)
- **Viewport Kamera:** Frame pemindai kotak dengan laser pemindai animasi.
- **Performa Instan:** Menggunakan package `mobile_scanner`.
- **Hasil Pemindaian Real-Time (Overlay Card):**
  - **SUKSES (Hijau Mint + Getar Haptic Pendek):**
    - Nama Peserta, NIM, Program Studi.
    - Jam Hadir tercatat otomatis.
    - Pesan: *"Check-in Berhasil! Silakan masuk."*
  - **PERINGATAN SUDAH CHECK-IN (Kuning Amber):**
    - *"Tiket ini sudah pernah dipindai pada 08:45 WIB oleh Panitia A."*
  - **GAGAL / INVALID (Merah Danger + Getar 2x):**
    - *"Tiket Tidak Terdaftar / Bukan untuk Acara Ini."*
- **Opsi Manual (Fallback Pencarian NIM):**
  - Jika kamera HP peserta pecah atau baterai habis, panitia bisa menekan tombol "Input Manual NIM / Nama" untuk menandai kehadiran peserta.
- **Counter Kehadiran:** Header menampilkan angka langsung: `Hadir: 142 / 200 Peserta`.

---

### 2.7 Modul 7: Profil Mahasiswa & Pengaturan

#### SCR-15: Profil Pengguna
- Foto Profil Avatar (Bisa ganti foto dengan kamera/galeri).
- Nama Lengkap & Email Terverifikasi.
- Nomor Induk Mahasiswa (NIM) & Program Studi (**Read-only**, tidak bisa diubah sembarangan sesuai BR-23).
- Nomor WhatsApp aktif (dapat diubah).
- Pengaturan: Ubah Kata Sandi, Syarat & Ketentuan, Kebijakan Privasi, Hubungi Bantuan.
- Tombol "Keluar" (Logout) dengan konfirmasi.

---

## 3. Matriks Paritas Fitur: Web vs Mobile

| Modul / Fitur | Web TemuKampus | Mobile Flutter | Keterangan Sinkronisasi |
|---|---|---|---|
| Katalog & Filter Acara | ✔ (Blade + Alpine/Livewire) | ✔ (Flutter Widget) | Data 100% identik dari API yang sama |
| Login & Registrasi NIM | ✔ (Fortify + Blade) | ✔ (Sanctum Token) | Validasi 11 digit NIM identik |
| Alur Pendaftaran Event | ✔ (Formulir Web) | ✔ (Mobile Form + Native Camera) | Menggunakan transaksi DB & locking yang sama di backend |
| Kode Unik 3 Digit | ✔ | ✔ | Nominal transfer sama persis |
| Unggah Bukti Bayar | ✔ (Dropzone) | ✔ (Native Image Picker) | File disimpan di private storage backend yang sama |
| Status Tiket & Logs | ✔ | ✔ | State machine 5 status sinkron |
| Akses Grup WA Terenkripsi | ✔ (Hanya `confirmed`) | ✔ (Hanya `confirmed`) | Dekripsi dilakukan aman oleh backend sebelum kirim JSON |
| Scanner Check-in Hari-H | v1.5 (Webcam) | **✔ Prioritas v1.0 (Kamera HP)** | Mobile jadi alat utama panitia di lapangan |
| Admin CRUD / Wizard Acara | ✔ (Panel Laptop) | – (v2) | Pembuatan acara tetap di web karena butuh input teks panjang |
| Ekspor PDF Daftar Hadir | ✔ (Dompdf di Web) | – | Dicetak oleh panitia via laptop |

---

## 4. Aturan Bisnis yang Wajib Dipatuhi (Business Rules Parity)
- **BR-01 (Format NIM):** 11 digit numerik murni.
- **BR-02 (Prodi dari NIM):** 3 digit awal menentukan prodi (misal `415` TI, `418` SI).
- **BR-03 (Angkatan dari NIM):** Digit 4–5 menentukan tahun angkatan (`20` + YY).
- **BR-04 (Eligibility Gate):** Evaluasi syarat `public`, `umb_only`, atau `restricted` (Fakultas, Prodi, Rentang Angkatan). Jika user tidak memenuhi syarat, tolak pendaftaran di sisi aplikasi dan server.
- **BR-09 (Kunci Kuota):** Server mengunci baris event (`lockForUpdate`) saat pendaftaran; aplikasi mobile harus siap menerima respon jika kuota habis di detik terakhir.
- **BR-13 (Privasi Tautan Grup WA & Meeting):** Tautan tidak boleh dikirimkan ke aplikasi mobile sebelum status pendaftaran mencapai `confirmed`.
- **BR-23 (Immutability NIM):** User tidak boleh bisa mengedit NIM-nya sendiri di aplikasi mobile.

