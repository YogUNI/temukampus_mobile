# TemuKampus — Database Schema, Domain Entities & Invariants

Dokumen referensi skema database MySQL dan aturan invarian domain backend Laravel 13 untuk pengembang klien mobile Flutter.

---

## 1. Hubungan Antar Tabel (Entity Relationship)

```
┌──────────────┐       ┌─────────────────┐       ┌────────────────┐
│  FACULTIES   │───<   │ STUDY_PROGRAMS  │───<   │     USERS      │
└──────────────┘       └─────────────────┘       └────────────────┘
       │                        │                         │
       v                        v                         v
┌────────────────────────────────────────┐       ┌────────────────┐
│             ORGANIZATIONS              │───<   │  ORGANIZATION  │
│ (BEM, DPM, HIMA, UKM, UKK)             │       │    MEMBERS     │
└──────────────────┬─────────────────────┘       └────────────────┘
                   │
                   v
┌────────────────────────────────────────┐       ┌────────────────┐
│                 EVENTS                 │───<   │ REGISTRATIONS  │
│ (Katalog Acara Kampus)                 │       │ (Tiket Peserta)│
└──────────────────┬─────────────────────┘       └───────┬────────┘
                   │                                     │
         ┌─────────┴─────────┐                           v
         │                   │                 ┌──────────────────┐
         v                   v                 │   REGISTRATION   │
┌────────────────┐  ┌─────────────────┐        │   STATUS LOGS    │
│EVENT_FACULTIES │  │EVENT_STUDY_PROGS│        │  (Audit Trail)   │
└────────────────┘  └─────────────────┘        └──────────────────┘
```

---

## 2. Kamus Data & Entitas Utama

### 2.1 Entitas `User` (Pengguna / Mahasiswa)
- `id` (bigint): ID unik akun.
- `name` (string): Nama lengkap mahasiswa / peserta.
- `email` (string, unique): Alamat email aktif.
- `role` (enum: `user`, `admin`, `superadmin`):
  - `user`: Mahasiswa biasa / peserta umum.
  - `admin`: Panitia acara (anggota suatu organisasi).
  - `superadmin`: Pengelola platform kampus.
- `account_type` (enum: `umb`, `external`):
  - `umb`: Mahasiswa UMB resmi (wajib memiliki NIM 11 digit).
  - `external`: Peserta umum / non-UMB (mengisi `institution_name`).
- `nim` (char 11, nullable, unique): Format 11 digit angka.
- `study_program_id` (FK nullable): Program studi mahasiswa.
- `cohort_year` (smallint): Tahun angkatan (e.g. `2024`), diturunkan dari digit 4–5 NIM.
- `phone` (string): Nomor WhatsApp aktif untuk koordinasi darurat.
- `status` (enum: `active`, `suspended`): Akun yang disuspend tidak dapat login/mendaftar.

### 2.2 Entitas `Event` (Acara Kampus)
- `id` (bigint): ID acara.
- `organization_id` (FK): Organisasi penyelenggara acara.
- `title` (string): Judul kegiatan.
- `slug` (string, unique): Slug ramah URL.
- `summary` (string): Ringkasan 1–2 kalimat.
- `description` (text Markdown): Deskripsi lengkap, tata tertib, dan jadwal.
- `poster_path` (string): Path gambar poster resmi di storage public.
- `format` (enum: `offline`, `online`, `hybrid`).
- `location` (string): Lokasi fisik (e.g., "Auditorium Gedung Tower Lt. 7 Kampus Meruya").
- `start_at` & `end_at` (datetime): Waktu mulai dan selesai acara (WIB).
- `is_paid` (bool): `false` untuk acara gratis, `true` untuk berbayar.
- `price` (unsigned integer): Harga tiket dasar dalam rupiah (e.g., `25000`).
- `bank_name`, `bank_account_number`, `bank_account_name`: Rekening transfer panitia.
- `qris_path` (string nullable): Path gambar QRIS panitia.
- `has_unique_code` (bool): Jika true, sistem menambahkan kode acak 3 digit pada nominal transfer.
- `skp_points` (smallint): Poin SKP/SKPI mahasiswa (0 jika tidak ada).
- `has_certificate` (bool): Menandakan peserta berhak mendapat sertifikat.
- `audience` (enum: `public`, `umb_only`, `restricted`):
  - `public`: Terbuka untuk umum.
  - `umb_only`: Khusus mahasiswa UMB dengan akun `umb`.
  - `restricted`: Dibatasi fakultas/prodi dan rentang angkatan tertentu.
- `quota` (int nullable): Kuota maksimal peserta (null = tanpa batas).
- `status` (enum: `draft`, `published`, `cancelled`).
- `wa_group_link` (text encrypted): Tautan undangan grup WhatsApp peserta.
- `online_url` (text encrypted): Tautan Zoom/Google Meet.

### 2.3 Entitas `Registration` (Tiket & Pendaftaran)
- `id` (bigint): ID pendaftaran.
- `event_id` (FK) & `user_id` (FK): **Unique komposit (1 user hanya boleh punya 1 tiket aktif per event)**.
- `ticket_code` (string 8 char, unique): Format `TK-XXXXXX` (e.g., `TK-7F3KQ9`).
- `status` (enum):
  - `pending_verification`: Menunggu panitia memverifikasi bukti bayar.
  - `needs_revision`: Bukti bayar buram/kurang nominal; peserta wajib unggah ulang.
  - `confirmed`: Pendaftaran sah & disetujui; QR aktif & grup WA terbuka.
  - `rejected`: Ditolak secara permanen oleh panitia.
  - `cancelled`: Dibatalkan oleh peserta sebelum acara dimulai.
- `amount_due` (int): Nominal rupiah yang harus dibayar (Harga + Kode Unik, misal Rp 25.137).
- `unique_code` (smallint): 3 digit kode unik (misal 137).
- `payment_proof_path` (string nullable): Path bukti bayar di disk private.
- `payment_proof_hash` (char 64 nullable): SHA-256 hash untuk mendeteksi bukti transfer ganda.
- `checked_in_at` (datetime nullable): Waktu presensi kehadiran di hari-H acara.
- `checked_in_by` (FK user nullable): ID panitia yang memindai QR tiket peserta.

---

## 3. Invarian Bisnis Kritis (Business Rules Integrity)

1. **Aturan Kuota (Concurrency & Quota Integrity):**
   - Kuota peserta dihitung dari total pendaftaran dengan status:
     `pending_verification` + `needs_revision` + `confirmed`.
   - Backend melakukan `lockForUpdate` pada baris event di database saat pendaftaran berlangsung agar tidak terjadi overbooking.
2. **Kerahasiaan Akses (Privacy & Security):**
   - Kolom `wa_group_link` dan `online_url` disimpan secara terenkripsi (`AES-256-CBC`).
   - Backend **TIDAK AKAN PERNAH** membocorkan tautan ini ke klien mobile jika status tiket bukan `confirmed`.
3. **Immutabilitas NIM:**
   - NIM mahasiswa tidak boleh diubah dari aplikasi mobile setelah akun dibuat untuk mencegah pemalsuan identitas.
4. **Log Riwayat Status:**
   - Setiap perubahan status tiket (dari pending ke confirmed, rejected, atau needs_revision) dicatat secara append-only di tabel `registration_status_logs`.
