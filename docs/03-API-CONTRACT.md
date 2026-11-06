# TemuKampus — REST API Contract (Laravel 13 <-> Flutter)

Spesifikasi antarmuka API REST antara backend Laravel (`temukampus`) dan klien Flutter (`temukampus_mobile`).

- **Base URL Dev:** `http://<HOST>:8000/api/v1`
- **Content-Type:** `application/json` (Kecuali multipart upload bukti transfer)
- **Accept:** `application/json`
- **Authentication:** `Authorization: Bearer <SANCTUM_TOKEN>`

---

## 1. Format Standar Respon (Response Envelopes)

### 1.1 Respon Berhasil (HTTP 200, 201)
```json
{
  "success": true,
  "message": "Operasi berhasil diselesaikan.",
  "data": { ... },
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 68
  }
}
```

### 1.2 Respon Galat Validasi (HTTP 422 Unprocessable Entity)
```json
{
  "success": false,
  "message": "Data yang dikirimkan tidak valid.",
  "errors": {
    "nim": [
      "NIM harus terdiri dari 11 digit angka."
    ],
    "payment_proof": [
      "Bukti pembayaran wajib diunggah untuk acara berbayar."
    ]
  }
}
```

### 1.3 Respon Galat Terautentikasi & Otorisasi (HTTP 401, 403)
```json
{
  "success": false,
  "message": "Sesi tidak valid atau telah kedaluwarsa.",
  "error_code": "UNAUTHENTICATED"
}
```

---

## 2. Modul Autentikasi (`/auth`)

### 2.1 Pendaftaran Akun (Register)
`POST /auth/register`

#### Request Body (Mahasiswa UMB)
```json
{
  "account_type": "umb",
  "name": "Yoga Gustira",
  "email": "yoga@mercubuana.ac.id",
  "phone": "081234567890",
  "nim": "41524010001",
  "password": "Password123!",
  "password_confirmation": "Password123!"
}
```

#### Request Body (Peserta Umum / Eksternal)
```json
{
  "account_type": "external",
  "name": "Dina Pratiwi",
  "email": "dina@gmail.com",
  "phone": "089876543210",
  "institution_name": "Universitas Indonesia",
  "password": "Password123!",
  "password_confirmation": "Password123!"
}
```

#### Respon Sukses (HTTP 201 Created)
```json
{
  "success": true,
  "message": "Registrasi berhasil. Silakan periksa email untuk verifikasi.",
  "data": {
    "token": "1|sanctum_token_string_here",
    "user": {
      "id": 14,
      "name": "Yoga Gustira",
      "email": "yoga@mercubuana.ac.id",
      "role": "user",
      "account_type": "umb",
      "nim": "41524010001",
      "phone": "081234567890",
      "study_program": {
        "id": 1,
        "code": "415",
        "name": "Teknik Informatika"
      },
      "cohort_year": 2024,
      "email_verified": false
    }
  }
}
```

---

### 2.2 Masuk Akun (Login)
`POST /auth/login`

#### Request Body
```json
{
  "login": "41524010001", 
  "password": "Password123!",
  "device_name": "Xiaomi Redmi Note 12"
}
```
*(Catatan: Field `login` menerima format alamat email atau 11 digit NIM).*

#### Respon Sukses (HTTP 200 OK)
```json
{
  "success": true,
  "message": "Berhasil masuk.",
  "data": {
    "token": "2|sanctum_token_string_here",
    "user": {
      "id": 14,
      "name": "Yoga Gustira",
      "email": "yoga@mercubuana.ac.id",
      "role": "user",
      "account_type": "umb",
      "nim": "41524010001",
      "phone": "081234567890",
      "avatar_url": null,
      "study_program": {
        "code": "415",
        "name": "Teknik Informatika"
      },
      "cohort_year": 2024,
      "email_verified": true,
      "is_organizer": false,
      "managed_organizations": []
    }
  }
}
```

---

### 2.3 Profil Pengguna Aktif (Get Current User)
`GET /auth/me`
*Headers: `Authorization: Bearer <TOKEN>`*

#### Respon Sukses (HTTP 200 OK)
Mengembalikan objek pengguna terkini beserta status verifikasi profil dan role panitia.

---

### 2.4 Verifikasi Kode Email (OTP 6 Angka)
`POST /auth/verify-email-code`

#### Request Body
```json
{
  "code": "849201"
}
```

#### Respon Sukses (HTTP 200 OK)
```json
{
  "success": true,
  "message": "Email berhasil diverifikasi."
}
```

---

### 2.5 Keluar Akun (Logout)
`POST /auth/logout`
*Menghapus Personal Access Token aktif di database.*

---

## 3. Modul Katalog Acara (`/events`)

### 3.1 Ambil Daftar Acara (Katalog & Filter)
`GET /events`

#### Query Parameters:
- `search` (string): Kata kunci judul/penyelenggara.
- `category` (string): Slug kategori (e.g. `teknologi`, `seminar`).
- `tag` (string): `gratis`, `skp`, `minggu-ini`, `workshop`.
- `format` (string): `offline`, `online`, `hybrid`.
- `suitable_for_me` (bool): `1` untuk filter otomatis sesuai prodi & angkatan user yang sedang login.
- `page` (int): Halaman pagination (default: 1).

#### Respon Sukses (HTTP 200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": 3,
      "title": "Seminar Nasional: Masa Depan Artificial Intelligence di Indonesia",
      "slug": "seminar-nasional-ai-2026",
      "summary": "Membahas terobosan model fondasi AI terkini bersama pakar industri.",
      "poster_url": "http://temukampus.test/storage/posters/poster-ai.jpg",
      "format": "hybrid",
      "start_at": "2026-11-20T09:00:00+07:00",
      "end_at": "2026-11-20T12:30:00+07:00",
      "location": "Auditorium Tower UMB Meruya & Zoom Meeting",
      "is_paid": true,
      "price": 25000,
      "formatted_price": "Rp 25.000",
      "skp_points": 2,
      "has_certificate": true,
      "audience": "public",
      "quota": 200,
      "remaining_quota": 48,
      "is_full": false,
      "organization": {
        "id": 2,
        "name": "HIMA Teknik Informatika UMB",
        "slug": "hima-ti",
        "logo_url": "http://temukampus.test/storage/logos/hima-ti.png"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "total": 35
  }
}
```

---

### 3.2 Detail Acara Lengkap
`GET /events/{slug}`

#### Respon Sukses (HTTP 200 OK)
Menyertakan seluruh deskripsi (Markdown), syarat fakultas/prodi, info rekening/QRIS (jika berbayar), dan **CTA State Calculator** otomatis:
```json
{
  "success": true,
  "data": {
    "id": 3,
    "title": "Seminar Nasional: Masa Depan Artificial Intelligence di Indonesia",
    "slug": "seminar-nasional-ai-2026",
    "description": "## Latar Belakang\nEvent ini ditujukan untuk seluruh mahasiswa...",
    "poster_url": "http://temukampus.test/storage/posters/poster-ai.jpg",
    "format": "hybrid",
    "start_at": "2026-11-20T09:00:00+07:00",
    "end_at": "2026-11-20T12:30:00+07:00",
    "location": "Auditorium Gedung Tower Lt. 7 Kampus Meruya",
    "is_paid": true,
    "price": 25000,
    "bank_name": "Bank Central Asia (BCA)",
    "bank_account_number": "5410982311",
    "bank_account_name": "HIMA TEKNIK INFORMATIKA UMB",
    "qris_image_url": "http://temukampus.test/storage/qris/qris-hima.png",
    "skp_points": 2,
    "audience": "restricted",
    "restrictions": {
      "allowed_faculties": ["Fakultas Ilmu Komputer"],
      "allowed_programs": ["Teknik Informatika", "Sistem Informasi"],
      "cohort_min": 2022,
      "cohort_max": 2026
    },
    "quota": 200,
    "registered_count": 152,
    "remaining_quota": 48,
    "cta_state": {
      "status": "can_register", 
      "label": "Daftar & Bayar",
      "reason": null,
      "has_active_ticket": false,
      "active_ticket_code": null
    }
  }
}
```

---

## 4. Modul Pendaftaran & Pembayaran (`/registrations`)

### 4.1 Hitung Pratinjau Biaya & Kode Unik
`GET /events/{slug}/payment-preview`
*Headers: `Authorization: Bearer <TOKEN>`*

#### Respon Sukses (HTTP 200 OK)
```json
{
  "success": true,
  "data": {
    "ticket_price": 25000,
    "unique_code": 137,
    "total_amount_due": 25137,
    "formatted_total": "Rp 25.137",
    "bank_name": "BCA",
    "account_number": "5410982311",
    "account_name": "HIMA TEKNIK INFORMATIKA UMB",
    "qris_url": "http://temukampus.test/storage/qris/qris-hima.png"
  }
}
```

---

### 4.2 Kirim Pendaftaran (Submit Registration)
`POST /events/{slug}/register`
*Headers: `Authorization: Bearer <TOKEN>`, `Content-Type: multipart/form-data`*

#### Form-Data Parameters:
- `terms_accepted` (int): `1` (Wajib disetujui)
- `payment_proof` (file): Gambar bukti transfer (Wajib jika acara berbayar, max 4096 KB).

#### Respon Sukses (HTTP 201 Created)
```json
{
  "success": true,
  "message": "Pendaftaran berhasil dikirim. Panitia akan memverifikasi bukti pembayaran maksimal 1x24 jam.",
  "data": {
    "ticket_code": "TK-7F3KQ9",
    "status": "pending_verification",
    "status_label": "Menunggu Verifikasi",
    "amount_due": 25137,
    "registered_at": "2026-11-06T14:20:00+07:00"
  }
}
```

---

## 5. Modul Tiket Saya (`/tickets`)

### 5.1 Daftar Tiket Pengguna
`GET /tickets`
*Query Parameters:* `tab=upcoming|pending|completed|cancelled`

#### Respon Sukses (HTTP 200 OK)
```json
{
  "success": true,
  "data": [
    {
      "ticket_code": "TK-7F3KQ9",
      "status": "confirmed",
      "status_label": "Terkonfirmasi",
      "event": {
        "title": "Seminar Nasional AI 2026",
        "slug": "seminar-nasional-ai-2026",
        "poster_url": "http://temukampus.test/storage/posters/poster-ai.jpg",
        "start_at": "2026-11-20T09:00:00+07:00",
        "location": "Auditorium Tower UMB Meruya",
        "format": "hybrid"
      },
      "checked_in_at": null
    }
  ]
}
```

---

### 5.2 Detail Tiket & Kunci Akses
`GET /tickets/{ticket_code}`

#### Respon Sukses (HTTP 200 OK)
```json
{
  "success": true,
  "data": {
    "ticket_code": "TK-7F3KQ9",
    "status": "confirmed",
    "status_label": "Terkonfirmasi",
    "participant": {
      "name": "Yoga Gustira",
      "nim": "41524010001",
      "study_program": "Teknik Informatika"
    },
    "event": {
      "title": "Seminar Nasional AI 2026",
      "start_at": "2026-11-20T09:00:00+07:00",
      "end_at": "2026-11-20T12:30:00+07:00",
      "location": "Auditorium Tower UMB Meruya"
    },
    "amount_paid": 25137,
    "revision_notes": null,
    "checked_in_at": null,
    "unlocked_access": {
      "can_access_links": true,
      "wa_group_url": "https://chat.whatsapp.com/ExAmPlEgRoUpLiNk",
      "meeting_url": "https://zoom.us/j/98127391823"
    }
  }
}
```
*(Catatan Penting BR-13: Jika status bukan `confirmed`, `unlocked_access.can_access_links` akan bernilai `false` dan URL WhatsApp/Meeting bernilai `null`).*

---

### 5.3 Unggah Ulang Bukti (Saat Status `needs_revision`)
`POST /tickets/{ticket_code}/resubmit-proof`
*Headers: `multipart/form-data`*
- `payment_proof` (file): Gambar baru pengganti bukti sebelumnya.

---

### 5.4 Batalkan Tiket
`POST /tickets/{ticket_code}/cancel`

---

## 6. Modul Pemindai Tiket Panitia (`/panitia/check-in`)

### 6.1 Pemindaian QR Code Tiket (Scan)
`POST /panitia/check-in/scan`
*Headers: `Authorization: Bearer <TOKEN>` (Hanya role `admin`)*

#### Request Body
```json
{
  "event_id": 3,
  "ticket_code": "TK-7F3KQ9"
}
```

#### Respon 1: Check-in Berhasil (HTTP 200 OK)
```json
{
  "success": true,
  "status": "SUCCESS",
  "message": "Peserta berhasil check-in.",
  "data": {
    "ticket_code": "TK-7F3KQ9",
    "checked_in_at": "2026-11-20T08:32:15+07:00",
    "participant": {
      "name": "Yoga Gustira",
      "nim": "41524010001",
      "study_program": "Teknik Informatika",
      "cohort_year": 2024
    }
  }
}
```

#### Respon 2: Sudah Pernah Check-in Sebelumnya (HTTP 409 Conflict)
```json
{
  "success": false,
  "status": "ALREADY_CHECKED_IN",
  "message": "Tiket ini sudah pernah dipindai pada 08:15 WIB.",
  "data": {
    "first_checked_in_at": "2026-11-20T08:15:20+07:00",
    "participant_name": "Yoga Gustira"
  }
}
```

#### Respon 3: Tiket Tidak Ditemukan / Acara Salah (HTTP 404 Not Found)
```json
{
  "success": false,
  "status": "INVALID_TICKET",
  "message": "Kode tiket tidak valid atau bukan terdaftar untuk acara ini."
}
```

